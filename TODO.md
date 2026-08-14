# TODO

Things we deliberately kicked down the road. Written 2026-07-31.

Background and rules live in `CLAUDE.md` — especially the sudo/faillock warning
(print root commands, don't run them) and the fact that `ivy` is a disk that has
outlived two computers.

---

## 1. dotkey — searchable Unicode popup — **BUILT 2026-07-31, MERGED 2026-08-10**

> **Moved.** dotkey and commando were one program twice over, and are now one
> program once: `~/src/commando`, its own repo, one daemon holding one popup
> with N tab-menus. `dotkey` survives as the name of the glyph menu and as the
> client that opens straight on it, so the chord and the muscle memory are
> unchanged. `bin/{commandod,commando,dotkey}` here are symlinks into it.
> Everything below is history; the live notes are in that repo's `CLAUDE.md`.

*"win-key dot, but mangled a bit."* Bound to **Mod4-period**, the same chord
Windows uses. Works end to end: press it, type a name, hit enter, the glyph
lands in whatever you were typing in.

- `bin/dotkeyd` — resident daemon: the index, the popup, the delivery
- `bin/dotkey` — tiny shell client that pokes the daemon through a fifo
- `.config/dotkey/custom.tsv` — own glyphs, ranked above all of Unicode
- `.bbkeysrc` holds the binding (now tracked and symlinked out); `.xinitrc`
  starts the daemon at login

Searches **all 148,875 named codepoints**, straight out of python's own
`unicodedata` (16.0.0) — no `UnicodeData.txt` download, no curated subset. The
open question about scope answered itself: with CJK and Hangul pushed down the
ranking, the full set is *better* than a curated one, because nothing is
missing and nothing is in the way. See `CLAUDE.md` for the design notes that
matter.

Answers to the questions this file asked before it was built:

1. **Scope** — the whole thing, ~149k. Bulk algorithmic names (CJK, Hangul,
   Tangut...) rank last, so they never crowd a real answer.
2. **Selector** — none of them. `rofi`, `dmenu` and `rofimoji` are all *not
   installed*, and installing needs root. A resident GTK daemon needs nothing
   new and is faster than any cold start could be.
3. **Insert method** — **the assumption here was wrong.** Typing via `xdotool`
   is the *un*reliable option on this box, not the safe one: 1 success in 8.
   Clipboard + a per-app paste chord is the reliable path. Details in
   `CLAUDE.md`.
4. **Resident?** — yes, and measurably so. GTK's import alone is 1.64s here.
5. **Recents** — done, frequency-ranked, in `~/.cache/dotkey/recent.json`.
6. **Absorbs the five glyph scripts?** — the *content* does: `heart`, `supson`,
   `endash`, `emdash` and the shrug are all in `custom.tsv` and rank first.
   `bin/{heart,supson,endash,emdash,♡}` are still there and still work; deleting
   them is a separate call, since `.blackbox/menu` may reference them.

### Still open on the glyph menu

- No **skin-tone** or variation-selector handling.
- The grid is 63 cells and does not scroll; more matches exist than are shown.
  Fine in practice, but paging would be nice.
- `shift+enter` typing is kept as a fallback and is genuinely unreliable — see
  the measurement before trying to "fix" it.

---

## 2. Clipboard — **history BUILT 2026-08-10**

The clipboard **history** is the `clipboard` tab-menu in `~/src/commando`, and
it cost no new packages: the watch is XFixes, which gtk already speaks, and
xclip was already here. So `copyq`, `clipmenu` and `clipnotify` were all
considered and none was needed — don't re-propose installing one to get history.

What it does **not** do, still open and a deliberate decision rather than an
omission: it **records but does not hold**. The clip still dies with the
process that owned it, so alacritty's intermittent `Unable to store text in
clipboard` is untouched — nothing arbitrates selection ownership, and adding a
second fighter over one selection is not obviously an improvement on nobody
arbitrating. Taking persistent ownership is a small change if it is ever
wanted; it needs a decision first, and a way to tell "we own it because we are
the manager" from "we own it because someone just picked a clip".
- **Wire up `g:clipboard` in `.vimrc`.** Arch's vim is built `-clipboard -X11
  -xterm_clipboard`, so `set clipboard=unnamedplus` (line 11) has never done
  anything — `has('clipboard_working')` is 0. Vim 9.2 has
  `+clipboard_provider`, so a `g:clipboard` dict pointed at `xclip` would make
  `"+y` work natively. Keep `:XClip` and the visual `Y`/`D`/`X` maps regardless
  — they are load-bearing today.

---

## 3. Razer Cynosa Chroma

The Logitech board was stolen; `keyledsd` is now dead weight. The Cynosa is
**per-key addressable** (OpenRazer `MATRIX_DIMS = [6, 22]`) and supports wave,
static, spectrum, reactive, breath, starlight, ripple, and full custom per-key.
The DeathAdder Essential mouse (`1532:0098`) is supported by the same daemon.

- **Finish activating it.** `openrazer-daemon` and `linux-headers` are
  installed, but no razer module is loaded and there is **no `plugdev` group**:

  ```bash
  sudo gpasswd -a astrid plugdev     # creates membership; group may need creating
  sudo modprobe razerkbd
  ```

  Then log out and back in for the group. Verify with
  `python -c "import openrazer.client as c; print(c.DeviceManager().devices)"`.
- **Rebuild the per-app profiles.** `python-openrazer` gives a real API, so
  keyledsd's idea — match on window class, set an effect — is a `bin/` script.
  This is the thing actually worth having back.
- **Retire the keyledsd relics**: `.config/keyledsd.conf`, `bin/keyleds_toggle`,
  and the `RGB Keyboard LEDs` entry in `.blackbox/menu`, which currently
  launches something that silently does nothing.

---

## 4. System

- **`sudo resize2fs /dev/sda1`** — still outstanding, still ~38G of the
  partition unreachable. One online command. See `CLAUDE.md`.
- **Set the wifi regulatory country.** `iw reg get` reports `country 00`, the
  conservative world domain, which limits channels and TX power.
  `wireless-regdb` is installed now, so the database is there; nothing sets a
  country.
- **JACK runs non-realtime, and cannot do otherwise as configured.** Every
  server start logs `JACK server starting in non-realtime mode` and
  `Cannot lock down 107341340 byte memory area (Cannot allocate memory)`:
  `ulimit -l` is 8192 KB, there is no `/etc/security/limits.d/` at all, and
  `astrid` is in neither an `audio` nor a `realtime` group (`realtime` doesn't
  exist; `audio` does, gid 995, empty). Audio works — Pulse, the TASCAM and
  Carla are all fine at 1024/3/48000 — so this is xruns-under-load rather than
  anything broken, which is why it has gone unnoticed. The standard fix is the
  `realtime-privileges` package plus adding the user to its group, then a
  re-login; it needs root and a decision about whether the latency is actually
  wanted, so it is here rather than done.

*(Done this session, don't redo: fallback initramfs enabled and built,
`intel-ucode` installed, `grub-mkconfig` run — grub.cfg now has 3 ucode
references — and `wireless-regdb` installed.)*

---

## 5. Colours

`bin/palette` is built: edit the sixteen, write the console `.color`, the
`XTerm*colorN` block and the alacritty toml from one place. See `CLAUDE.md`.

Still open:

- **Nothing has been converted yet.** The three live files still hold two
  stale disagreements (`palette bin/Tomorrow-Night-Nineties.color -d
  .Xresources -d .config/alacritty/alacritty.toml` prints them): colour 1,
  where `.Xresources` kept `ea9cc3` from the 90s scheme and has the right
  value sitting commented out, and colour 8, `442244` vs `604070`. Deciding
  which of the two is right is a taste call, not a merge.
- **Red → hot pink / bold magenta**, the thing that started this.
- **The vim colorscheme is a fourth copy and has extra colours** —
  `orange ff9800`, `window 4d5057`, `line`/`comment 442244`, plus a
  `background 222244` and `foreground ffa5de` that both disagree with the
  terminal palette (the foreground is the pre-`875f783` colour 15). Its names
  are shuffled relative to the ansi slots as well — its `yellow` is ansi 10
  and its `green` is ansi 11 — so nothing can be mapped across by name.
  Whether `palette` grows a vim export, and whether the extras get real
  palette slots or just `termguicolors`, is undecided; the constraints are
  written up in `CLAUDE.md`.

---

## 6. Repo hygiene

- **`origin/serverside` is nearly exhausted.** Two passes are merged. What's
  left is mostly serverside being *older* than master. Genuinely un-reviewed:
  `bin/maeusic` (serverside has `cadence-jackmeter` and
  `carla-single ~/doc/baby_grand.carxp` that master dropped — a music-rig
  preference call), and `.blackbox/menu`'s Enable/Disable Laptop Monitor
  entries, which reference `LVDS-1` and would need `eDP1` to work on the Dell.
  `.config/keyledsd.conf`'s four extra effects are now moot. **Diff two-dot**
  (`git diff master origin/serverside`), never three-dot — see `CLAUDE.md`.
- **`etc/default/grub` has drifted from live**: repo says `GRUB_DEFAULT=0` /
  `GRUB_TIMEOUT=1`, live says `saved` / `2`. Expected for `etc/` staging, but
  worth reconciling.
- **`bell/.sequence`** is transient runtime state written into a tracked
  directory; it flickers in and out of `git status`. Probably wants a
  `.gitignore` line.
- **`bin/setadd` is truncated and has never worked.** It ends mid-string on
  line 21 (`the_set="$the_set`, no closing quote), so every call dies with
  `unexpected EOF` after echoing only its first argument — and it is called
  with three arguments while reading two. `bashrc/exports` builds `PATH`,
  `NODE_PATH` and `LD_PRELOAD` through it, so **sourcing `exports` leaves
  `PATH=/home/astrid/bin` and nothing else** — no `/usr/bin`. The interactive
  shell survives by accident and wears the evidence: `$PATH` carries
  `~/bin:~/.npm/packages/bin` three times over, the exact duplication setadd
  exists to prevent. Verified 2026-08-07; committed broken in `e85eb01`.

  Not patched blind because finishing it is a design call, not a typo fix:
  what separator does it append with (`:` for `PATH`, but the truncated line
  opens a *multi-line* string), and are the three-argument call sites right or
  should it take a list? Both `~/src/commando` and anything else that sources
  `exports` currently work around it by saving and restoring `PATH` and
  dropping stderr; those workarounds say to delete them once this is fixed.
- **`~/src/diet-vhost` and `~/src/maitre-d`** declare dependencies but have no
  `node_modules` — they need an `npm install` before they'll run.

---

## 7. commando — the command runner — **BUILT 2026-08-07, MOVED 2026-08-10**

> Now `~/src/commando`, and now the whole program rather than one of two — see
> §1. The command sources are one tab-menu, `~/bin/shortcuts` is a second, and
> the glyphs and clipboard are the rest.

`bin/commando` (client) and `bin/commandod` (daemon), on **Mod4-slash**.
Replaces the reflexive right-click → Alacritty, whose whole problem was the
terminal window left behind to be closed by hand an hour later.

Answers to the questions this file asked before it was built:

1. **Run-and-forget vs. show output** — neither, and that was the wrong axis.
   A command gets a **new screen window inside a session you already have
   open**, so the output is kept *and* there is nothing new to close. Which
   session, in order: `c` → `v` → `cclod` → `vvim` → commando's own `run`.
   The landing may be invisible (detached session, other workspace) and that
   is fine. GUI apps skip the whole mechanism and are simply launched.
2. **Naming** — "Command Presence" lost to **commando**, which puns on the
   same idea and is shorter to type. "Commander" was rejected as thoroughly
   taken: Midnight Commander, Norton, Total Commander, npm's argument parser.
3. **History** — done, frequency-ranked, `~/.cache/commando/recent.json`, and
   genuinely system-wide since it was never typed into a terminal to begin
   with. Past one-liners rank as a source of their own.
4. **Suggestions** — four sources, best first: `~/bin/shortcuts` (curated, new
   file, and the only one written by hand), `.blackbox/menu`'s `[exec]`
   entries, every `.desktop` file in three directories, then history. What you
   typed is always offered verbatim as the last row, so it is never *only* a
   launcher.
5. **The grab** — dotkeyd's five traps applied wholesale and all five were
   real. `owner_events=False`, `SeatCapabilities.ALL`, tear down on failure,
   retry against a monotonic deadline.

### Still open on commando

- No paging: 12 rows, and more matches exist than are shown.
- **A new `.tsv` needs a restart.** Editing one is live, but discovery runs at
  startup because the tab list is what the popup indexes into and growing it
  under a running popup is a way to land on a tab that no longer exists.
- No hotkey lands directly on the `clipboard` or `shortcuts` menus. `commando
  --tab NAME` exists and works, so it is one line in `.bbkeysrc` if a chord can
  be spared — deliberately not chosen for Astrid.
- `bin/shortcuts` is a first pass. It is the file to edit when something
  should be the first hit for its own name — edits are live on the next
  Mod4-slash, no restart.
- The **`.desktop` stash is stale.** `.local/share/applications/` is tracked
  here (7 files, last touched 2023) but was never symlinked, so the live
  `~/.local/share/applications/` is a separate real directory that has since
  grown to 26 files — wine, steam, chrome and discord all wrote theirs into
  the live one only. commando reads both, so nothing is missing today, but the
  repo copy is not the source of truth it looks like. Deciding which files
  deserve tracking (and linking those individually, never the directory — it
  holds live files the repo must not own) is a separate call.
- **commando is not in the click menu, on purpose.** It is not another entry
  in that menu, it is the thing replacing it — the menu is a *source* commando
  reads, not a place it needs to appear. That makes §8 below less "reorganize
  the menu" and more "work out what is left for it to do."
- The menu's `Ardour 8` entry launches `ardour8`, which **is not installed**;
  only an orphaned `ardour9.desktop` remains. Unresolvable commands fall back
  to "term", so it fails visibly rather than silently, but the entry is stale.

---

## 8. Reorganize the blackbox click menu

Written 2026-08-01. No concrete plan yet — just years of organic growth and
the sense that item 7 landing will change what the menu is even for. Revisit
*after* the command runner exists: some entries here today are single-shot
launches that may be better served as recent-history entries there than as
permanent menu real estate. Reorganizing first risks redoing it once that
shape is clearer.

---

## 9. Dockapps

Written 2026-08-01. Lower lift than it sounds: **the infra already exists.**
`.blackboxrc` has a Slit configured (`BottomRight`, vertical, always on top),
and `bin/dockapps` already launches three withdrawn-state dockapps
(`wmcpuload`, `wmmemload`, `wmclockmon`) with a matching `dockapps kill`. New
ones join that script, not a new subsystem.

`wmcpuload` and `wmclockmon` are AUR packages (`pacman -Qm`); `wmmemload` is
hand-built into `/usr/local/bin` — the AUR version was busted on the last Arch
reinstall, so its source was fetched and compiled by hand (`./configure` and
all). That source is **already saved**: `~/doc/download/wmmemload-0.1.8.tar.gz`
(matches the installed version exactly) plus an old `-0.1.7.tar.gz`. It's just
sitting in the general downloads pile, not anywhere dockapp-specific.

**Done 2026-08-01: source for all four gathered into `~/src/dockapps/`** —
`wmcpuload/`, `wmclockmon/` (AUR git clone + `makepkg -o` to pull the actual
upstream tarball each PKGBUILD points at, from dockapps.net and
tnemeth.free.fr respectively), `wmmemload/` (the tarball already saved in
`~/doc/download/`, just copied and extracted here), and `wmgtemp/` — see
below, this is the temperature one. Two reasons for keeping this around: style
reference when writing the volume/wifi/keyring ones, and insurance against the
exact failure that already happened once — an AUR package or its upstream
disappearing with no local source to fall back to.

**The temperature dockapp — good news.** `wmgtemp` (AUR, not currently
installed) is a real, better-than-expected candidate for "what if it did
work": its source (`~/src/dockapps/wmgtemp/`) already calls the *modern*
libsensors3 API directly — `sensors_init`, `sensors_get_detected_chips`,
`sensors_get_subfeature(..., SENSORS_SUBFEATURE_TEMP_INPUT)` — the same
library this box has installed (`lm_sensors 3.6.2`, confirmed working via
`sensors`). `./configure` gets as far as `checking for sensors_get_features in
-lsensors... yes` before failing, so the sensors API is not the blocker. The
actual blocker is one missing build dependency, a small windowing helper
library called `dockapp` (pkg-config can't find it) — it's in AUR
(`aur/libdockapp`, 24 votes) but not installed. That's a `sudo`-ending `yay -S`
at the end, so per the sudo/faillock rule in CLAUDE.md: the command to run by
hand is

```bash
yay -S libdockapp
```

— then re-run `makepkg` in `~/src/dockapps/wmgtemp/` to confirm it builds.

One tuning step waits after that, and it's a one-liner, not real work.
`wmgtemp` defaults to reading features named `temp1`/`temp2` off whichever
chip matches `-c` (or the first chip found with no `-c`), and `sensors` here
reports several (`dell_smm-isa-00de`, `coretemp-isa-0000`, two
`soc_dts*-virtual-0`). Left on defaults it locks onto `dell_smm`'s `temp1`
(a fan/case sensor) rather than the actual cores. `-c` matches on the chip's
*driver prefix* (`"coretemp"`), not the bus-numbered full name, so
`-c coretemp` is the fix and it's portable to the Acer's i5 too — no
per-machine bus-id pin needed. `sensors -u coretemp-isa-0000` shows this
chip's cores are named `temp2`..`temp5` (Core 0–3), not `temp1`..`temp4` (no
aggregate "Package" feature exposed here), so `wmgtemp -c coretemp` on
defaults lands on just Core 0 (`temp2`) — which is fine, cores 1–4 track each
other closely barring something actually wrong, so one core is most of the
signal for free. For both display slots lit: `wmgtemp -c coretemp -1 temp2
-2 temp4` (Core 0 and Core 2). Worth noting while in there: `sensors`
currently reports all four cores in `ALARM (CRIT)` state against a 90°C
threshold while sitting at 59–62°C — looks like a stuck/latched alarm bit
rather than a real overheat, but worth a second look before trusting
`wmgtemp`'s own warning-light logic on this chip.

Wanted, roughly in order:

- **Volume** — mixer level + mute. Check what's actually running here
  (ALSA vs. pulseaudio vs. pipewire) before assuming a backend; `bin/volumectl`
  already exists for something, worth reading first so a dockapp doesn't
  duplicate its logic.
- **Wifi** — connection state at a glance. `nmcli` is already the interface of
  choice in this repo (`.blackbox/menu`'s `nmcli con up wifi`), so shelling out
  to `nmcli` is a reasonable v1 before reaching for NetworkManager's D-Bus API.
- **Keyring manager** — actually wanted, not a set-completer. Scope undecided:
  a front-end for `secret-tool`/gnome-keyring, or something smaller. Check
  what backend is actually installed before designing a UI for it.
- **Bluetooth — not pursued.** Neither the Acer nor the Dell has a Bluetooth
  radio (see CLAUDE.md, "ivy is a disk, not a computer"), so there is nothing
  to control. Revisit only if the disk ever moves to a third machine that has
  one.

"They're written in C, how hard could it be" is less scary now that
`~/src/dockapps/` has four real examples to copy conventions from —
`wmmemload`'s `src/dockapp.c`/`dockapp.h` (Alfredo K. Kojima's original
withdrawn-window helper, copied into most classic dockapps of that era) is the
one to read first for the X11/withdrawn-state boilerplate every dockapp
repeats, before writing volume/wifi/keyring's XPM-and-event-loop specifics on
top of it.
