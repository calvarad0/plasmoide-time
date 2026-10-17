/*
 * Calendar settings: week numbers, first day of week and event plugins.
 * Adapted from applets/digital-clock/package/contents/ui/configCalendar.qml.
 *
 * SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
 * SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>
 * SPDX-FileCopyrightText: 2026 Carlos Alvarado
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: calendarPage

    // emitted when a plugin checkbox changes, which no cfg_* property tracks
    signal configurationChanged()

    property alias cfg_showWeekNumbers: showWeekNumbersBox.checked
    property int cfg_firstDayOfWeek

    // called by the framework when the settings are applied
    function saveConfig() {
        Plasmoid.configuration.enabledCalendarPlugins = eventPluginsManager.enabledPlugins
    }

    Kirigami.FormLayout {
        PlasmaCalendar.EventPluginsManager {
            id: eventPluginsManager
            Component.onCompleted: {
                populateEnabledPluginsList(Plasmoid.configuration.enabledCalendarPlugins)
            }
        }

        QQC2.CheckBox {
            id: showWeekNumbersBox
            Kirigami.FormData.label: i18n("General:")
            text: i18n("Show week numbers")
        }

        QQC2.ComboBox {
            id: firstDayOfWeekCombo
            Kirigami.FormData.label: i18n("First day of week:")
            Layout.fillWidth: true

            textRole: "text"
            model: [-1, 0, 1, 5, 6].map(day => ({
                day,
                text: day === -1 ? i18n("Use region defaults") : Qt.locale().dayName(day),
            }))
            onActivated: index => {
                calendarPage.cfg_firstDayOfWeek = model[index].day
            }
            currentIndex: model.findIndex(item => item.day === calendarPage.cfg_firstDayOfWeek)
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ColumnLayout {
            id: calendarPluginsLayout
            Kirigami.FormData.label: i18n("Available Plugins:")
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: eventPluginsManager.model

                delegate: QQC2.CheckBox {
                    required property var model

                    text: model.display
                    checked: model.checked

                    onClicked: {
                        // writing back calls the model's setData()
                        model.checked = checked
                        calendarPage.configurationChanged()
                    }
                }

                onItemAdded: (index, item) => {
                    if (index === 0) {
                        calendarPluginsLayout.Kirigami.FormData.buddyFor = item
                    }
                }
            }
        }
    }
}
