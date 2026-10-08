import QtQuick

Item {
    id: artwork

    property url source: ""
    property color placeholderColor: "#f2f2f4"
    property int placeholderFontPixelSize: 18
    property bool artworkReady: false

    implicitWidth: 48
    implicitHeight: implicitWidth

    function loadArtwork() {
        artworkReady = false
        if (source.toString().length === 0)
            return
        if (!artworkCanvas.isImageLoaded(source) && !artworkCanvas.isImageLoading(source))
            artworkCanvas.loadImage(source)
    }

    onSourceChanged: loadArtwork()

    Canvas {
        id: artworkCanvas
        anchors.fill: parent
        renderTarget: Canvas.Image

        Component.onCompleted: {
            artwork.loadArtwork()
        }

        onImageLoaded: {
            artwork.artworkReady = artworkCanvas.isImageLoaded(artwork.source)
            requestPaint()
        }

        onPaint: {
            var context = getContext("2d")
            context.clearRect(0, 0, width, height)

            if (!artwork.artworkReady)
                return

            context.save()
            context.beginPath()
            context.arc(width / 2, height / 2, Math.min(width, height) / 2, 0, Math.PI * 2, false)
            context.closePath()
            context.clip()
            context.drawImage(artwork.source, 0, 0, width, height)
            context.restore()
        }
    }

    Text {
        anchors.centerIn: parent
        text: "♪"
        color: artwork.placeholderColor
        font.pixelSize: artwork.placeholderFontPixelSize
        visible: !artwork.artworkReady
    }
}