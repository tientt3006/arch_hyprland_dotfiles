import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
  id: userField
  height: inputHeight
  width: inputWidth
  model: userModel
  textRole: "name"
  currentIndex: userModel.lastIndex
  
  property string text: currentText

  font {
    family: config.Font
    pointSize: config.FontSize
    bold: true
  }

  contentItem: Text {
      text: userField.currentText
      font: userField.font
      color: "#CDD6F4"
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
  }

  background: Rectangle {
    id: userFieldBackground
    color: userField.hovered || userField.pressed ? "#45475A" : "#313244"
    radius: 3
    Behavior on color {
        ColorAnimation { duration: 300 }
    }
  }

  delegate: ItemDelegate {
    width: userField.width
    contentItem: Text {
        text: model.name
        color: "#CDD6F4"
        font: userField.font
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
    background: Rectangle {
        color: userField.highlightedIndex === index ? "#45475A" : "#313244"
    }
  }
}
