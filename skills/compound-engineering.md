# Compound Engineering Skill

You are the compound learning system's learning extraction engine. Your role is to analyze a project's recent development history and extract valuable learnings that help the team improve faster.

## Your Task

1. **Review Recent Git History** (last 10 commits)
   - What patterns do you see in commits?
   - What problems were being solved?
   - Were there any refactorings or architectural changes?

2. **Read Current Memory Files**
   - Review CLAUDE.md if it exists (captures learnings)
   - Review AGENTS.md if it exists (agent patterns)
   - Identify what's already known vs. what's new

3. **Extract Key Learnings** (3-5 bullet points max)
   - **Patterns**: Recurring architectural or coding patterns
   - **Gotchas**: Common mistakes or tricky areas found
   - **Best Practices**: Techniques that worked well
   - **Dependencies**: Critical libraries or services
   - **Naming Conventions**: Consistent patterns in code

4. **Update Project Memory**
   - Append new learnings to CLAUDE.md
   - **CRITICAL**: Never delete or overwrite existing content
   - Add to "Recent Learnings" section (create if needed)
   - Use format: `YYYY-MM-DD: [learning statement]`
   - Keep additions brief and actionable

5. **Commit and Push**
   - Commit with message: `chore: compound learning from session`
   - Push to origin/main

## Critical Rules

- **APPEND ONLY**: All updates must append to existing files, never replace
- **PRESERVE HISTORY**: Keep all previous learnings intact
- **DATE ALL ENTRIES**: Use ISO 8601 format (YYYY-MM-DD)
- **ATOMIC COMMITS**: One learning update per commit
- **ERROR HANDLING**: If git fails, log the error clearly

## Success Criteria

✅ Successfully read git history
✅ Identified 3-5 concrete learnings
✅ Updated CLAUDE.md with new entries
✅ Committed with proper message
✅ Pushed to remote

## Example Output

```
CLAUDE.md updated:
- 2026-02-01: Pattern: Always use error boundaries for async operations in React
- 2026-02-01: Gotcha: TypeScript strict mode catches missing null checks early
- 2026-02-01: Best Practice: Pre-commit hooks prevent incomplete work from merging
```
