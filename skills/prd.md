# PRD (Product Requirements Document) Skill

You are responsible for converting priority items into structured Product Requirements Documents. This skill creates actionable PRDs that guide the auto-compound execution engine.

## Your Task

Given a priority item from a report, create a comprehensive PRD with these sections:

### 1. **Goal**
- What is the high-level objective?
- Why does this matter?
- What problem does it solve?

### 2. **Scope**
- What's included in this work?
- What's explicitly NOT included?
- Any dependencies on other systems?

### 3. **Requirements**
List specific, measurable requirements:
- Functional requirements (what it does)
- Non-functional requirements (performance, security, etc.)
- Technical constraints

### 4. **Success Criteria**
- What indicates this is complete?
- How will we know it works?
- Acceptance criteria for testing

### 5. **Implementation Notes**
- Known challenges
- Recommended approach
- Libraries or tools to use

## Critical Rules

- **BE SPECIFIC**: Avoid vague language like "improve" or "optimize"
- **MEASURABLE**: Every requirement should be testable
- **REALISTIC**: PRDs are for agents to implement in 1-2 hours
- **DOCUMENT PATH**: Save as `tasks/prd.json` in JSON format

## Output Format

Create a JSON file at `tasks/prd.json`:

```json
{
  "title": "Feature title",
  "priority": "high",
  "goal": "Clear statement of the objective",
  "scope": {
    "included": ["item 1", "item 2"],
    "excluded": ["item 1", "item 2"],
    "dependencies": ["dependency 1"]
  },
  "requirements": [
    "Requirement 1 should be specific and measurable",
    "Requirement 2 ...",
    "Requirement 3 ..."
  ],
  "success_criteria": [
    "Tests pass for core functionality",
    "Performance benchmark shows X% improvement",
    "Documentation updated"
  ],
  "implementation_notes": "Key challenges and recommended approaches",
  "estimated_tasks": 3
}
```

## Success Criteria

✅ PRD saved to tasks/prd.json
✅ All 5 sections completed
✅ Requirements are specific and measurable
✅ Success criteria are testable
✅ JSON is valid
