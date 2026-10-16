/*
 * City Weather & Time - Plasma 6 applet
 * Shows the current weather and the local wall-clock time of a configurable city.
 *
 * Data sources (public, no API key required):
 *   - Open-Meteo Geocoding: https://geocoding-api.open-meteo.com/v1/search
 *   - Open-Meteo Forecast : https://api.open-meteo.com/v1/forecast
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import "js/weather.js" as Weather

PlasmoidItem {
    id: root

    // ----- configuration (live bindings; defaults come from contents/config/main.xml) -----
    readonly property string cfgCity: Plasmoid.configuration ? (Plasmoid.configuration.city || "") : ""
    readonly property int cfgRefreshMinutes: Plasmoid.configuration ? Plasmoid.configuration.refreshMinutes : 15
    readonly property bool useFahrenheit: Plasmoid.configuration ? (Plasmoid.configuration.units === "f") : false
    readonly property bool use12h: Plasmoid.configuration ? (Plasmoid.configuration.timeFormat === "12") : false

    // visibility toggles; a missing value (old config) counts as enabled
    function cfgFlag(name) {
        return !Plasmoid.configuration || Plasmoid.configuration[name] !== false
    }
    readonly property bool showTime: cfgFlag("showTime")
    readonly property bool showDate: cfgFlag("showDate")
    readonly property bool showWeatherIcon: cfgFlag("showWeatherIcon")
    readonly property bool showTemperature: cfgFlag("showTemperature")
    readonly property bool showCondition: cfgFlag("showCondition")
    readonly property bool showFeelsLike: cfgFlag("showFeelsLike")
    readonly property bool showHumidity: cfgFlag("showHumidity")
    readonly property bool showWind: cfgFlag("showWind")
    readonly property bool showUpdated: cfgFlag("showUpdated")
    readonly property bool showTooltip: cfgFlag("showTooltip")

    // ----- resolved city state (filled by the geocoding request) -----
    property string resolvedName: ""     // localized city name, e.g. "Buenos Aires"
    property string resolvedCountry: ""  // e.g. "Argentina"
    property string cityTimezone: ""     // IANA id; "" means "use the system timezone"
    property real cityLat: 0
    property real cityLon: 0

    // ----- weather state -----
    property int fetchState: 0           // 0 = idle, 1 = loading, 2 = ok, 3 = error
    property string lastErrorCode: ""    // machine-readable; translated in translateError()
    property int weatherCode: -1         // WMO weather interpretation code
    property real tempC: 0               // temperature, always stored in Celsius
    property real feelsC: 0              // apparent temperature, always stored in Celsius
    property int humidity: -1            // relative humidity in %
    property real windKmh: 0             // 10 m wind speed, always stored in km/h
    property string lastUpdated: ""      // wall-clock time of the last successful refresh

    // ----- wall clock of the city -----
    // The city's UTC offset comes from the forecast response (utc_offset_seconds),
    // so no KDE clock module is needed. It is refreshed with the weather, which
    // keeps daylight-saving changes in sync within one refresh interval.
    property int cityUtcOffset: 0        // seconds east of UTC
    property bool hasCityOffset: false   // false -> show the system time
    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    // A Date whose *local* fields equal the city's wall-clock time, for Qt.formatTime().
    readonly property date cityDateTime: root.hasCityOffset
        ? new Date(root.now.getTime() + root.now.getTimezoneOffset() * 60000 + root.cityUtcOffset * 1000)
        : root.now

    // ----- presentation -----
    preferredRepresentation: compactRepresentation
    Plasmoid.icon: "weather-none-ambivalent"
    Plasmoid.configurationRequired: root.cfgCity === ""

    // empty texts hide the tooltip
    toolTipMainText: root.showTooltip ? root.toolTipTitle : ""
    toolTipSubText: root.showTooltip ? root.toolTipBody : ""

    readonly property string cityDisplayName: root.resolvedName !== "" ? root.resolvedName : root.cfgCity
    readonly property string cityHeader: root.resolvedCountry !== ""
        ? root.cityDisplayName + ", " + root.resolvedCountry
        : root.cityDisplayName

    // wall-clock time of the current city, formatted per the configured format
    readonly property string timeText: Qt.formatTime(root.cityDateTime, root.use12h ? "h:mm AP" : "hh:mm")

    // date of the current city, short and localized, e.g. "Fri 16 Oct"
    readonly property string dateText: root.cityDateTime.toLocaleDateString(Qt.locale(), "ddd d MMM")

    // temperature in the configured units
    readonly property string tempText: root.fetchState === 2
        ? (Math.round(root.useFahrenheit ? root.tempC * 9 / 5 + 32 : root.tempC) + "\u00B0")
        : "---"

    // wind speed in the configured units
    readonly property string windText: root.fetchState === 2
        ? (Math.round(root.useFahrenheit ? root.windKmh * 0.621371 : root.windKmh)
           + (root.useFahrenheit ? " mph" : " km/h"))
        : "---"

    readonly property string feelsText: root.fetchState === 2
        ? (Math.round(root.useFahrenheit ? root.feelsC * 9 / 5 + 32 : root.feelsC) + "\u00B0")
        : "---"

    readonly property string conditionText: root.weatherCode >= 0 ? Weather.conditionLabel(root.weatherCode) : ""
    readonly property string weatherIcon: root.weatherCode >= 0 ? Weather.conditionIcon(root.weatherCode) : "weather-none-ambivalent"

    readonly property string toolTipTitle: root.cfgCity === "" ? "" : root.cityHeader + " \u00B7 " + root.timeText
    readonly property string toolTipBody: root.cfgCity === "" ? "" : root.fetchState === 2
        ? (root.tempText + " " + root.conditionText + " \u00B7 " + i18n("updated %1", root.lastUpdated))
        : (root.fetchState === 3 ? i18n("Weather unavailable") : i18n("Loading\u2026"))

    // ----- compact representation: time + temperature, fits a panel ----------
    compactRepresentation: RowLayout {
        id: compactItem
        Layout.fillHeight: true
        spacing: Kirigami.Units.smallSpacing * 2

        readonly property bool showWeatherIconNow: root.showWeatherIcon && root.fetchState === 2
        readonly property bool nothingShown: !root.showTime && !root.showDate
            && !compactItem.showWeatherIconNow && !root.showTemperature

        // time with the date under it
        ColumnLayout {
            visible: root.showTime || root.showDate
            spacing: 0

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.showTime
                text: root.timeText
                font: Kirigami.Theme.defaultFont
            }

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.showDate
                text: root.dateText
                font: Kirigami.Theme.smallFont
            }
        }

        Kirigami.Icon {
            source: root.weatherIcon
            Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.small)
            Layout.preferredHeight: Math.round(Kirigami.Units.iconSizes.small)
            visible: compactItem.showWeatherIconNow
        }

        PlasmaComponents3.Label {
            text: root.tempText
            verticalAlignment: Text.AlignVCenter
            visible: root.showTemperature
        }

        // fallback so the widget stays clickable when every item is disabled
        Kirigami.Icon {
            source: Plasmoid.icon
            Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.small)
            Layout.preferredHeight: Math.round(Kirigami.Units.iconSizes.small)
            visible: compactItem.nothingShown
        }
    }

    // ----- full representation: the popup shown when clicking the widget ----
    fullRepresentation: ColumnLayout {
        id: fullItem
        spacing: Kirigami.Units.largeSpacing
        Layout.minimumWidth: 260
        Layout.minimumHeight: 220

        // header: city + time
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                elide: Text.ElideRight
                text: root.cityHeader
            }

            ColumnLayout {
                spacing: 0

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignRight
                    text: root.timeText
                }

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignRight
                    text: root.dateText
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }
            }

            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                Accessible.name: i18n("Refresh weather")
                onClicked: root.refreshAll()
            }
        }

        // placeholder when no city is configured
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.cfgCity === ""
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: i18n("Enter a city in settings.")
            }

            PlasmaComponents3.Button {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Configure\u2026")
                onClicked: root.openConfiguration()
            }
        }

        // main weather block
        RowLayout {
            Layout.fillWidth: true
            visible: root.cfgCity !== ""
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: root.weatherIcon
                Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.large)
                Layout.preferredHeight: Math.round(Kirigami.Units.iconSizes.large)
                visible: root.fetchState === 2
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents3.Label {
                    text: root.tempText
                    font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 2)
                    font.weight: Font.DemiBold
                }

                PlasmaComponents3.Label {
                    text: root.conditionText
                    visible: root.fetchState === 2 && root.showCondition
                }
            }
        }

        // detail rows
        GridLayout {
            columns: 2
            visible: root.fetchState === 2
                && (root.showFeelsLike || root.showHumidity || root.showWind || root.showUpdated)
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            PlasmaComponents3.Label { text: i18n("Feels like"); visible: root.showFeelsLike }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.feelsText
                visible: root.showFeelsLike
            }

            PlasmaComponents3.Label { text: i18n("Humidity"); visible: root.showHumidity }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.humidity >= 0 ? (root.humidity + " %") : "---"
                visible: root.showHumidity
            }

            PlasmaComponents3.Label { text: i18n("Wind"); visible: root.showWind }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.windText
                visible: root.showWind
            }

            PlasmaComponents3.Label { text: i18n("Updated"); visible: root.showUpdated }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.lastUpdated
                visible: root.showUpdated
            }
        }

        // error state
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.fetchState === 3 && root.cfgCity !== ""
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Kirigami.Theme.negativeTextColor
                text: root.translateError(root.lastErrorCode)
            }

            PlasmaComponents3.Button {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Try again")
                onClicked: root.refreshAll()
            }
        }

        // loading hint
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: root.fetchState === 1 && root.cfgCity !== ""
            color: Kirigami.Theme.disabledTextColor
            text: i18n("Loading\u2026")
        }
    }

    // ----- logic -------------------------------------------------------------
    function refreshAll() {
        if (root.cfgCity === "") {
            root.resetState()
            return
        }
        root.fetchState = 1
        root.lastErrorCode = ""
        Weather.fetchGeocode(
            root.cfgCity,
            function (result) {
                root.resolvedName = result.name
                root.resolvedCountry = result.country
                root.cityLat = result.latitude
                root.cityLon = result.longitude
                root.cityTimezone = result.timezone
                root.fetchWeather()
            },
            function (errorCode) { root.fail(errorCode) }
        )
    }

    function fetchWeather() {
        Weather.fetchForecast(
            root.cityLat,
            root.cityLon,
            root.cityTimezone,
            function (data) {
                // The API always returns Celsius; conversion happens in the display bindings.
                root.tempC = Weather.number(data, ["current", "temperature_2m"], 0)
                root.feelsC = Weather.number(data, ["current", "apparent_temperature"], 0)
                root.humidity = Weather.number(data, ["current", "relative_humidity_2m"], -1)
                root.windKmh = Weather.number(data, ["current", "wind_speed_10m"], 0)
                root.weatherCode = Weather.number(data, ["current", "weather_code"], -1)
                root.cityUtcOffset = Weather.number(data, ["utc_offset_seconds"], 0)
                root.hasCityOffset = typeof data.utc_offset_seconds === "number"
                root.lastUpdated = Qt.formatTime(new Date(), root.use12h ? "h:mm AP" : "hh:mm")
                root.fetchState = 2
            },
            function (errorCode) { root.fail(errorCode) }
        )
    }

    function fail(errorCode) {
        root.lastErrorCode = errorCode
        root.fetchState = 3
    }

    function resetState() {
        root.resolvedName = ""
        root.resolvedCountry = ""
        root.cityTimezone = ""
        root.cityUtcOffset = 0
        root.hasCityOffset = false
        root.cityLat = 0
        root.cityLon = 0
        root.weatherCode = -1
        root.tempC = 0
        root.feelsC = 0
        root.humidity = -1
        root.windKmh = 0
        root.lastUpdated = ""
        root.lastErrorCode = ""
        root.fetchState = 0
    }

    function translateError(code) {
        switch (code) {
        case "notfound": return i18n("City not found.")
        case "network":  return i18n("Network error.")
        case "http":     return i18n("Weather service error.")
        case "invalid":  return i18n("Invalid weather data.")
        default:         return i18n("Weather unavailable.")
        }
    }

    function openConfiguration() {
        // Defensive: modern Plasma exposes the "configure" action on the Plasmoid
        // object; showConfigurationInterface() is the classic fallback.
        // TODO verify on target: at least one of these must open the dialog.
        var action = null
        if (Plasmoid.internalAction) {
            action = Plasmoid.internalAction("configure")
        }
        if (!action && Plasmoid.action) {
            action = Plasmoid.action("configure")
        }
        if (action) {
            action.trigger()
        } else if (Plasmoid.showConfigurationInterface) {
            Plasmoid.showConfigurationInterface()
        }
    }

    Component.onCompleted: root.refreshAll()

    onCfgCityChanged: {
        root.resetState()
        root.refreshAll()
    }

    Timer {
        id: refreshTimer
        // re-binds automatically when the interval setting changes
        interval: Math.max(5, root.cfgRefreshMinutes) * 60000
        // pause while a request is in flight to avoid overlapping fetches
        running: root.cfgCity !== "" && root.fetchState !== 1
        repeat: true
        onTriggered: root.refreshAll()
    }
}