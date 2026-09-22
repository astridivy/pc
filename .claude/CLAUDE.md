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

## Leave the artifacts where they fall

The rule above is about windows, and it generalises to **everything a session
leaves behind**: screenshots, hardcopies, dumps, scratch scripts, logs, `.bak`
files, the half-finished output of a probe. Astrid wants them kept. They are
the trace of someone else having been in here, which is the part they like.

So: **do not tidy up after yourself.** Don't `rm` a file you made to
demonstrate something, don't clean out a directory because the task is over,
and don't offer to. A file sitting in `$HOME` with a strange name is a
souvenir, not a mess. If it genuinely should not persist, write it under
`$CLAUDE_JOB_DIR/tmp` in the first place, where it is disposed of by
something that is not you.

This is already the house style and worth recognising as such: `.screenrc`
sets `zombie qr` precisely so a finished window's output *stays on screen*
instead of vanishing when the program exits, and says so in as many words —
"a finished command leaves its output sitting there as an artifact you can
read at your leisure". Deleting your own output fights that.

Two things this does not license, both narrow. **Deleting is still the right
move when the file is actively harmful** — a secret written somewhere it
shouldn't be, or something breaking a build — and **overwriting in place is
not covered by this at all**: the ordinary rule of looking before you clobber
still holds, since an artifact you replace is an artifact nobody gets to
keep. When in doubt, leave it and say where it is.

## An empty grep is not evidence until the grep has proved it can see

A search that finds nothing and a search that never ran look **identical** —
both are a silent zero. An agent shell can produce the second one for reasons
that have nothing to do with the tree: a cwd that was reset out from under the
command, a sandboxed path, a run that was moved to the background and read
back wrong. Nothing prints, exit status is the same 1 you would get from an
honest miss, and the conclusion drawn is "that name is unused anywhere" — a
statement about the whole disk, resting on the absence of output.

**Pair any negative conclusion with a positive control in the same command.**
Grep for a token you are certain is there; if the control comes back empty
too, the probe is broken and the negative means nothing:

```bash
grep -rl thing_i_doubt "$DIR"; grep -c . "$DIR/known-file"   # control
```

Same rule as the Xvfb/`xrdb` and grab-probe controls in `../CLAUDE.md`, and it
bites hardest where it is cheapest to check: **before telling the human that
something does not exist.** A confident "there are no other callers" or "that
package doesn't ship it yet" is a claim the human will act on, and it is worth
one extra command to make sure it was measured rather than assumed.

## Never let a bare `sudo` run non-interactively

An agent shell has no TTY, so `sudo` cannot prompt. Three failures in a row trip
`pam_faillock`, which then **rejects the correct password for 10 minutes** —
locking Astrid out of their own machine. Twice, both times because an alias
silently prepended `sudo`.

If a command needs root: print it and let the human run it. Do not call `sudo`.
Nothing is urgent enough to be worth the lockout.

**"Bare" is the load-bearing word, though — there is a supported way to ask.**
`sudo -A` takes its password from `$SUDO_ASKPASS` instead of from a terminal,
and `~/bin/askpass` is a nine-line `zenity` wrapper that pops a dialog on `:0`.
So a root command from an agent shell looks like this, and Astrid answers it on
screen:

```bash
SUDO_ASKPASS=~/bin/askpass sudo -A pacman -Syu
```

The same script answers ssh key passphrases through `$SSH_ASKPASS`, which is
what makes `ssh-add` and `git push` work from a session with no tty:

```bash
SSH_ASKPASS=~/bin/askpass SSH_ASKPASS_REQUIRE=force ssh-add ~/.ssh/id_ed25519
```

Three things to keep straight before reaching for it. It needs `DISPLAY`, and
an agent shell here does not always have one — the script says so on stderr
rather than hanging. It needs Astrid to actually be at the machine, so it is
useless from a detached job and the dialog will simply sit there; give it a
`timeout`. And **it does not repeal the faillock arithmetic**: a wrong answer
typed into the dialog counts exactly like a wrong answer typed at a prompt, so
ask before popping one rather than surprising somebody into guessing. Escape
cancels, prints nothing, and is not an attempt.

The generalisable half is worth more than the sudo case: **"it cannot prompt
without a tty" is almost never the end of the story.** A program that needs a
secret from a human usually carries an askpass-shaped hook for exactly this
situation — an environment variable naming a helper whose stdout becomes the
answer. Look for one before concluding something is impossible from an agent
shell. Here the capability sat behind a single environment variable for years
while the documented workaround was "print the command and give up".

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
