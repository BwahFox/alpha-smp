#!/usr/bin/env bash
# Download the client's third-party libraries (all open-source / Mojang-hosted;
# none are Minecraft game code) into <dest>/libraries, plus LWJGL+jinput natives
# for the current OS into <dest>/libraries/natives.
#   ./fetch-client-libraries.sh <dest>
set -euo pipefail

DEST="${1:?usage: fetch-client-libraries.sh <dest>}/libraries"
MOJANG="https://libraries.minecraft.net"
CENTRAL="https://repo1.maven.org/maven2"
GLASS="https://maven.glass-launcher.net/releases"

fetch() { # fetch <base> <maven-path>
  local out="$DEST/$2"
  [ -f "$out" ] && return 0
  mkdir -p "$(dirname "$out")"
  echo "  $2"
  curl -fsSL -o "$out" "$1/$2"
}

echo "libraries -> $DEST"
fetch $MOJANG com/paulscode/codecjorbis/20101023/codecjorbis-20101023.jar
fetch $MOJANG com/paulscode/codecwav/20101023/codecwav-20101023.jar
fetch $MOJANG com/paulscode/libraryjavasound/20101123/libraryjavasound-20101123.jar
fetch $MOJANG com/paulscode/librarylwjglopenal/20100824/librarylwjglopenal-20100824.jar
fetch $MOJANG com/paulscode/soundsystem/20120107/soundsystem-20120107.jar
fetch $MOJANG net/java/jinput/jinput/2.0.5/jinput-2.0.5.jar
fetch $MOJANG net/java/jutils/jutils/1.0.0/jutils-1.0.0.jar
fetch $MOJANG org/lwjgl/lwjgl/lwjgl/2.9.4-nightly-20150209/lwjgl-2.9.4-nightly-20150209.jar
fetch $MOJANG org/lwjgl/lwjgl/lwjgl_util/2.9.4-nightly-20150209/lwjgl_util-2.9.4-nightly-20150209.jar
fetch $MOJANG org/lwjgl/lwjgl/lwjgl-platform/2.9.4-nightly-20150209/lwjgl-platform-2.9.4-nightly-20150209.jar
fetch $CENTRAL org/json/json/20230227/json-20230227.jar
fetch $CENTRAL org/ow2/asm/asm/9.9/asm-9.9.jar
fetch $CENTRAL org/ow2/asm/asm-commons/9.9/asm-commons-9.9.jar
fetch $CENTRAL org/ow2/asm/asm-tree/9.9/asm-tree-9.9.jar
fetch $GLASS org/mcphackers/launchwrapper/1.2/launchwrapper-1.2.jar

case "$(uname -s)" in
  Linux)  NAT=natives-linux ;;
  Darwin) NAT=natives-osx ;;
  *)      NAT=natives-windows ;;
esac
echo "natives ($NAT) -> $DEST/natives"
mkdir -p "$DEST/natives"
for coord in \
  org/lwjgl/lwjgl/lwjgl-platform/2.9.4-nightly-20150209/lwjgl-platform-2.9.4-nightly-20150209-$NAT.jar \
  net/java/jinput/jinput-platform/2.0.5/jinput-platform-2.0.5-$NAT.jar; do
  tmp="$(mktemp)"
  curl -fsSL -o "$tmp" "$MOJANG/$coord"
  unzip -o -q "$tmp" -d "$DEST/natives" -x "META-INF/*"
  rm -f "$tmp"
done
echo "done"
