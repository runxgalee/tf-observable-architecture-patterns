---
description: Use task-planner agent to break down and elaborate tasks
---

## Task

Use the Task tool with `subagent_type=task-planner` to help refine vague requests into well-structured, actionable tasks through iterative questioning and collaborative planning.

### Arguments

Pass the user's task description or request as the prompt to the task-planner agent. If arguments are provided, use them as the initial task description. If no arguments are provided, ask the user what they want to plan.

### When to Use

- User has a vague or high-level request that needs clarification
- Task requires breaking down into smaller steps
- Need to explore different approaches before implementation
- Want to collaboratively define requirements and scope

### Example

```
User: /plan-task Add authentication to the application
- Launch task-planner agent to help elaborate requirements
- Agent will ask questions about auth methods, user flows, etc.
- Collaboratively define the detailed implementation plan
```
