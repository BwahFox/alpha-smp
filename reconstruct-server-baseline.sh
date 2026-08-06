#!/usr/bin/env bash
# Reconstruct the deterministic server decompile baseline from a pristine
# a0.2.1.jar. Used BOTH by release generation (here) and by the end-user
# installer: same jar + same pinned decompilers => byte-identical baseline,
# which is what makes shipping source patches (and no Mojang code) possible.
#
#   ./reconstruct-server-baseline.sh <a0.2.1.jar> <outdir> <tools-dir>
#
# tools-dir must contain cfr.jar and vineflower.jar at the pinned versions
# (CFR 0.152, Vineflower — the exact jars this repo pins in tools/).
#
# Steps mirror server/BUILD.md "How the source tree was made":
#   - CFR decompile of everything
#   - Vineflower's version swapped in for aj.java, ea.java, z.java
#   - `do`/`if` renamed to BlockStairs/Path (Java keywords, illegal as source names)
#   - every default-package class moved to net/minecraft/src with a package line
# All OTHER fixes (throws restoration, enum repairs, references to the renamed
# classes, and every gameplay change) live in the patch set applied on top.
set -euo pipefail

JAR="$1"; OUT="$2"; TOOLS="$3"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

java -jar "$TOOLS/cfr.jar" "$JAR" --outputdir "$WORK/cfr" --silent true > /dev/null
java -jar "$TOOLS/vineflower.jar" --silent "$JAR" "$WORK/vf" > /dev/null 2>&1

for f in aj.java ea.java z.java; do
  cp "$WORK/vf/$f" "$WORK/cfr/$f"
done

rm -rf "$OUT"
mkdir -p "$OUT/net/minecraft/src" "$OUT/net/minecraft/server"
cp "$WORK/cfr/net/minecraft/server/MinecraftServer.java" "$OUT/net/minecraft/server/"

for f in "$WORK/cfr/"*.java; do
  base="$(basename "$f")"
  case "$base" in
    do.java) base=BlockStairs.java ;;
    if.java) base=Path.java ;;
  esac
  { printf 'package net.minecraft.src;\n\n'; cat "$f"; } > "$OUT/net/minecraft/src/$base"
done

echo "baseline: $(find "$OUT" -name '*.java' | wc -l) sources -> $OUT"
