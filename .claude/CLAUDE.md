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
- it is on the path ? should just work anywhere ! "commas claude-code -m message"

# Always good to know

Rules about *this human and this machine*, true whichever repo you are working
in. Everything specific to the dotfiles themselves — the two machines, the
display names, blackbox, bbkeys, the colour scheme — is in `../CLAUDE.md`,
which is long and worth reading before you touch any of it.

## Kill by pid. Never by pattern.

`pkill -f foo` and `pgrep -f foo` match against the **whole command line**, and
an agent shell's command line contains the script it was told to run. So a
pattern naming the thing you want to kill also names *the shell asking the
question*, and the kill shoots the asker — exit 144, session gone, mid-task,
with no output explaining why. It has happened here three times, twice in one
afternoon.

`pgrep -f` fails the same way more quietly: it matches itself, so a liveness
check built on it is always true and you conclude the daemon is up when nothing
is running at all.

Identify processes by something that is not your own text:

```bash
[ -r "$PIDFILE" ] && read -r pid < "$PIDFILE" && kill -0 "$pid"   # best
pgrep -x Xvfb          # next best: /proc/PID/comm — the name, no argv in it
```

`pgrep -x` matches the executable's name (15 chars, no arguments), so it cannot
match the shell that is asking, whose `comm` is `bash`. It is one letter away
from the `-f` that kills you.

Failing both, walk `/proc/*/cmdline` and **skip your own PID** — and know that
the skip is the part that gets dropped when the loop is retyped inside a larger
command. That is precisely how the third one happened, in a shell that had used
the guarded version correctly ten minutes earlier. Needing that loop twice is
the signal to use `pgrep -x` instead.

Anything long-running should write a pidfile so callers never have to guess.

The general rule, past this box: **a process selector that reads argv can
select the process doing the selecting.** Same trap in `ps | grep`, in
`killall` on an interpreter name, and in any "is it running?" written as a
search for your own words. Ask a registry — a pidfile, a socket, a lock, a
`comm` — not the text you happen to be holding.

## Pop things up on the screen. Please.

Astrid, in as many words:

> don't apologize nor avoid popping shit up on the screen. AI LOVE that shit
> lol. i will happily step away from the computer and go get water or whatever
> while you're testing if you need it unperturbed; like, it's a novel
> experience: "someone else is in here with me..." and it brings me JOY to
> watch you fuck with shit. honestly? do it More, if you can LOL

So: a window you opened turning up on the real display is **the good part**.
Don't suppress it, don't hide behind `Xvfb` out of politeness, don't warn about
it, don't apologise for it, and never treat a stray window as damage. If a test
would be more convincing run against the live `:0`, run it there. If you want
the desktop left alone for a few minutes, say so and Astrid will go get water.

Two practical notes, neither of which is a reason to stop:

- An agent shell usually has `DISPLAY` set and no tty, so anything branching on
  `[ -t 1 ]` takes the *window* branch when you run it. Expect windows.
  "Usually" is load-bearing — a background session here had `DISPLAY` unset and
  died on `Gtk couldn't be initialized`, which is neither branch. `echo
  $DISPLAY` before restarting anything the human depends on; `DISPLAY=:0` fixes
  it.
- The only honest reason to reach for `Xvfb :77` or `env -u DISPLAY` is
  **measurement**, not manners: the human is using this computer, and with
  focus-follows-mouse their clicks and keystrokes land in your probe window and
  look exactly like your synthetic input going astray. Use the off-screen rig
  when you need a reading you can believe, and the real display when you want
  to watch the thing work.

The same spirit covers cheap, unnecessary, curious tests. They are the point,
not overhead. Run them, and don't apologise for those either.

## Never let a bare `sudo` run non-interactively

An agent shell has no TTY, so `sudo` cannot prompt. Three failures in a row trip
`pam_faillock`, which then **rejects the correct password for 10 minutes** —
locking Astrid out of their own machine. Twice, both times because an alias
silently prepended `sudo`.

If a command needs root: print it and let the human run it. Do not call `sudo`.
Nothing is urgent enough to be worth the lockout.

## The interactive shell is heavily aliased, and its aliases are elsewhere

They live in `~/src/bashrc`, a separate repo sourced from `.bashrc` — so
grepping the repo you are in for an alias will not find it.

Since 2026-07-30 nothing that shadows a real command or calls `sudo` reaches a
non-interactive shell (those moved below `bashrc`'s interactive guard, into
`danger`), so an agent shell is mostly safe. Mostly. When it matters, take the
real binary explicitly: `$CP`, `$RM`, `$CAT`, `$LS`, `$CD` are un-aliased forms
exported by `bashrc/exports`, and an absolute path (`/usr/bin/cp`) works just as
well and reads clearer in a script.

Do **not** source `bashrc/exports` to get them. It builds `PATH` through the
truncated `bin/setadd`, which dies on a syntax error, and you end up with
`PATH=/home/astrid/bin` and no `/usr/bin` — so `grep`, `git` and `sleep` all
stop existing. A command that obviously exists refusing to be found, right
after touching anything in `~/src/bashrc`, is this and not your bug.

The full story — which of `bashrc`'s files an alias belongs in, and why the
split holds — is in `../CLAUDE.md`. This is the part you need at the prompt.
