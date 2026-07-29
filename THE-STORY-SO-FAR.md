# the story so far

Once upon a time I got a laptop and blinged it all the way up. Then I didn't
have a computer for a long time. Now I'm back on my computer and it needs work.

## the machine

An **Acer Aspire 5741G** — Core i5 M430 @ 2.27GHz, 3.7 GiB of RAM, Radeon HD
5430. Hardware from about 2010. It is not fast and that is fine.

Two keys have opinions of their own, which is why `keyledsd.conf` ends with a
`blackout` effect that exists purely to paper over them:

- **F1** lost its keycap and never got it back, so it's painted black.
- **The "4" key** sends a wrong colour signal. The value `4444ff71` happens to
  correct for it almost exactly. Nobody planned this.

## the timeline

| when | what |
|---|---|
| **2018-11-29** | first commit in this repo — `Initial commit` |
| **2021-06-20** | Arch installed on this machine (`base base-devel vim lua ruby git lynx acpi tamsyn-font tree light`) — same day most of `/etc` was configured, including passwordless console login |
| 2022–2023 | the bling years: Blackbox, per-app RGB keyboard profiles, a whole Ardour/JACK music rig, pink themes for everything |
| **2024-10-04** | last full system upgrade |
| … | *no computer* |
| **2026-07-29** | back on the computer |

That's a **21-month gap**. Long enough that things didn't just get old, they got
structurally wrong.

## what was broken when I came back

**pacman was completely dead**, and not for the reason it looked like. The
`[community]` repo was merged into `extra` back in May 2023 and no longer
exists — but the mirror answers that dead path with an HTML error page and a
`200 OK`, so pacman happily "downloaded" a web page as `community.db` and
another as `community.db.sig`. With `SigLevel = Required DatabaseOptional`, a
*missing* database signature is fine but a *present and invalid* one is fatal.
So one decommissioned repo took down every other repo, and `pacman -Sl extra`
would report a `community` error.

The fix was deleting a config section, not updating anything.

Then: `archlinux-keyring` was 25 months old and had to go first, before the rest.

**`bin/google` had been silently broken** for a year — a flag-collecting loop put
the flags between `--session` and its filename, and `$~` doesn't expand in bash,
so lynx cheerfully went off to browse `www.$~.com`.

**A year of uncommitted work** was sitting in the tree: Ardour 7→8 everywhere,
the keyboard LED rework, Battle.net→Steam. Committed 2026-07-29 as
`catch up on a year of man-moding it`.

**ESLint had been half-migrated and left.** Turns out I'd been writing JavaScript
with no linting at all for about a year, just man-moding it. Still not fixed —
see `CLAUDE.md`.

## the security scare that wasn't

Somewhere in here `sudo` stopped accepting my password, which is an alarming
thing for a computer to start doing.

It was `pam_faillock`. The shell aliased `pacman` to `sudo pacman`, an agent
shell with no TTY called it a few times, three silent auth failures stacked up,
and faillock locked the account — at which point it rejects the *correct*
password too. Nothing was wrong with the password. Those two aliases are gone
now.

While we were already spooked, we audited the whole box: `pacman -Qkk`
checksummed every file of all 1,125 installed packages. Two files differed
outside pacman's expected config category, and both were innocent — `bbkeys`
was a local build that never got stripped (2.1 MB of DWARF debug symbols; strip
a copy and it matches), and VLC's `plugins.dat` is a cache it regenerates
itself. No intruder.

The genuinely interesting find: I'm in a `nopasswdlogin` group, and
`/etc/pam.d/login` grants passwordless **console** login on that basis. Set up
deliberately in 2021. Doesn't touch SSH or sudo.

The real risks were never exotic — a two-year-old Chrome, and SSH accepting
passwords on `0.0.0.0:22`. SSH is now key-only from my phone.

## where things stand

- pacman works; keyring current; **985 packages pending upgrade**
- upgrading will need manual intervention for `linux-firmware`, and glibc 2.41
  will break the Discord install
- SSH is key-only
- 97 AUR packages, several long abandoned (`youtube-dl` frozen at 2021,
  `google-chrome` at 128, `qt3`, `js78`)
- ESLint still unfinished

Everything on this computer is cursed. It's *my* curse though.
