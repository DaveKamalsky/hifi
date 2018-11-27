//
//  SignInBody.qml
//
//  Created by Wayne Chen on 10/18/18
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0
import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4 as OriginalStyles

import controlsUit 1.0 as HifiControlsUit
import stylesUit 1.0 as HifiStylesUit
import TabletScriptingInterface 1.0

Item {
    id: signInBody
    clip: true
    height: root.height
    width: root.width
    property int textFieldHeight: 31
    property string fontFamily: "Raleway"
    property int fontSize: 15
    property bool fontBold: true

    property bool keyboardEnabled: false
    property bool keyboardRaised: false
    property bool punctuationMode: false

    onKeyboardRaisedChanged: d.resize();

    property string errorString: errorString

    QtObject {
        id: d
        readonly property int minWidth: 480
        readonly property int minWidthButton: !root.isTablet ? 256 : 174
        property int maxWidth: root.isTablet ? 1280 : root.width
        readonly property int minHeight: 120
        readonly property int minHeightButton: !root.isTablet ? 56 : 42
        property int maxHeight: root.isTablet ? 720 : root.height

        function resize() {
            maxWidth = root.isTablet ? 1280 : root.width;
            maxHeight = root.isTablet ? 720 : root.height;
            var targetWidth = Math.max(titleWidth, mainContainer.width);
            var targetHeight =  hifi.dimensions.contentSpacing.y + mainContainer.height +
                    4 * hifi.dimensions.contentSpacing.y;

            var newWidth = Math.max(d.minWidth, Math.min(d.maxWidth, targetWidth));
            if (!isNaN(newWidth)) {
                parent.width = root.width = newWidth;
            }

            parent.height = root.height = Math.max(d.minHeight, Math.min(d.maxHeight, targetHeight))
                    + (keyboardEnabled && keyboardRaised ? (200 + 2 * hifi.dimensions.contentSpacing.y) : hifi.dimensions.contentSpacing.y);
        }
    }

    function login() {
        loginDialog.signup(emailField.text, usernameField.text, passwordField.text);
        return;
        bodyLoader.setSource("LoggingInBody.qml", { "loginDialog": loginDialog, "root": root, "bodyLoader": bodyLoader, "withSteam": false, "withOculus": false, "fromBody": "" });
    }

    function init() {
        // going to/from sign in/up dialog.
        loginDialog.isLogIn = false;
        loginErrorMessage.visible = (signInBody.errorString !== "");
        if (signInBody.errorString !== "") {
            loginErrorMessage.text = signInBody.errorString;
            errorContainer.anchors.bottom = usernameField.top;
            errorContainer.anchors.left = usernameField.left;
        }
        loginButtonAtSignIn.text = "Sign Up";
        loginButtonAtSignIn.color = hifi.buttons.blue;
        emailField.placeholderText = "Email";
        emailField.text = "";
        emailField.anchors.top = usernameField.bottom;
        emailField.anchors.topMargin = 1.5 * hifi.dimensions.contentSpacing.y;
        passwordField.text = "";
        usernameField.focus = true;
        loginContainer.visible = true;
    }

    Item {
        id: mainContainer
        width: root.width
        height: root.height
        onHeightChanged: d.resize(); onWidthChanged: d.resize();

        Rectangle {
            id: opaqueRect
            height: parent.height
            width: parent.width
            opacity: 0.9
            color: "black"
        }

        Item {
            id: bannerContainer
            width: parent.width
            height: banner.height
            anchors {
                top: parent.top
                topMargin: 85
            }
            Image {
                id: banner
                anchors.centerIn: parent
                source: "../../images/high-fidelity-banner.svg"
                horizontalAlignment: Image.AlignHCenter
            }
        }

        Item {
            id: loginContainer
            width: parent.width
            height: parent.height - (bannerContainer.height + 1.5 * hifi.dimensions.contentSpacing.y)
            anchors {
                top: bannerContainer.bottom
                topMargin: 1.5 * hifi.dimensions.contentSpacing.y
            }
            visible: true

            Item {
                id: errorContainer
                width: loginErrorMessageTextMetrics.width
                height: loginErrorMessageTextMetrics.height
                anchors {
                    bottom: emailField.top;
                    bottomMargin: 2;
                    left: emailField.left;
                }
                TextMetrics {
                    id: loginErrorMessageTextMetrics
                    font: loginErrorMessage.font
                    text: loginErrorMessage.text
                }
                Text {
                    id: loginErrorMessage;
                    color: "red";
                    font.family: signInBody.fontFamily
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: ""
                    visible: false
                }
            }

            HifiControlsUit.TextField {
                id: usernameField
                width: banner.width
                height: signInBody.textFieldHeight
                font.family: "Fira Sans"
                placeholderText: "Username"
                anchors {
                    top: parent.top
                    topMargin: 0.2 * parent.height
                    left: parent.left
                    leftMargin: (parent.width - usernameField.width) / 2
                }
                focus: true
                Keys.onPressed: {
                    if (!usernameField.visible) {
                        return;
                    }
                    switch (event.key) {
                        case Qt.Key_Tab:
                            event.accepted = true;
                            if (event.modifiers === Qt.ShiftModifier) {
                                passwordField.focus = true;
                            } else {
                                emailField.focus = true;
                            }
                            break;
                        case Qt.Key_Backtab:
                            event.accepted = true;
                            passwordField.focus = true;
                            break;
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                            event.accepted = true;
                            if (keepMeLoggedInCheckbox.checked) {
                                Settings.setValue("keepMeLoggedIn/savedUsername", usernameField.text);
                            }
                            signInBody.login();
                            break;
                    }
                }
                onFocusChanged: {
                    root.text = "";
                    root.isPassword = !focus;
                }
            }

            HifiControlsUit.TextField {
                id: emailField
                width: banner.width
                height: signInBody.textFieldHeight
                font.family: "Fira Sans"
                anchors {
                    top: parent.top
                    left: parent.left
                    leftMargin: (parent.width - emailField.width) / 2
                }
                placeholderText: "Username or Email"
                activeFocusOnPress: true
                Keys.onPressed: {
                    switch (event.key) {
                        case Qt.Key_Tab:
                            event.accepted = true;
                            if (event.modifiers === Qt.ShiftModifier) {
                                if (usernameField.visible) {
                                    usernameField.focus = true;
                                    break;
                                }
                            }
                            passwordField.focus = true;
                            break;
                        case Qt.Key_Backtab:
                            event.accepted = true;
                            usernameField.focus = true;
                            break;
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                            event.accepted = true;
                            if (keepMeLoggedInCheckbox.checked) {
                                Settings.setValue("keepMeLoggedIn/savedUsername", usernameField.text);
                            }
                            signInBody.login();
                            break;
                    }
                }
                onFocusChanged: {
                    root.text = "";
                    root.isPassword = !focus;
                }
            }
            HifiControlsUit.TextField {
                id: passwordField
                width: banner.width
                height: signInBody.textFieldHeight
                font.family: "Fira Sans"
                placeholderText: "Password"
                activeFocusOnPress: true
                echoMode: passwordFieldMouseArea.showPassword ? TextInput.Normal : TextInput.Password
                anchors {
                    top: emailField.bottom
                    topMargin: 1.5 * hifi.dimensions.contentSpacing.y
                    left: parent.left
                    leftMargin: (parent.width - emailField.width) / 2
                }

                onFocusChanged: {
                    root.text = "";
                    root.isPassword = focus;
                }

                Item {
                    id: showPasswordContainer
                    z: 10
                    // width + image's rightMargin
                    width: showPasswordImage.width + 8
                    height: parent.height
                    anchors {
                        right: parent.right
                    }

                    Image {
                        id: showPasswordImage
                        width: passwordField.height * 16 / 23
                        height: passwordField.height * 16 / 23
                        anchors {
                            right: parent.right
                            rightMargin: 8
                            top: parent.top
                            topMargin: passwordFieldMouseArea.showPassword ? 6 : 8
                            bottom: parent.bottom
                            bottomMargin: passwordFieldMouseArea.showPassword ? 5 : 8
                        }
                        source: passwordFieldMouseArea.showPassword ?  "../../images/eyeClosed.svg" : "../../images/eyeOpen.svg"
                        MouseArea {
                            id: passwordFieldMouseArea
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            property bool showPassword: false
                            onClicked: {
                                showPassword = !showPassword;
                            }
                        }
                    }
                }
                Keys.onPressed: {
                    switch (event.key) {
                        case Qt.Key_Tab:
                            event.accepted = true;
                            if (event.modifiers === Qt.ShiftModifier) {
                                emailField.focus = true;
                            } else if (usernameField.visible) {
                                usernameField.focus = true;
                            } else {
                                emailField.focus = true;
                            }
                            break;
                        case Qt.Key_Backtab:
                            event.accepted = true;
                            emailField.focus = true;
                            break;
                    case Qt.Key_Enter:
                    case Qt.Key_Return:
                        event.accepted = true;
                        if (keepMeLoggedInCheckbox.checked) {
                            Settings.setValue("keepMeLoggedIn/savedUsername", usernameField.text);
                        }
                        signInBody.login();
                        break;
                    }
                }
            }
            HifiControlsUit.CheckBox {
                id: keepMeLoggedInCheckbox
                checked: Settings.getValue("keepMeLoggedIn", false);
                text: qsTr("Keep Me Logged In");
                boxSize: 18;
                labelFontFamily: signInBody.fontFamily
                labelFontSize: 18;
                color: hifi.colors.white;
                anchors {
                    top: passwordField.bottom;
                    topMargin: hifi.dimensions.contentSpacing.y;
                    left: passwordField.left;
                }
                onCheckedChanged: {
                    Settings.setValue("keepMeLoggedIn", checked);
                    if (checked) {
                        Settings.setValue("keepMeLoggedIn/savedUsername", Account.username);
                        var savedUsername = Settings.getValue("keepMeLoggedIn/savedUsername", "");
                        usernameField.text = savedUsername === "Unknown user" ? "" : savedUsername;
                    } else {
                        Settings.setValue("keepMeLoggedIn/savedUsername", "");
                    }
                }
                Component.onDestruction: {
                    Settings.setValue("keepMeLoggedIn", checked);
                }
            }
            Item {
                id: cancelContainer
                width: cancelText.width
                height: d.minHeightButton
                anchors {
                    top: keepMeLoggedInCheckbox.bottom
                    topMargin: hifi.dimensions.contentSpacing.y
                    left: parent.left
                    leftMargin: (parent.width - passwordField.width) / 2
                }
                Text {
                    id: cancelText
                    anchors.centerIn: parent
                    text: qsTr("Cancel");

                    lineHeight: 1
                    color: "white"
                    font.family: signInBody.fontFamily
                    font.pixelSize: signInBody.fontSize
                    font.capitalization: Font.AllUppercase;
                    font.bold: signInBody.fontBold
                    lineHeightMode: Text.ProportionalHeight
                }
                MouseArea {
                    id: cancelArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    onEntered: {
                        Tablet.playSound(TabletEnums.ButtonHover);
                    }
                    onClicked: {
                        Tablet.playSound(TabletEnums.ButtonClick);
                        bodyLoader.setSource("LinkAccountBody.qml", { "loginDialog": loginDialog, "root": root, "bodyLoader": bodyLoader });
                    }
                }
            }
            HifiControlsUit.Button {
                id: loginButtonAtSignIn
                width: d.minWidthButton
                height: d.minHeightButton
                text: qsTr("Log In")
                fontFamily: signInBody.fontFamily
                fontSize: signInBody.fontSize
                fontBold: signInBody.fontBold
                anchors {
                    top: cancelContainer.top
                    right: passwordField.right
                }

                onClicked: {
                    signInBody.login()
                }
            }
        }
    }

    Component.onCompleted: {
        //but rise Tablet's one instead for Tablet interface
        root.keyboardEnabled = HMD.active;
        root.keyboardRaised = Qt.binding( function() { return keyboardRaised; })
        root.text = "";
        d.resize();
        init();
    }

    Keys.onPressed: {
        if (!visible) {
            return;
        }

        switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
                event.accepted = true;
                Settings.setValue("keepMeLoggedIn/savedUsername", usernameField.text);
                signInBody.login();
                break;
        }
    }
    Connections {
        target: loginDialog
        onHandleSignupCompleted: {
            console.log("Sign Up Completed");

            loginDialog.login(usernameField.text, passwordField.text);
            bodyLoader.setSource("LoggingInBody.qml", { "loginDialog": loginDialog, "root": root, "bodyLoader": bodyLoader, "withSteam": false, "fromBody": "" });
        }
        onHandleSignupFailed: {
            console.log("Sign Up Failed")

            var errorStringEdited = errorString.replace(/[\n\r]+/g, ' ');
            loginErrorMessage.visible = (errorStringEdited !== "");
            if (errorStringEdited !== "") {
                loginErrorMessage.text = errorStringEdited;
                errorContainer.anchors.bottom = usernameField.top;
                errorContainer.anchors.left = usernameField.left;
            }
        }
    }
}
