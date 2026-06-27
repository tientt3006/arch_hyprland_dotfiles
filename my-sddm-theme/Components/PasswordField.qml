import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
  id: passwordField
  focus: true
  selectByMouse: true
  placeholderText: "Password"
  echoMode: TextInput.Password
  passwordCharacter: "•"
  passwordMaskDelay: config.PasswordShowLastLetter
  selectionColor: "#6C7086"
  renderType: Text.NativeRendering
  font {
    family: config.Font
    pointSize: config.FontSize
    bold: true
  }
  color: "#CDD6F4"
  horizontalAlignment: TextInput.AlignHCenter
  background: Rectangle {
    id: passFieldBackground
    radius: 3
    color: "#313244"
  }
  function flashError() {
    errorAnim.start()
  }

  SequentialAnimation {
    id: errorAnim
    ColorAnimation {
      target: passFieldBackground
      property: "color"
      to: "#F38BA8" // Catppuccin Red
      duration: 150
    }
    ColorAnimation {
      target: passFieldBackground
      property: "color"
      to: passwordField.activeFocus ? "#45475A" : "#313244"
      duration: 200
    }
  }

  states: [
    State {
      name: "focused"
      when: passwordField.activeFocus
      PropertyChanges {
        target: passFieldBackground
        color: "#45475A"
      }
    },
    State {
      name: "hovered"
      when: passwordField.hovered
      PropertyChanges {
        target: passFieldBackground
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
