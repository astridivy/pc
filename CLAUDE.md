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
| `xrandr` on the Dell (intel/modesetting) | `eDP-1`, `HDMI-1`, `DP-1`, `DP-2`, `HDMI-2` |
| `/sys/class/drm` on the Dell | `card0-eDP-1`, `card0-HDMI-A-1` |
| Acer era, in `.xinitrc` and `.blackbox/menu` | `HDMI-0`, `LVDS-1` |

Only `eDP-1` is connected here. `.xinitrc` still runs `xrandr --output HDMI-0
--primary`, which matches nothing on the Dell and fails silently on every X
start — harmless, and correct again if the laptop board comes back. **Never
hardcode an output name from memory or from another machine's config; run
`xrandr --query` on the box you're actually targeting.**

That rule applies to *this table too*. It said `eDP1`, unhyphenated, until
2026-08-15, when a `xrandr --query` run for an unrelated task came back
`eDP-1` — the name having presumably changed under a driver upgrade at some
point nobody noticed, because nothing reads these names from here. A written
note about a name the system generates is a cache, and caches go stale
silently; the server is the only authority. Scripts should derive it at
runtime rather than quoting either the table or their own memory:

```sh
output=$(xrandr --query | awk '/ connected/ {print $1; exit}')
```

The `~/bin` terminal launchers are sized for the machine too (`watbat` is 18x1,
`watsen` 23x8). A geometry that looks wrong may just be tuned for the other
screen. The grub cmdline carries `video=LVDS-1:d` for the same reason — it
blanked the Acer's panel and is inert on the Dell. Another keeper, not a bug.

### Installed packages follow the same two-machines rule as config

The disk carries drivers for **both** boards, so a package matching no hardware
present is the normal case, not cruft. `vulkan-radeon`, `xf86-video-ati`,
`xf86-video-amdgpu` and their `lib32-` twins serve the Acer's Radeon; the
`linux-firmware-{amdgpu,radeon,nvidia,broadcom,mediatek,atheros}` splits are
dependencies of the `linux-firmware` metapackage and are not optional anyway.
**Don't propose removing a driver package because `lspci` on the current box
doesn't list its vendor** — that reasoning deletes exactly the half of the
install that makes the transplant work.

The inverse is the actual bug to look for: hardware that *is* present with no
userspace driver installed, because it arrived with the second machine and
nobody added anything for it. `lspci -nnk` answers this directly — it prints
`Kernel driver in use` per device, so a device with a kernel driver bound can
still be missing the userspace half (VA-API, Vulkan, a protocol daemon), which
`lspci` will not tell you about. Check those by capability, not by device.

The Dell is Braswell (Pentium J3710, Cherryview, HD Graphics 405, Gen8) with
Intel Wireless 3160, Realtek RTL8111 ethernet, ALC662 HDA audio, a Weida
`hid_multitouch` touchscreen and an Intel 8087:07dc bluetooth radio. Kernel-side
that is all bound and firmware-clean; `libva-intel-driver` (i965 is the driver
for this generation, not iHD) and the `bluez` daemon are the userspace pieces
that were missing as of 2026-08-05.

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
`commandod` does.

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

### Sourcing `bashrc/exports` destroys `PATH`

**`bin/setadd` is truncated.** It ends mid-string on line 21 — `the_set="$the_set`
with no closing quote — so it dies with `unexpected EOF while looking for
matching '"'` on every single call, having already echoed only its *first*
argument. It is also called with three arguments and reads two.

`bashrc/exports` builds `PATH`, `NODE_PATH` and `LD_PRELOAD` through it:

```bash
export PATH=`setadd "$HOME/bin" "$HOME/.npm/packages/bin" "$PATH"`
```

so anything that sources `exports` ends up with **`PATH=/home/astrid/bin`** and
nothing else — no `/usr/bin`, so `sleep`, `grep` and `git` all stop existing.
`NODE_PATH` comes out empty. Verified 2026-08-07.

The interactive shell survives this only by accident, and wears the evidence:
`echo $PATH` shows `~/bin:~/.npm/packages/bin` repeated **three times** ahead of
the system paths — which is the exact duplication `setadd` was written to
prevent. The one thing it is for is the one thing it does not do.

Two consequences:

- **Any script that sources `bashrc/exports` must save and restore `PATH`
  around it.** `~/src/commando`'s `run_script()` does this and says why.
- Don't read a failure here as your own bug. A command that exists refusing to
  be found, immediately after sourcing anything from `~/src/bashrc`, is this.

Fixing `setadd` properly needs a decision about what it should do — append with
which separator, and whether the three-argument call sites are right — so it is
in `TODO.md` rather than patched blind.

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

### A package split during a deferred upgrade silently loses features

Deferring upgrades for years means crossing whole *repackagings*, not just
version bumps. When Arch splits a monolithic package into a base plus a family
of `foo-plugin-*`, the upgrade installs the base and whichever pieces became
hard dependencies — and **pacman never installs optdepends**, so every feature
that landed in an optional one just disappears. Nothing errors; `pacman -Q foo`
reports the newest version and the install looks complete.

The tell is an application reporting a capability as *unsupported* rather than
missing — it started, it read the file, it simply has no plugin for that job.
Two commands settle it, and neither needs root:

```bash
pacman -Qi foo | sed -n '/Optional Deps/,/^[A-Z]/p'   # what could be there
pacman -Qq | grep ^foo                                # what is
```

Diff those, and check the plugin directory (`/usr/lib/foo/plugins/…`) for the
one that would do the work. An absent `.so` is proof; a present one moves the
search elsewhere.

Concretely, this is why VLC refused h264 (2026-08-05): `vlc-plugin-ffmpeg`
carries `libavcodec_plugin.so` and is *optional*, so the split left a VLC that
could still play AV1, Vorbis and Theora — the codecs whose plugins happened to
be dependencies — while every ffmpeg-backed format was gone. A partial-looking
codec list is the signature of this, not of a corrupt install.

### Two audio servers running is not automatically a conflict

`pulseaudio` and `pipewire` are both resident here, which reads as a
misconfiguration and is not one. **Ask which process holds the device before
concluding anything:**

```bash
fuser -v /dev/snd/*        # who actually owns the card
pactl info | grep 'Server Name'
```

PulseAudio owns `/dev/snd/controlC0` and serves the desktop. Production audio
is **JACK** — `jack2`, `qjackctl`, `ardour`, `carla` and a pile of `jack-*`
tools are installed, with `pulseaudio-jack` bridging the two. `jackd` is not
resident because qjackctl starts it on demand, so its absence from `ps` means
nothing.

PipeWire is running but **inert**: no `wireplumber` and no
`pipewire-media-session`, so it has no session manager, never enumerates
devices, and claims nothing. An empty graph still reports a handful of nodes
(`pw-cli ls Node` counts the core dummy/freewheel drivers), so a nonzero node
count is not evidence it is doing work. That inertness is exactly why there is
no fight over the card.

The trap is that PipeWire is a *replacement* for PulseAudio and JACK, not a
third layer beside them — so "they're for different things" is never a real
topology, and the instinct on seeing both is to migrate. **Don't.** The
JACK-for-production / Pulse-for-desktop split is deliberate and working, and
`pipewire-jack` has latency behaviour Ardour users deliberately avoid.
Installing a session manager is what would turn this from harmless into a
device-ownership fight.

### "Is JACK running?" has two answers, and the daemon only tells you one

`jackdbus` can report the server as **started** while its ALSA driver is
**dead**. Losing the capture or playback device — a USB interface sleeping,
dropping off the bus, or being unplugged — stops the driver, and nothing
restarts it:

```
ERROR: ALSA: capture device disconnected
ERROR: JackAudioDriver::ProcessSync: read error, stopping...
```

From then on `jack_control status` still says `started`, the existing graph
still lists every client that was already connected, and qjackctl looks
entirely normal — because clients are only torn down when *they* exit. But
every **new** client is refused, with `Driver is not running` → `Cannot create
new client` on the server side and, on the client side, a set of errors that
point nowhere near the cause:

```
Cannot read socket fd = 9 err = Success      # note: "err = Success"
CheckRes error / JackSocketClientChannel read fail
Cannot open <name> client
```

So the symptom is *"my meters/tools stopped appearing in the graph"* while
audio that was already patched keeps working, and the shape of the client-side
error invites a hunt for a version or protocol mismatch that isn't there.

**Read `~/.log/jack/jackdbus.log` first.** It names the real cause in plain
English and timestamps it, which no client-side message does. The generalisable
part: when a daemon's own status call and its log disagree, the log wins — a
status flag reports what the daemon was *asked* to do, the log reports what
happened to it since. The fix is a driver restart, needs no root, and is safe
precisely because audio is already dead:

```bash
jack_control stop && sleep 2 && jack_control start
```

Confirm the device actually came back first (`aplay -l`, `arecord -l`) or the
restart just fails again — and check `/proc/asound/cardN/stream0`, which shows
`Status: Running` plus the real channel count and format once it does.

**`stop`/`start` restarts the driver but not the engine, and after a crash that
is not enough.** New clients connect again, so it looks fixed — but the engine
carries the damage forward and says so, in lines that are easy to scroll past
because the thing you were testing just started working:

```
ERROR: JackFreewheelDriver::ProcessSync: SuspendRefNum error
ERROR: JackAudioDriver::ProcessGraphSync: ProcessWriteSlaves error, engine may now behave abnormally!!
ERROR: JackEngine::ClientDeactivate wait error / ClientKill cannot be removed from the graph !!
ERROR: Failed to find port 'system:capture_1' to [dis]connect
```

That last one is the tell worth knowing generally: **the engine failing to find
a port that `jack.Client().get_ports()` lists** means the two registries have
diverged, and no amount of client-side retrying will reconcile them. The cost
is a **5-second** stall — `LockedTimedWait usec = 5000000` — on client open and
again on exit, hit intermittently, which reads as "this tool is slow to start"
rather than as a server fault. Measured here: 5.08s on 3 runs of 5.

`jack_control exit` (terminate jackdbus entirely; the next dbus call
re-activates it) followed by `jack_control start` clears it. Same box, same
tool, after a full restart: **0.086s to open, 0.007s to exit**, every
connection landing. PulseAudio re-registers its sink and source by itself, so
desktop audio comes back without intervention — but anything that was patched
by hand needs re-patching.

Two tooling notes for anything that has to inspect the graph here:

- **`jack_lsp` is not installed** — Arch split the example tools out of `jack2`
  and only `jackmeter`, `jack_delay`, `jack_mixer` and friends are present. Use
  **`python-jack-client`** (`import jack; jack.Client(...)`), which is
  installed, rather than assuming the classic CLI tools exist.
- **The dbus patchbay graph goes stale; libjack does not.**
  `org.jackaudio.JackPatchbay.GetGraph` can keep serving a pre-restart snapshot
  — listing only MIDI ports, or ports that no longer exist — while
  `jack.Client().get_ports()` shows the true state. Never conclude a port is
  missing from the dbus view alone; that reads as a half-started driver when
  nothing is wrong. Same rule as above: ask the thing that owns the state.

Finally, **a meter connects to *output* ports only.** `jack_meter`'s own port
is an input, so naming `system:playback_1` fails with `Cannot connect port
'system:playback_1' to 'meter:in'` — playback ports are sinks. To meter what
reaches the speakers, name whatever is *feeding* them (`PulseAudio JACK
Sink:front-left`, a track's output); to meter what comes in, `system:capture_N`
is already an output and works directly.

### A black screen is not a dead computer, and the power button costs you the session

The panel on this box dies while everything behind it keeps running. i915
drops the display pipe and says so:

```
i915 0000:00:02.0: [drm] *ERROR* pipe A underrun
i915 0000:00:02.0: [drm] *ERROR* CPU pipe A FIFO underrun
```

Nothing in the kernel ever retries the pipe, so the screen stays black
forever — while X is *fine* (`Xorg.0.log` records "Server terminated
successfully" on the way out, no crash and no `(EE)`), the terminal bell
still rings, and ssh still answers. The natural reading of a black screen is
"the computer is gone", so the power button gets held, and the session dies
of the cure rather than the disease.

**`~/bin/unblank` is the way out, bound to `Mod4-M` in `.bbkeysrc`** (it also
answers to `ahhh`). bbkeys is still resident and still holding its grabs
during this, which is the entire reason a keybinding can rescue it. Each
press inside 12s escalates — dpms wake, dpms off/on, then a full modeset —
so mashing the key *is* the interface and three presses is the big hammer.
If all three fail the wedge is below X: `ctrl+alt+F2` then `ctrl+alt+F1`
makes fbcon do its own modeset without X's cooperation. Power button last.

The prevention side is `xset s off -dpms` in `.xinitrc`: every one of those
deaths came out of a long idle stretch, so not blanking removes the trigger,
and it costs nothing on a mains-powered all-in-one. **`xset dpms force off`
silently re-enables dpms**, though — the `force` verbs turn the extension back
on as a side effect, with no output and nothing in any log. So anything that
cycles dpms to recover has to read the state first and put it back after, or
one panic press quietly hands the blank timer back to the machine it just
rescued. `unblank` does this; grep it for `dpms_was`. The general shape:
a "force this now" API that implicitly enables the subsystem it operates on
will undo your configuration as a side effect of using it.

Two general lessons, both of which cost real sessions here:

**When something "keeps happening", diff how each boot *ended*, not what is
in the current one.** `journalctl --list-boots` plus a per-boot count of the
suspect message and of `"Power key pressed short"` turns a vague complaint
into a table, and the table settles causation in a way no amount of reading
one boot's log can. Here it was unanimous — every boot logging the underrun
ended in a power-key mash, every boot without one shut down cleanly, and the
clean boots were the control that made it an argument instead of a hunch.
The underrun is also the *last* kernel line in each of those boots, with
minutes of total journal silence before it, which is what says "idle, then
the pipe went" rather than "something was thrashing".

**`xrandr --output <the only output> --off` fails, and can leave the panel
dark.** With nothing else connected the screen would have to shrink to 0x0,
which is below the server's stated minimum, so `RRSetScreenSize` answers
`BadValue` and xrandr exits 1 — *after* possibly having already pulled the
CRTC down. Any recovery path built on `--off` must therefore treat it as
best-effort, run the re-enable as a separate command that happens regardless,
and then *verify* the output actually came back rather than trusting either
call's exit status. `unblank`'s stage 3 is written that way and says why.

**`xrandr --query` has no fixed columns — the primary output gets an extra
word.** A normal output reads `eDP-1 connected 1920x1080+0+0 (…)`; the primary
one reads `eDP-1 connected primary 1920x1080+0+0 (…)`, so the geometry moves
from `$3` to `$4`. Anything keyed on the column number therefore works
perfectly until something sets `--primary`, and then reads the literal string
`primary` as the mode forever after. Scan the fields for a `WxH+X+Y` pattern
instead of counting them:

```sh
awk -v o="$output" '$1 == o { for (i = 2; i <= NF; i++)
        if ($i ~ /^[0-9]+x[0-9]+\+/) { split($i, a, "+"); print a[1]; exit } }'
```

The nasty half is what it does to a *check*. "Is the output alive?" written as
`grep "^$output connected [0-9]"` stops matching the moment the output is
primary — which yields a test that can never pass, and therefore can never
fail: its recovery branch fires unconditionally and a genuinely dead panel
looks exactly like a healthy one. **A verification step that always reports
failure has stopped being a verification step**, and it announces itself as a
too-eager fallback rather than as a broken test. Unit-test any such predicate
against both answers — a live line and an output-off line (`eDP-1 connected
(normal left …)`, no geometry at all) — before trusting either.

**Beware of fixing the display state in your own test harness.** Checking
whether a recovery left dpms the way it found it, by running `xset dpms force
on` first, re-enables dpms as a side effect and reports your own command's
work as the script's. The harness has to be more passive than the thing it
measures: read `xset q`, never `xset`.

For testing this sort of thing, note **Xvfb speaks RANDR but has no DPMS
extension**, and `+extension DPMS` does not add one — `xset dpms force on`
there prints its usage text and fails. So the off-screen rig can exercise
every `xrandr` path but no `xset dpms` path, and a script driving both has to
be checked in two places: the rig for the modeset, the live display for the
dpms calls (which are harmless — forcing a monitor *on* cannot blank it).

### A menu launch already has a terminal, and it is tty1

X starts from a tty via the `desktop` alias and there is **no display manager**,
so blackbox inherits that login shell's stdio and never lets go of it. Its
fds 0, 1 and 2 are all `/dev/tty1`, and every child it execs from the menu
inherits them.

The consequence catches anything trying to be clever: **a script launched from
the right-click menu passes `[ -t 1 ]`.** So the usual "am I being run from a
terminal, or from a mouse?" test answers *terminal* — and a script that
branches on it runs its curses app, its editor or its pager on tty1, behind X,
where nobody can see it or quit it. Nothing errors; the menu entry just appears
to do nothing. `$TERM` is no better (`linux` from the menu, `linux` from a real
console shell too).

There is no reliable sniff here. **Decide the mode explicitly** — a flag, a
separate script, or simply always bringing your own terminal, which is what
every launcher in `bin/` does:

```sh
exec alacritty --config-file ~/.config/alacritty/SIZE.toml --title "…" -e CMD
```

`alacritty -e` **execs** its argument — there is no shell inside it. It cannot
expand an alias or find a shell function, and nearly everything in
`~/src/bashrc` is one of those. To reach a bashrc function from a menu entry,
wrap a bash around it and source what it needs first, passing arguments as real
arguments rather than pasting them into the script text:

```sh
exec alacritty … -e bash -c 'source "$1"/functions; source "$1"/screen
                             shift; screenvim "$@"' _ "$BASHRC" "$@"
```

`bin/vvim` and `bin/cclod` are the worked examples.

### The root window is painted from three places, and `~/.fehbg` names the culprit

Changing the wallpaper in the obvious place is not enough, because the obvious
place is one of three writers and not the last one to run:

| where | when it runs |
|---|---|
| `bin/wallpaper`, from `.xinitrc` | login, after its deliberate `sleep 1.61` |
| `rootCommand:` in the blackbox **style** | every style load — startup, Restart Blackbox, any style change |
| `[exec] (Redraw Desktop)` in `.blackbox/menu` | when clicked |

The style is the one that hides, because it lives **outside both repos** —
`session.styleFile` in `.blackboxrc` points at
`/usr/share/blackbox/styles/NAME`, which is a symlink into
`/usr/local/share/blackbox/styles/`. Grepping `~/src/pc` and `~/src/bashrc`
for the old filename finds two of the three and reads like a complete answer.
Every stock style in that directory carries a `rootCommand` too, so switching
styles changes the wallpaper as a side effect.

**`feh` rewrites `~/.fehbg` on every `--bg-*` with the exact command it ran**,
so that file is a receipt naming whichever writer went last — read it first,
before instrumenting anything. It settles "who set my wallpaper" in one `cat`.

`.xinitrc` backgrounds its whole startup line with `&`, so these writers race,
and `bin/wallpaper`'s `sleep` is a **participant in that race**, not just
flavour — it is tuned to land after blackbox has loaded its style. A sleep
tuned that way rots silently as startup gets slower or busier: nothing errors,
the wrong image simply wins. Don't re-tune it and don't delete it. **Make every
writer draw the same thing**, so whoever wins is invisible, and keep the sleep
out of `rootCommand` — a Restart Blackbox that pauses before repainting is not
what that hook is for.

Match the `--bg-*` **flag** across all three as well, not just the path. The
flag is invisible while the image happens to be exactly screen-sized —
`--bg-scale`, `--bg-max` and `--bg-fill` all agree on a 1920x1080 file — and
starts mattering the moment it isn't. Check `identify` against `xrandr` before
assuming a flag is inert.

## Layout

- `bin/` — personal scripts, symlinked as `~/bin` (on `$PATH`). Three entries
  are **symlinks out of this repo** into `~/src/commando`
  (`commandod`, `commando`, `dotkey`), which is how a program that grew its own
  checkout stays on `$PATH` without anything being added to it. `$PATH` here is
  built by `bashrc/exports`, which is broken (see above), so pointing a link at
  the sibling repo is much safer than teaching the shell a new directory.
- `.config/keyledsd.conf` — per-application RGB keyboard profiles (Logitech, via
  `keyledsd`). Profiles match on window class; effects are composited in order.
- `.blackbox/menu`, `.blackboxrc` — Blackbox WM. There is no desktop
  environment; X starts from a tty via the `desktop` alias. The menu is re-read
  whenever it is opened, so an edit is live on the next right-click — no
  restart, no reconfigure, don't tell Astrid to do either.

  Restructuring that file wants a real check, because a broken menu is a menu
  that silently comes up short rather than an error. Two things to know before
  writing a validator: **`[end]` takes no `(label)`**, so a parser keyed on
  `\[(\w+)\]\s*\((...)\)` matches every *opening* tag and no closing one, and
  therefore reports any file whatsoever as unbalanced-but-nested — the shape of
  a checker that is measuring nothing. Match the tag first and read the label
  separately. And a nesting check proves only nesting: diff the sorted set of
  leaf lines (`[exec]`, `[config]`, `[restart]`, `[exit]`, `[stylesdir]`,
  `[workspaces]`) against `git show HEAD:.blackbox/menu` too, which is what
  catches an entry dropped while moving subtrees around.
- `bin/palette` — the colour-scheme editor. Sixteen ansi colours in, the
  console / xterm / alacritty files out. See the colour section below.
- `.config/alacritty/` — `alacritty.toml` is the base (colours, font, bell,
  keybinds) and is found automatically;
  `tall/medium/bitsy/eensy/xlarge/countdown/nearly.toml` each `import` it and
  override only window geometry. Edit colours in the base once, not six times.
  Alacritty dropped YAML in 0.14, so the old `~/.alacritty.*.yml` are gone —
  anything passing `--config-file` wants the `.toml` paths
  (`bin/{watbat,watsen,watempo,volumectl,clock,vvim,cclod}`, `.blackbox/menu`).

  Sizing a new variant needs the cell, not the pixel, and the cell is
  measurable rather than guessable: **Misc Tamsyn at size 12 is exactly 8x16
  px**, so the Dell's 1920x1080 is 240x67 cells and a percentage of the screen
  is simple arithmetic (`nearly.toml` is 90% of it, 216x59). Measure it again
  rather than trusting that after any font change — launch one with
  `alacritty -o window.dimensions.columns=80 -o window.dimensions.lines=24` and
  divide what `xwininfo` reports.

  **Don't hardcode `[window.position]`** unless the window is a pinned readout
  like `eensy`. `session.windowPlacement: CascadePlacement` in `.blackboxrc`
  wraps between slots instead of marching off the edge — verified with three
  216x59 windows, worst case `right=1790 bottom=1034` on a 1920x1080 screen —
  so blackbox places these correctly by itself, and a fixed x/y would be wrong
  on the other machine anyway.
- `.config/ardour{7,8}/` — one directory per Ardour major version. When
  upgrading, copy the *live* `~/.config/ardourN/` files in; don't `cp -r` the
  previous version's directory, which silently enshrines stale keybindings.
- `.screenrc` — screen's keybindings, and the only screen config that isn't in
  `bashrc/screen`. That file is the *dance* and the little guys — shell
  functions, all of it — so grepping the bashrc repo for a key never finds one.
  Keys live here; sessions and windows live there.

  What's in it: `C-a h/j/k/l` move between **split regions** (`focus left` and
  friends), the binding screen's own man page suggests under `focus`.

  **"Window" and "region" are different things in screen, and the words are
  easy to swap by accident.** A *window* is a shell; a *region* is a pane that
  a window is displayed in. `next`/`prev` cycle windows, `focus` moves between
  regions, and a binding pointed at the wrong one of those still works
  perfectly — it just does something nobody asked for. Worth saying back which
  one is meant before writing the `bind` line.

  Region motions are also no-ops on an unsplit screen, and no-ops at the edges
  (`focus left` from the leftmost region does nothing rather than wrapping, and
  that is deliberate on screen's part). So "the key does nothing" is the
  expected result of testing one without splitting first, and reads exactly
  like a binding that failed to load.

  Bind all four or none, too: `C-a S` splits into regions stacked *vertically*
  and `C-a |` splits them side by side, so `h`/`l` alone leave the commoner
  split unreachable.

  Three things bite when editing it, and two of them do it silently:

  **Every letter is already bound.** `C-a ?` lists the lot, and `bind` will
  overwrite any of them without a word — there is no warning and no error, the
  old command simply stops having a key. Check `man screen`'s table before
  claiming a letter, and give whatever you evicted somewhere to live (or write
  down that you didn't). Most defaults answer to a `C-a x` *and* a `C-a C-x`,
  so taking the plain letter usually costs nothing — that is how `k` was freed
  (`kill` kept `C-a C-k`) and `l` (`redisplay` kept `C-a C-l`). `C-a h` was the
  one real eviction: `hardcopy` had no twin, so it took `C-a C-h`, which was
  only a fourth spelling of `prev`.

  **A running session never re-reads this file.** `.screenrc` is read at session
  *creation*, so an edit does nothing at all to the screen you are sitting in,
  and the symptom is a key that just doesn't work. `screen -X source ~/.screenrc`
  applies it live, per session; new sessions get it for free. This matters more
  here than most places, because the ssh session is long-lived by design.

  **Testing one needs a pty**, which an agent shell hasn't got — `screen`
  detached refuses anything that wants a display. The rig that works is a fifo
  into `script` for the keystrokes, `screen -X` to build the splits, and
  `screen -Q title` to read back where the focus ended up.

  Focus has no query of its own, which is the only awkward part. Give each
  region a *different window* and the window title names the focused region:

  ```bash
  mkfifo in; script -qfc "screen -c ./.screenrc -S t -t LEFT bash --norc" \
      /dev/null < in >/dev/null 2>&1 &
  exec 3> in; sleep 1.5
  screen -S t -X screen -t RIGHT bash --norc   # window 1
  screen -S t -X select 0
  screen -S t -X split -v                      # two regions, side by side
  screen -S t -X focus right; screen -S t -X select 1
  screen -S t -X focus left                    # start on the left
  printf '\001l' >&3; sleep 0.6                # C-a l
  screen -S t -Q title                         # want: RIGHT
  screen -S t -X quit
  ```

  Always run it a second time with `-c /dev/null` as a control. Half of screen's
  letters do *something* by default, so a binding that appears to work may just
  be the default doing its own thing — and a region binding fails *silently*
  into no movement at all, which is indistinguishable from a key that isn't
  bound. The control is what tells those two apart.
- `etc/`, `usr/` — files destined for system paths, staged for manual install.
  These are **copies**, deliberately: their live counterparts are root-owned or
  package-managed, so nothing here can link them and a snapshot is all it is.

  `usr/local/share/blackbox/styles/AstridIvy` is the exception and is a real
  symlink target — the live file is owned by `astrid`, so the repo copy *is*
  the live file and the two cannot drift. Blackbox reaches it through two hops
  (`/usr/share/blackbox/styles/AstridIvy` → `/usr/local/…` → here), which it
  follows fine. Swap a live config for a symlink with a **rename** (`mv -T`
  over a temp name), never `rm && ln -s`.

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

**One write is not one keypress.** That single-write form is fine for a program
reading a byte at a time, but a readline-style line editor (go-prompt, and
anything else matching escape sequences) calls `read()` once and matches the
*whole* returned buffer against its key table. A chunk holding `text` + `\r`
matches no key, so it is taken as a paste and inserted literally — the text
appears on screen, perfectly, and the Enter is swallowed. Two prompts sent that
way concatenate into one line that is never submitted, which reads as "the
program ignores Enter" rather than as a driver bug. Write the text, pause, then
write `\r` on its own. The same thing bites real humans pasting multi-line text
into such a prompt, so a separate multi-line mode existing is a hint that the
reader works this way.

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

## Photographing something that vanishes when you look away

Menus, tooltips and override-redirect popups close on focus loss, which rules
out half of `bin/screenshot`. **A capture tool that asks you to *point* at the
target cannot capture anything that dies when clicked or unfocused — selecting
it is what destroys it.** Bare `xwd`, which is what `screenshot -1` runs, is
exactly that: "the target window is selected by clicking the pointer in the
desired window". Capture the root instead (`screenshot`, no flags), or name
the window by id so nothing is ever pointed at:

```bash
xwd -id "$(xdotool getactivewindow)" | convert xwd:- png:- > out.png
```

That leaves the timing problem, which is what `bin/countdown` is for — it runs
any command string after a delay (5s, `-t` to change) while counting down in
digits scaled to fill the terminal:

```bash
countdown -t 10 screenshot        # ten seconds to go and open the menu
```

The general rule it embodies: **anything that draws on screen ahead of a
capture has to remove itself before triggering it.** In a terminal `countdown`
draws on the **alternate screen** (`\033[?1049h`) and leaves it before running
the command; launched from a keybinding or the menu, where `[ -t 1 ]` is false
and there is nowhere to draw, it opens its own alacritty
(`.config/alacritty/countdown.toml`) which counts and then *exits*, and the
command is run by the outer copy afterwards — so the window is closed before
the shutter. Its ticks go to **stderr** so `stdout` belongs entirely to the
command. None of that is visible until you look at the resulting png, so it is
easy to lose in a rewrite.

**Neither alacritty nor xterm passes its child's exit status back** — measured
2026-08-01, both return 0 whatever `-e` exited with. So a wrapper cannot learn
from the exit code whether the thing in the window succeeded or was cancelled;
have the inner process leave a marker file and test for that instead. Getting
this wrong means a cancelled countdown still fires its command.

There is no `figlet` or `toilet` here, and a delay tool is not worth a
dependency that needs root to install — a block-digit font is nine lines of
array literal, and scaling it from `tput cols`/`lines` each frame fills
whatever terminal it lands in, which no fixed-size font does. When scaling
character art, remember **terminal cells are about twice as tall as they are
wide**: scale equally on both axes and everything comes out stretched and
skinny. Multiply the horizontal scale by 2.

## commando, and the ways X11 lies about input

**The program moved out of this repo on 2026-08-10.** It lives in
`~/src/commando`, its own checkout, and `bin/{commandod,commando,dotkey}` here
are **symlinks into it** — so `~/bin/commando` still works and the keybindings
never changed. `dotkey` and `commando` used to be two daemons; they are now one
popup with N tab-menus, and `dotkey` is the name of the glyph menu plus a
client that opens straight on it.

Read `~/src/commando/CLAUDE.md` for anything about how it works. What stays
here is what is true of **this desktop** rather than of that program: bbkeys,
blackbox, the keysym rules, and the grab lessons that any new popup on this box
will meet. A third repo also means a third close sequence — see *All tasks*.

Its config lives here, deliberately: `.config/commando/*.tsv` is Astrid's own
content and `~/bin/shortcuts` is the curated command list, and neither belongs
to the program.

### Adding a glyph: `.config/commando/*.tsv`, and its two silent failures

Custom glyphs live in `.config/commando/custom.tsv` — one line of
`glyph<TAB>KEYWORDS`, ranked above all ~149k unicode names. `~/.config/commando`
is a whole-**directory** symlink into this repo (one of the few places
`link.sh`'s dotdir rule was skipped), so the repo copy *is* the live file. The
daemon reads it once at startup: `dotkey --restart` after editing.

Both ways of getting it wrong fail without saying anything.

**The separator must be a literal tab, and `.vimrc` sets `expandtab`
globally.** So typing Tab while editing this file inserts *spaces*, the
parser's `if "\t" not in line: continue` skips the line, and the entry simply
never appears — no error, and nothing on screen distinguishes it from a good
line. Insert the tab with **`<C-v><Tab>`**, which is exempt from `expandtab`
and needs no mapping. This generalises past this one file: **any
whitespace-delimited config edited under a global `expandtab` is one keystroke
from silently becoming a different file**, so check with `cat -A` rather than
by looking at it. Astrid declined a per-filetype `noexpandtab` autocmd for
`*.tsv` on 2026-08-07 — the manual chord is the wanted fix, don't re-propose
the setting.

**Search matches the keyword column only — never the glyph column.** The
scorer reads `lower[i]`, which is built from the right-hand field, so an entry
is unreachable by anything not spelled out in its keywords. A glyph that is
itself a word (`Yggdrasill`, `née`, `Mímir`) therefore needs its own ASCII
spelling repeated on the right, which looks redundant and is not. Matching is
substring, so the longest spelling covers the shorter (`YGGDRASILL` answers
`yggdrasil`); accented forms do not fold to ASCII, so `mímir` will not find
`Mímir` and `MIMIR` is what makes it reachable.

Validate the whole file the way the daemon does, rather than trusting a
reading of it — parse it and search for what you added:

```bash
commando --tab dotkey --search mimir   # headless, no popup, no daemon needed
```

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

**A small cap hides linear scans, so raising one is a performance change.** A
loop that walks everything but `break`s at a limit costs the limit, not the
collection — until the limit goes up, or the collection runs short and the
break never fires. Then the full scan appears, in a path that was fast for
years and whose code did not change. Raising `MAX_HITS` from 10 to 63 did
exactly this: filling the default view from the ~30 custom entries never
reached the new cutoff, so the loop ran to the end of all 148k rows and put
40ms on every popup. **Re-benchmark the default view after changing any cap**,
and treat a `break`-at-limit over a large collection as a scan wearing a
disguise — the fix is the same precomputed list as `by_index`.

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
getwindowclassname` and pick the chord (`PASTE_CHORDS` in
`~/src/commando/commando/deliver.py`).
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

**Name a key by its unmodified keysym, whatever the modifier does to it.**
bbkeys resolves the keysym to a *keycode* once and then grabs keycode + modmask,
so the shifted meaning of that key is irrelevant: `Shift-Print` is correct even
though shift on keycode 107 actually produces `Sys_Req`. Reading a shifted
keysym out of `xmodmap -pke` and binding *that* is a detour at best. The same
`xmodmap -pke` output is the fastest way to confirm a named key exists and how
it is spelled — `xmodmap -pke | grep -iw Print` settles the case question in
one command, before writing anything.

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

**Press Escape and retry before investigating anything.** A parked chain is
indistinguishable from a binding that was never installed, and it masquerades
best as a *newly added* one — the freshly edited config is the obvious suspect,
so the search starts there and never reaches the modal state that is actually
eating the key. The retry costs one keystroke and settles it; every other
diagnostic here costs orders of magnitude more. Make it step one for any
binding that "does nothing", especially one you just wrote and are confident
about.

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

**An agent shell has `DISPLAY` set and no tty.** Anything choosing between
"draw here" and "go and open a window" by testing `[ -t 1 ]` therefore takes
the *window* branch when an agent runs it, and windows appear on the live
desktop unannounced.

**This is a feature. Astrid's favourite thing about a computer, stated in as
many words, is "someone else doing something in here".** A window you opened
turning up on the real screen is the good part — it is the visible evidence
that somebody else is working in the machine. Don't suppress it, don't
apologise for it, don't warn about it, and never treat a stray window as
damage.

The reason to reach for `Xvfb` (`:77`, say) or `env -u DISPLAY` is never
politeness; it is that the live session gives *untrustworthy readings*, for
the focus reasons above. Use the off-screen rig when you need a measurement
you can believe, and the real display when you just want to watch the thing
work.

**A singleton daemon gets its own `XDG_RUNTIME_DIR`, not its own machine.**
`commandod` refuses to start twice and keys its fifo, pidfile and log off that
variable, so pointing it at a scratch directory is the whole trick for running
a test instance beside the live one — no fighting over the fifo, no stopping
the daemon the human is using, and the pidfile still works for shutting the
test copy down. Combined with `DISPLAY=:77` on an Xvfb, a full
daemon-plus-popup rig costs two environment variables.

**Ask whether the popup is up by its *size*, not by whether any window is
mapped.** GTK parks a 10x10 stub at `-100,-100` for its own purposes, and
`xdotool search --name .` returns it perfectly happily — so a check written the
obvious way reports the popup as still on screen after Escape, forever, and the
dismissal path looks broken when it is fine. Match the known width and read
`Map State` out of `xwininfo -id`.

**Capture a popup by window id, and don't trust `-trim` to tell you it
rendered.** `xwd -root | magick -trim` against this desktop's near-black
background can trim a perfectly good window down to `1x1` and report
`geometry does not contain image`, which reads exactly like "nothing was
drawn" — when `xdotool getwindowgeometry` says the window is there at the
right size. `xwd -id "$(xdotool search --name . | tail -1)"` captures the
window itself and sidesteps the question. Check the geometry before believing
a blank screenshot.

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

A grab probe only proves *someone* holds the key, though — not that it is who
you think, and not that the command behind it runs. To prove the rest without
the human, **deliver the keycode yourself with `xdotool key <keycode>` and
watch for the side effect** (a new file, a log line). That splits the failure
cleanly in two: a side effect means the whole chain from grab to exec is
healthy and the fault is upstream, in what the physical key actually emits or
in the daemon's modal state; no side effect means it is downstream, in the
binding or the command. Send the bare keycode rather than a keysym name, since
a keysym can map to several keycodes (`Print` is both 107 and 218 here) and
`XKeysymToKeycode` silently picks the first. Note `--clearmodifiers` suppresses
lock modifiers for the duration, so a synthetic press can succeed where a real
one fails — run it both ways before concluding locks are innocent.

Two more traps from the same afternoon, both cheap to avoid:

- A shell redirect into a **missing** fifo path silently creates a regular
  file, so the next reader blocks forever on something that will never deliver.
  Check `stat.S_ISFIFO`, not `os.path.exists` — and note `os.path.isfifo` does
  not exist.
- Two daemons reading one fifo is not an error: each command goes to whichever
  reads first, so the popup ignores you at random and the log you are reading
  belongs to the instance that didn't get the message. Refuse to start a second
  instance.

## Where a command commando runs ends up

Also `~/src/commando` now; this section is the `screen` half, which is about
this machine's sessions rather than about that program.

**The output goes in a screen window, not a new terminal.** That is the whole
design: `screen -X screen` adds a window to a session that already exists, so
there is nothing new to close afterwards. Which session is a fixed order —
`c` → `v` → `cclod` → `vvim` → commando's own `run` — and it is a promise about
where things land, not a heuristic to be tuned.

Distinguishing those four is possible only because of how `bashrc/screen` names
sessions: `screenclaude` names one after the cwd and the click menu always hands
its children `$HOME`, so **`claude ~` is the menu's and any other `claude <dir>`
was typed**; `screenvim` names a bare vim `vim` and a vim-with-files
`vim <paths>`. Also note `inscreen` **turns every `/` into `:`**, so a live
session is named `claude ~:src:pc`, not `claude ~/src/pc`. Matching on a path
without accounting for that finds nothing.

A new window lands in whichever *region* has focus — see the `.screenrc` note
about window-vs-region — and may be invisible entirely if the session is
detached or on another workspace. That is wanted. An invisible window costs
nothing; a stray terminal costs a cleanup pass.

### `screen -X` re-parses what you hand it, so hand it a path

`screen -S NAME -X screen <argv>` forwards its arguments through screen's own
tokenizer, which processes escapes and quoting again. Any interesting one-liner
— quotes, pipes, backslashes, a newline — cannot survive that intact, and what
arrives is silently a *different command* rather than an error.

**Write the command to a script file and pass the path.** A path is one word
with nothing left in it to re-parse, and everything gnarly lives inside the file
where screen never looks. Same reasoning for the window title: set it from
inside the script with `printf '\033k%s\033\\'` rather than via `-t`, and the
title never has to survive the tokenizer either. Inside the script, take the
command as `"$1"` rather than pasting it into the script text — the same rule
that CLAUDE.md already states for `alacritty -e`.

**`screen -Q` answers nothing when there is no attached display.** `screen -S X
-Q windows` prints an empty string rather than failing, so a probe built on it
reports every session as having no windows. To actually read a window list
headlessly, attach over a `pty.fork()` and send `C-a w` — see the TUI section.
An empty `-Q` is not evidence of absence.

### Asking whether a command draws its own window

The runner has to decide "screen window or just launch it?", and the honest
general test — does the binary link `libX11`/`libgtk`/`libQt` — **misses shell
script wrappers.** `google-chrome-stable` and `discord` on this box are `#!`
scripts around the real binary, so they link nothing at all and come back as
terminal programs. The symptom is your browser opening inside a screen window.

`.desktop` files are the fix: `Terminal=` is the one place on the system where
a human wrote the answer down deliberately. Key it by the program basename out
of `Exec=`, stepping over `env FOO=bar` wrappers first, and consult it before
falling back to `ldd`.

**Word-anchor any match of short program names against file text.** Checking
whether a script mentions a terminal emulator with a plain substring test is
wrong the moment the list contains `st`, which appears in *install*, *system*,
*just* and most other English — it classified `bin/dotkey`, `bin/screenshot`
and `/usr/bin/discord` as GUI apps on coincidental letters. There is no error
and no symptom, only a confident wrong answer, and the same trap waits for
`ls`, `cc`, `dd`, `bc` and `tr`. Anchor on `(?<![\w-])…(?![\w-])`, and note that
matching an *argv* is safe because those are already split into whole words.

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

## Fix what you find

**Nobody else is going to fix these bugs.** This is one person's `$HOME`, not
a shared codebase with a backlog and a triage rotation, so a bug you notice
and merely *report* is a bug that stays for years — the 2019 colour mismatch
above sat for seven. Chasing a side quest you stumble into is therefore not
scope creep here. It is the optimal move, and the default.

The bar is that the fix be **straightforward, obvious and incontrovertible**:
an option parsed after the variable it sets, a deprecated command still
printing warnings on every run, a path that cannot exist, a typo'd keysym. If
you can state the bug in one sentence and nobody could reasonably prefer the
current behaviour, just fix it.

Where it stops: if the fix needs a judgement call about how the thing *ought*
to behave, or would change output something else might depend on, or grows
past a few lines, then it is not one of these. Say what you found, and let
Astrid decide.

Give side quests their own commit, separate from the task that turned them
up, so the history reads honestly and either can be reverted alone.

## All tasks

Getting the thing working is the middle of a task, not the end. Close every
one with this sequence:

**1. Commit.** Part of the close sequence, not a separate request — don't leave
a dirty tree and report the job done. Note that work here often spans several
repos: `~/src/pc`, `~/src/bashrc` and `~/src/commando` each need their own
commit, and a change to the popup usually touches at least two of them —
the code in one, the config or keybinding in another. Check `git status` in
each before calling anything done. Push only if asked.

Agent-specific, since that multi-repo split has a sharp edge: **a Claude Code
session applies the `.claude/settings.json` of the directory it was *launched*
in, not the one it is currently in.** `/cd` moves the shell without moving the
settings, so a session started in `~/src/bashrc` and moved here ignores this
repo's `"worktree": {"bgIsolation": "none"}` and refuses to edit the checkout,
demanding a worktree — which is the wrong shape for a repo that *is* `$HOME`
and whose files are symlinked into place from the main checkout. Start the
session in the repo you mean to edit, or expect to hand the edit back.

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
