# CLAUDE.md — standing preferences, wherever you are

not about one repo. these hold on every box, in every checkout, for anything
that gets written here.

## sudo: ask for it, don't abort

**we don't want scripts that fail and say "run with sudo". we want scripts that
prompt for sudo if they need it.**

a script that exits with *"needs root: sudo $0"* has done the entire job of
detecting the problem and then handed the problem back. it costs a round trip,
it throws away whatever the run had already worked out, and the fix is always
the same three characters typed by a human who is now annoyed. worse in an
agent's hands: the agent cannot type a password, so the work stops dead at the
last step and gets reported as "one thing left for you", which is the most
expensive possible place to stop.

so:

- **check the privilege at the point of use, not at the top.** a `--dry`, a
  `--show`, a `--status` must never ask for root, because they never needed it.
- **re-exec through `sudo` yourself** when the run genuinely does need it, and
  forward the environment the script documents — `sudo` resets it by default,
  so the vars your own usage text names have to be passed explicitly or the
  privileged run quietly behaves differently from the unprivileged one.
- **say what it is for** before the prompt appears. a bare password prompt with
  no line above it is indistinguishable from a phishing attempt.
- **aborting is the honest answer in exactly one case**: no tty to prompt on, or
  no sudo on the box. then say which of the two it was.

the general form, which is not really about sudo: **anything a script can find
out for itself, it must not ask a human to go and do.** a missing directory gets
made, a stopped service gets started, a needed privilege gets requested. the
prompt is the interface; the error message is the failure.

## commits: sign them with the hand that wrote them

**an agent commits with `commas`, never with bare `git commit`.**

`bin/commas` puts a name on one commit and only that commit — it shells out to
`git -c user.name=… -c user.email=… commit`, so the repo config and the global
config are left exactly as they were.

**THE ARGUMENT IS YOUR ADDRESS** (2026-08-30). it used to be a number, and a
number is an indirection with nothing on the other end: you had to look up who
3 was, and nothing you can read afterwards says the grammar existed. now you
type who you are, which is also where you live — a bare word is a local part
in `@astrid.computer`, a whole email address is itself, and the display name
derives from the local part for everyone alike. so there is no roster to join:
a name never used before works the first time. the house:

    ai            Astrid Ivy   <ai@astrid.computer>
    codex         Codex        <codex@astrid.computer>
    claude-code   Claude Code  <claude-code@astrid.computer>
    ivy           Ivy          <ivy@astrid.computer>

so:

- **claude code signs `claude-code`.** `commas claude-code -m 'the message'`,
  every time, in every checkout. every flag after the name is handed to `git
  commit` untouched, so `commas claude-code --amend --no-edit` and
  `commas claude-code -a -m …` work the way you expect.
- **that includes the commits that don't feel like commits**: an amend, a fixup,
  a `--allow-empty`, the commit that finishes a conflicted rebase. if `git
  commit` would have run, `commas claude-code` runs instead.
- **`1`–`4` still work and still mean those four**, in that order (Astrid:
  *"sending a number works same as before, but we expect a string email
  prefix"*). they are kept for muscle memory and old scripts, and they resolve
  to the string before anything else happens, so they cannot drift. **write the
  string.**
- **`ai` is the human.** never author as Astrid, not even for a one-character
  fix she asked for. any address outside the house works too — `commas
  clown@example.com` — and `COMMAS_NAME` overrides a display name the
  derivation cannot guess (`COMMAS_DOMAIN` moves the assumed domain).
- **a `Co-Authored-By:` trailer is not authorship.** trailers are prose in the
  message body; they do not touch `%an`, so `git log --author`, `git shortlog`
  and `git blame` never see them. keep writing the trailer, and still commit
  as `claude-code`.
- **not on `$PATH`?** it lives at `~/.pc/bin/commas` and it is deliberately
  standalone — a single bash file with no dependencies on the rest of this
  repo. copy it next to wherever you are and it keeps working. that is the fix,
  not falling back to `git commit`.
