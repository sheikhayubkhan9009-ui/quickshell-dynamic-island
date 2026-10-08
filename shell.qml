import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris

PanelWindow {
    id: playerRoot

    implicitWidth: 360
    implicitHeight: isExpanded ? (showLauncher ? 388 : 180) : 42
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        right: true
    }

    property bool isExpanded: false
    property bool isLauncherOpen: false
    property string selectedPlayerId: ""
    property int paletteIndex: 0
    readonly property var player: {
        var players = Mpris.players.values
        if (players.length === 0)
            return null

        for (var i = 0; i < players.length; i++) {
            if (players[i].dbusName === selectedPlayerId)
                return players[i]
        }

        for (var j = 0; j < players.length; j++) {
            if (players[j].isPlaying)
                return players[j]
        }

        return players[0]
    }
    function paletteColor(offset) {
        var colors = albumPalette.colors
        if (!colors || colors.length === 0)
            return Qt.hsla((paletteIndex * 0.13 + offset * 0.31) % 1, 0.78, 0.63, 1)

        var sampled = colors[(paletteIndex + offset) % colors.length]
        return Qt.hsla(
            sampled.hslHue,
            Math.max(0.55, sampled.hslSaturation),
            Math.max(0.42, Math.min(0.72, sampled.hslLightness)),
            1
        )
    }
    readonly property color accentColor: paletteColor(0)
    readonly property bool hasActiveMusic: player !== null && player.isPlaying
    readonly property bool showLauncher: !hasActiveMusic || isLauncherOpen

    PersistentProperties {
        id: preferences
        reloadableId: "dynamicBarPreferences"

        property bool use24HourClock: true
        property bool musicOnly: false
    }

    function clockText() {
        return Qt.formatDateTime(
            systemClock.date,
            preferences.use24HourClock ? "hh:mm" : "h:mm AP"
        )
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    function selectedPlayerIndex() {
        var players = Mpris.players.values
        for (var i = 0; i < players.length; i++) {
            if (players[i] === player)
                return i
        }
        return -1
    }

    function formatTime(seconds) {
        var safeSeconds = Math.max(0, Math.floor(Number(seconds) || 0))
        var minutes = Math.floor(safeSeconds / 60)
        var remainder = safeSeconds % 60
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
    }

    onPlayerChanged: paletteIndex = 0

    ColorQuantizer {
        id: albumPalette
        source: playerRoot.player ? playerRoot.player.trackArtUrl : ""
        depth: 3
        rescaleSize: 48
    }

    Connections {
        target: playerRoot.player
        function onTrackArtUrlChanged() {
            playerRoot.paletteIndex = 0
        }
        function onTrackTitleChanged() {
            compactTitleScroll.restart()
        }
        function onTrackArtistChanged() {
            compactTitleScroll.restart()
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: hideTimer
        interval: 350
        repeat: false
        onTriggered: playerRoot.isExpanded = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: playerRoot.player !== null && playerRoot.player.isPlaying
        onTriggered: playerRoot.player.positionChanged()
    }

    Timer {
        interval: 1800
        repeat: true
        running: playerRoot.player !== null
            && playerRoot.player.isPlaying
            && albumPalette.colors.length > 1
        onTriggered: playerRoot.paletteIndex = (playerRoot.paletteIndex + 1) % albumPalette.colors.length
    }

    Rectangle {
        width: playerRoot.isExpanded
            ? Math.max(0, Math.min(parent.width - 24, 360))
            : Math.min(parent.width - 24, playerRoot.hasActiveMusic ? 330 : 200)
        height: playerRoot.isExpanded ? (playerRoot.showLauncher ? 372 : 164) : 33
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 8
        }
        color: playerRoot.isExpanded ? Qt.darker(playerRoot.accentColor, 5.5) : "#090a0c"
        border.color: playerRoot.isExpanded
            ? Qt.darker(playerRoot.accentColor, 1.7)
            : Qt.rgba(playerRoot.accentColor.r, playerRoot.accentColor.g, playerRoot.accentColor.b, 0.42)
        border.width: 1
        radius: playerRoot.isExpanded ? 24 : 17
        clip: true

        Behavior on color {
            ColorAnimation { duration: 700 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 700 }
        }

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop()
                    playerRoot.isExpanded = true
                } else if (playerRoot.isExpanded) {
                    hideTimer.start()
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: !playerRoot.isExpanded

            Item {
                width: 34
                height: 23
                visible: playerRoot.player !== null && playerRoot.player.isPlaying
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 6

                    delegate: Rectangle {
                        required property int index
                        property int restHeight: [5, 9, 16, 11, 7, 13][index]

                        x: index * 5
                        y: (parent.height - height) / 2
                        width: 2
                        height: restHeight
                        radius: 2
                        color: playerRoot.paletteColor(index)

                        Behavior on color {
                            ColorAnimation { duration: 650 }
                        }

                        SequentialAnimation on height {
                            running: playerRoot.player !== null && playerRoot.player.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 4 + ((index * 9) % 16)
                                duration: 260 + index * 52
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 4 + ((index * 13) % 17)
                                duration: 300 + index * 43
                                easing.type: Easing.InOutSine
                            }
                            onStopped: parent.height = parent.restHeight
                        }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                visible: playerRoot.player !== null && playerRoot.player.isPlaying
                radius: 14
                color: "#101115"
                border.color: playerRoot.accentColor
                border.width: 1
                clip: true

                Behavior on border.color {
                    ColorAnimation { duration: 650 }
                }

                CircularArtwork {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: playerRoot.player ? playerRoot.player.trackArtUrl : ""
                    placeholderColor: playerRoot.accentColor
                    placeholderFontPixelSize: 13
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 11
                    color: "transparent"
                    border.color: "#55565b"
                    border.width: 1
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    radius: 8
                    color: "transparent"
                    border.color: "#424349"
                    border.width: 1
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 3
                    height: 3
                    radius: 2
                    color: "#e4e5e8"
                }

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 7200
                    loops: Animation.Infinite
                    running: playerRoot.player !== null && playerRoot.player.isPlaying
                }
            }

            Item {
                id: compactTitleViewport
                anchors.left: parent.left
                anchors.leftMargin: 54
                anchors.right: playingClock.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                clip: true
                visible: playerRoot.hasActiveMusic

                Text {
                    id: compactTrackText
                    y: (parent.height - height) / 2
                    text: playerRoot.player
                        ? (playerRoot.player.trackTitle || playerRoot.player.identity || "Now playing")
                            + (playerRoot.player.trackArtist ? "  |  " + playerRoot.player.trackArtist : "")
                        : ""
                    color: "#f4f4f5"
                    font.family: "Sans Serif"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    wrapMode: Text.NoWrap
                }

                SequentialAnimation {
                    id: compactTitleScroll
                    running: playerRoot.hasActiveMusic
                    loops: Animation.Infinite

                    ScriptAction {
                        script: compactTrackText.x = compactTitleViewport.width
                    }
                    PauseAnimation { duration: 350 }
                    NumberAnimation {
                        target: compactTrackText
                        property: "x"
                        to: -compactTrackText.implicitWidth
                        duration: Math.max(2600, compactTrackText.implicitWidth * 42)
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 450 }
                }
            }

            Text {
                id: playingClock
                anchors.right: parent.right
                anchors.rightMargin: 36
                anchors.verticalCenter: parent.verticalCenter
                text: playerRoot.clockText()
                color: "#f4f4f5"
                font.family: "Sans Serif"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                visible: playerRoot.hasActiveMusic
            }

            Text {
                anchors.centerIn: parent
                text: playerRoot.clockText()
                color: "#f4f4f5"
                font.family: "Sans Serif"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                visible: !playerRoot.hasActiveMusic
            }

            TapHandler {
                onTapped: {
                    playerRoot.isLauncherOpen = true
                    playerRoot.isExpanded = true
                }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 9
            visible: playerRoot.isExpanded && playerRoot.hasActiveMusic && !playerRoot.isLauncherOpen

            Item {
                width: parent.width
                height: 58

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 58
                    height: 58
                    radius: 29
                    color: "#292b30"
                    border.color: playerRoot.accentColor
                    border.width: 1
                    clip: true

                    Behavior on border.color {
                        ColorAnimation { duration: 650 }
                    }

                    CircularArtwork {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: playerRoot.player ? playerRoot.player.trackArtUrl : ""
                        placeholderColor: "#f2f2f4"
                        placeholderFontPixelSize: 28
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        radius: 22
                        color: "transparent"
                        border.color: "#55565b"
                        border.width: 1
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 31
                        height: 31
                        radius: 16
                        color: "transparent"
                        border.color: "#424349"
                        border.width: 1
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 5
                        height: 5
                        radius: 3
                        color: "#e4e5e8"
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 7200
                        loops: Animation.Infinite
                        running: playerRoot.player !== null && playerRoot.player.isPlaying
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 72
                    anchors.right: playerPicker.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        width: parent.width
                        text: playerRoot.player
                            ? (playerRoot.player.trackTitle || "Unknown title")
                            : ""
                        color: "#f4f4f5"
                        font.family: "Sans Serif"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: playerRoot.player
                            ? (playerRoot.player.trackArtist || "Unknown artist")
                            : ""
                        color: "#a1a2a7"
                        font.family: "Sans Serif"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                Row {
                    width: 36
                    height: 22
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    anchors.right: parent.right
                    spacing: 4

                    Repeater {
                        model: 5

                        delegate: Rectangle {
                            required property int index
                            property int restHeight: [6, 12, 17, 9, 14][index]

                            width: 4
                            height: restHeight
                            x: index * 8
                            y: (parent.height - height) / 2
                            radius: 2
                            color: playerRoot.accentColor

                            Behavior on color {
                                ColorAnimation { duration: 700 }
                            }

                            SequentialAnimation on height {
                                running: playerRoot.player !== null && playerRoot.player.isPlaying
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 4 + ((index * 7) % 14)
                                    duration: 280 + index * 55
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 5 + ((index * 9) % 12)
                                    duration: 320 + index * 45
                                    easing.type: Easing.InOutSine
                                }
                                onStopped: parent.height = parent.restHeight
                            }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: playerRoot.clockText()
                    color: "#a1a2a7"
                    font.family: "Sans Serif"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                ComboBox {
                    id: playerPicker
                    width: 108
                    height: 28
                    anchors.top: parent.top
                    anchors.right: appsButton.left
                    anchors.rightMargin: 8
                    model: Mpris.players.values
                    textRole: "identity"
                    currentIndex: playerRoot.selectedPlayerIndex()
                    enabled: Mpris.players.values.length > 1
                    onActivated: index => {
                        var selected = Mpris.players.values[index]
                        if (selected) {
                            playerRoot.selectedPlayerId = selected.dbusName
                            playerRoot.paletteIndex = 0
                        }
                    }

                    contentItem: Text {
                        leftPadding: 10
                        rightPadding: 24
                        text: playerRoot.player ? playerRoot.player.identity : "No player"
                        color: playerRoot.accentColor
                        font.family: "Sans Serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    indicator: Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▾"
                        color: playerRoot.accentColor
                        font.pixelSize: 12
                    }

                    background: Rectangle {
                        radius: 8
                        color: "#25262b"
                        border.color: Qt.darker(playerRoot.accentColor, 1.5)
                    }

                    delegate: ItemDelegate {
                        required property var modelData
                        required property int index
                        width: playerPicker.width
                        highlighted: playerPicker.highlightedIndex === index

                        contentItem: Text {
                            text: modelData.identity
                            color: highlighted ? "#111216" : "#f4f4f5"
                            font.family: "Sans Serif"
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            radius: 5
                            color: highlighted ? playerRoot.accentColor : "transparent"
                        }
                    }

                    popup.background: Rectangle {
                        color: "#202126"
                        border.color: playerRoot.accentColor
                        radius: 8
                    }
                }

                Button {
                    id: appsButton
                    width: 48
                    height: 28
                    anchors.top: parent.top
                    anchors.right: parent.right
                    text: "Apps"
                    onClicked: playerRoot.isLauncherOpen = true

                    contentItem: Text {
                        text: parent.text
                        color: playerRoot.accentColor
                        font.family: "Sans Serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: "#25262b"
                        border.color: Qt.darker(playerRoot.accentColor, 1.5)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 4

                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: "#3c3e44"

                    Rectangle {
                        width: playerRoot.player && playerRoot.player.length > 0
                            ? Math.max(0, Math.min(1, playerRoot.player.position / playerRoot.player.length)) * parent.width
                            : 0
                        height: parent.height
                        radius: parent.radius
                        color: playerRoot.accentColor

                        Behavior on color {
                            ColorAnimation { duration: 700 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: playerRoot.player !== null
                            && playerRoot.player.canSeek
                            && playerRoot.player.positionSupported
                            && playerRoot.player.length > 0
                        onClicked: mouse => {
                            playerRoot.player.position = (mouse.x / width) * playerRoot.player.length
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 12

                    Text {
                        anchors.left: parent.left
                        text: playerRoot.player ? playerRoot.formatTime(playerRoot.player.position) : "0:00"
                        color: "#a1a2a7"
                        font.family: "Sans Serif"
                        font.pixelSize: 10
                    }
                    Text {
                        anchors.right: parent.right
                        text: playerRoot.player && playerRoot.player.length > 0
                            ? playerRoot.formatTime(playerRoot.player.length)
                            : "0:00"
                        color: "#a1a2a7"
                        font.family: "Sans Serif"
                        font.pixelSize: 10
                    }
                }
            }

            Item {
                width: 150
                height: 28
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "|◀"
                    color: playerRoot.player && playerRoot.player.canGoPrevious ? "#f4f4f5" : "#686a70"
                    font.pixelSize: 19

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        enabled: playerRoot.player !== null && playerRoot.player.canGoPrevious
                        onClicked: playerRoot.player.previous()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: playerRoot.player && playerRoot.player.isPlaying ? "Ⅱ" : "▶"
                    color: "#f4f4f5"
                    font.pixelSize: 20

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        enabled: playerRoot.player !== null && playerRoot.player.canTogglePlaying
                        onClicked: playerRoot.player.togglePlaying()
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▶|"
                    color: playerRoot.player && playerRoot.player.canGoNext ? "#f4f4f5" : "#686a70"
                    font.pixelSize: 19

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        enabled: playerRoot.player !== null && playerRoot.player.canGoNext
                        onClicked: playerRoot.player.next()
                    }
                }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 9
            visible: playerRoot.isExpanded && playerRoot.showLauncher

            Row {
                width: parent.width
                height: 28
                spacing: 8

                Text {
                    width: parent.width - closeLauncher.width - parent.spacing
                    text: "Launch an app"
                    color: "#f4f4f5"
                    font.family: "Sans Serif"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Button {
                    id: closeLauncher
                    width: 50
                    height: 28
                    text: "Back"
                    onClicked: playerRoot.isLauncherOpen = false

                    contentItem: Text {
                        text: parent.text
                        color: "#d5d6da"
                        font.family: "Sans Serif"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 7
                        color: "#25262b"
                    }
                }
            }

            Row {
                width: parent.width
                height: 28
                spacing: 6

                Button {
                    width: 64
                    height: 28
                    text: "All"
                    onClicked: preferences.musicOnly = false
                    contentItem: Text {
                        text: parent.text
                        color: preferences.musicOnly ? "#a1a2a7" : playerRoot.accentColor
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: "#25262b"
                        border.color: preferences.musicOnly ? "#41434a" : playerRoot.accentColor
                    }
                }

                Button {
                    width: 76
                    height: 28
                    text: "Music"
                    onClicked: preferences.musicOnly = true
                    contentItem: Text {
                        text: parent.text
                        color: preferences.musicOnly ? playerRoot.accentColor : "#a1a2a7"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: "#25262b"
                        border.color: preferences.musicOnly ? playerRoot.accentColor : "#41434a"
                    }
                }

                Text {
                    width: 38
                    height: 28
                    text: "Clock"
                    color: "#a1a2a7"
                    font.family: "Sans Serif"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }

                Button {
                    width: 48
                    height: 28
                    text: "12h"
                    onClicked: preferences.use24HourClock = false
                    contentItem: Text {
                        text: parent.text
                        color: preferences.use24HourClock ? "#a1a2a7" : playerRoot.accentColor
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: "#25262b"
                        border.color: preferences.use24HourClock ? "#41434a" : playerRoot.accentColor
                    }
                }

                Button {
                    width: 48
                    height: 28
                    text: "24h"
                    onClicked: preferences.use24HourClock = true
                    contentItem: Text {
                        text: parent.text
                        color: preferences.use24HourClock ? playerRoot.accentColor : "#a1a2a7"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: "#25262b"
                        border.color: preferences.use24HourClock ? playerRoot.accentColor : "#41434a"
                    }
                }
            }

            TextField {
                id: appSearch
                width: parent.width
                height: 32
                placeholderText: "Search apps"
                color: "#f4f4f5"
                placeholderTextColor: "#85868d"
                font.family: "Sans Serif"
                font.pixelSize: 12
                selectByMouse: true
                background: Rectangle {
                    radius: 8
                    color: "#202126"
                    border.color: "#41434a"
                }
            }

            ListView {
                width: parent.width
                height: parent.height - 118
                clip: true
                spacing: 3
                model: {
                    var query = appSearch.text.trim().toLowerCase()
                    return DesktopEntries.applications.values.filter(function(entry) {
                        var appName = String(entry.name || "").toLowerCase()
                        var matchesQuery = appName.indexOf(query) !== -1
                        var categories = entry.categories || []
                        var isMusic = categories.indexOf("AudioVideo") !== -1
                            || categories.indexOf("Audio") !== -1
                            || categories.indexOf("Music") !== -1
                        return matchesQuery && (!preferences.musicOnly || isMusic)
                    })
                }

                delegate: ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    height: 38
                    onClicked: {
                        modelData.execute()
                        playerRoot.isLauncherOpen = false
                        playerRoot.isExpanded = false
                    }

                    contentItem: Row {
                        spacing: 10
                        Image {
                            width: 22
                            height: 22
                            anchors.verticalCenter: parent.verticalCenter
                            source: modelData.icon ? "image://icon/" + modelData.icon : ""
                            sourceSize.width: 22
                            sourceSize.height: 22
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            width: parent.width - 32
                            height: parent.height
                            text: modelData.name
                            color: "#f0f0f2"
                            font.family: "Sans Serif"
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    background: Rectangle {
                        radius: 6
                        color: parent.hovered ? "#34363d" : "transparent"
                    }
                }
            }
        }
    }
}