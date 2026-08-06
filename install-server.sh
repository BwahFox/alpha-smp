#!/usr/bin/env bash
# Build the alpha-SMP parity server from YOUR OWN pristine a0.2.1 server jar.
# No Minecraft code is distributed: your jar is decompiled locally with the
# pinned decompilers, our patch set is applied, and the result is compiled.
#   ./install-server.sh <path-to-a0.2.1.jar> <dest-dir>
# Requires: java (JDK 17+, for javac/jar), git (for git apply).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR="${1:?usage: install-server.sh <a0.2.1.jar> <dest>}"
DEST="${2:?usage: install-server.sh <a0.2.1.jar> <dest>}"
mkdir -p "$DEST"

echo "[1/4] reconstructing decompile baseline (deterministic; ~a minute)"
"$HERE/reconstruct-server-baseline.sh" "$JAR" "$DEST/baseline" "$HERE/tools"

echo "[2/4] applying patch set"
rm -rf "$DEST/src"; cp -r "$DEST/baseline" "$DEST/src"
( cd "$DEST/src" && git apply -p2 "$HERE/patches/server.patch" )

echo "[3/4] compiling"
( cd "$DEST/src"
  find . -name '*.java' > /tmp/alpha-server-srcs.txt
  mkdir -p ../classes
  javac --release 8 -nowarn -d ../classes @/tmp/alpha-server-srcs.txt )

echo "[4/4] packaging"
printf 'Manifest-Version: 1.0\nMain-Class: net.minecraft.server.MinecraftServer\n' > /tmp/alpha-server-manifest.txt
jar cfm "$DEST/minecraft_server_alpha-smp.jar" /tmp/alpha-server-manifest.txt -C "$DEST/classes" .

cat > "$DEST/run-server.sh" << 'EOF'
#!/usr/bin/env bash
# -Xss512m matters: Far Lands light propagation recurses past the default stack.
cd "$(dirname "$0")"
exec java -Xmx2G -Xms512M -Xss512m -jar minecraft_server_alpha-smp.jar nogui
EOF
chmod +x "$DEST/run-server.sh"
echo "OK: $DEST/minecraft_server_alpha-smp.jar  (start with ./run-server.sh)"
echo "NOTE: this server speaks protocol 100 (matched client required)."
echo "NOTE: spawn-protection default is 16 in server.properties, like vanilla."
