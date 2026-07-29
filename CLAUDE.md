# CLAUDE.md

Dotfiles for `ivy`, an Acer Aspire 5741G running Arch. **This repo is `$HOME`.**
Paths here mirror their destination (`bin/`, `.config/`, `.blackbox/`), and
`link.sh` symlinks them into place:

```bash
./link.sh bin .vimrc .inputrc     # ln -s $REPO/$T -T ~/$T, backing up any existing file
```

Nothing is copied. Editing `~/bin/google` *is* editing `bin/google` here.

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

### Aliases that break non-interactive use

| alias | expands to | why it hurts |
|---|---|---|
| `cp` | `cp -i` | **hangs forever** waiting on a y/n that never comes |
| `mv` | `mv -i` | same |
| `ls` | `ls_or_cat` | a shell function, not `ls` |
| `cat` | `cat_or_ls` | a shell function, not `cat` |
| `cd`  | `cd+` | wrapped |
| `grep` | `grep --exclude-dir=…` | silently skips `.git` and `node_modules` |
| `time` | `date +%l:%M%P` | **interactive shells only** — `bashrc/danger` sits past a `[[ $- != *i* ]] && return` guard, so this shadows timing for a human but not for an agent shell |
| `visudo` `umount` `wifi-menu` | `sudo …` | faillock trap above |
| `shutdown` `restart` `suspend` | `sudo systemctl …` | faillock trap above |

`pacman` and `systemctl` used to be `sudo`-aliased too. They were removed on
2026-07-29 precisely because they caused the lockouts — typing `sudo` is fine.

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

## Layout

- `bin/` — personal scripts, symlinked as `~/bin` (on `$PATH`)
- `.config/keyledsd.conf` — per-application RGB keyboard profiles (Logitech, via
  `keyledsd`). Profiles match on window class; effects are composited in order.
- `.blackbox/menu`, `.blackboxrc` — Blackbox WM. There is no desktop
  environment; X starts from a tty via the `desktop` alias.
- `.config/ardour{7,8}/` — one directory per Ardour major version. When
  upgrading, copy the *live* `~/.config/ardourN/` files in; don't `cp -r` the
  previous version's directory, which silently enshrines stale keybindings.
- `etc/`, `usr/` — files destined for system paths, staged for manual install.

## Open work

- **ESLint migration is unfinished and deliberately uncommitted.** `.eslintrc.js`
  is deleted and `eslint.config.js` is untracked in the working tree. The config
  cannot load (`@eslint/js` lives in the global npm prefix, unreachable from this
  repo) and was never symlinked into `$HOME`, so it only ever covered
  `~/src/pc`. System ESLint is 9.6.0; upstream is on 10.x. Leave these two files
  alone until that work is picked up.
- The system is mid-catch-up after a 21-month gap. See `THE-STORY-SO-FAR.md`.

## Conventions

- Commit messages are lowercase, informal, and explain *why*. Match that.
- Old commits carry an older email on purpose — **never rewrite history to
  normalize author identity.** It was true when written.
- `.claude/` is gitignored.
