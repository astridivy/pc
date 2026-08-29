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
