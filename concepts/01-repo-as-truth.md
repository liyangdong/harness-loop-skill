## 1. Repo as Truth

If it is not in the repo, it does not exist for the agent.

### Why it matters

Agents start every iteration with a fresh read of the repository. Anything living in
Slack DMs, Google Docs, Notion, a video call summary, or someone's head is **invisible**
to that fresh read. The agent cannot ask "what did the team decide last week?" — it can
only ask "what does the repo say right now?"

This is the single largest source of agent confusion in real projects: a human reviewer
remembers the conversation that produced a decision, the agent does not. The agent then
re-litigates the decision, rewrites working code, or contradicts an earlier choice. Every
re-litigation burns throughput and erodes trust in the constraint system.

The fix is structural, not procedural: decisions must live in versioned files the agent
can read. A decision written in Slack is a decision the agent has not seen.

### How to apply

- Every architectural decision gets an ADR (`docs/specs/decisions/NNNN-*.md`).
- Every "we agreed to do X" lives in a comment in code, a `TASKS.md` entry, or a
  `state/` log line — not in chat.
- When a human reviews agent output and finds an error, the fix is a repo edit (new
  check, new AGENTS.md line, new test) — never "I'll just tell the agent next time".
- `state/iteration.md` is the agent's short-term memory; it is rebuilt from disk each
  iteration, never from session history.
- Treat the repo as the **only** channel: if a teammate wants to constrain the agent,
  they open a PR, not a chat thread.

### Anti-patterns

- "We decided in standup yesterday to use library X." — not in repo, agent picks Y.
- Reviewer feedback given only as a chat message: the next iteration forgets it.
- Tribal knowledge like "don't touch the `legacy/` folder" living only in a senior dev's
  head. Encode it in `AGENTS.md` or `scripts/check-*.sh`.
- ADR written to a wiki but not committed to `docs/specs/decisions/`.

### References

- `state/iteration.md` — short-term agent memory on disk
- Concept 03 — mechanical enforcement turns repo decisions into invariants
- deusyu/harness-engineering — "Disk Is State, Git Is Memory"
