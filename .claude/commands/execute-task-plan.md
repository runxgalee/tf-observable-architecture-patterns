---
description: Execute tasks using task-orchestrator subagent based on task-estimate file
---

## Task

Use the Task tool with `subagent_type=task-orchestrator` to execute the implementation plan defined in the specified task-estimate file.

### Arguments

If the user provides a file path argument, read that task-estimate file first to understand the plan. If no argument is provided, search for recent task-estimate files in the `docs/` directory.

### Steps

1. Read the specified task-estimate file (or find the most recent one if not specified)
2. Review the task breakdown, execution flow, and implementation steps
3. Launch the task-orchestrator agent with a prompt that includes:
   - Reference to the task-estimate file location
   - Instructions to follow the documented plan
   - Any specific requirements from the task breakdown

### Example

```
User provides: /execute-task-plan docs/task-estimates/feature-implementation.md
- Read the task-estimate file
- Launch task-orchestrator with the plan details
```
