#!/bin/sh
# ---------------------------------------------------------------------------
# Maakt de Linux-release van Logic: Logic-<versie>-linux-<arch>.tar.gz
#
# Uitvoeren ONDER LINUX vanuit de repository:
#
#     sh projects/LogicCEF/make-linux-release.sh                 (versie 1.0.0)
#     sh projects/LogicCEF/make-linux-release.sh 1.0.1           (eigen versie)
#     sh projects/LogicCEF/make-linux-release.sh 1.0.1 --no-build
#     sh projects/LogicCEF/make-linux-release.sh 1.0.1 --upload  (ook naar GitHub)
#
# Bouwen: met lazbuild uit PATH of uit $LAZBUILD. Zonder lazbuild (of met
# --no-build) wordt het programma gebruikt dat al in Resultaat/ staat.
#
# Help: met pwsh wordt ze opnieuw opgebouwd uit helpsrc. Zonder pwsh wordt
# Resultaat/help gebruikt, of als die ontbreekt de help uit de Windows-zip
# van dezelfde release op GitHub.
#
# Onder Linux gebruikt Logic geen CEF (de help opent in de standaardbrowser),
# dus de CEF-runtime hoort niet in het pakket.
#
# Resultaat: projects/LogicCEF/release/Logic-<versie>-linux-<arch>.tar.gz
# ---------------------------------------------------------------------------
set -e

VERSION=1.0.0
BUILD=1
UPLOAD=0
for A in "$@"; do
  case "$A" in
    --no-build) BUILD=0 ;;
    --upload)   UPLOAD=1 ;;
    -*)         echo "Onbekende optie: $A" >&2; exit 1 ;;
    *)          VERSION="$A" ;;
  esac
done

PROJ=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$PROJ/../.." && pwd)
SRC="$PROJ/Resultaat"
ARCH=$(uname -m)
NAME="Logic-$VERSION-linux-$ARCH"
OUT="$PROJ/release"

# ------------------------------------------------------------------
# Bouwen
# ------------------------------------------------------------------
LB="${LAZBUILD:-$(command -v lazbuild || true)}"
if [ "$BUILD" = 1 ] && [ -n "$LB" ]; then
  "$LB" --build-mode=Default "$PROJ/logic.lpi"
elif [ "$BUILD" = 1 ]; then
  echo "lazbuild niet gevonden (zet LAZBUILD=/pad/naar/lazbuild); ik gebruik Resultaat/logicCEF."
fi
if [ ! -x "$SRC/logicCEF" ]; then
  echo "Bouw eerst het programma: '$SRC/logicCEF' ontbreekt." >&2
  exit 1
fi

# ------------------------------------------------------------------
# Help
# ------------------------------------------------------------------
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$PROJ/helpsrc/make-help.ps1"
elif [ -f "$SRC/help/index.html" ]; then
  echo "pwsh niet gevonden; ik gebruik de bestaande help in Resultaat/help."
else
  echo "pwsh niet gevonden; ik haal de help uit de Windows-zip van v$VERSION."
  TMPZIP=$(mktemp)
  curl -fL -o "$TMPZIP" \
    "https://github.com/willem750-win/Logical/releases/download/v$VERSION/Logic-$VERSION-win64.zip"
  unzip -q -o "$TMPZIP" 'help/*' -d "$SRC"
  rm -f "$TMPZIP"
fi

# ------------------------------------------------------------------
# Pakket samenstellen
# ------------------------------------------------------------------
STAGE=$(mktemp -d)
DST="$STAGE/$NAME"
mkdir -p "$DST"

cp "$SRC/logicCEF" "$DST/"
strip "$DST/logicCEF" 2>/dev/null || true
chmod 755 "$DST/logicCEF"
[ -f "$SRC/taal.ini" ] && cp "$SRC/taal.ini" "$DST/"
for D in help html panels ini; do
  cp -r "$SRC/$D" "$DST/$D"
done
rm -f "$DST/ini/comboColor.ini"
find "$DST" \( -name '*.bak' -o -name '*.log' \) -exec rm -f {} +
cp "$REPO/LICENSE" "$REPO/README.md" "$DST/"

mkdir -p "$OUT"
TAR="$OUT/$NAME.tar.gz"
tar -czf "$TAR" -C "$STAGE" "$NAME"
rm -rf "$STAGE"
echo "Klaar: $TAR ($(du -h "$TAR" | cut -f1))"

# ------------------------------------------------------------------
# Optioneel: toevoegen aan de GitHub-release
# ------------------------------------------------------------------
if [ "$UPLOAD" = 1 ]; then
  gh release upload "v$VERSION" "$TAR" --clobber --repo willem750-win/Logical
  echo "Toegevoegd aan release v$VERSION."
fi
