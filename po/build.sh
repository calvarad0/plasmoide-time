#!/bin/sh
# Compiles every po/<lang>.po into the package's contents/locale tree,
# where Plasma looks up the applet's translations.
# Requires msgfmt (gettext). Run from anywhere.
set -eu

DOMAIN="plasma_applet_org.plasma.citytimeweather"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for po in "$ROOT"/po/*.po; do
    lang="$(basename "$po" .po)"
    out="$ROOT/contents/locale/$lang/LC_MESSAGES"
    mkdir -p "$out"
    msgfmt --check -o "$out/$DOMAIN.mo" "$po"
    echo "built $lang"
done
