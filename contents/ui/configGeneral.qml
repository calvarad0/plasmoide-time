import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configGeneral

    // These cfg_* properties are synchronized with the plasmoid configuration
    // by the framework (Contents/config/main.xml + Contents/config/config.qml).
    property alias cfg_city: cityField.text
    property string cfg_units: "c"
    property string cfg_timeFormat: "24"
    property alias cfg_refreshMinutes: refreshMinutesSpin.value
    property alias cfg_showTime: showTimeBox.checked
    property alias cfg_showDate: showDateBox.checked
    property alias cfg_showWeatherIcon: showWeatherIconBox.checked
    property alias cfg_showTemperature: showTemperatureBox.checked
    property alias cfg_showCondition: showConditionBox.checked
    property alias cfg_showFeelsLike: showFeelsLikeBox.checked
    property alias cfg_showHumidity: showHumidityBox.checked
    property alias cfg_showWind: showWindBox.checked
    property alias cfg_showUpdated: showUpdatedBox.checked
    property alias cfg_showTooltip: showTooltipBox.checked
    property alias cfg_tempFontSizePanel: tempFontSizePanelSpin.value
    property alias cfg_tempFontSizeDesktop: tempFontSizeDesktopSpin.value

    // The framework may apply the saved values either before or after the page
    // finishes loading; re-syncing on change covers both orders. The user
    // selection also writes back through these handlers, so the sync is a no-op
    // on user interaction.
    onCfg_unitsChanged: syncUnitsCombo()
    onCfg_timeFormatChanged: syncTimeFormatCombo()

    function syncUnitsCombo() {
        const idx = unitsCombo.indexOfValue(configGeneral.cfg_units)
        if (idx >= 0) {
            unitsCombo.currentIndex = idx
        }
    }

    function syncTimeFormatCombo() {
        const idx = timeFormatCombo.indexOfValue(configGeneral.cfg_timeFormat)
        if (idx >= 0) {
            timeFormatCombo.currentIndex = idx
        }
    }

    Kirigami.FormLayout {
        QQC2.TextField {
            id: cityField
            Kirigami.FormData.label: i18n("City:")
            Layout.fillWidth: true
            placeholderText: i18n("e.g. Buenos Aires")
        }

        QQC2.ComboBox {
            id: unitsCombo
            Kirigami.FormData.label: i18n("Units:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Celsius (\u00B0C)"), value: "c" },
                { text: i18n("Fahrenheit (\u00B0F)"), value: "f" },
            ]
            Component.onCompleted: configGeneral.syncUnitsCombo()
            onActivated: configGeneral.cfg_units = unitsCombo.currentValue
        }

        QQC2.ComboBox {
            id: timeFormatCombo
            Kirigami.FormData.label: i18n("Time format:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("24-hour (14:05)"), value: "24" },
                { text: i18n("12-hour (2:05 PM)"), value: "12" },
            ]
            Component.onCompleted: configGeneral.syncTimeFormatCombo()
            onActivated: configGeneral.cfg_timeFormat = timeFormatCombo.currentValue
        }

        QQC2.SpinBox {
            id: refreshMinutesSpin
            Kirigami.FormData.label: i18n("Refresh every (minutes):")
            from: 5
            to: 120
            stepSize: 5
            editable: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel")
        }

        QQC2.CheckBox {
            id: showTimeBox
            Kirigami.FormData.label: i18n("Show:")
            text: i18n("Time")
        }

        QQC2.CheckBox {
            id: showDateBox
            text: i18n("Date")
        }

        QQC2.CheckBox {
            id: showWeatherIconBox
            text: i18n("Weather icon")
        }

        QQC2.CheckBox {
            id: showTemperatureBox
            text: i18n("Temperature")
        }

        QQC2.SpinBox {
            id: tempFontSizePanelSpin
            Kirigami.FormData.label: i18n("Temperature size in panels (pt):")
            from: 6
            to: 48
            editable: true
        }

        QQC2.SpinBox {
            id: tempFontSizeDesktopSpin
            Kirigami.FormData.label: i18n("Temperature size on desktop (pt):")
            from: 6
            to: 48
            editable: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Popup")
        }

        QQC2.CheckBox {
            id: showConditionBox
            Kirigami.FormData.label: i18n("Show:")
            text: i18n("Weather condition")
        }

        QQC2.CheckBox {
            id: showFeelsLikeBox
            text: i18n("Feels like")
        }

        QQC2.CheckBox {
            id: showHumidityBox
            text: i18n("Humidity")
        }

        QQC2.CheckBox {
            id: showWindBox
            text: i18n("Wind")
        }

        QQC2.CheckBox {
            id: showUpdatedBox
            text: i18n("Last updated")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showTooltipBox
            Kirigami.FormData.label: i18n("Tooltip:")
            text: i18n("Show on hover")
        }
    }
}