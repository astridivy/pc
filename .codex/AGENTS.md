# Global working agreements

## Commits

- When making a Git commit, use `~/bin/commas` instead of invoking `git commit`
  directly. This helper is the one commit path for every repository.

## Turn closure

- At the end of every substantial turn, leave closure in the repository where
  the work occurred.
- Append unfinished work to `TODO.md`.
- Append preventable problems that tripped up the agent to `FANGS.md`, with
  enough context to keep a later run from repeating them.
- Append completely finished work to `CHANGELOG.md`.
- Create any of those Markdown files when needed and absent.
- `TODO.md`, `FANGS.md`, and `CHANGELOG.md` are swept automatically by a
  background roomba. Keep them short and greppable; embed an entry directly
  only when immediate recall is actually needed.
- Commit the completed turn closure to `master` with `~/bin/commas`; do not
  push.
- `/home/ai` itself must not be made into a Git repository. Only make closure
  commits inside an existing repository. Work outside a repository does not
  authorize initializing one merely to make a closure commit.

## Yggdrasill

- In any project with a `<project-root>/ygg` tree, use the global `ygg` skill
  proactively whenever its stored knowledge could inform the work.
- Ask the tree before touching an unfamiliar mechanism, especially to learn why
  it is shaped that way, what it cost, and whether it has bitten us before.
- Tell the tree after learning a durable fact, fang, decision, or measured
  number that a future session would need.
- Follow the skill's per-project routing rules. Embedding uses an append-only
  queue that background work drains eventually; do not wait on or manage it.

## Mimir

- Yggdrasill is what is *known*; Mimir is what *happened*. Mimir is a dated
  list of episodes across every repository, which is to say the changelog.
- `/anima/bin/mimir` is the binary. It runs from any directory and needs nothing
  from the environment. `--help` is the manual.
- Read it at the start of a turn — `/anima/bin/mimir | head -20` answers "what
  have we been up to lately", and `--in <story>` narrows to one repository.
- Write to it at the end of a substantial turn:
  `/anima/bin/mimir tell '<title>' --says '<body>'`, or with the body on stdin
  for anything longer. A title alone is a valid episode.
- The story is not an argument: it is the repository you are standing in,
  taken from the nearest ancestor holding a `.git`. Do not pass `--story`
  unless the episode genuinely belongs somewhere else.
- This does not replace the `CHANGELOG.md` closure above and is not a
  duplicate of it. The changelog is what shipped, in one repository, for a
  human. The shelf is what the work was like, across all of them, and it is
  cross-agent: Ivy, Claude Code and Codex share one list, and each row records
  who wrote it without anyone declaring it.
