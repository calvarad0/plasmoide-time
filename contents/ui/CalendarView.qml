/*
 * Calendar popup, modeled on the Digital Clock applet of plasma-workspace.
 * Leading column: selected date, current weather, the agenda of the selected
 * day (when calendar event plugins are enabled) and world clocks.
 * Trailing column: the month view.
 * Adapted from applets/digital-clock/package/contents/ui/CalendarView.qml.
 *
 * SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
 * SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 * SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>
 * SPDX-FileCopyrightText: 2026 Carlos Alvarado
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.ksvg as KSvg
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmaExtras.Representation {
    id: calendar

    // the applet root (main.qml); "today" follows the configured city's date
    required property var applet

    readonly property bool showAgenda: eventPluginsManager.enabledPlugins.length > 0
    readonly property int paddings: Kirigami.Units.largeSpacing
    // keeps the agenda header aligned with the month view header
    readonly property real headerHeight: Math.max(agendaHeader.implicitHeight, monthView.viewHeader.implicitHeight)

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    Layout.minimumWidth: Kirigami.Units.gridUnit * 40
    Layout.maximumWidth: Kirigami.Units.gridUnit * 80
    Layout.minimumHeight: Math.max(Kirigami.Units.gridUnit * 25, leadingColumn.implicitHeight)
    Layout.maximumHeight: Kirigami.Units.gridUnit * 40

    collapseMarginsHint: true

    // the columns bring their own headers
    header: Item {}

    Connections {
        target: calendar.applet

        function onExpandedChanged() {
            // start from today every time the popup opens or closes
            monthView.resetToToday()
        }
    }

    PlasmaCalendar.EventPluginsManager {
        id: eventPluginsManager
        enabledPlugins: Plasmoid.configuration.enabledCalendarPlugins
    }

    // ----- leading column: date, weather, agenda and world clocks -----
    ColumnLayout {
        id: leadingColumn

        anchors {
            top: parent.top
            left: parent.left
            right: mainSeparator.left
            bottom: parent.bottom
        }
        spacing: 0

        QtObject {
            id: agenda

            function dateEquals(date1, date2) {
                return date1.getFullYear() === date2.getFullYear()
                    && date1.getMonth() === date2.getMonth()
                    && date1.getDate() === date2.getDate()
            }

            function updateEventsForCurrentDate() {
                eventsList.model = monthView.daysModel.eventsForDate(monthView.currentDate)
            }
        }

        Connections {
            target: monthView

            function onCurrentDateChanged() {
                agenda.updateEventsForCurrentDate()
            }
        }

        Connections {
            target: monthView.daysModel

            function onAgendaUpdated(updatedDate) {
                if (agenda.dateEquals(updatedDate, monthView.currentDate)) {
                    agenda.updateEventsForCurrentDate()
                }
            }
        }

        PlasmaExtras.PlasmoidHeading {
            id: agendaHeader
            Layout.preferredHeight: calendar.headerHeight
            Layout.fillWidth: true
            leftInset: 0
            rightInset: 0

            contentItem: Kirigami.Heading {
                leftPadding: calendar.paddings
                rightPadding: calendar.paddings
                verticalAlignment: Text.AlignTop
                level: 2
                elide: Text.ElideRight
                text: monthView.currentDate.toLocaleDateString(Qt.locale(), Locale.LongFormat)
                textFormat: Text.PlainText
            }
        }

        WeatherDetails {
            Layout.fillWidth: true
            applet: calendar.applet
            wide: true
            showHeader: false
        }

        KSvg.SvgItem {
            Layout.fillWidth: true
            Layout.preferredHeight: naturalSize.height
            visible: calendar.showAgenda
            imagePath: "widgets/line"
            elementId: "horizontal-line"
        }

        // agenda of the selected day (only with event plugins enabled)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: calendar.showAgenda ? Kirigami.Units.gridUnit * 4 : 0
            visible: calendar.showAgenda

            PlasmaComponents3.ScrollView {
                id: eventsView
                anchors.fill: parent

                ListView {
                    id: eventsList
                    focus: false
                    currentIndex: -1

                    delegate: PlasmaComponents3.ItemDelegate {
                        id: eventItem

                        required property var modelData

                        width: ListView.view.width
                        leftPadding: calendar.paddings
                        text: eventTitle.text
                        hoverEnabled: true
                        Accessible.description: modelData.description

                        // all-day events, explicit or spanning midnight to midnight, show no times
                        readonly property bool hasTime: {
                            if (modelData.isAllDay) {
                                return false
                            }
                            const start = modelData.startDateTime
                            const end = modelData.endDateTime
                            const startIsMidnight = start.getHours() === 0 && start.getMinutes() === 0
                            const endIsMidnight = end.getHours() === 0 && end.getMinutes() === 0
                            return !(startIsMidnight && endIsMidnight)
                        }

                        PlasmaComponents3.ToolTip {
                            text: eventItem.modelData.description
                            visible: text !== "" && eventItem.hovered
                        }

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing

                            Rectangle {
                                Layout.fillHeight: true
                                implicitWidth: 5
                                color: eventItem.modelData.eventColor
                                visible: eventItem.modelData.eventColor !== ""
                            }

                            ColumnLayout {
                                spacing: 0
                                visible: eventItem.hasTime

                                PlasmaComponents3.Label {
                                    Layout.alignment: Qt.AlignRight
                                    text: Qt.formatTime(eventItem.modelData.startDateTime, calendar.applet.use12h ? "h:mm AP" : "hh:mm")
                                    textFormat: Text.PlainText
                                }

                                PlasmaComponents3.Label {
                                    Layout.alignment: Qt.AlignRight
                                    text: Qt.formatTime(eventItem.modelData.endDateTime, calendar.applet.use12h ? "h:mm AP" : "hh:mm")
                                    textFormat: Text.PlainText
                                    opacity: 0.7
                                }
                            }

                            PlasmaComponents3.Label {
                                id: eventTitle
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: eventItem.modelData.title
                                textFormat: Text.PlainText
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }

            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: eventsView
                width: eventsView.width - Kirigami.Units.gridUnit * 4
                visible: eventsList.count === 0
                iconName: "checkmark"
                text: monthView.isToday(monthView.currentDate)
                    ? i18n("No events for today")
                    : i18n("No events for this day")
            }
        }

        // keeps the time zones at the bottom when there is no agenda
        Item {
            Layout.fillHeight: true
            visible: !calendar.showAgenda
        }

        // world clocks; loaded by URL so a missing Digital Clock module only
        // hides this section instead of breaking the whole popup
        Loader {
            id: timeZonesLoader
            Layout.fillWidth: true
            visible: status === Loader.Ready && item.hasClocks
            Component.onCompleted: setSource(Qt.resolvedUrl("TimeZonesView.qml"), {
                applet: calendar.applet,
                paddings: calendar.paddings,
            })
        }
    }

    KSvg.SvgItem {
        id: mainSeparator

        anchors {
            top: parent.top
            right: monthViewWrapper.left
            bottom: parent.bottom
        }
        width: naturalSize.width

        imagePath: "widgets/line"
        elementId: "vertical-line"
    }

    // ----- month view -----
    FocusScope {
        id: monthViewWrapper

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }
        // not anchored to the center to avoid sub-pixel misalignment
        width: Math.round(parent.width / 2)

        PlasmaCalendar.MonthView {
            id: monthView
            viewHeader.height: calendar.headerHeight

            anchors {
                fill: parent
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
                bottomMargin: Kirigami.Units.smallSpacing
            }

            borderOpacity: 0.25
            focus: true

            eventPluginsManager: eventPluginsManager
            today: calendar.applet.cityDateTime
            firstDayOfWeek: Plasmoid.configuration.firstDayOfWeek > -1
                ? Plasmoid.configuration.firstDayOfWeek
                : Qt.locale().firstDayOfWeek
            showWeekNumbers: Plasmoid.configuration.showWeekNumbers
        }
    }
}
