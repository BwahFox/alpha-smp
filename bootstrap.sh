#!/usr/bin/env bash
# One-command setup: downloads everything needed and builds the alpha-SMP
# parity server and client.
#
#   ./bootstrap.sh                  # build both into ./alpha-smp
#   ./bootstrap.sh --server         # server only
#   ./bootstrap.sh --client         # client only
#   ./bootstrap.sh --jar my.jar     # use your own a0.2.1.jar instead of downloading
#   ./bootstrap.sh --dest DIR       # choose the output directory
#
# What gets downloaded, and from where:
#   - Ooney's Alpha Patches workspace (github.com/lcdnet/ooneys-Alpha-Patches)
#   - the pristine a0.2.1 server jar (Betacraft's server archive), verified
#     against a pinned sha256 before anything uses it
#   - client libraries from Mojang's maven / Maven Central / Glass Launcher
#   - a Temurin JDK, ONLY if no javac 17+ is on your PATH
# We distribute no Minecraft code; your machine assembles everything locally.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="./alpha-smp"; DO_SERVER=1; DO_CLIENT=1; USER_JAR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --server) DO_CLIENT=0 ;;
    --client) DO_SERVER=0 ;;
    --jar) USER_JAR="$2"; shift ;;
    --dest) DEST="$2"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done
mkdir -p "$DEST"; DEST="$(cd "$DEST" && pwd)"

OONEY_ZIP_URL="https://github.com/lcdnet/ooneys-Alpha-Patches/archive/refs/heads/master.zip"
SERVER_JAR_URL="https://files.betacraft.uk/server-archive/alpha/a0.2.1.jar"
SERVER_JAR_SHA256="1981f4402b8ac01a1d6c2d900f28056ff2d6bc913594edb55187c32cc48d10d5"

for tool in curl unzip git; do
  command -v "$tool" > /dev/null || { echo "missing required tool: $tool" >&2; exit 1; }
done

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }

# ---- Java: use system javac 17+, else fetch a local Temurin JDK ------------
need_jdk=1
if command -v javac > /dev/null; then
  ver="$(javac -version 2>&1 | grep -oE '[0-9]+' | head -1)"
  [ "${ver:-0}" -ge 17 ] && need_jdk=0
fi
if [ "$need_jdk" = 1 ]; then
  if [ ! -x "$DEST/jdk/bin/javac" ]; then
    case "$(uname -s)" in Linux) os=linux ;; Darwin) os=mac ;; *) echo "no javac 17+ found; install a JDK and re-run" >&2; exit 1 ;; esac
    case "$(uname -m)" in aarch64|arm64) arch=aarch64 ;; *) arch=x64 ;; esac
    echo "[jdk] no javac 17+ found — fetching Temurin 21 ($os/$arch)"
    curl -fSL -o "$DEST/jdk.tar.gz" "https://api.adoptium.net/v3/binary/latest/21/ga/$os/$arch/jdk/hotspot/normal/eclipse"
    mkdir -p "$DEST/jdk"; tar -xzf "$DEST/jdk.tar.gz" -C "$DEST/jdk" --strip-components=1; rm -f "$DEST/jdk.tar.gz"
    [ "$os" = mac ] && [ -d "$DEST/jdk/Contents/Home" ] && mv "$DEST/jdk" "$DEST/jdk-bundle" && mv "$DEST/jdk-bundle/Contents/Home" "$DEST/jdk" && rm -rf "$DEST/jdk-bundle"
  fi
  export PATH="$DEST/jdk/bin:$PATH"; export JAVA_HOME="$DEST/jdk"
fi
echo "[java] using: $(command -v javac) ($(javac -version 2>&1))"

# ---- Ooney workspace (client baseline; also carries deobfuscated.jar) ------
if [ "$DO_CLIENT" = 1 ] && [ ! -d "$DEST/ooneys-Alpha-Patches-master/source" ]; then
  echo "[ooney] downloading workspace"
  curl -fSL -o "$DEST/ooney.zip" "$OONEY_ZIP_URL"
  unzip -o -q "$DEST/ooney.zip" -d "$DEST"; rm -f "$DEST/ooney.zip"
  [ -d "$DEST/ooneys-Alpha-Patches-master/source" ] || { echo "unexpected workspace layout — repo changed?" >&2; exit 1; }
fi

# ---- pristine server jar ---------------------------------------------------
if [ "$DO_SERVER" = 1 ]; then
  JAR="$DEST/a0.2.1.jar"
  if [ -n "$USER_JAR" ]; then cp "$USER_JAR" "$JAR"; fi
  if [ ! -f "$JAR" ]; then
    echo "[server-jar] downloading pristine a0.2.1.jar"
    curl -fSL -o "$JAR" "$SERVER_JAR_URL"
  fi
  got="$(sha256 "$JAR")"
  if [ "$got" != "$SERVER_JAR_SHA256" ]; then
    echo "server jar sha256 mismatch (got $got) — wrong or corrupted jar; refusing to continue" >&2
    exit 1
  fi
  echo "[server-jar] sha256 verified"
fi

# ---- build -----------------------------------------------------------------
[ "$DO_SERVER" = 1 ] && "$HERE/install-server.sh" "$DEST/a0.2.1.jar" "$DEST/server"
[ "$DO_CLIENT" = 1 ] && "$HERE/install-client.sh" "$DEST/ooneys-Alpha-Patches-master" "$DEST/client"

echo
echo "ALL DONE."
[ "$DO_SERVER" = 1 ] && echo "  server: $DEST/server/run-server.sh"
[ "$DO_CLIENT" = 1 ] && echo "  client: $DEST/client/run-client.sh YourName"
exit 0  # the && above is falsy when that side wasn't built; don't let it become the exit code
