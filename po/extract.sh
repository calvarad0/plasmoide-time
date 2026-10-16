#!/bin/sh
# Extracts translatable strings into po/template.pot and merges them into
# every po/<lang>.po. Requires xgettext and msgmerge (gettext).
set -eu

DOMAIN="plasma_applet_org.plasma.citytimeweather"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

xgettext --from-code=UTF-8 --language=JavaScript \
    --keyword=i18n --keyword=I18N_NOOP \
    --package-name="$DOMAIN" \
    -o po/template.pot \
    contents/config/*.qml contents/ui/*.qml contents/ui/js/*.js

for po in po/*.po; do
    msgmerge --update --backup=none "$po" po/template.pot
done
