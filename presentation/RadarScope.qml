import QtQuick

Item {
    id: scope

    property var flights
    property int rangeNm: 80
    property bool sweepEnabled: true
    property bool weatherEnabled: true
    property bool routesEnabled: true
    property int selectedTrack: 0
    property color phosphor: "#6fffc1"
    property color mutedPhosphor: "#3b9d7d"

    signal trackSelected(int index)
    signal rangeChangeRequested(int delta)

    clip: true

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => scope.rangeChangeRequested(event.angleDelta.y > 0 ? -20 : 20)
    }

    onRangeNmChanged: radarCanvas.requestPaint()
    onSweepEnabledChanged: radarCanvas.requestPaint()
    onWeatherEnabledChanged: radarCanvas.requestPaint()
    onRoutesEnabledChanged: radarCanvas.requestPaint()

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
            }
            for (let angle = 0; angle < Math.PI; angle += Math.PI / 6) {
                ctx.beginPath()
                ctx.moveTo(cx - Math.cos(angle) * radius, cy - Math.sin(angle) * radius)
                ctx.lineTo(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius)
                ctx.stroke()
            }

            ctx.fillStyle = "#6d9c8d"
            ctx.font = "11px monospace"
            ctx.fillText(rangeNm + " NM", cx + 8, cy - radius + 17)
            ctx.fillText("N", cx - 4, cy - radius - 8)

            ctx.strokeStyle = "#406d5d"
            ctx.lineWidth = 1.5
            const boundary = [[.08,.60],[.17,.48],[.28,.43],[.38,.28],[.52,.31],[.64,.19],[.76,.30],[.88,.25]]
            ctx.beginPath()
            boundary.forEach((point, index) => {
                const px = point[0] * w
                const py = point[1] * h
                if (index === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
            })
            ctx.stroke()

            if (routesEnabled) {
                ctx.setLineDash([7, 7])
                ctx.strokeStyle = "#315f52"
                const routes = [
                    [[.08,.82],[.32,.58],[.53,.48],[.93,.24]],
                    [[.12,.20],[.34,.38],[.56,.51],[.90,.76]],
                    [[.31,.93],[.43,.64],[.52,.51],[.65,.10]]
                ]
                routes.forEach(route => {
                    ctx.beginPath()
                    route.forEach((point, index) => index === 0
                        ? ctx.moveTo(point[0] * w, point[1] * h)
                        : ctx.lineTo(point[0] * w, point[1] * h))
                    ctx.stroke()
                })
                ctx.setLineDash([])
            }

            if (weatherEnabled) {
                const cells = [[.28,.66,.10,"#385f31"],[.30,.65,.065,"#7f7b25"],[.74,.33,.09,"#305b38"],[.76,.34,.045,"#976f22"]]
                cells.forEach(cell => {
                    ctx.globalAlpha = 0.58
                    ctx.fillStyle = cell[3]
                    ctx.beginPath()
                    ctx.arc(cell[0] * w, cell[1] * h, cell[2] * radius, 0, Math.PI * 2)
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
        model: scope.flights

        Item {
            id: trackMarker
            required property int index
            required property string callSign
            required property string level
            required property int speed
            required property real positionX
            required property real positionY
            required property bool alert
            x: positionX * scope.width - 7
            y: positionY * scope.height - 7
            width: 122
            height: 52

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
                width: 96
                height: 36
                color: trackMarker.index === scope.selectedTrack ? "#163b31" : "#091713"
                border.color: trackMarker.alert ? "#ffb443" : (trackMarker.index === scope.selectedTrack ? scope.phosphor : "#346a59")
                border.width: 1

                Text {
                    anchors.fill: parent
                    anchors.margins: 4
                    text: trackMarker.callSign + "  " + trackMarker.level + "\n" + trackMarker.speed + "KT  -0"
                    color: trackMarker.alert ? "#ffcc75" : (trackMarker.index === scope.selectedTrack ? "#ffffff" : scope.phosphor)
                    font.family: "Consolas"
                    font.pixelSize: 10
                    lineHeight: 0.9
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: scope.trackSelected(trackMarker.index)
                onDoubleClicked: {
                    scope.trackSelected(trackMarker.index)
                    scope.rangeChangeRequested(-20)
                }
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
}
