/*
 * World clocks for the calendar popup, modeled on the Digital Clock applet:
 * the configured city's time zone plus the time zones chosen in the settings,
 * sorted by UTC offset. Uses the Digital Clock's private QML module for the
 * translated city names, so it is loaded through a Loader and simply stays
 * hidden on systems without that module.
 * Adapted from the Digital Clock's CalendarView.qml (clocks list) and
 * main.qml (time zone helpers).
 *
 * SPDX-FileCopyrightText: 2013 Heena Mahour <heena393@gmail.com>
 * SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
 * SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
 * SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>
 * SPDX-FileCopyrightText: 2026 Carlos Alvarado
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.digitalclock
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.config as KConfig
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: zones

    // the applet root (main.qml)
    required property var applet
    // left/right padding matching the rest of the popup
    property int paddings: Kirigami.Units.largeSpacing

    readonly property var selectedTimeZones: Plasmoid.configuration.selectedTimeZones
    readonly property var rows: zones.buildRows()
    // a single row would only repeat the city time already shown in the popup
    readonly property bool hasClocks: zones.rows.length > 1

    spacing: 0

    P5Support.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: {
            const sources = ["Local"].concat(zones.selectedTimeZones)
            if (zones.applet.cityTimezone !== "" && sources.indexOf(zones.applet.cityTimezone) === -1) {
                sources.push(zones.applet.cityTimezone)
            }
            return sources
        }
        interval: 60000
        intervalAlignment: P5Support.Types.AlignToMinute
    }

    // City first, then the configured zones; zones resolving to an already listed
    // time zone are dropped (e.g. "Local" when the system is in the city's zone).
    function buildRows() {
        const candidates = []
        if (zones.applet.cityTimezone !== "") {
            candidates.push({ zone: zones.applet.cityTimezone, isCity: true })
        }
        for (const zone of zones.selectedTimeZones) {
            candidates.push({ zone: zone, isCity: false })
        }

        const seen = []
        const result = []
        for (const candidate of candidates) {
            const data = dataSource.data[candidate.zone]
            const resolved = data !== undefined ? data["Timezone"] : candidate.zone
            if (seen.indexOf(resolved) !== -1) {
                continue
            }
            seen.push(resolved)
            result.push(candidate)
        }
        return result.sort((a, b) => zones.offsetOf(a.zone) - zones.offsetOf(b.zone))
    }

    function offsetOf(zone) {
        const data = dataSource.data[zone]
        return data !== undefined ? data["Offset"] : 0
    }

    function displayName(row) {
        if (row.isCity) {
            return zones.applet.cityDisplayName
        }
        const data = dataSource.data[row.zone]
        return data !== undefined ? TimeZonesI18n.i18nCity(data["Timezone"]) : row.zone
    }

    // wall-clock time of the zone; adds the date when it differs from the local day
    function timeForZone(zone) {
        const data = dataSource.data[zone]
        const local = dataSource.data["Local"]
        if (data === undefined || local === undefined) {
            return ""
        }
        const now = data["DateTime"]
        const msUtc = now.getTime() + now.getTimezoneOffset() * 60000
        const dateTime = new Date(msUtc + data["Offset"] * 1000)

        let text = Qt.formatTime(dateTime, zones.applet.use12h ? "h:mm AP" : "hh:mm")
        if (dateTime.getDay() !== local["DateTime"].getDay()) {
            text += " (" + dateTime.toLocaleDateString(Qt.locale(), "ddd d MMM") + ")"
        }
        return text
    }

    PlasmaExtras.PlasmoidHeading {
        Layout.fillWidth: true

        enabledBorders: Qt.TopEdge | Qt.BottomEdge
        topInset: 0
        topPadding: Kirigami.Units.smallSpacing
        leftInset: 0
        rightInset: 0
        leftPadding: zones.paddings
        rightPadding: Kirigami.Units.smallSpacing

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 2
                text: i18n("Time Zones")
                textFormat: Text.PlainText
                maximumLineCount: 1
                elide: Text.ElideRight
                Accessible.ignored: true
            }

            PlasmaComponents3.ToolButton {
                visible: KConfig.KAuthorized.authorizeControlModule("kcm_clock.desktop")
                text: i18n("Switch…")
                icon.name: "preferences-system-time"
                Accessible.name: i18n("Switch to another time zone")
                Accessible.description: i18n("Switch to another time zone")
                onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_clock")

                PlasmaComponents3.ToolTip {
                    text: parent.Accessible.description
                }
            }
        }
    }

    PlasmaComponents3.ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(clocksList.contentHeight, Kirigami.Units.gridUnit * 8)

        ListView {
            id: clocksList
            interactive: contentHeight > height
            currentIndex: -1
            model: zones.rows

            delegate: PlasmaComponents3.ItemDelegate {
                id: clockItem

                required property var modelData

                width: ListView.view.width
                leftPadding: zones.paddings
                rightPadding: zones.paddings
                hoverEnabled: false
                down: false
                Accessible.name: zones.displayName(modelData)
                Accessible.description: zones.timeForZone(modelData.zone)

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: zones.displayName(clockItem.modelData)
                        textFormat: Text.PlainText
                        font.weight: clockItem.modelData.isCity ? Font.Bold : Font.Normal
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    PlasmaComponents3.Label {
                        horizontalAlignment: Qt.AlignRight
                        text: zones.timeForZone(clockItem.modelData.zone)
                        textFormat: Text.PlainText
                        font.weight: clockItem.modelData.isCity ? Font.Bold : Font.Normal
                        maximumLineCount: 1
                    }
                }
            }
        }
    }
}
