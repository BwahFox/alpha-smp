# Minecraft Alpha 1.1.2_01 SMP — parity patch set

Multiplayer for Minecraft Alpha 1.1.2_01 that behaves like singleplayer:
working damage, PvP, death and respawn, server-authoritative inventory and
containers, crafting, furnaces, chests, bows and snowballs, boats, minecarts
and riding, paintings, jukeboxes, sounds, particles, mining effects, sneaking,
equipment on other players, and more. Gameplay stays alpha — fixes were ported
from later versions only where multiplayer was broken by design.

**This repository contains no Minecraft code.** You supply your own jars; the
installers decompile them locally (pinned, deterministic decompilers included),
apply our patch set, and build. What we distribute is patches and tooling.

Prefer a launcher? Prebuilt **jarmod zips for Prism/MultiMC** are on the
[Releases page](../../releases) — see the jarmod section below.

## Quick start (one command)

    git clone https://github.com/BwahFox/alpha-smp
    cd alpha-smp
    ./bootstrap.sh

Downloads everything required — Ooney's public workspace, the pristine server
jar (sha256-verified), libraries, and a JDK if you don't have one — then
builds both server and client into `./alpha-smp/`:

    ./alpha-smp/server/run-server.sh
    ./alpha-smp/client/run-client.sh YourName

`./bootstrap.sh --server` or `--client` builds just one; `--jar your.jar`
uses a server jar you already have; `--dest DIR` picks the output directory.
Needs: curl, unzip, git (and ~15 minutes on a slow connection). The manual
per-piece route is below if you prefer to see each step.

## Server

You need: the pristine alpha server jar (`a0.2.1.jar`, the one matching client
a1.1.2_01), a JDK (17+), and git.

    ./install-server.sh /path/to/a0.2.1.jar ./server
    ./server/run-server.sh

Admin notes:
- The wire protocol is **100** (deliberately not vanilla's 2 — stock clients
  get a clean "Outdated client!" instead of a corrupt half-join). Players need
  the matching client below.
- `server.properties` works as vanilla, including `spawn-protection`
  (default 16; ops are exempt).
- Give `-Xss512m` if you change the run script — Far Lands light recursion
  overflows the default stack.

## Client

You need: a checkout of **Ooney's Alpha Patches** repository (public; it
provides the deobfuscated a1.1.2_01 workspace this patch set targets), a JDK
(17+), git, curl, unzip.

    ./install-client.sh /path/to/ooneys-Alpha-Patches ./client
    ./client/run-client.sh YourName

Then Multiplayer → your server's address. Libraries are fetched from
Mojang's and Maven Central's public repositories at pinned versions.

## Mod authors

The patch sets ARE the source: apply them and read the result. Client changes
live almost entirely in readable-named classes; server additions use readable
names while vanilla classes keep their obfuscated ones — the
obfuscated-to-real mapping table is [MAPPING.md](MAPPING.md). Layer your mod
as further patches on top — that is exactly how this base was built and
tested (Ooney's Oonic mod runs merged on top of it).

## Known rough edges

- Sounds require game assets under the client's `game/` directory; the
  launchwrapper fetches what it can, but a full assets folder from any
  standard launcher install of a1.1.2_01 can be dropped in.
- ARM64 (e.g. Raspberry Pi) works with Debian's LWJGL 2.9.3 jar+native pair
  swapped in (`liblwjgl-java` + `liblwjgl-java-jni`, extracted with
  `dpkg-deb -x`; the jar and native must version-match) and the system
  OpenAL symlinked into the natives dir.
- **Nvidia + Wayland**: multi-second freezes around world entry are an
  nvidia-GLX-under-XWayland issue, not the game. Fix: set
  `__GLX_VENDOR_LIBRARY_NAME=mesa` and `MESA_LOADER_DRIVER_OVERRIDE=zink`
  in the game's environment (Prism: instance Settings → Environment
  variables) to route GL through Mesa/zink, or use an X11 session.

## Prism Launcher / MultiMC (jarmod)

Prebuilt jarmod zips are on the [Releases page](../../releases):
`alpha-smp-jarmod.zip` (the parity base) and `alpha-smp-oonic-jarmod.zip`
(the base merged with Ooney's Oonic mod — never stack the two separately,
they overwrite whole classes). In Prism: create an **a1.1.2_01** instance →
Edit → Version → **Add to Minecraft.jar** → the zip. Prism supplies assets
and sounds itself. (The jarmod zips contain modified Mojang-derived classes —
standard community jarmod convention — which is why they are release
downloads rather than part of this clean-room repo.)

To build one yourself instead, `./build-jarmod.sh <workdir> <output.zip>
<source-tree>` (fetches its own JDK 8 if needed; ~5 minutes). It needs
[RetroMCP-Java](https://github.com/MCPHackers/RetroMCP-Java)'s CLI jar at
`tools/RetroMCP-Java-CLI.jar`, and the source tree is the patched client
source that `install-client.sh` produces (or your modified copy of it).

## Online mode

Both sides speak Mojang's LIVE session services: servers can set
`online-mode=true` (login verified via hasJoined), clients authenticate with
the session from any modern logged-in launcher, skins load by username from
minotar.net (modern skins are auto-cropped to the alpha format), and the
client fills `resources/` with era-correct sounds from the community mirror
of the original S3 bucket. Offline mode (`online-mode=false`, any username)
works exactly as before.
