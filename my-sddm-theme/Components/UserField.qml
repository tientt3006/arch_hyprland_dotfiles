import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
  id: userField
  
  property alias text: userField.currentText
  
  model: userModel
  textRole: "name"
  currentIndex: userModel.lastIndex
  
  font {
    family: config.Font
    pointSize: config.FontSize
    bold: true
  }

  delegate: ItemDelegate {
    width: userField.width
    height: userField.height
    contentItem: Text {
      text: model.name
      color: "#CDD6F4"
      font: userField.font
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignHCenter
    }
    highlighted: userField.highlightedIndex === index
    background: Rectangle {
        color: highlighted ? "#45475A" : "#313244"
        radius: 3
    }
  }

  indicator: Canvas {
    id: canvas
    x: userField.width - width - 10
    y: (userField.height - height) / 2
    width: 10
    height: 6
    contextType: "2d"
    Connections {
        target: userField
        function onPressedChanged() { canvas.requestPaint(); }
    }
    onPaint: {
        context.reset();
        context.moveTo(0, 0);
        context.lineTo(width, 0);
        context.lineTo(width / 2, height);
        context.closePath();
        context.fillStyle = "#CDD6F4";
        context.fill();
    }
  }

  contentItem: Text {
    text: userField.currentText
    font: userField.font
    color: "#CDD6F4"
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideRight
  }

  background: Rectangle {
    id: userFieldBackground
    color: "#313244"
    radius: 3
  }

  popup: Popup {
    y: userField.height + 4
    width: userField.width
    implicitHeight: contentItem.implicitHeight
    padding: 0
    contentItem: ListView {
        clip: true
        implicitHeight: contentHeight
        model: userField.popup.visible ? userField.delegateModel : null
        currentIndex: userField.highlightedIndex
        ScrollIndicator.vertical: ScrollIndicator { }
    }
    background: Rectangle {
        color: "#313244"
        radius: 3
        border.color: "#45475A"
        border.width: 1
    }
  }
  
  states: [
    State {
      name: "hovered"
      when: userField.hovered
      PropertyChanges {
        target: userFieldBackground
        color: "#45475A"
      }
    }
  ]
  transitions: Transition {
    PropertyAnimation {
      properties: "color"
      duration: 300
    }
  }
}
