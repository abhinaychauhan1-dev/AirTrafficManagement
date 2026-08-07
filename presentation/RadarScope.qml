import QtQuick

Item {
    id: scope

    property var airTaxis
    property int rangeNm: 80
    property bool sweepEnabled: true
    property bool weatherEnabled: true
    property bool routesEnabled: true
    property bool sectorBoundariesEnabled: true
    property bool approachCorridorsEnabled: true
    property bool geofencesEnabled: true
    property int selectedTrack: 0
    property color phosphor: "#6fffc1"
    property color mutedPhosphor: "#3b9d7d"
    property bool atMinimumRange: false
    property bool atMaximumRange: false
    property var boundaryPolyline
    property var routeOverlays
    property var weatherCells
    property real viewCenterX: .5
    property real viewCenterY: .51
    readonly property real zoomScale: 20 / rangeNm

    signal trackSelected(int index)
    signal rangeStepRequested(int steps)
    signal trackFocusRequested(int index)

    clip: true

    function mapX(normalizedX) {
        return width * 0.5 + (normalizedX - viewCenterX) * width * zoomScale
    }

    function mapY(normalizedY) {
        return height * 0.51 + (normalizedY - viewCenterY) * height * zoomScale
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => scope.rangeStepRequested(event.angleDelta.y > 0 ? -1 : 1)
    }

    onRangeNmChanged: radarCanvas.requestPaint()
    onSweepEnabledChanged: radarCanvas.requestPaint()
    onWeatherEnabledChanged: radarCanvas.requestPaint()
    onRoutesEnabledChanged: radarCanvas.requestPaint()
    onSectorBoundariesEnabledChanged: radarCanvas.requestPaint()
    onApproachCorridorsEnabledChanged: radarCanvas.requestPaint()
    onGeofencesEnabledChanged: radarCanvas.requestPaint()
    onViewCenterXChanged: radarCanvas.requestPaint()
    onViewCenterYChanged: radarCanvas.requestPaint()
    onBoundaryPolylineChanged: radarCanvas.requestPaint()
    onRouteOverlaysChanged: radarCanvas.requestPaint()
    onWeatherCellsChanged: radarCanvas.requestPaint()

    Rectangle {
        anchors.fill: parent
        color: "#07110f"
    }

    Canvas {
        id: radarCanvas
        anchors.fill: parent
        antialiasing: true

        property real sweepAngle

        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            const cx = w * 0.5
            const cy = h * 0.51
            const radius = Math.min(w, h) * 0.43
            ctx.reset()

            const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius)
            glow.addColorStop(0, "#0d2a22")
            glow.addColorStop(0.75, "#091a16")
            glow.addColorStop(1, "#06100e")
            ctx.fillStyle = glow
            ctx.fillRect(0, 0, w, h)

            ctx.strokeStyle = "#285247"
            ctx.lineWidth = 1
            for (let ring = 1; ring <= 4; ++ring) {
                ctx.beginPath()
                ctx.arc(cx, cy, radius * ring / 4, 0, Math.PI * 2)
                ctx.stroke()

                ctx.fillStyle = "#587b71"
                ctx.font = "12px Consolas"
                ctx.fillText(Math.round(rangeNm * ring / 4), cx + 5, cy - radius * ring / 4 + 12)
            }
            for (let angle = 0; angle < Math.PI; angle += Math.PI / 6) {
                ctx.beginPath()
                ctx.moveTo(cx - Math.cos(angle) * radius, cy - Math.sin(angle) * radius)
                ctx.lineTo(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius)
                ctx.stroke()
            }

            ctx.fillStyle = "#7fa99d"
            ctx.font = "14px Consolas"
            ctx.fillText("N", cx - 4, cy - radius - 8)

            ctx.beginPath()
            ctx.moveTo(cx, cy - radius - 4)
            ctx.lineTo(cx - 4, cy - radius + 4)
            ctx.lineTo(cx + 4, cy - radius + 4)
            ctx.closePath()
            ctx.fillStyle = phosphor
            ctx.fill()

            if (sectorBoundariesEnabled) {
                ctx.strokeStyle = "#579b82"
                ctx.lineWidth = 1.5
                ctx.beginPath()
                boundaryPolyline.forEach((point, index) => {
                    const px = scope.mapX(point.x)
                    const py = scope.mapY(point.y)
                    if (index === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
                })
                ctx.stroke()
            }

            if (approachCorridorsEnabled) {
                const corridors = [
                    [{x: .18, y: .80}, {x: .48, y: .52}, {x: .79, y: .27}],
                    [{x: .28, y: .18}, {x: .53, y: .48}, {x: .83, y: .72}]
                ]
                ctx.setLineDash([10, 5])
                ctx.lineWidth = 4
                ctx.strokeStyle = "rgba(115,217,255,.55)"
                corridors.forEach(corridor => {
                    ctx.beginPath()
                    corridor.forEach((point, index) => index === 0
                        ? ctx.moveTo(scope.mapX(point.x), scope.mapY(point.y))
                        : ctx.lineTo(scope.mapX(point.x), scope.mapY(point.y)))
                    ctx.stroke()
                })
                ctx.setLineDash([])
            }

            if (geofencesEnabled) {
                const geofences = [{x: .32, y: .44, radius: .075}, {x: .68, y: .62, radius: .06}]
                ctx.fillStyle = "rgba(255,116,108,.10)"
                ctx.strokeStyle = "rgba(255,116,108,.82)"
                ctx.lineWidth = 1.5
                geofences.forEach(geofence => {
                    ctx.beginPath()
                    ctx.arc(scope.mapX(geofence.x), scope.mapY(geofence.y), geofence.radius * w * scope.zoomScale, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.stroke()
                })
            }

            if (routesEnabled) {
                ctx.setLineDash([7, 7])
                ctx.strokeStyle = "#315f52"
                routeOverlays.forEach(route => {
                    ctx.beginPath()
                    route.forEach((point, index) => index === 0
                        ? ctx.moveTo(scope.mapX(point.x), scope.mapY(point.y))
                        : ctx.lineTo(scope.mapX(point.x), scope.mapY(point.y)))
                    ctx.stroke()
                })
                ctx.setLineDash([])
            }

            if (weatherEnabled) {
                weatherCells.forEach(cell => {
                    ctx.globalAlpha = 0.58
                    ctx.fillStyle = cell.color
                    ctx.beginPath()
                    ctx.arc(scope.mapX(cell.x), scope.mapY(cell.y), cell.radius * radius * scope.zoomScale, 0, Math.PI * 2)
                    ctx.fill()
                })
                ctx.globalAlpha = 1
            }

            if (sweepEnabled) {
                const sweep = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius)
                sweep.addColorStop(0, "rgba(91,255,188,.04)")
                sweep.addColorStop(1, "rgba(91,255,188,.25)")
                ctx.fillStyle = sweep
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.arc(cx, cy, radius, sweepAngle - 0.22, sweepAngle)
                ctx.closePath()
                ctx.fill()
                ctx.strokeStyle = "rgba(111,255,193,.58)"
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx + Math.cos(sweepAngle) * radius, cy + Math.sin(sweepAngle) * radius)
                ctx.stroke()
            }
        }

        NumberAnimation on sweepAngle {
            from: -Math.PI
            to: Math.PI
            duration: 6000
            loops: Animation.Infinite
            running: scope.sweepEnabled
        }
        onSweepAngleChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Repeater {
        model: scope.airTaxis

        Item {
            id: trackMarker
            required property int index
            required property string callSign
            required property string level
            required property int speed
            required property int heading
            required property int verticalRate
            required property real positionX
            required property real positionY
            required property bool alert
            x: scope.mapX(positionX) - 7
            y: scope.mapY(positionY) - 7
            width: 142
            height: 58
            scale: markerHover.hovered || index === scope.selectedTrack ? 1.04 : 1
            z: index === scope.selectedTrack ? 3 : (markerHover.hovered ? 2 : 1)

            Behavior on scale { NumberAnimation { duration: 100 } }

            Rectangle {
                x: 6
                y: -22
                width: 1
                height: 28
                rotation: trackMarker.heading
                transformOrigin: Item.Bottom
                color: trackMarker.alert ? "#ffb443" : scope.mutedPhosphor
                opacity: markerHover.hovered || trackMarker.index === scope.selectedTrack ? 0.9 : 0.55
            }

            Rectangle {
                x: 2
                y: 2
                width: 10
                height: 10
                rotation: 45
                color: trackMarker.alert ? "#ffb443" : (trackMarker.index === scope.selectedTrack ? "#ffffff" : scope.phosphor)
            }
            Rectangle {
                x: 7
                y: -13
                width: 1
                height: 18
                rotation: 28
                transformOrigin: Item.Bottom
                color: trackMarker.alert ? "#ffb443" : scope.mutedPhosphor
            }
            Rectangle {
                x: 19
                y: 0
                width: 116
                height: 42
                color: trackMarker.index === scope.selectedTrack ? "#163b31" : "#091713"
                border.color: trackMarker.alert ? "#ffb443" : (trackMarker.index === scope.selectedTrack ? scope.phosphor : "#346a59")
                border.width: 1

                Text {
                    anchors.fill: parent
                    anchors.margins: 4
                    text: trackMarker.callSign + "  " + trackMarker.level + "\n" + trackMarker.speed + "KT  " + (trackMarker.verticalRate > 0 ? "+" : "") + trackMarker.verticalRate
                    color: trackMarker.alert ? "#ffcc75" : (trackMarker.index === scope.selectedTrack ? "#ffffff" : scope.phosphor)
                    font.family: "Consolas"
                    font.pixelSize: 12
                    lineHeight: 0.9
                }
            }
            HoverHandler {
                id: markerHover
                cursorShape: Qt.PointingHandCursor
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: scope.trackSelected(trackMarker.index)
                onDoubleClicked: scope.trackFocusRequested(trackMarker.index)
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 8
        height: 8
        radius: 4
        color: scope.phosphor
        border.color: "#d6fff0"
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        width: 194
        height: 36
        color: "#d00a1714"
        border.color: "#2b4b43"
        radius: 3

        Text {
            anchors.centerIn: parent
            text: scope.rangeNm + " NM  •  UAM NETWORK RANGE"
            color: (scope.atMinimumRange || scope.atMaximumRange) ? "#ffb443" : "#7f9690"
            font.family: "Consolas"
            font.pixelSize: 11
            font.bold: scope.atMinimumRange || scope.atMaximumRange
        }
    }
}
