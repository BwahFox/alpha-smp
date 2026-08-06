#!/usr/bin/env bash
# Build the alpha-SMP parity client on top of Ooney's Alpha Patches workspace
# (public; provides the deobfuscated a1.1.2_01 base this patch set targets).
# We distribute only patches and this tooling.
#   ./install-client.sh <path-to-ooneys-Alpha-Patches> <dest-dir>
# Requires: java (JDK 17+), git, curl, unzip.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OONEY="${1:?usage: install-client.sh <ooneys-repo> <dest>}"
DEST="${2:?usage: install-client.sh <ooneys-repo> <dest>}"
[ -d "$OONEY/source" ] || { echo "no source/ tree in $OONEY" >&2; exit 1; }
[ -f "$OONEY/jars/deobfuscated.jar" ] || { echo "no jars/deobfuscated.jar in $OONEY" >&2; exit 1; }
mkdir -p "$DEST"

echo "[1/4] applying patch set to a copy of the pristine source tree"
rm -rf "$DEST/src"; cp -r "$OONEY/source" "$DEST/src"
( cd "$DEST/src" && git apply -p2 "$HERE/patches/client.patch" )

echo "[2/4] fetching libraries"
"$HERE/fetch-client-libraries.sh" "$DEST"

echo "[3/4] compiling"
# deobfuscated.jar first on the classpath: the bundled Paul's Code CodecJOrbis
# declares protected fields where the standalone artifact has them private.
CP="$OONEY/jars/deobfuscated.jar:$(find "$DEST/libraries" -name '*.jar' | sort | tr '\n' ':')"
( cd "$DEST/src"
  find . -name '*.java' > /tmp/alpha-client-srcs.txt
  mkdir -p ../classes
  javac --release 8 -nowarn -cp "$CP" -d ../classes @/tmp/alpha-client-srcs.txt )

echo "[4/4] writing launcher"
mkdir -p "$DEST/game"
cat > "$DEST/run-client.sh" << EOF
#!/usr/bin/env bash
#   ./run-client.sh [username]
set -euo pipefail
HERE="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
CP="\$HERE/classes:$OONEY/jars/deobfuscated.jar:\$(find "\$HERE/libraries" -name '*.jar' | sort | tr '\n' ':')"
exec java -Xss512m \\
  -Djava.library.path="\$HERE/libraries/natives" \\
  -cp "\$CP" \\
  org.mcphackers.launchwrapper.Launch \\
  --username "\${1:-Player}" \\
  --session - --accessToken - \\
  --version a1.1.2_01 \\
  --gameDir "\$HERE/game" \\
  --assetsDir "\$HERE/game/assets" \\
  --assetIndex a1.0.14 \\
  --userProperties "{}" --userType legacy --versionType release
EOF
chmod +x "$DEST/run-client.sh"
echo "OK: run with $DEST/run-client.sh [username]"
echo "NOTE: protocol 100 — connects to alpha-SMP parity servers only."
