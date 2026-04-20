module Ui.Theme exposing
    ( Mode(..)
    , modeFromPrefersDark
    , isDark
    , themeColor
    , Palette
    , palette
    , paletteFor
    , Type
    , type_
    , Space
    , space
    , Radius
    , radius
    , Shadow
    , shadow
    , shadowFor
    , maxContentWidth
    , fontSans
    , fontDisplay
    , fontMono
    , fontLogo
    )

{-| Centralised design tokens for the Quone marketing site.

The palette is built around R's logo blue (`#276DC3`) as the primary
accent and a warm coral as the secondary - a classic split-
complementary pairing also used in scientific data viz (the RdBu
diverging palette). Neutrals are tuned for code-block readability: a
near-white surface, a subtle code background, and high-contrast text.

Typography pairs Space Grotesk (display) with Inter (body) and
JetBrains Mono (code). The logo mark uses Bitcount Grid Double, a
distinctive grid/dot-matrix display face that evokes the early days
of statistical computing without being kitsch.

-}

import Element exposing (Color, rgb255, rgba255)
import Element.Font as Font



-- MODE


type Mode
    = Light
    | Dark


modeFromPrefersDark : Bool -> Mode
modeFromPrefersDark prefersDark =
    if prefersDark then
        Dark

    else
        Light


isDark : Mode -> Bool
isDark mode =
    case mode of
        Light ->
            False

        Dark ->
            True


themeColor : Mode -> String
themeColor mode =
    case mode of
        Light ->
            "#fafaf9"

        Dark ->
            "#0b1015"



-- PALETTE


type alias Palette =
    { -- Brand
      primary : Color
    , primaryDark : Color
    , primaryHover : Color
    , secondary : Color

    -- Surfaces
    , background : Color
    , surface : Color
    , codeSurface : Color
    , border : Color

    -- Text
    , textPrimary : Color
    , textSecondary : Color
    , textMuted : Color
    , textOnPrimary : Color

    -- Syntax highlighting
    , codeKeyword : Color
    , codeType : Color
    , codeString : Color
    , codeNumber : Color
    , codeComment : Color
    , codeOperator : Color
    , codePlain : Color
    }


palette : Palette
palette =
    { primary = rgb255 0x27 0x6D 0xC3
    , primaryDark = rgb255 0x1A 0x4F 0x8B
    , primaryHover = rgb255 0x32 0x82 0xDC
    , secondary = rgb255 0xE0 0x60 0x4C
    , background = rgb255 0xFA 0xFA 0xF9
    , surface = rgb255 0xFF 0xFF 0xFF
    , codeSurface = rgb255 0xF5 0xF3 0xEF
    , border = rgb255 0xE5 0xE5 0xE3
    , textPrimary = rgb255 0x1A 0x1A 0x1A
    , textSecondary = rgb255 0x4A 0x4A 0x4A
    , textMuted = rgb255 0x8A 0x8A 0x8A
    , textOnPrimary = rgb255 0xFF 0xFF 0xFF
    , codeKeyword = rgb255 0xB0 0x3A 0x28
    , codeType = rgb255 0x0D 0x94 0x88
    , codeString = rgb255 0xA1 0x62 0x07
    , codeNumber = rgb255 0x6D 0x28 0xD9
    , codeComment = rgb255 0x8A 0x8A 0x8A
    , codeOperator = rgb255 0xB0 0x3A 0x28
    , codePlain = rgb255 0x1A 0x1A 0x1A
    }


darkPalette : Palette
darkPalette =
    { primary = rgb255 0x37 0x7E 0xD6
    , primaryDark = rgb255 0x98 0xC6 0xFF
    , primaryHover = rgb255 0x49 0x92 0xEC
    , secondary = rgb255 0xF0 0x7B 0x67
    , background = rgb255 0x0B 0x10 0x15
    , surface = rgb255 0x14 0x19 0x20
    , codeSurface = rgb255 0x0F 0x14 0x1B
    , border = rgb255 0x2A 0x33 0x3D
    , textPrimary = rgb255 0xF2 0xF5 0xF8
    , textSecondary = rgb255 0xC8 0xD0 0xDA
    , textMuted = rgb255 0x8D 0x97 0xA7
    , textOnPrimary = rgb255 0xFF 0xFF 0xFF
    , codeKeyword = rgb255 0xFF 0x90 0x7A
    , codeType = rgb255 0x54 0xD1 0xC8
    , codeString = rgb255 0xE8 0xB7 0x63
    , codeNumber = rgb255 0xBC 0x9C 0xFF
    , codeComment = rgb255 0x8D 0x97 0xA7
    , codeOperator = rgb255 0xFF 0x90 0x7A
    , codePlain = rgb255 0xF2 0xF5 0xF8
    }


paletteFor : Mode -> Palette
paletteFor mode =
    case mode of
        Light ->
            palette

        Dark ->
            darkPalette



-- TYPOGRAPHY


type alias Type =
    { displaySize : Int
    , h1Size : Int
    , h2Size : Int
    , h3Size : Int
    , bodyLargeSize : Int
    , bodySize : Int
    , smallSize : Int
    , codeSize : Int
    , codeSmallSize : Int
    , tightLineHeight : Float
    , normalLineHeight : Float
    , looseLineHeight : Float
    }


type_ : Type
type_ =
    { displaySize = 64
    , h1Size = 44
    , h2Size = 32
    , h3Size = 22
    , bodyLargeSize = 20
    , bodySize = 17
    , smallSize = 14
    , codeSize = 15
    , codeSmallSize = 13
    , tightLineHeight = 1.15
    , normalLineHeight = 1.55
    , looseLineHeight = 1.7
    }


fontSans : Font.Font
fontSans =
    Font.typeface "Inter"


fontDisplay : Font.Font
fontDisplay =
    Font.typeface "Space Grotesk"


fontMono : Font.Font
fontMono =
    Font.typeface "JetBrains Mono"


fontLogo : Font.Font
fontLogo =
    Font.typeface "Bitcount Grid Double"



-- SPACING


type alias Space =
    { xs : Int
    , sm : Int
    , md : Int
    , lg : Int
    , xl : Int
    , xxl : Int
    , section : Int
    }


space : Space
space =
    { xs = 4
    , sm = 8
    , md = 16
    , lg = 24
    , xl = 40
    , xxl = 64
    , section = 96
    }



-- RADIUS


type alias Radius =
    { sm : Int
    , md : Int
    , lg : Int
    , pill : Int
    }


radius : Radius
radius =
    { sm = 4
    , md = 8
    , lg = 12
    , pill = 999
    }



-- SHADOW (alpha overlays used as subtle borders / cards)


type alias Shadow =
    { soft : Color
    , medium : Color
    }


shadow : Shadow
shadow =
    { soft = rgba255 0x1B 0x22 0x2C 0.06
    , medium = rgba255 0x1B 0x22 0x2C 0.12
    }


darkShadow : Shadow
darkShadow =
    { soft = rgba255 0x00 0x00 0x00 0.28
    , medium = rgba255 0x00 0x00 0x00 0.44
    }


shadowFor : Mode -> Shadow
shadowFor mode =
    case mode of
        Light ->
            shadow

        Dark ->
            darkShadow



-- LAYOUT CONSTANTS


maxContentWidth : Int
maxContentWidth =
    1120
