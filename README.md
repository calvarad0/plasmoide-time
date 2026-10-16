# City Weather & Time

A Plasma 6 applet that shows the **current weather and the local wall-clock
time of any city**, using the free [Open-Meteo](https://open-meteo.com) public
APIs (no API key needed).

- City time is shown in the city's own timezone, using the UTC offset that
  Open-Meteo reports for it (daylight-saving changes are picked up on the next
  weather refresh).
- Current conditions on refresh: temperature, feels-like, humidity, wind speed,
  weather condition and icon.
- Compact panel form (time, date, icon, temperature), full popup with details,
  and tooltip. Every element can be turned off in the settings.
- Nothing leaves your machine except the two Open-Meteo requests.

## Requirements

- KDE Plasma 6 (the metadata requires `X-Plasma-API-Minimum-Version: 6.0`).
- Internet access to `api.open-meteo.com` and `geocoding-api.open-meteo.com`.
- `kpackagetool6` (provided by the `kpackage` package).

## Quick start

Install the widget (run from this directory — the repository root IS the
package):

```sh
kpackagetool6 --type Plasma/Applet --install .
```

Then right-click the desktop (or a panel) → **Add Widgets** → search for
**City Weather & Time** → click to add.

Configure: right-click the widget → **Configure…** and set the city name.

Update after a change:

```sh
kpackagetool6 --type Plasma/Applet --upgrade .
```

Remove:

```sh
kpackagetool6 --type Plasma/Applet --remove org.plasma.citytimeweather
```

## Configuration

| Setting            | Key             | Default        | Notes                                  |
| ------------------ | --------------- | -------------- | -------------------------------------- |
| City name          | `city`          | `Buenos Aires` | Free text; resolved via geocoding      |
| Temperature units  | `units`         | `c`            | `c` = Celsius, `f` = Fahrenheit        |
| Time format        | `timeFormat`    | `24`           | `24` = 24-hour, `12` = 12-hour         |
| Refresh interval   | `refreshMinutes`| `15`           | Weather only; 5–120 minutes            |
| Show time          | `showTime` | `true` | Panel |
| Show date          | `showDate` | `true` | Panel; shown under the time |
| Show weather icon  | `showWeatherIcon` | `true` | Panel |
| Show temperature   | `showTemperature` | `true` | Panel |
| Show condition     | `showCondition` | `true` | Popup |
| Show feels like    | `showFeelsLike` | `true` | Popup |
| Show humidity      | `showHumidity` | `true` | Popup |
| Show wind          | `showWind` | `true` | Popup |
| Show last updated  | `showUpdated` | `true` | Popup |
| Show tooltip       | `showTooltip` | `true` | Tooltip on hover |

The temperature unit also drives the wind speed unit (km/h vs mph). The time
format affects the compact view, the popup header and the tooltip.

## How it works

1. On startup and whenever the city changes: geocode the city name via
   `geocoding-api.open-meteo.com` → coordinates + IANA timezone.
2. Fetch `current` weather for those coordinates via `api.open-meteo.com`
   (temperature, apparent temperature, humidity, wind speed, WMO weather code).
3. The wall clock adds the forecast's `utc_offset_seconds` to the current UTC
   time. Until the first successful fetch it shows the system time. No KDE
   clock module is required, so it works on every Plasma 6 release.
4. A timer re-fetches the weather every `refreshMinutes`, pausing while a
   request is already in flight.

## Layout

```
metadata.json              Package metadata (KPlugin block + Plasma keys)
contents/config/config.qml Configuration dialog: category list
contents/config/main.xml   KConfigXT schema (defaults, ranges, choices)
contents/ui/main.qml       Applet UI: PlasmoidItem root, compact/full views
contents/ui/js/weather.js  Logic: Open-Meteo requests + WMO code mapping
contents/ui/configGeneral.qml  Configuration page (general settings)
```

## Credits & license

- Weather data: [Open-Meteo](https://open-meteo.com) (CC-BY 4.0).
- This widget: GPL-2.0-or-later, © Carlos.

## Known caveats

- **First-run verification** — the following points could not be verified from
  docs alone and are marked `// TODO verify on target` in the code:
  - At least one of `Plasmoid.internalAction("configure")` /
    `Plasmoid.action("configure")` / `Plasmoid.showConfigurationInterface()`
    opens the configuration dialog.
  - The `configurationRequired` flag draws the stock Configure button.
- Weather condition labels are English by default.
- Requires Plasma 6; the widget will not appear in the Plasma 5 widget list.