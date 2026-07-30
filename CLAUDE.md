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
