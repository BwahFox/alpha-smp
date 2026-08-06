#!/usr/bin/env bash
# Build the Prism-/MultiMC-style JARMOD: a zip of class files overlaid onto a
# vanilla a1.1.2_01 minecraft.jar ("Add to Minecraft.jar" in Prism).
#
#   ./build-jarmod.sh <workdir> <output.zip>
#
# Pipeline (RetroMCP): fresh workspace -> setup a1.1.2_01 (downloads the
# pristine client jar + MCPHackers mappings) -> decompile -> pristine compile +
# updatemd5 under JDK 17 -> swap in client/src-vanilla -> recompile ->
# reobfuscate (only md5-changed classes get vanilla obfuscated names; our new
# classes keep readable names) -> zip.
#
# JDK 8 SPECIFICALLY (a local Temurin is fetched if the system java is not 8):
# RetroMCP compiles with its own runtime's compiler and ignores source/target
# config, so the tool must RUN on 8 to emit class-file version 52 — which
# Prism's legacy JRE 8 requires — and JDK 8 natively has java.applet.Applet
# and Thread.stop, which the vanilla decompile needs.
#
# NOTE ON DISTRIBUTION: the produced zip contains MODIFIED MOJANG-DERIVED
# CLASSES (community jarmod convention, same shape as Ooney's own release).
# The clean-room distribution channel remains the patch set + installers; the
# jarmod is the convenience form for launcher users.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${1:?usage: build-jarmod.sh <workdir> <output.zip> <source-tree>}"
OUT="${2:?usage: build-jarmod.sh <workdir> <output.zip> <source-tree>}"
# 3rd arg: the patched client source tree to build — the tree that
# install-client.sh produces (its workspace's source/ after patching), or any
# further-modified copy of it. NOTE: never stack separately-built jarmods in a
# launcher: they overwrite whole classes and overlap sets are semantically
# entangled (e.g. World.playRecord).
SRC="${3:?usage: build-jarmod.sh <workdir> <output.zip> <source-tree>  (source-tree = the patched client source from install-client.sh)}"
MCP_JAR="$HERE/tools/RetroMCP-Java-CLI.jar"
[ -f "$MCP_JAR" ] || { echo "missing $MCP_JAR — download RetroMCP-Java-CLI.jar from https://github.com/MCPHackers/RetroMCP-Java/releases into tools/"; exit 1; }
[ -d "$SRC" ] || { echo "source tree not found: $SRC"; exit 1; }
mkdir -p "$WORK"; WORK="$(cd "$WORK" && pwd)"

# ---- JDK 8 -----------------------------------------------------------------
JAVA8=""
if command -v java > /dev/null && java -version 2>&1 | grep -q '"1\.8\.'; then
  JAVA8="$(command -v java)"
elif [ -x "$WORK/jdk8/bin/java" ]; then
  JAVA8="$WORK/jdk8/bin/java"
else
  case "$(uname -m)" in aarch64|arm64) arch=aarch64 ;; *) arch=x64 ;; esac
  echo "[jdk8] fetching Temurin 8 ($arch)"
  curl -fSL -o "$WORK/jdk8.tar.gz" "https://api.adoptium.net/v3/binary/latest/8/ga/linux/$arch/jdk/hotspot/normal/eclipse"
  mkdir -p "$WORK/jdk8"; tar -xzf "$WORK/jdk8.tar.gz" -C "$WORK/jdk8" --strip-components=1; rm -f "$WORK/jdk8.tar.gz"
  JAVA8="$WORK/jdk8/bin/java"
fi
echo "[jdk8] $("$JAVA8" -version 2>&1 | head -1)"

# ---- MCP workspace ---------------------------------------------------------
MCP="$WORK/mcp"
if [ ! -d "$MCP/minecraft/src_original" ]; then
  rm -rf "$MCP"; mkdir -p "$MCP"; cd "$MCP"
  "$JAVA8" -jar "$MCP_JAR" setup a1.1.2_01
  sed -i 's/^side=.*/side=CLIENT/' options.cfg
  "$JAVA8" -jar "$MCP_JAR" decompile
fi
cd "$MCP"
echo "[baseline] pristine compile + updatemd5"
rm -rf minecraft/src; cp -r minecraft/src_original minecraft/src
"$JAVA8" -jar "$MCP_JAR" recompile > /dev/null
"$JAVA8" -jar "$MCP_JAR" updatemd5 > /dev/null

echo "[ours] recompile + reobfuscate"
rm -rf minecraft/src; cp -r "$SRC" minecraft/src
"$JAVA8" -jar "$MCP_JAR" recompile > /dev/null
"$JAVA8" -jar "$MCP_JAR" reobfuscate > /dev/null

n="$(ls minecraft/reobf | wc -l)"
rm -f "$OUT"
( cd minecraft/reobf && zip -q -r "$OUT" . )
# Non-code resource dirs shipped inside the source tree (e.g. Oonic's cape/
# and title/) ride along into the jar root.
for d in cape title; do
  [ -d "$SRC/$d" ] && ( cd "$SRC" && zip -q -r "$OUT" "$d" )
done
echo "jarmod: $OUT ($n classes, $(du -h "$OUT" | cut -f1))"
