module Ui.Button exposing
    ( primary
    , secondary
    , linkPrimary
    , linkSecondary
    )

{-| Buttons and link-buttons in a small set of variants.
-}

import Element
    exposing
        ( Element
        , el
        , link
        , paddingXY
        , text
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Ui.Theme as Theme exposing (type_)



-- BUTTONS (msg-producing)


primary : Theme.Mode -> { onPress : Maybe msg, label : String } -> Element msg
primary themeMode { onPress, label } =
    Input.button
        (primaryStyle themeMode)
        { onPress = onPress
        , label = el [ Element.centerX ] (text label)
        }


secondary : Theme.Mode -> { onPress : Maybe msg, label : String } -> Element msg
secondary themeMode { onPress, label } =
    Input.button
        (secondaryStyle themeMode)
        { onPress = onPress
        , label = el [ Element.centerX ] (text label)
        }



-- LINK BUTTONS (navigate via URL)


linkPrimary : Theme.Mode -> { url : String, label : String } -> Element msg
linkPrimary themeMode { url, label } =
    link
        (primaryStyle themeMode)
        { url = url
        , label = el [ Element.centerX ] (text label)
        }


linkSecondary : Theme.Mode -> { url : String, label : String } -> Element msg
linkSecondary themeMode { url, label } =
    link
        (secondaryStyle themeMode)
        { url = url
        , label = el [ Element.centerX ] (text label)
        }



-- STYLES


primaryStyle : Theme.Mode -> List (Element.Attribute msg)
primaryStyle themeMode =
    let
        colors =
            Theme.paletteFor themeMode
    in
    [ Background.color colors.primary
    , Font.color colors.textOnPrimary
    , Font.medium
    , Font.size type_.bodySize
    , paddingXY Theme.space.lg (Theme.space.md - 2)
    , Border.rounded Theme.radius.md
    , Element.mouseOver [ Background.color colors.primaryHover ]
    ]


secondaryStyle : Theme.Mode -> List (Element.Attribute msg)
secondaryStyle themeMode =
    let
        colors =
            Theme.paletteFor themeMode
    in
    [ Background.color colors.surface
    , Font.color colors.textPrimary
    , Font.medium
    , Font.size type_.bodySize
    , paddingXY Theme.space.lg (Theme.space.md - 2)
    , Border.rounded Theme.radius.md
    , Border.width 1
    , Border.color colors.border
    , Element.mouseOver
        [ Background.color colors.codeSurface
        , Border.color colors.primary
        ]
    ]
