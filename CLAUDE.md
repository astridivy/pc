# CLAUDE.md

Dotfiles for `ivy`, an Arch install that has outlived its original computer.
**This repo is `$HOME`.** Paths here mirror their destination (`bin/`,
`.config/`, `.blackbox/`), and `link.sh` symlinks them into place:

```bash
./link.sh bin .vimrc .inputrc     # ln -s $REPO/$T -T ~/$T, backing up any existing file
```

Nothing is copied. Editing `~/bin/google` *is* editing `bin/google` here.

## `ivy` is a disk, not a computer

The install began life on an **Acer Aspire 5741G** laptop. That machine is dead
— it was dropped and the DC jack sheared clean off the board — so the drive was
moved into a **Dell Inspiron 24-3452** all-in-one (Pentium J3710, Intel
integrated graphics), which is what boots today. The laptop board may yet be
resurrected.

So this repo configures **two different machines**, and config that matches
neither the current box nor any obvious purpose is usually correct for the
*other* one. Don't delete hardware-specific settings just because they don't
apply here; make them conditional, or leave them and note which machine they
serve. Anything referencing a discrete GPU, a battery, or a laptop panel is
Acer-era.

Display output names are the sharp edge, because there are three naming schemes
in play and none of them agree:

| where | looks like |
|---|---|
| `xrandr` on the Dell (intel/modesetting) | `eDP1`, `HDMI1`, `DP1` — **no hyphen** |
| `/sys/class/drm` on the Dell | `card0-eDP-1`, `card0-HDMI-A-1` |
| Acer era, in `.xinitrc` and `.blackbox/menu` | `HDMI-0`, `LVDS-1` |

Only `eDP1` is connected here. `.xinitrc` still runs `xrandr --output HDMI-0
--primary`, which matches nothing on the Dell and fails silently on every X
start — harmless, and correct again if the laptop board comes back. **Never
hardcode an output name from memory or from another machine's config; run
`xrandr --query` on the box you're actually targeting.**

The `~/bin` terminal launchers are sized for the machine too (`watbat` is 18x1,
`watsen` 23x8). A geometry that looks wrong may just be tuned for the other
screen. The grub cmdline carries `video=LVDS-1:d` for the same reason — it
blanked the Acer's panel and is inert on the Dell. Another keeper, not a bug.

### The initramfs has to survive the transplant

The disk moves between machines, so **the boot image must not be
hardware-specific.** mkinitcpio's `autodetect` hook bundles drivers only for
the machine present when the image was built, which makes the default image a
snapshot of whatever box generated it. The 7.1.5 image was built on the Acer at
15:35 and first booted on the Dell at 23:13 the same day; it worked only
because both use Intel AHCI SATA. That was luck, not design.

The safety net is the **fallback** image, which the stock preset builds with
`fallback_options="-S autodetect"` — autodetect *disabled*, so every module is
included and the image boots anything. That is exactly what this disk needs,
and it is currently switched off: `/etc/mkinitcpio.d/linux.preset` has
`PRESETS=('default')` with the fallback lines commented out, so no
`initramfs-linux-fallback.img` exists — while `grub.cfg` still offers a
"fallback initramfs" menu entry pointing at that missing file. Choosing it
fails.

Before regenerating anything on the boot path, keep the image that is known to
boot the current hardware:

```bash
sudo cp /boot/initramfs-linux.img /boot/initramfs-linux.img.known-good
```

There is no separate `/boot` partition — it is on `/`, so boot images compete
with everything else for the same thin 55G.

**Building the fallback prints a wall of `Possibly missing firmware` warnings.
That is the fallback working, not failing.** `-S autodetect` pulls in every
module, so mkinitcpio checks firmware for drivers covering hardware nobody
here owns — enterprise SAS/FibreChannel HBAs (`aic94xx`, `wd719x`, `bfa`,
`qed`, `qla2xxx`). Those blobs are not in `linux-firmware` and are not packaged
in Arch at all, so there is nothing to install and nothing to silence. The
warnings are about the *image*, not about this computer.

mkinitcpio cannot tell you whether firmware is missing for hardware you
actually have. **`journalctl -k -b` can**, and it's the only source worth
acting on (`dmesg` is restricted here — `kernel.dmesg_restrict=1`):

```bash
journalctl -k -b | grep -iE 'firmware|microcode'
```

A real failure looks like `Direct firmware load for X failed with error -2`,
against a driver for hardware that exists. Successes are stated just as
plainly (`Intel BT fw patch 0x27 completed & activated`), so absence of a
failure line is a real answer.

Installing microcode is two steps, and the second is easy to forget: pacman
drops `/boot/intel-ucode.img`, but nothing loads it until grub is regenerated
with `sudo grub-mkconfig -o /boot/grub/grub.cfg`. Until then the kernel keeps
logging `x86/CPU: Running old microcode` and the package looks installed but
does nothing. The same regeneration is what teaches grub about a newly built
fallback image.

**`grub-mkconfig` is not `grub-install`.** `grub-mkconfig -o /boot/grub/grub.cfg`
rewrites the *menu* and is the one that's wanted after adding microcode, images,
or kernel parameters — it cannot make the machine unbootable in any way a
rebuild doesn't fix. `grub-install` rewrites the *boot sector*, is only needed
when the boot device or firmware mode changes, and takes a target argument that
must be the **disk** (`/dev/sda`) and never a partition. This box is legacy
BIOS — no ESP, `i386-pc` modules, grub in the MBR of `/dev/sda` — and that MBR
already survived the transplant, so `grub-install` has no reason to run here.
Reach for it only if the machine stops booting entirely.

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

Two more things about `link.sh` before reaching for it. It links
`$REPO/$T` → `~/$T`, so **the repo copy has to exist first** — adopting a file
that currently only lives in `$HOME` means copying it in before linking, not
after. And its link step is `ln -s -i`, which against an *existing* file
prompts; with no TTY the prompt reads EOF, answers no, and exits 1, so the
link silently never happens while the `.own` backup still gets made. From a
non-interactive shell, do the swap by hand.

Corollary for anything secret-adjacent: give it a deny-by-default rule in
`.gitignore` and allowlist the one file that belongs (`.ssh/*` then
`!.ssh/config`). This repo is `$HOME`, so an unignored key is one `git add .`
from being committed.

## This machine is cursed. Read this before running anything.

The interactive shell is heavily aliased. The aliases live in **`~/src/bashrc`**
— a *separate* repo, pulled in by the `source $HOME/src/bashrc/bashrc` line at
the top of `.bashrc`. Grepping this repo for an alias will not find it.

### Never let a bare `sudo` run non-interactively

An agent shell has no TTY, so `sudo` cannot prompt for a password. Three failed
attempts in a row trip `pam_faillock`, which then **rejects the correct password
for 10 minutes** — locking Astrid out of their own machine. This has happened
twice, both times because an alias silently prepended `sudo`.

If a command needs root: print it and let the human run it. Do not call `sudo`.

### Never `pkill -f` / `pgrep -f` from a shell you are running in

`-f` matches against the **whole command line**, and an agent shell's command
line contains the script it was told to run. So a pattern naming the thing you
want to kill also names *the shell asking the question*, and `pkill -f foo`
shoots the asker. This killed the session twice in one afternoon (exit 144),
both times while trying to restart a daemon called `dotkeyd` from a command
that mentioned `dotkeyd`. `pgrep -f` fails the same way more quietly: it
answers "yes, running" about itself, so a liveness check is always true.

The fix is to identify processes by something that isn't your own text:

```bash
[ -r "$PIDFILE" ] && read -r pid < "$PIDFILE" && kill -0 "$pid"   # best
```

Failing a pidfile, walk `/proc/*/cmdline` and skip your own PID. Long-running
daemons here should write a pidfile precisely so callers never have to guess —
`bin/dotkeyd` does.

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

### Confirm the running kernel before building a module

Upgrades here are deferred for years at a time (kernel jumps: 2021, 2022, 2024,
2026), so "did I reboot after that?" is a live question every time. It matters
before anything DKMS: a kernel upgrade **deletes the previous version's**
`/usr/lib/modules` tree, so an un-rebooted system can no longer `modprobe`
anything not already resident, and DKMS builds against the installed kernel
rather than the running one.

One check settles it — the module tree for the *running* kernel either exists
or it doesn't:

```bash
uname -r; ls /usr/lib/modules/; [ -d "/usr/lib/modules/$(uname -r)" ] && echo ok
```

`uptime -s` against `grep 'upgraded linux (' /var/log/pacman.log` confirms the
ordering. Note `uname -r` and pacman's version differ in punctuation for the
same kernel (`7.1.5-arch1-2` vs `7.1.5.arch1-2`) — that mismatch is cosmetic
and not evidence of anything.

## Layout

- `bin/` — personal scripts, symlinked as `~/bin` (on `$PATH`)
- `.config/keyledsd.conf` — per-application RGB keyboard profiles (Logitech, via
  `keyledsd`). Profiles match on window class; effects are composited in order.
- `.blackbox/menu`, `.blackboxrc` — Blackbox WM. There is no desktop
  environment; X starts from a tty via the `desktop` alias.
- `bin/palette` — the colour-scheme editor. Sixteen ansi colours in, the
  console / xterm / alacritty files out. See the colour section below.
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
on this hardware (185ms vs 574ms), which matters on a low-power Pentium — and
mattered just as much on the Acer's 2010 i5, so the reasoning survives whichever
board the disk is in.

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

Reference the linters **by name** (`eslint_d`), never by absolute path. `$PATH`
ordering is the entire mechanism that selects the npm-global toolchain over
pacman's, so a hardcoded `/usr/bin/eslint_d` bypasses the choice — and on this
box that path does not exist at all, which syntastic reports as zero errors
rather than as a failure. Other machines' branches contain exactly that pin.

## Verifying a vim change

Sourcing `.vimrc` proves almost nothing. A mapping is stored as an unparsed
string, so a syntax error in an `<expr>` map or a typo'd `` ` `` mark only
fails when the key is actually pressed — the file loads clean and the breakage
waits months. Exercise the mapping instead:

```bash
printf 'let foo = bar\n' > /tmp/t.txt
vim -Nes -u .vimrc /tmp/t.txt -c 'normal ;}' -c 'wq'   # then check the file
```

`:normal` (no bang) honours mappings, and `-Nes` runs headless without a TTY.
Run it twice for anything that toggles, and assert the *undo* half too — half
of these maps are `mm…`m` cursor-restore dances or `"_x` black-hole deletes
whose whole point is what they leave untouched, which a one-way test misses.

Don't `git stash` to get at a pre-change baseline. This repo is a live `$HOME`
and the tree routinely holds the human's in-flight edits to unrelated files;
`git show master:.vimrc > "$TMP/base.vimrc"` gets the same comparison without
picking up anyone else's work.

### nnoremap does not remap what an `<expr>` returns

This is load-bearing, not trivia. auto-pairs owns `"` and `'` in insert mode,
so `:normal A"` yields `""` while `:normal! A"` yields `"`. A mapping defined
with **`nnoremap <expr>`** returns keys that are fed *without* remapping, so
its `A"` never reaches auto-pairs and inserts exactly one character. That is
precisely why the `<leader>"` / `<leader>'` toggles exist — auto-pairs is
wanted almost always, and these are the escape hatch for when it isn't.

The same non-recursion is a trap in the other direction: an `<expr>` map that
*wants* another mapping to fire has to be `nmap`, not `nnoremap`. And when
testing, `:normal` vs `:normal!` is the difference between measuring the map
and measuring raw keystrokes — pick deliberately, and run the plain-`A` control
alongside, or a plugin's interference looks like your map's behaviour.

## Verifying a TUI change

Same principle as the vim section above, and the same failure: the code loads,
the batch path passes, and the thing only breaks when a key is pressed.

**A tool's `--export`-style batch path is not a test of its interactive path.**
The two normally hold the same data in different shapes — freshly parsed
values on one side, the editor's mutable working copy on the other — so a
shared helper can be perfectly exercised by the batch path and still crash the
moment the interactive one reaches it. (Concretely: `%` formatting unpacks
tuples and refuses lists, which is invisible until the copy someone can edit
arrives.) Drive the real keystrokes.

Headlessly, that means a pty — `pty.fork()`, then set the window size
explicitly with `TIOCSWINSZ` or the child inherits nothing and lays itself out
for an 80×24 that isn't there:

```python
pid, fd = pty.fork()
if pid == 0:
    os.environ.update(TERM='alacritty', COLORTERM='truecolor')
    os.execv('/usr/bin/python3', ['python3', 'bin/palette'])
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 80, 0, 0))
os.write(fd, b'#ff44cc\rw\r\r')          # keys, then read fd back
```

Assert on what the program *emitted*, not only on what it drew: escape
sequences sent to the terminal (`OSC 4`, `OSC P`) and files written are the
parts that outlive the process, and stripping the escapes to eyeball the
screen hides exactly those. Vary `TERM` and the width across runs — folding
and console-vs-emulator branches are where the layout bugs live.

## The clipboard, and why `:XClip` exists

`set clipboard=unnamedplus` in `.vimrc` **does nothing here.** Arch's `vim` is
built `-clipboard -X11 -xterm_clipboard`, so it cannot own an X selection at
all — `has('clipboard_working')` returns 0 while the option still reads back as
`unnamedplus`, which is exactly the shape of failure that looks like success.
That is the reason `command! XClip` shells out to `xclip`, and why the visual
`Y`/`D`/`X` maps route through it. Don't "simplify" them into plain yanks.

Vim 9.2 does have `+clipboard_provider`, so a `g:clipboard` dict wiring copy and
paste to `xclip` would make `"+y` work natively. It is not configured yet.

X11 has no clipboard *storage*: the copying process must stay alive and own the
selection, which is why `xclip -i` lingers rather than exiting, and why
`bin/{heart,supson,endash,emdash,♡}` all leave a resident `xclip` behind. Two
consequences worth knowing before debugging anything clipboard-shaped:

- Copied text dies when the owning program exits, unless a clipboard manager
  holds it. **None is installed** — no `autocutsel`, `clipmenu`, `copyq`,
  `parcellite`.
- Only one process may own a selection, so a copy has to *take* ownership from
  whoever holds it. Alacritty (0.17, via `x11-clipboard`) reports a lost race
  as `Unable to store text in clipboard: …` and the copy silently doesn't
  happen. Intermittent clipboard failures are usually this, not a bug in the
  app doing the copying.

`xclip -o -selection {clipboard,primary}` shows what is actually held, and
`pgrep -a xclip` shows who is holding it.

## dotkey, and the three ways X11 lies about input

`bin/dotkeyd` is a resident daemon that pops an override-redirect window on
**Mod4-period**, searches all ~149k named codepoints, and delivers the pick to
whatever window you were already typing in. `bin/dotkey` is the client.
`TODO.md` has the feature list; what follows is the part that cost the time.

**Resident because process startup dominates, not rendering.** Measured here:
`import gi` + GTK 3.24 alone is **1.64s**, building the unicode index 2.2s,
alacritty cold 0.61s, xterm cold 0.19s, bare python3 0.20s. Anything
cold-started is too slow for a key you hit constantly, so the daemon pays it
once at login and afterwards only maps a prebuilt window. This generalises: on
this CPU, *measure import cost before designing around render cost.*

**A daemon amortises startup and nothing else.** Once the resident-process win
is banked it stops being the interesting number, and the remaining latency is
whatever each request *redoes*. The usual culprit is a structure derived from
state that never changes after init — an index, a reverse map, a sorted copy —
rebuilt inside the hot path because that's where it's used. It never shows up
in a cold-start profile, because cold start is the thing you already fixed.
When something resident still feels slow, profile one request, not one launch.

**Benchmark the empty input, not just the interesting one.** The default view —
empty query, no filter, first paint — is the path *every* invocation takes, and
it's the one most likely to skip the fast paths that exist for real queries: a
narrowing cache keyed on the previous query does nothing for a query that isn't
narrowing anything. A timing table that only lists the expensive-looking
operation will happily sit next to a default case costing an order of magnitude
more. Time the boring case first; it's the one the human actually feels.

The whole unicode database is already local — `python3 -c "import unicodedata"`
knows every name, so there is nothing to download and no `UnicodeData.txt` to
parse. ~149k codepoints enumerate in about 2s.

### 1. A keyboard grab with `owner_events=True` silently delivers keys elsewhere

`Gdk.Seat.grab(...)` reports `GrabStatus.SUCCESS` either way. With
`owner_events=True` X routes key events to the window that would *normally*
have received them — i.e. the still-focused window underneath — so the popup
sits there holding a perfectly good grab and never sees a keystroke. Pass
**False** to route keys to the grab holder. Textbook silent success: the API
says yes, the feature does nothing.

An override-redirect window (`Gtk.WindowType.POPUP`) is still the right shape
here, because blackbox predates most `_NET_WM_*` hints and anything needing WM
cooperation is a gamble. And because a grab is not focus, the window underneath
keeps X input focus the entire time — which is what makes delivery possible at
all.

**Grab every device that could dismiss you, or the grab becomes a hang.** A
keyboard-only grab leaves the pointer free, so a click gives focus to some
other window while the grabbing popup — which has no pointer events to learn
from — goes on swallowing every keystroke on the desktop. Nothing looks
broken; the machine simply stops accepting input, and the only cure is killing
the process. Grab `SeatCapabilities.ALL`, and make click-outside an explicit
dismissal path. The same pointer grab also pins the paste target, since
focus-follows-mouse would otherwise let a stray pointer drift retarget the
delivery between opening the popup and choosing something.

Corollary for the failure branch: if the grab does *not* return `SUCCESS`,
tear the window down instead of leaving it mapped. A visible popup that holds
no input grab cannot be typed at or dismissed, which is the same hang wearing
a different hat.

**`owner_events=False` means child widgets never see pointer events.** X
reports them to the *grab window* only, so per-row `Gtk.EventBox` handlers
silently never fire — the familiar shape of GTK click handling is simply not
available under a grab. Hit-test on the toplevel instead, comparing the event
coordinates against each child's `get_allocation()`. This is not a workaround:
it is also what makes click-outside detectable, since those events arrive at
the grab window too, carrying coordinates outside its bounds. Note that
`Gtk.Box` and `Gtk.Label` are no-window widgets and cannot receive events
under any circumstances, grab or not.

### 2. `xdotool type` cannot reliably type characters your keymap lacks

To type an unmapped keysym, xdotool temporarily remaps a spare keycode, sends
the key, and restores the keymap immediately — so an application that reads the
event *after* the restore sees whatever that keycode used to mean. Measured
2026-07-31: typing a lone `♡` landed correctly **1 run in 8**; the other 7
arrived as `BackSpace`. Tuning `--delay` does not fix it and is not monotonic
(20 and 60 dropped characters that 40 got through). There are 15 spare keycodes
free, so this is not exhaustion — don't go looking for one.

**Put the glyph on the clipboard and send a paste chord instead.** `ctrl+v` and
`ctrl+shift+v` are ordinary mapped keys, so no remapping happens and there is
no race to lose. Measured 100% reliable across repeated trials.

Paste is not one keystroke, though. Terminals treat `ctrl+v` as the shell's
literal-next, and the xterm family pastes PRIMARY via `shift+Insert` rather
than CLIPBOARD at all — so match on `xdotool getactivewindow
getwindowclassname` and pick the chord (`PASTE_CHORDS` in `bin/dotkeyd`).
Getting it wrong fails silently: the glyph really is on the clipboard, the
window simply never reads it. Own **both** selections and middle-click works
too.

### 3. bbkeys keysym names are case-sensitive, and a wrong one fails silently

`[execute] (Mod4-Period) { dotkey }` does nothing at all. The X keysym for `.`
is `period`, lowercase — `Mod4-period` works. bbkeys does not warn, does not
log, and does not grab the key; the binding is simply absent, which is
indistinguishable from "my program is broken" until you check from the other
end. Modifiers and named keys are capitalised (`Mod4`, `Tab`, `Prior`) but
letter and punctuation keysyms are not, so don't infer the case from
neighbouring lines.

Verify a binding by having it leave a trace (a log line, `date >> /tmp/x`)
rather than by watching for its effect — and note `autoConfig` is on with a 1s
poll, so `touch ~/.bbkeysrc` is enough to reload, no restart needed.

`.bbkeysrc` **is** tracked here now (2026-07-31) and `~/.bbkeysrc` is a symlink
into the repo, so keybindings travel with the checkout instead of living only
on whichever box last had them. bbkeys follows the symlink and its `autoConfig`
poll still notices edits, so `touch` reloads as before.

Swapping a live config file for a symlink wants a **rename**, not
`rm && ln -s`: build the link under a temp name and `mv -T` it over the
original. bbkeys re-reads on a 1s timer, and the delete-then-create window is
long enough for a poll to land on a missing file. The same applies to
*rewriting* it: write a temp file and `os.replace`/`mv -T` it into place, or
the poll can read a half-written config and silently drop every binding after
the truncation point.

### 4. A bbkeys chain parks silently, then eats the next hotkey

Chains (`[chain] (Mod4-X)`) are modal, and the mode is left **only when bbkeys
receives a grabbed key**. Inside a chain bbkeys grabs that chain's children and
nothing else, so pressing a key which is *not* in the chain is never delivered
to bbkeys at all: the chain pointer stays parked on that node indefinitely,
with no timeout. The next hotkey is then matched against the chain's children
instead of the top level, fails to match, and is consumed resetting to the top.

So one mistyped chain key costs *two* later presses, and the symptom surfaces
on a completely unrelated binding — "the unicode popup stopped working" is
usually "I pressed a key that isn't in the execute chain a minute ago".
Interleaving a wrong key with a right one fails forever, which reads as the
whole keyboard config being broken.

**Give every chain a cancel, nested ones included** — `[cancelChain] (Escape)`
resets to the top from any depth. A chain without one can only be left by
spending a hotkey on it. Bracket tags are lowercased by the tokenizer, so
`[cancelChain]` and `[cancelchain]` both parse; the keysym in the parens is
**not** lowercased, so it is `Escape` and never `escape` (`NoSymbol`, binding
dropped). Same trap as the section above, one line further right.

Two corollaries when a binding "does nothing":

- **Check it is actually bound before debugging anything else.** The same
  mnemonic tends to live on different keys in different chains, and the chains
  here do not agree with each other — a remembered shortcut is a hypothesis,
  not evidence.
- bbkeys is started from `.xinitrc`, so its stderr is the tty that ran
  `startx`. Every `invalid key`, `could not activate keybinding` and
  reconfigure message lands on tty1, where nobody will ever see it from inside
  X. Don't wait to be told a config is broken; validate it yourself — balance
  the brackets and resolve every keysym through `XKeysymToKeycode`, since
  keycode 0 is exactly what makes a binding vanish without a trace.

### 5. A hotkey's own modifier holds the grab you are about to ask for

Anything launched *from* a hotkey that then needs an input grab must **retry**
the grab rather than trust the first answer. `XGrabKey` is a passive grab: the
instant the combo matches, X promotes it to an *active* grab owned by the
hotkey daemon, and holds it until every modifier comes back up. A resident
process maps its window in milliseconds — far faster than a finger leaves the
Win key — so attempt one reliably returns `ALREADY_GRABBED` (Gdk status **1**;
0 is success, so a bare `grab failed (1)` in a log means exactly this).

The symptom points away from the cause: **works from a shell, fails from the
hotkey.** Typing the command by hand holds no modifier, so every manual test
passes and only real usage fails — which reads as "the keybinding is broken"
when the keybinding is the only part that works. So when a hotkey-launched
thing does nothing, read the target's *own* log before touching the keymap or
the keysym case: a `grab failed` line is proof the binding fired correctly and
moves the whole investigation downstream.

Retry on a short interval (10ms) against a ~1s deadline, and measure that
deadline with **`time.monotonic()`, never `time.time()`** — the wall clock can
step under NTP, and a timeout measured on it can expire instantly or never.
Reproduce the whole thing headlessly by installing a passive grab from a
throwaway client, `xdotool keydown`-ing the modifier, and grabbing while it is
held; assert the released case too, or a broken probe looks like a pass.

### Testing anything GUI on the live session

The human is using this computer. Their clicking changes which window has
focus, and with focus-follows-mouse their keystrokes land in whatever probe
window you just opened — which looks exactly like your synthetic input going
astray, and produced two false diagnoses here. Before concluding a GUI bug is
real, confirm the desktop was actually idle, and prefer probes that record
where input landed over probes that only show whether it arrived.

**Ask X about grabs instead of typing at the desktop.** Two questions that
otherwise need synthetic input have direct, side-effect-free answers:

- *Is this hotkey actually live?* `XGrabKey` the same keycode+modifier from a
  throwaway client. `BadAccess` means someone already holds it (the daemon is
  alive and bound); success means the binding is dead — ungrab immediately.
- *Is something holding the keyboard right now?* `XGrabKeyboard` /
  `XGrabPointer` return `AlreadyGrabbed` if another client owns it, which is
  the difference between "my popup is broken" and "a menu somewhere never let
  go". A popup that reports a failed grab is usually the victim, not the bug.

Both need an error handler plus `XSync`, because grab errors arrive
asynchronously. Always include a **control** — a combination known to be
unbound, a grab known to be free — since a probe reporting everything as held
is indistinguishable from a probe that is simply broken.

Two more traps from the same afternoon, both cheap to avoid:

- A shell redirect into a **missing** fifo path silently creates a regular
  file, so the next reader blocks forever on something that will never deliver.
  Check `stat.S_ISFIFO`, not `os.path.exists` — and note `os.path.isfifo` does
  not exist.
- Two daemons reading one fifo is not an error: each command goes to whichever
  reads first, so the popup ignores you at random and the log you are reading
  belongs to the instance that didn't get the message. Refuse to start a second
  instance.

## The colour scheme lives in three files and drifts

The same sixteen ansi colours are written out three times — `bin/*.color` for
the linux console, `.Xresources` for xterm, `.config/alacritty/alacritty.toml`
for alacritty — and nothing kept them in step. **`bin/palette` is now the
editor and the single source**: it loads any of the three formats, edits the
sixteen colours in a tui, and writes all three back out.

```bash
palette bin/Tomorrow-Night-Nineties.color        # edit
palette --export alacritty                       # one format to stdout
palette FILE -d OTHER -d OTHER                   # which files disagree, and where
```

**A colour that differs between the three files is stale, not mis-mapped.**
All three dialects are plain ansi order 0–15 — console `OSC P<nibble>`,
`XTerm*colorN`, and alacritty's `[colors.normal]`/`[colors.bright]` (0–7 then
8–15) index identically. There is no ordering quirk to compensate for, so when
xterm's red does not match the console's red the answer is always that one
file was edited and another wasn't. The 2019 mismatch here was one line missed
in a bulk paste, and the *comment* left next to it recorded the wrong
hypothesis ("why does it have to be so inconsistent with linux terminal"),
which then kept the correct value commented out for seven years. `git blame`
settles it in one command: the stale line is the one whose blame is much older
than its neighbours.

### Colours past 15 are not equally available

| where | 0–15 | 16–255 |
|---|---|---|
| linux console | `OSC P<nibble><rrggbb>` | **impossible** — the console has 16 slots |
| xterm resources | `XTerm*colorN` ✓ | **silently ignored** |
| alacritty config | `[colors.normal]`/`[colors.bright]` | `[colors.indexed_colors]` ✓ |
| escape sequences | `OSC 4;<n>;rgb:rr/gg/bb` ✓ | `OSC 4` ✓, xterm and alacritty both |

`color16` through `color255` are in `man xterm`, but the page also says they
are "omitted when wide-character support and luit are enabled" — which is the
Arch build, so **they do nothing here.** The strings are still in the binary,
so grepping it will tell you they exist. Measured on xterm(410):
`-xrm 'XTerm*color1: rgb:11/22/33'` takes, `-xrm 'XTerm*color16: …'` leaves
index 16 at its cube default. An ignored resource looks exactly like a
resource that had no effect. Anything past 15 has to be set with `OSC 4` at
runtime, or from alacritty's config.

Bear in mind 16–231 are the standard 6×6×6 cube and 232–255 the grey ramp, and
every 256-colour app computes its indices from those values — vim's own
colorschemes included. Overriding cube slots makes those computations point at
the wrong colour. In alacritty the honest fix for vim is `set termguicolors`,
which uses the scheme's exact `gui` hex and needs no palette slots at all.

### Testing colours without touching the live session

`Xvfb` is installed, and both xterm and alacritty run on it, so colour
behaviour can be measured off-screen instead of popping windows onto the
human's desktop (see the GUI-testing warning above). Query what a terminal
actually holds by asking it — `OSC 4;<n>;?` and read the reply back off the
tty — rather than by looking at a screenshot.

Two rig-specific traps, neither of which is true of the real display:

- **`xrdb` silently loads nothing under Xvfb.** `xrdb -merge` exits 0, and
  `RESOURCE_MANAGER` is never set on the root window, so every resource reads
  as its default and any conclusion drawn is backwards. Inject resources with
  `xterm -xrm 'XTerm*color1: …'` instead, which works. On the real `:0` xrdb
  is fine.
- A terminal that ignores the resource and a terminal that never received it
  look the same. Always run a control — a resource you know works, like
  `color1` — in the same invocation as the one you are testing.

## Merging the per-machine branches

`origin/{serverside,baby,phone,remote,windoze,wsl}` are long-lived per-machine
branches, merged into master **piecemeal and repeatedly** — master already
carries earlier cherry-picks from them. Two rules follow from that:

**Diff two-dot, not three-dot.** `git diff master...origin/serverside` shows the
branch's changes since the merge base, which includes everything master has
*already* independently taken — it will present settled files as if they were
open questions. `git diff master origin/serverside` shows what actually still
differs. Check `git log --oneline master -- <path>` for a prior cherry-pick
before treating any hunk as new.

**Run `git diff -w --stat` before reading anything.** These branches drift in
indentation across machines, and the reformatting dominates: a recent `.vimrc`
comparison was 200/209 lines changed, but only 52/61 ignoring whitespace — 23
hunks collapsing to 12. Cherry-pick behaviour and leave master's whitespace
alone, or the real changes are unreviewable.

Per-machine files stay per-machine. `.local.vimrc` is sourced at the end of
`.vimrc` precisely so machines can disagree, and `.tryhardrc` lists paths that
exist on *that* box (`$HOME/www` on the server, `$HOME/doc` here). Verify a path
exists locally before importing it.

`git merge-tree --write-tree --name-only master origin/<branch>` lists the
conflict set without touching the working tree or creating a worktree.

## Open work

**See `TODO.md`** for the current list — the searchable-Unicode popup, the
clipboard manager, finishing the Razer keyboard, and the rest. Keep it updated
as things land; this section is just the pointer.

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
