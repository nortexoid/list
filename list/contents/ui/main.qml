/*
 KWin - the KDE window manager
 This file is part of the KDE project.

 SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>

 SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kwin 2.0 as KWin

KWin.Switcher {
    id: tabBox
    currentIndex: compactListView.currentIndex

    /**
    * Returns the caption with adjustments for minimized items.
    * @param caption the original caption
    * @param mimized whether the item is minimized
    * @return Caption adjusted for minimized state
    **/
    function itemCaption(caption, minimized) {
        if (minimized) {
            return "(" + caption + ")";
        }
        return caption;
    }

    TextMetrics {
        id: textMetrics
        property string longestCaption: tabBox.model.longestCaption()
        text: itemCaption(longestCaption, true)
        font.bold: false
    }

    onVisibleChanged: {
        if (visible) {
            // Window captions may have change completely
            textMetrics.longestCaption = tabBox.model.longestCaption();
        }
    }
    onModelChanged: {
        textMetrics.longestCaption = tabBox.model.longestCaption();
    }

    PlasmaCore.Dialog {
        id: dialog
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - dialogMainItem.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem.height * 0.5

        mainItem: Item {
            id: dialogMainItem

            property int optimalWidth: textMetrics.width + PlasmaCore.Units.iconSizes.medium + 2 * dialogMainItem.textMargin + hoverItem.margins.right + hoverItem.margins.left
            property int optimalHeight: compactListView.rowHeight * compactListView.count
            width: Math.min(Math.max(tabBox.screenGeometry.width * 0.2, optimalWidth), tabBox.screenGeometry.width * 0.8)
            height: Math.min(optimalHeight, tabBox.screenGeometry.height * 0.8)
            focus: true

            property int textMargin: PlasmaCore.Units.mediumSpacing

            // just to get the margin sizes
            PlasmaCore.FrameSvgItem {
                id: hoverItem
                imagePath: "widgets/viewitem"
                prefix: "hover"
                visible: false
            }

            // delegate
            Component {
                id: listDelegate
                Item {
                    id: delegateItem
                    width: compactListView.width
                    height: compactListView.rowHeight
                    opacity: minimized ? 0.6 : 1.0
                    QIconItem {
                        id: iconItem
                        icon: model.icon
                        width: PlasmaCore.Units.iconSizes.medium
                        height: PlasmaCore.Units.iconSizes.medium
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: hoverItem.margins.left
                        }
                    }
                    PlasmaComponents3.Label {
                        id: captionItem
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        text: itemCaption(caption, minimized)
                        font.weight: index === compactListView.currentIndex ? Font.Normal : Font.Normal
                        elide: Text.ElideMiddle
                        anchors {
                            left: iconItem.right
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                            topMargin: hoverItem.margins.top
                            rightMargin: hoverItem.margins.right
                            bottomMargin: hoverItem.margins.bottom
                            leftMargin: 2 * dialogMainItem.textMargin
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            compactListView.currentIndex = index;
                        }
                    }
                }
            }
            ListView {
                id: compactListView

                // the maximum text width + icon item width (32 + 4 margin) + margins for hover item
                property int rowHeight: Math.max(PlasmaCore.Units.iconSizes.large, textMetrics.height + hoverItem.margins.top + hoverItem.margins.bottom)
                anchors {
                    fill: parent
                }
                model: tabBox.model
                clip: true
                delegate: listDelegate
                highlight: PlasmaCore.FrameSvgItem {
                    id: highlightItem
                    imagePath: "widgets/viewitem"
                    prefix: "hover"
                    width: compactListView.width
                }
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                Connections {
                    target: tabBox
                    function onCurrentIndexChanged() {compactListView.currentIndex = tabBox.currentIndex;}
                }
            }
            /*
            * Key navigation on outer item for two reasons:
            * @li we have to emit the change signal
            * @li on multiple invocation it does not work on the list view. Focus seems to be lost.
            **/
            Keys.onPressed: {
                if (event.key == Qt.Key_Up) {
                    compactListView.decrementCurrentIndex();
                } else if (event.key == Qt.Key_Down) {
                    compactListView.incrementCurrentIndex();
                }
            }
        }
    }
}
