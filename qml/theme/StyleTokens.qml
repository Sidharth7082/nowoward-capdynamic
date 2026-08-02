pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property color transparent: "transparent"
    readonly property color black: "#000000"
    readonly property color white: "#ffffff"
    readonly property color clearBlack: "#00000000"
    readonly property color panel: "#000000"
    readonly property color module: "#1c1c1e"
    readonly property color moduleHover: "#232326"
    readonly property color track: "#2c2c2e"
    readonly property color cardFillActive: "#26272b"
    readonly property color cardFillHover: "#222327"
    readonly property color connectivityCard: "#343437"
    readonly property color connectivityCardHover: "#3a3a3d"
    readonly property color prompt: "#323236"
    readonly property color input: "#212226"
    readonly property color inputBorder: "#3f4046"
    readonly property color secondaryButton: "#4a4b50"
    readonly property color textPrimary: "#f5f5f7"
    readonly property color textPrimaryBright: "#f7f8fb"
    readonly property color textSecondary: "#8e8e93"
    readonly property color textMuted: "#9b9da4"
    readonly property color textSoft: "#9da0a8"
    readonly property color textTertiary: "#7f828a"
    readonly property color textDisabled: "#878a92"
    readonly property color textSubtle: "#8f9198"
    readonly property color textDim: "#b5b7bf"
    readonly property color accent: "#0a84ff"
    readonly property color accentPressed: "#0066d6"
    readonly property color accentSoft: "#6ea8ff"
    readonly property color success: "#34c759"
    readonly property color warning: "#ffcc00"
    readonly property color danger: "#ff3b30"
    readonly property color error: "#ff7c72"
    readonly property color disabledControl: "#868991"
    readonly property color switchOff: "#63656c"
    readonly property color buttonFill: "#f5f5f7"
    readonly property color buttonFillHover: "#ffffff"
    readonly property color buttonFillPressed: "#e9e9ec"

    // Overview & Workspace tokens
    readonly property color overviewCard: "#ee17181b"
    readonly property color overviewBorder: "#33ffffff"
    readonly property color overviewInnerBorder: "#12ffffff"
    readonly property color workspaceCell: "#ff202226"
    readonly property color workspaceCellHover: "#ff2b2d34"
    readonly property color workspaceCellBorder: "#1effffff"
    readonly property color workspaceCellBorderHover: "#66d9f6ff"
    readonly property color workspaceOverlay: "#42070b10"
    readonly property color workspaceOverlayHover: "#280d131a"
    readonly property color workspaceActiveBorder: "#73d4ff"

    readonly property int radiusPanel: 28
    readonly property int radiusModule: 24
    readonly property int radiusPrompt: 16
    readonly property int radiusButton: 12
    readonly property int durationFast: 120
    readonly property int durationControl: 130
    readonly property int durationQuick: 140
    readonly property int durationStandard: 280
}
