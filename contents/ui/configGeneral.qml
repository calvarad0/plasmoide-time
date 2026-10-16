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
    }
}