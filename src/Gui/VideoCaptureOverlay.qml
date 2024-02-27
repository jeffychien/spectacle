/* SPDX-FileCopyrightText: 2023 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami
import org.kde.spectacle.private

MouseArea {
    id: root
    readonly property rect viewportRect: G.mapFromPlatformRect(screenToFollow.geometry,
                                                               screenToFollow.devicePixelRatio)
    focus: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true
    anchors.fill: parent
    enabled: !VideoPlatform.isRecording

    component Overlay: Rectangle {
        color: Settings.useLightMaskColor ? "white" : "black"
        opacity: if (VideoPlatform.isRecording) {
            return 0
        } else if (Selection.empty) {
            return 0.25
        } else {
            return 0.5
        }
        LayoutMirroring.enabled: false
        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }
    Overlay { // top / full overlay when nothing selected
        id: topOverlay
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: selectionRectangle.visible ? selectionRectangle.top : parent.bottom
    }
    Overlay { // bottom
        id: bottomOverlay
        anchors.left: parent.left
        anchors.top: selectionRectangle.visible ? selectionRectangle.bottom : undefined
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: selectionRectangle.visible && height > 0
    }
    Overlay { // left
        anchors {
            left: topOverlay.left
            top: topOverlay.bottom
            right: selectionRectangle.visible ? selectionRectangle.left : undefined
            bottom: bottomOverlay.top
        }
        visible: selectionRectangle.visible && height > 0 && width > 0
    }
    Overlay { // right
        anchors {
            left: selectionRectangle.visible ? selectionRectangle.right : undefined
            top: topOverlay.bottom
            right: topOverlay.right
            bottom: bottomOverlay.top
        }
        visible: selectionRectangle.visible && height > 0 && width > 0
    }

    Rectangle {
        id: selectionRectangle
        color: "transparent"
        border.color: palette.active.highlight
        border.width: contextWindow.dprRound(1)
        visible: !Selection.empty
            && !VideoPlatform.isRecording
            && G.rectIntersects(Qt.rect(x,y,width,height), Qt.rect(0,0,parent.width, parent.height))
        x: dprFloor(Selection.x - border.width - root.viewportRect.x)
        y: dprFloor(Selection.y - border.width - root.viewportRect.y)
        width: dprCeil(Selection.right + border.width - root.viewportRect.x) - x
        height: dprCeil(Selection.bottom + border.width - root.viewportRect.y) - y

        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
    }

    SelectionBackground {
        visible: VideoPlatform.isRecording
        strokeWidth: selectionRectangle.border.width
        // We need to be a bit careful about staying out of the recorded area
        x: dprFloor(Selection.x - strokeWidth - root.viewportRect.x) - 1 / Screen.devicePixelRatio
        y: dprFloor(Selection.y - strokeWidth - root.viewportRect.y) - 1 / Screen.devicePixelRatio
        width: dprCeil(Selection.right + strokeWidth - root.viewportRect.x) - x + 2 / Screen.devicePixelRatio
        height: dprCeil(Selection.bottom + strokeWidth - root.viewportRect.y) - y + 2 / Screen.devicePixelRatio
    }

    Item {
        x: -root.viewportRect.x
        y: -root.viewportRect.y
        enabled: selectionRectangle.enabled
        visible: !VideoPlatform.isRecording

        component SelectionHandle: Handle {
            visible: enabled && selectionRectangle.visible
                && SelectionEditor.dragLocation === SelectionEditor.None
                && G.rectIntersects(Qt.rect(x,y,width,height), root.viewportRect)
            shapePath.fillColor: selectionRectangle.border.color
            shapePath.strokeWidth: 0
            width: Kirigami.Units.gridUnit
            height: width
        }

        SelectionHandle {
            startAngle: 90
            sweepAngle: 270
            x: dprFloor(SelectionEditor.handlesRect.x)
            y: dprFloor(SelectionEditor.handlesRect.y)
        }
        SelectionHandle {
            startAngle: 90
            sweepAngle: 180
            x: dprFloor(SelectionEditor.handlesRect.x)
            y: dprRound(SelectionEditor.handlesRect.y + SelectionEditor.handlesRect.height/2 - height/2)
        }
        SelectionHandle {
            startAngle: 0
            sweepAngle: 270
            x: dprFloor(SelectionEditor.handlesRect.x)
            y: dprCeil(SelectionEditor.handlesRect.y + SelectionEditor.handlesRect.height - height)
        }
        SelectionHandle {
            startAngle: 180
            sweepAngle: 180
            x: dprRound(SelectionEditor.handlesRect.x + SelectionEditor.handlesRect.width/2 - width/2)
            y: dprFloor(SelectionEditor.handlesRect.y)
        }
        SelectionHandle {
            startAngle: 0
            sweepAngle: 180
            x: dprRound(SelectionEditor.handlesRect.x + SelectionEditor.handlesRect.width/2 - width/2)
            y: dprCeil(SelectionEditor.handlesRect.y + SelectionEditor.handlesRect.height - height)
        }
        SelectionHandle {
            startAngle: 270
            sweepAngle: 180
            x: dprCeil(SelectionEditor.handlesRect.x + SelectionEditor.handlesRect.width - width)
            y: dprRound(SelectionEditor.handlesRect.y + SelectionEditor.handlesRect.height/2 - height/2)
        }
        SelectionHandle {
            startAngle: 180
            sweepAngle: 270
            x: dprCeil(SelectionEditor.handlesRect.x + SelectionEditor.handlesRect.width - width)
            y: dprFloor(SelectionEditor.handlesRect.y)
        }
        SelectionHandle {
            startAngle: 270
            sweepAngle: 270
            x: dprCeil(SelectionEditor.handlesRect.x + SelectionEditor.handlesRect.width - width)
            y: dprCeil(SelectionEditor.handlesRect.y + SelectionEditor.handlesRect.height - height)
        }
    }

    Item { // separate item because it needs to be above the stuff defined above
        visible: !VideoPlatform.isRecording
        width: SelectionEditor.screensRect.width
        height: SelectionEditor.screensRect.height
        x: -root.viewportRect.x
        y: -root.viewportRect.y

        // Size ToolTip
        SizeLabel {
            id: ssToolTip
            readonly property int valignment: {
                if (Selection.empty) {
                    return Qt.AlignVCenter
                }
                const margin = Kirigami.Units.mediumSpacing * 2
                const w = width + margin
                const h = height + margin
                if (SelectionEditor.handlesRect.top >= h) {
                    return Qt.AlignTop
                } else if (SelectionEditor.screensRect.height - SelectionEditor.handlesRect.bottom >= h) {
                    return Qt.AlignBottom
                } else {
                    // At the bottom of the inside of the selection rect.
                    return Qt.AlignBaseline
                }
            }
            readonly property bool normallyVisible: !Selection.empty
            Binding on x {
                value: contextWindow.dprRound(Selection.horizontalCenter - ssToolTip.width / 2)
                when: ssToolTip.normallyVisible
                restoreMode: Binding.RestoreNone
            }
            Binding on y {
                value: {
                    let v = 0
                    if (ssToolTip.valignment & Qt.AlignBaseline) {
                        v = Math.min(Selection.bottom, SelectionEditor.handlesRect.bottom - Kirigami.Units.gridUnit)
                            - ssToolTip.height - Kirigami.Units.mediumSpacing * 2
                    } else if (ssToolTip.valignment & Qt.AlignTop) {
                        v = SelectionEditor.handlesRect.top
                            - ssToolTip.height - Kirigami.Units.mediumSpacing * 2
                    } else if (ssToolTip.valignment & Qt.AlignBottom) {
                        v = SelectionEditor.handlesRect.bottom + Kirigami.Units.mediumSpacing * 2
                    } else {
                        v = (root.height - ssToolTip.height) / 2 - parent.y
                    }
                    return contextWindow.dprRound(v)
                }
                when: ssToolTip.normallyVisible
                restoreMode: Binding.RestoreNone
            }
            visible: opacity > 0
            opacity: ssToolTip.normallyVisible
                && G.rectIntersects(Qt.rect(x,y,width,height), root.viewportRect)
            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
            }
            size: G.rawSize(Selection.size, SelectionEditor.devicePixelRatio) // TODO: real pixel size on wayland
            padding: Kirigami.Units.mediumSpacing * 2
            topPadding: padding - QmlUtils.fontMetrics.descent
            bottomPadding: topPadding
            background: FloatingBackground {
                implicitWidth: Math.ceil(parent.contentWidth) + parent.leftPadding + parent.rightPadding
                implicitHeight: Math.ceil(parent.contentHeight) + parent.topPadding + parent.bottomPadding
                color: Qt.rgba(parent.palette.window.r,
                            parent.palette.window.g,
                            parent.palette.window.b, 0.85)
                border.color: Qt.rgba(parent.palette.windowText.r,
                                    parent.palette.windowText.g,
                                    parent.palette.windowText.b, 0.2)
                border.width: contextWindow.dprRound(1)
            }
        }
    }
}
