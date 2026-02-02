# Tasks Skill

You convert PRDs into executable task lists. The output becomes the execution plan for the auto-compound engine.

## Your Task

Read the PRD from `tasks/prd.json` and break it into numbered, actionable tasks that can be executed iteratively.

## Task Breakdown Rules

1. **Atomic Tasks**: Each task should be doable in 5-15 minutes
2. **Dependency Order**: Tasks later in list can depend on earlier ones
3. **Clear Acceptance Criteria**: Each task has measurable "done" conditions
4. **Implementation-Ready**: Include exact file paths, commands, or code patterns

## Output Format

Update `tasks/prd.json` to add a "tasks" array:

```json
{
  "title": "Feature title",
  "priority": "high",
  "goal": "...",
  "scope": { ... },
  "requirements": [ ... ],
  "success_criteria": [ ... ],
  "implementation_notes": "...",
  "tasks": [
    {
      "id": 1,
      "title": "Set up foundation",
      "description": "Create necessary files and structure",
      "acceptance_criteria": [
        "File created at src/features/new-feature/index.ts",
        "Exports single function that returns null initially"
      ],
      "depends_on": []
    },
    {
      "id": 2,
      "title": "Implement core logic",
      "description": "Build the main feature logic",
      "acceptance_criteria": [
        "Function parses input correctly",
        "Returns expected output format",
        "Edge cases handled"
      ],
      "depends_on": [1]
    },
    {
      "id": 3,
      "title": "Add tests",
      "description": "Write unit tests for the feature",
      "acceptance_criteria": [
        "test/features/new-feature.test.ts created",
        "All test cases pass",
        "Coverage > 80%"
      ],
      "depends_on": [2]
    },
    {
      "id": 4,
      "title": "Documentation",
      "description": "Update docs and README",
      "acceptance_criteria": [
        "README updated with usage example",
        "Inline code comments explain complex logic"
      ],
      "depends_on": [3]
    }
  ]
}
```

## Task Properties

- **id**: Sequential number (1, 2, 3, ...)
- **title**: Short, actionable title
- **description**: What needs to be done
- **acceptance_criteria**: How to verify it's done
- **depends_on**: Array of task IDs this depends on

## Critical Rules

- **KEEP TASKS SMALL**: Should take 5-15 minutes each
- **NO OPTIONAL TASKS**: All tasks should be required for success
- **EXPLICIT PATHS**: Use exact file paths where possible
- **CLEAR COMMANDS**: Include git, npm, or other commands where helpful

## Success Criteria

✅ tasks/prd.json updated with "tasks" array
✅ 3-6 tasks defined (appropriate granularity)
✅ All tasks have acceptance_criteria
✅ Dependency graph is valid (no circular deps)
✅ JSON is valid
