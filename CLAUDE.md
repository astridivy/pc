# CLAUDE.md

Dotfiles for `ivy`, an Acer Aspire 5741G running Arch. **This repo is `$HOME`.**
Paths here mirror their destination (`bin/`, `.config/`, `.blackbox/`), and
`link.sh` symlinks them into place:

```bash
./link.sh bin .vimrc .inputrc     # ln -s $REPO/$T -T ~/$T, backing up any existing file
```

Nothing is copied. Editing `~/bin/google` *is* editing `bin/google` here.

`link.sh` links **files, not directories**, unless the directory has no
counterpart in `$HOME` yet. Its backup step is a plain `cp` and its link step is
`ln -T`, so against an existing dotdir both refuse (`cp: -r not specified` /
`ln: cannot overwrite directory`) and nothing happens — noisy and harmless, but
it means `./link.sh .ssh` does not do what it looks like it does. That's the
right behaviour to keep: a dotdir like `~/.ssh` holds live files the repo must
never own (`id_rsa`, `authorized_keys`, `known_hosts`), and replacing the whole
directory with a symlink would take them out of the only place their tools look
for them. Link the individual file instead — `./link.sh .ssh/config` — which is
how `~/.ssh/config` is wired up.

Corollary for anything secret-adjacent: give it a deny-by-default rule in
`.gitignore` and allowlist the one file that belongs (`.ssh/*` then
`!.ssh/config`). This repo is `$HOME`, so an unignored key is one `git add .`
from being committed.

## This machine is cursed. Read this before running anything.

The interactive shell is heavily aliased. The aliases live in **`~/src/bashrc`**
— a *separate* repo, pulled in via the `~/lib/bashrc` symlink and the `import`
function in `~/.cutestrap`. Grepping this repo for an alias will not find it.

### Never let a bare `sudo` run non-interactively

An agent shell has no TTY, so `sudo` cannot prompt for a password. Three failed
attempts in a row trip `pam_faillock`, which then **rejects the correct password
for 10 minutes** — locking Astrid out of their own machine. This has happened
twice, both times because an alias silently prepended `sudo`.

If a command needs root: print it and let the human run it. Do not call `sudo`.

### Aliases no longer reach non-interactive shells

**Fixed 2026-07-30.** Every alias that shadowed a real command — `cp -i`,
`mv -i`, `cd`, `cat`, `ls`, `grep`, `tree`, `info`, `lynx` — and every alias
that called `sudo` — `visudo`, `umount`, `shutdown`, `restart`, `suspend` —
moved from `bashrc/aliases` into `bashrc/danger`.

`bashrc` sources `danger` *after* its `[[ $- != *i* ]] && return` guard, so
scripts, cron jobs and agent shells now see none of them, while an interactive
terminal is completely unchanged. Verified in both directions: all 15 absent
from `bash -lc`, all 43 original aliases still present under `bash -ic`.

What remains in `aliases`, and so still reaches a non-interactive shell, is
new names only — `la`, `lsl`, `wifi`, `stop`, `whattime`, `desktop`, `vimrc`,
`tree~` and friends. None of them shadow anything real.

**The invariant that keeps this true:** `aliases` is above the guard and may
only ever define *new names*; anything overriding an existing binary or shell
builtin, or invoking `sudo`, belongs in `danger` below it. Both files state
this in their header comments. Put new aliases in the correct one.

`pacman` and `systemctl` used to be `sudo`-aliased too. They were removed on
2026-07-29 because they caused the lockouts — typing `sudo` yourself is fine.

This does **not** retire the faillock warning above. It removes the trapdoor
where an alias appended `sudo` behind your back; a `sudo` you type yourself is
still a `sudo` with no TTY to answer.

### Use the escape-hatch variables

`~/src/bashrc/exports` defines un-aliased forms. Bash expands aliases on the
literal token, so `$CP` is **never** alias-expanded — this is the reliable way
to get the real binary:

| var | value |
|---|---|
| `$LS` | `ls --color=auto --hide="lost+found"` |
| `$CP` | `cp` — no `-i`, will not hang |
| `$RM` | `rm` |
| `$CAT` | `cat` |
| `$CD` | `cd` |

Absolute paths (`/usr/bin/cp`, `/usr/bin/pacman`) work equally well and are
clearer in scripts. Prefer either over the bare command.

### The root filesystem is 38G smaller than its own partition

`/dev/sda1` is a **92G partition containing a 55G ext4 filesystem**. The
partition was grown at some point and `resize2fs` was never run, so ~38G is
sitting there unreachable. `/home` is *not* a separate mount — it is on `/` —
so dotfiles, `~/src`, npm caches and the system all compete for the same 55G.
Verified 2026-07-30: fs 58862960640 B, partition 98784247808 B.

This is the real reason the disk "keeps filling up", and it is one online
command to fix (ext4 grows while mounted). It needs root, so print it and let
Astrid run it — see the faillock warning above:

```bash
sudo resize2fs /dev/sda1
```

Until that happens, headroom is thin enough that a big upgrade can exhaust it.
On 2026-07-30 a long-deferred full-system upgrade took `/` to **0 bytes
available**, which is not a warning state — writes fail half-finished and
things corrupt. The bulk was `/var/cache/pacman/pkg` at **14G across 8441
archives**; pacman never prunes it on its own, and it grows by roughly the
size of every upgrade you have ever done.

- `pacman -Sc` drops cached packages for versions no longer installed.
- `paccache -rk1` is finer-grained, but **`pacman-contrib` is not installed**,
  so that command does not currently exist here. Don't suggest it as if it did.
- `journalctl --vacuum-size=200M` caps the journal, a standing ~960M.
- `/mnt/datao` (`sda2`, 138G, ~23G free) is the roomy partition. Large scratch
  output belongs there, not under `$HOME`.

Check `df -h /` before anything that writes a lot. A `du -x` sweep of `/` on
this hardware takes minutes and is usually the wrong tool — `df` first, and
only then `du` on the one directory that looks suspicious.

## Layout

- `bin/` — personal scripts, symlinked as `~/bin` (on `$PATH`)
- `.config/keyledsd.conf` — per-application RGB keyboard profiles (Logitech, via
  `keyledsd`). Profiles match on window class; effects are composited in order.
- `.blackbox/menu`, `.blackboxrc` — Blackbox WM. There is no desktop
  environment; X starts from a tty via the `desktop` alias.
- `.config/alacritty/` — `alacritty.toml` is the base (colours, font, bell,
  keybinds) and is found automatically; `tall/medium/bitsy/eensy/xlarge.toml`
  each `import` it and override only window geometry. Edit colours in the base
  once, not six times. Alacritty dropped YAML in 0.14, so the old
  `~/.alacritty.*.yml` are gone — anything passing `--config-file` wants the
  `.toml` paths (`bin/{watbat,watsen,watempo,volumectl,clock}`,
  `.blackbox/menu`).
- `.config/ardour{7,8}/` — one directory per Ardour major version. When
  upgrading, copy the *live* `~/.config/ardourN/` files in; don't `cp -r` the
  previous version's directory, which silently enshrines stale keybindings.
- `etc/`, `usr/` — files destined for system paths, staged for manual install.

## Linting

ESLint is flat-config only since v9; v10 dropped `.eslintrc` support entirely.
`eslint.config.js` lives here and `link.sh` symlinks it to
`~/eslint.config.js`, so it covers any stray `.js` under `$HOME` that has no
config of its own -- eslint searches *upward* from the file being linted. The
old setup was never symlinked out, which is why it silently linted nothing
outside this repo.

The toolchain is npm-global rather than pacman's (pacman ships eslint too, but
`$PATH` puts `~/.npm/packages/bin` first, so npm's wins -- and `eslint_d` has
to resolve `eslint` from the same tree):

```bash
npm i -g eslint eslint_d @eslint/js globals eslint-formatter-compact
```

Use **`eslint_d`**, not `eslint`. It keeps a daemon resident and is ~3x faster
on this hardware (185ms vs 574ms), which matters on a 2010 i5.

`eslint-formatter-compact` is not optional — syntastic's eslint checker
hardcodes `-f compact`, and eslint 10 moved that formatter out of core. Without
it every run exits 2 with a message matching no `errorformat`, so vim reports
**zero errors on every file** rather than an error. Symptom: linting looks
"clean" no matter how broken the JS is. `.vimrc` pins the checker to `eslint_d`
via `g:syntastic_javascript_eslint_exec`.

`NODE_PATH` in `bashrc/exports` is what lets a config living in `$HOME`
resolve globally-installed modules -- without it `require("@eslint/js")` fails.

### gone: the orphaned `~/src/node_modules`

Deleted 2026-07-30. It was 112 packages with no `package.json` -- a stray
eslint 7 tree that nothing declared. Recorded here because the failure it
caused is worth recognising if a `node_modules` ever reappears up there.

Node resolves requires by **realpath**, so `~/eslint.config.js` dereferenced to
`~/src/pc/eslint.config.js` and walked up into it, shadowing globally-installed
packages for everything under `~/src`. It served an ancient `globals` whose
`"AudioWorkletGlobalScope "` key has a trailing space, which eslint 10 rejects
outright; the config still normalises global keys defensively.

It bit `eslint_d` harder than plain `eslint`. `eslint_d` resolves the *eslint
library* by walking `node_modules` up from cwd, so under `~/src` it loaded that
tree's **eslint 7**, which predates flat config and died with `No ESLint
configuration found` -- while plain `eslint`, being the global binary, worked
fine. If the two ever disagree again, suspect a local `node_modules` first.

## Open work

- `~/src/diet-vhost` and `~/src/maitre-d` declare dependencies but have no
  `node_modules` of their own -- they need an `npm install` before they'll run.
  (Unrelated to the orphan deleted above; their deps were never in it.)

## Conventions

- Commit messages are lowercase, informal, and explain *why*. Match that.
- Old commits carry an older email on purpose — **never rewrite history to
  normalize author identity.** It was true when written.
- `.claude/` is gitignored.

## All tasks

Getting the thing working is the middle of a task, not the end. Close every
one with this sequence:

**1. Commit.** Part of the close sequence, not a separate request — don't leave
a dirty tree and report the job done. Note that work here often spans two
repos: `~/src/pc` and `~/src/bashrc` each need their own commit. Push only if
asked.

**2. Post-mortem, then write it down.** Ask one question: *was there a step in
this task I would not have needed to take — or a wrong turn I would not have
taken — if CLAUDE.md had already told me something?* If yes, add it here, in
the section it belongs to, and include it in the same commit.

Write the instruction **generally**. The next reader needs the rule that
prevents the trap, not a report of the incident that revealed it:

- ✗ "the `globals` package shipped a key with a trailing space and eslint 10
  rejected it" — an anecdote; only fires again on that exact package
- ✓ "node resolves requires by **realpath**, so a config symlinked into `$HOME`
  picks up `node_modules` from wherever the file actually lives" — a rule that
  catches the whole family of failures

Bias toward writing it down. Anything that cost twenty minutes, or that
silently did nothing while appearing to work, earns three lines here — the
silent-success failures especially, since nothing else will ever surface them.
This is the entire reason the curse section exists, and every entry in it was
once someone's afternoon.
