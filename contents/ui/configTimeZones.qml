/*
 * Time zones listed in the calendar popup, next to the configured city's.
 * Modeled on the Digital Clock applet's page and built on its private QML
 * module (TimeZoneModel, TimeZoneFilterProxy).
 * Adapted from applets/digital-clock/package/contents/ui/configTimeZones.qml.
 *
 * SPDX-FileCopyrightText: 2013 Kai Uwe Broulik <kde@privat.broulik.de>
 * SPDX-FileCopyrightText: 2026 Carlos Alvarado
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.private.digitalclock
import org.kde.kirigami as Kirigami
import org.kde.config as KConfig
import org.kde.kcmutils as KCM

KCM.ScrollViewKCM {
    id: timeZonesPage

    property alias cfg_selectedTimeZones: timeZones.selectedTimeZones

    TimeZoneModel {
        id: timeZones
    }

    header: QQC2.Label {
        text: i18n("The city's time zone is always listed. Time zones that resolve to the same zone are shown once.")
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }

    view: ListView {
        id: configuredTimeZoneList
        clip: true
        focus: true
        activeFocusOnTab: true

        headerPositioning: ListView.OverlayHeader
        header: Kirigami.InlineViewHeader {
            width: ListView.view.width
            actions: [
                Kirigami.Action {
                    text: i18n("Add Time Zones…")
                    icon.name: "list-add-symbolic"
                    Accessible.name: text
                    onTriggered: timeZoneSheet.open()
                }
            ]
        }
        model: TimeZoneFilterProxy {
            sourceModel: timeZones
            onlyShowChecked: true
        }
        currentIndex: -1

        delegate: QQC2.ItemDelegate {
            id: timeZoneListItem

            required property int index
            required property var model

            width: ListView.view.width
            text: model.city
            down: false
            // stripes help the eye line up the text on the left and the button on the right
            Kirigami.Theme.useAlternateBackgroundColor: true

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.fillWidth: true
                    text: timeZoneListItem.text
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }

                QQC2.Button {
                    visible: timeZoneListItem.model.isLocalTimeZone && KConfig.KAuthorized.authorizeControlModule("kcm_clock.desktop")
                    text: i18n("Switch Systemwide Time Zone…")
                    icon.name: "preferences-system-time"
                    onClicked: KCM.KCMLauncher.openSystemSettings("kcm_clock")
                }

                QQC2.Button {
                    icon.name: "edit-delete-remove"
                    onClicked: timeZoneListItem.model.checked = false
                    Accessible.name: i18n("Remove this time zone")
                    QQC2.ToolTip.text: i18n("Remove this time zone")
                    QQC2.ToolTip.visible: hovered
                }
            }
        }

        section {
            property: "isLocalTimeZone"
            delegate: Kirigami.ListSectionHeader {
                required property string section

                width: configuredTimeZoneList.width
                label: section === "true" ? i18n("Systemwide Time Zone") : i18n("Additional Time Zones")
            }
        }

        Kirigami.PlaceholderMessage {
            visible: configuredTimeZoneList.count === 0
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.largeSpacing * 12
            text: i18n("Add time zones to list them in the calendar pop-up")
        }
    }

    Kirigami.OverlaySheet {
        id: timeZoneSheet

        parent: timeZonesPage.QQC2.Overlay.overlay

        onVisibleChanged: {
            filter.text = ""
            if (visible) {
                filter.forceActiveFocus()
            }
        }

        header: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                Layout.fillWidth: true
                text: i18n("Add More Time Zones")
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }

            Kirigami.SearchField {
                id: filter
                Layout.fillWidth: true
            }
        }

        footer: QQC2.DialogButtonBox {
            standardButtons: QQC2.DialogButtonBox.Ok
            onAccepted: timeZoneSheet.close()
        }

        ListView {
            focus: true
            activeFocusOnTab: true
            clip: true
            implicitWidth: Math.max(timeZonesPage.width / 2, Kirigami.Units.gridUnit * 25)

            model: TimeZoneFilterProxy {
                sourceModel: timeZones
                filterString: filter.text
            }

            delegate: QQC2.CheckDelegate {
                required property int index
                required property var model

                required checked
                required property string city
                required property string comment
                required property string region

                width: ListView.view.width
                focus: true
                text: {
                    if (!city || city.indexOf("UTC") === 0) {
                        return comment
                    } else if (comment) {
                        return i18n("%1, %2 (%3)", city, region, comment)
                    } else {
                        return i18n("%1, %2", city, region)
                    }
                }

                onToggled: {
                    model.checked = checked
                    ListView.view.currentIndex = index
                    ListView.view.forceActiveFocus()
                }
                highlighted: ListView.isCurrentItem
            }
        }
    }
}
