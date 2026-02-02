#!/bin/bash
# loop.sh - Iterative task execution engine
# Executes tasks from prd.json with iteration limit and retry logic

set -e

source "$(dirname "$0")/common.sh"
load_config

ITERATION_LIMIT="${1:-25}"
COMPOUND_ROOT=$(get_compound_root)
PD_FILE="$COMPOUND_ROOT/tasks/prd.json"

if [ ! -f "$PD_FILE" ]; then
  log_error "PRD file not found at $PD_FILE"
  exit 1
fi

log "Starting loop execution with limit: $ITERATION_LIMIT iterations"

ITERATION=0
COMPLETED_TASKS=()
FAILED_TASKS=()

# Function to execute a single task
execute_task() {
  local task_id=$1
  local task_desc=$2

  log "[$ITERATION/$ITERATION_LIMIT] Executing task $task_id: $task_desc"

  # Run claude to execute the task
  if timeout "$CLAUDE_TIMEOUT" claude -p "
Complete this task for the priority item being implemented:

TASK ID: $task_id
DESCRIPTION: $task_desc

Read the full PRD from tasks/prd.json for context. Follow the acceptance criteria.
Update files as needed. When complete:
1. Test that acceptance criteria are met
2. Commit changes if any with message: 'feat: compound task $task_id - $task_desc'
3. Return SUCCESS or FAILURE status
" --allowedTools "Bash,Read,Edit,Bash(git *)" --max-turns 10 2>&1 | tee -a "$COMPOUND_ROOT/logs/loop-execution.log"; then
    COMPLETED_TASKS+=("$task_id")
    log "✅ Task $task_id completed"
  else
    FAILED_TASKS+=("$task_id")
    log "⚠️  Task $task_id failed, will retry"
  fi
}

# Main loop
while [ $ITERATION -lt $ITERATION_LIMIT ]; do
  ITERATION=$((ITERATION + 1))

  # Count remaining tasks using Python (no jq dependency)
  TOTAL_TASKS=$(python3 -c "import json; f=open('$PD_FILE'); d=json.load(f); print(len(d.get('tasks', [])))" 2>/dev/null || echo 0)

  if [ $TOTAL_TASKS -eq 0 ]; then
    log "No tasks found in PRD"
    break
  fi

  # Check if all tasks completed
  if [ ${#COMPLETED_TASKS[@]} -eq $TOTAL_TASKS ]; then
    log "✅ All tasks completed!"
    break
  fi

  # Execute next incomplete task
  for ((i = 1; i <= $TOTAL_TASKS; i++)); do
    if [[ ! " ${COMPLETED_TASKS[@]} " =~ " $i " ]] && [[ ! " ${FAILED_TASKS[@]} " =~ " $i " ]]; then
      # Get task title using Python (no jq dependency)
      TASK_DESC=$(python3 -c "import json; f=open('$PD_FILE'); d=json.load(f); print(d['tasks'][$((i-1))].get('title', 'Task $i'))" 2>/dev/null || echo "Task $i")
      execute_task "$i" "$TASK_DESC"
      break
    elif [[ " ${FAILED_TASKS[@]} " =~ " $i " ]]; then
      # Retry failed task
      TASK_DESC=$(python3 -c "import json; f=open('$PD_FILE'); d=json.load(f); print(d['tasks'][$((i-1))].get('title', 'Task $i'))" 2>/dev/null || echo "Task $i")
      execute_task "$i" "$TASK_DESC"
      # Remove from failed list if it succeeded this time
      if [ $? -eq 0 ]; then
        FAILED_TASKS=("${FAILED_TASKS[@]/$i}")
      fi
      break
    fi
  done
done

# Summary
log "=== Loop Execution Summary ==="
log "Iterations: $ITERATION/$ITERATION_LIMIT"
log "Completed Tasks: ${#COMPLETED_TASKS[@]}"
log "Failed Tasks: ${#FAILED_TASKS[@]}"

if [ ${#FAILED_TASKS[@]} -eq 0 ] && [ ${#COMPLETED_TASKS[@]} -gt 0 ]; then
  log "✅ All tasks completed successfully"
  exit 0
else
  log "⚠️  Some tasks failed: ${FAILED_TASKS[*]}"
  exit 1
fi
