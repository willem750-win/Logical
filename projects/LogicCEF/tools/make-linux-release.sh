#!/bin/sh
# ---------------------------------------------------------------------------
# Maakt de Linux-release van Logic: Logic-<versie>-linux-<arch>.tar.gz
#
# Uitvoeren ONDER LINUX vanuit de repository:
#
#     sh projects/LogicCEF/tools/make-linux-release.sh                 (versie 1.2.0)
#     sh projects/LogicCEF/tools/make-linux-release.sh 1.2.0           (eigen versie)
#     sh projects/LogicCEF/tools/make-linux-release.sh 1.2.0 --no-build
#     sh projects/LogicCEF/tools/make-linux-release.sh 1.2.0 --upload  (ook naar GitHub)
#
# Bouwen: met lazbuild uit PATH of uit $LAZBUILD. Zonder lazbuild (of met
# --no-build) wordt het programma gebruikt dat al in Resultaat/ staat.
#
# Gegevens: panels, ini en html komen uit Git (de laatste commit, HEAD), niet
# uit Resultaat. Niet-gecommitte wijzigingen en testpanelen gaan dus niet mee;
# het script waarschuwt als er zulke wijzigingen zijn.
#
# Help: altijd vers, in een lege map. Met pwsh opgebouwd uit helpsrc, anders
# uit de Windows-zip van dezelfde release op GitHub. Alleen als dat allebei
# niet lukt, wordt Resultaat/help gebruikt (met een waarschuwing).
#
# Onder Linux gebruikt Logic geen CEF (de help opent in de standaardbrowser),
# dus de CEF-runtime hoort niet in het pakket.
#
# Resultaat in projects/LogicCEF/release/:
#   Logic-<versie>-linux-<arch>.tar.gz   uitpakken en ./logicCEF starten
#   logical_<versie>_<arch>.deb          als dpkg-deb aanwezig is
#
# Installeren:  sudo apt install ./logical_<versie>_<arch>.deb
# Verwijderen:  sudo apt remove logical
#
# Waarom een startscript in de .deb?
# Logic schrijft naast zijn eigen programmabestand (taal.ini, ini/, panels/).
# In /opt mag een gewone gebruiker niet schrijven. Het startscript kopieert
# het programma daarom per gebruiker naar ~/.local/share/logical en start
# het vandaar. Instellingen en eigen panelen blijven bij een update behouden;
# programma, help en html worden vervangen.
# ---------------------------------------------------------------------------
set -e

VERSION=1.2.0
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

# projects/LogicCEF; dit script staat in projects/LogicCEF/tools
PROJ=$(cd "$(dirname "$0")" && cd .. && pwd)
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
# Pakket samenstellen
# ------------------------------------------------------------------
STAGE=$(mktemp -d)
DST="$STAGE/$NAME"
mkdir -p "$DST"

cp "$SRC/logicCEF" "$DST/"
strip "$DST/logicCEF" 2>/dev/null || true
chmod 755 "$DST/logicCEF"
# Vaste taal.ini: nieuwe gebruikers starten in het Nederlands, los van de
# taal die je zelf laatst koos (bestaande installaties houden hun keuze).
printf '[Settings]\nLanguage=0\n' > "$DST/taal.ini"

# ------------------------------------------------------------------
# panels, ini en html uit Git (HEAD)
# ------------------------------------------------------------------
DATA="projects/LogicCEF/Resultaat/panels projects/LogicCEF/Resultaat/ini projects/LogicCEF/Resultaat/html"
if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  DIRTY=$(git -C "$REPO" status --porcelain -- $DATA)
  if [ -n "$DIRTY" ]; then
    echo "LET OP: deze niet-gecommitte wijzigingen gaan NIET mee in de release:"
    echo "$DIRTY"
  fi
  GITTMP=$(mktemp -d)
  # shellcheck disable=SC2086
  git -C "$REPO" archive HEAD -- $DATA | tar -x -C "$GITTMP"
  for D in panels ini html; do
    cp -r "$GITTMP/projects/LogicCEF/Resultaat/$D" "$DST/$D"
  done
  rm -rf "$GITTMP"
else
  echo "LET OP: $REPO is geen Git-repository; panels, ini en html komen uit Resultaat zoals ze zijn."
  for D in panels ini html; do
    cp -r "$SRC/$D" "$DST/$D"
  done
fi
rm -f "$DST/ini/comboColor.ini"

# ------------------------------------------------------------------
# Help: altijd vers, in een lege map
# ------------------------------------------------------------------
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$PROJ/helpsrc/make-help.ps1" -Out "$DST/help"
else
  echo "pwsh niet gevonden; ik haal de help uit de Windows-zip van v$VERSION."
  TMPZIP=$(mktemp)
  HELPTMP=$(mktemp -d)
  if curl -fsSL -o "$TMPZIP" \
      "https://github.com/willem750-win/Logical/releases/download/v$VERSION/Logic-$VERSION-win64.zip"; then
    # De help-bestanden eerst opsommen en dan precies die uitpakken:
    # 'help/*' als patroon pakt bij sommige unzip-versies de submappen niet
    # mee. Waarschuwingen zijn niet fataal: hieronder wordt gecontroleerd of
    # de help er echt is.
    # shellcheck disable=SC2046
    unzip -q -o "$TMPZIP" $(unzip -Z1 "$TMPZIP" | grep '^help/[^/]') -d "$HELPTMP" || true
  fi
  if [ -f "$HELPTMP/help/index.html" ]; then
    cp -r "$HELPTMP/help" "$DST/help"
  elif [ -f "$SRC/help/index.html" ]; then
    echo "LET OP: help niet te downloaden; ik gebruik Resultaat/help. Controleer of die actueel is"
    echo "        (geen oude bestanden), of installeer pwsh."
    cp -r "$SRC/help" "$DST/help"
  else
    echo "Geen help gevonden: installeer pwsh of zet eerst de Windows-release v$VERSION op GitHub." >&2
    exit 1
  fi
  rm -rf "$TMPZIP" "$HELPTMP"
fi
find "$DST" \( -name '*.bak' -o -name '*.log' \) -exec rm -f {} +
cp "$REPO/LICENSE" "$REPO/README.md" "$DST/"

mkdir -p "$OUT"
TAR="$OUT/$NAME.tar.gz"
tar -czf "$TAR" -C "$STAGE" "$NAME"
echo "Klaar: $TAR ($(du -h "$TAR" | cut -f1))"
FILES="$TAR"

# ------------------------------------------------------------------
# Debian-pakket
# ------------------------------------------------------------------
if command -v dpkg-deb >/dev/null 2>&1; then
  PKG=logical
  DARCH=$(dpkg --print-architecture)
  DEB="$OUT/${PKG}_${VERSION}_${DARCH}.deb"
  ROOT="$STAGE/deb"
  mkdir -p "$ROOT/DEBIAN" "$ROOT/opt" "$ROOT/usr/bin" \
           "$ROOT/usr/share/applications" \
           "$ROOT/usr/share/icons/hicolor/48x48/apps" "$ROOT/usr/share/pixmaps"

  # Programmabestanden: dezelfde inhoud als de tar.gz
  cp -r "$DST" "$ROOT/opt/$PKG"
  echo "$VERSION" > "$ROOT/opt/$PKG/VERSION"

  # Startscript
  cat > "$ROOT/usr/bin/$PKG" <<EOF
#!/bin/sh
SRC=/opt/$PKG
DST="\${XDG_DATA_HOME:-\$HOME/.local/share}/$PKG"

if [ "\$(cat "\$DST/VERSION" 2>/dev/null)" != "\$(cat "\$SRC/VERSION")" ]; then
  mkdir -p "\$DST"
  # Programma, help, html en licentie altijd vernieuwen
  cp -f "\$SRC/logicCEF" "\$SRC/LICENSE" "\$SRC/README.md" "\$DST/"
  rm -rf "\$DST/help" "\$DST/html"
  cp -r "\$SRC/help" "\$SRC/html" "\$DST/"
  # Instellingen en panelen: alleen wat nog ontbreekt (eigen werk blijft)
  [ -f "\$DST/taal.ini" ] || [ ! -f "\$SRC/taal.ini" ] || cp "\$SRC/taal.ini" "\$DST/"
  for D in ini panels; do
    mkdir -p "\$DST/\$D"
    cp -rn "\$SRC/\$D/." "\$DST/\$D/"
  done
  cp -f "\$SRC/VERSION" "\$DST/VERSION"
fi

cd "\$DST"
exec "\$DST/logicCEF" "\$@"
EOF

  # Menu-item en pictogram
  cp "$PROJ/logic.png" "$ROOT/usr/share/icons/hicolor/48x48/apps/$PKG.png"
  cp "$PROJ/logic.png" "$ROOT/usr/share/pixmaps/$PKG.png"
  cat > "$ROOT/usr/share/applications/$PKG.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Logic
Comment=Simulator voor digitale schakelingen
Comment[en]=Digital circuit simulator
Comment[fr]=Simulateur de circuits numériques
Comment[de]=Simulator für digitale Schaltungen
Exec=$PKG
Icon=$PKG
Terminal=false
Categories=Education;Electronics;
EOF

  SIZE=$(du -sk "$ROOT" | cut -f1)
  cat > "$ROOT/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: education
Priority: optional
Architecture: $DARCH
Depends: libc6, libgtk2.0-0, xdg-utils
Installed-Size: $SIZE
Maintainer: Willy Jansen <willyjansen@telenet.be>
Homepage: https://github.com/willem750-win/Logical
Description: Simulator voor digitale schakelingen
 Logic is een Lazarus-programma om schakelingen met schakelaars,
 sensoren, logische poorten, tellers, geheugens, lampen en displays
 op te bouwen en te simuleren. Nederlands, Engels, Frans en Duits.
EOF

  # Na installeren/verwijderen de menu- en pictogramcache vernieuwen
  for SCRIPT in postinst postrm; do
    cat > "$ROOT/DEBIAN/$SCRIPT" <<'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi
exit 0
EOF
  done

  # Rechten zoals dpkg ze verwacht
  find "$ROOT" -type d -exec chmod 755 {} +
  find "$ROOT" -type f -exec chmod 644 {} +
  chmod 755 "$ROOT/usr/bin/$PKG" "$ROOT/opt/$PKG/logicCEF" \
            "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/postrm"

  dpkg-deb --root-owner-group --build "$ROOT" "$DEB"
  echo "Klaar: $DEB ($(du -h "$DEB" | cut -f1))"
  echo "Installeren met: sudo apt install \"$DEB\""
  FILES="$FILES $DEB"
else
  echo "dpkg-deb niet gevonden: geen .deb gemaakt."
fi
rm -rf "$STAGE"

# ------------------------------------------------------------------
# Optioneel: toevoegen aan de GitHub-release
# ------------------------------------------------------------------
if [ "$UPLOAD" = 1 ]; then
  # shellcheck disable=SC2086
  gh release upload "v$VERSION" $FILES --clobber --repo willem750-win/Logical
  echo "Toegevoegd aan release v$VERSION."
fi
