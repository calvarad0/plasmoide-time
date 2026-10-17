/*
 * Weather details for the configured city: header, current conditions and the
 * detail rows. Shown as the rich tooltip of the applet, so it holds no controls.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: details

    // the applet root (main.qml), which owns the weather state and the formatted texts
    required property var applet
    // side by side: detail rows on the left, conditions on the right (popup);
    // otherwise stacked (tooltip)
    property bool wide: false
    // city + time header; the popup hides it because the time zones already show both
    property bool showHeader: true

    implicitWidth: Math.max(Kirigami.Units.gridUnit * 16, content.implicitWidth) + content.anchors.margins * 2
    implicitHeight: content.implicitHeight + content.anchors.margins * 2

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        // header: city + time
        RowLayout {
            Layout.fillWidth: true
            visible: details.showHeader
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                elide: Text.ElideRight
                text: details.applet.cityHeader
            }

            ColumnLayout {
                spacing: 0

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignRight
                    text: details.applet.timeText
                }

                PlasmaComponents3.Label {
                    Layout.alignment: Qt.AlignRight
                    text: details.applet.dateText
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }
            }
        }

        // placeholder when no city is configured
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: details.applet.cfgCity === ""
            horizontalAlignment: Text.AlignHCenter
            text: i18n("Enter a city in settings.")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: details.wide ? 2 : 1
            rowSpacing: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing * 2

            // main weather block
            RowLayout {
                Layout.row: 0
                Layout.column: details.wide ? 1 : 0
                Layout.fillWidth: !details.wide
                Layout.alignment: Qt.AlignTop | (details.wide ? Qt.AlignRight : Qt.AlignLeft)
                visible: details.applet.cfgCity !== ""
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: details.applet.weatherIcon
                    Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.large)
                    Layout.preferredHeight: Math.round(Kirigami.Units.iconSizes.large)
                    visible: details.applet.fetchState === 2
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents3.Label {
                        text: details.applet.tempText
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 2)
                        font.weight: Font.DemiBold
                        // same accent as the temperature in the panel
                        color: Kirigami.Theme.highlightColor
                    }

                    PlasmaComponents3.Label {
                        text: details.applet.conditionText
                        visible: details.applet.fetchState === 2 && details.applet.showCondition
                    }
                }
            }

            // detail rows
            GridLayout {
                Layout.row: details.wide ? 0 : 1
                Layout.column: 0
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                columns: 2
                visible: details.applet.fetchState === 2
                    && (details.applet.showFeelsLike || details.applet.showHumidity
                        || details.applet.showWind || details.applet.showUpdated)
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                PlasmaComponents3.Label { text: i18n("Feels like"); visible: details.applet.showFeelsLike }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: details.applet.feelsText
                    visible: details.applet.showFeelsLike
                }

                PlasmaComponents3.Label { text: i18n("Humidity"); visible: details.applet.showHumidity }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: details.applet.humidity >= 0 ? (details.applet.humidity + " %") : "---"
                    visible: details.applet.showHumidity
                }

                PlasmaComponents3.Label { text: i18n("Wind"); visible: details.applet.showWind }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: details.applet.windText
                    visible: details.applet.showWind
                }

                PlasmaComponents3.Label { text: i18n("Updated"); visible: details.applet.showUpdated }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: details.applet.lastUpdated
                    visible: details.applet.showUpdated
                }
            }
        }

        // error state; refreshing is available from the context menu
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: details.applet.fetchState === 3 && details.applet.cfgCity !== ""
            horizontalAlignment: Text.AlignHCenter
            color: Kirigami.Theme.negativeTextColor
            text: details.applet.translateError(details.applet.lastErrorCode)
        }

        // loading hint
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: details.applet.fetchState === 1 && details.applet.cfgCity !== ""
            color: Kirigami.Theme.disabledTextColor
            text: i18n("Loading…")
        }
    }
}
