// ui/ConfigGeneral.qml
import QtQuick 2.6
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2 as Controls
import org.kde.kirigami 2.4 as Kirigami

Item {
    id: page
    width: childrenRect.width
    height: childrenRect.height

    property alias cfg_city: city.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        Controls.TextField {
            id: city
            Kirigami.FormData.label: "Enter Location "
            onTextEdited: {
                cfg_city = city.text
            }
        }
    }    
}