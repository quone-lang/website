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
import Ui.Theme as Theme exposing (palette, type_)



-- BUTTONS (msg-producing)


primary : { onPress : Maybe msg, label : String } -> Element msg
primary { onPress, label } =
    Input.button
        primaryStyle
        { onPress = onPress
        , label = el [ Element.centerX ] (text label)
        }


secondary : { onPress : Maybe msg, label : String } -> Element msg
secondary { onPress, label } =
    Input.button
        secondaryStyle
        { onPress = onPress
        , label = el [ Element.centerX ] (text label)
        }



-- LINK BUTTONS (navigate via URL)


linkPrimary : { url : String, label : String } -> Element msg
linkPrimary { url, label } =
    link
        primaryStyle
        { url = url
        , label = el [ Element.centerX ] (text label)
        }


linkSecondary : { url : String, label : String } -> Element msg
linkSecondary { url, label } =
    link
        secondaryStyle
        { url = url
        , label = el [ Element.centerX ] (text label)
        }



-- STYLES


primaryStyle : List (Element.Attribute msg)
primaryStyle =
    [ Background.color palette.primary
    , Font.color palette.textOnPrimary
    , Font.medium
    , Font.size type_.bodySize
    , paddingXY Theme.space.lg (Theme.space.md - 2)
    , Border.rounded Theme.radius.md
    , Element.mouseOver [ Background.color palette.primaryHover ]
    ]


secondaryStyle : List (Element.Attribute msg)
secondaryStyle =
    [ Background.color palette.surface
    , Font.color palette.textPrimary
    , Font.medium
    , Font.size type_.bodySize
    , paddingXY Theme.space.lg (Theme.space.md - 2)
    , Border.rounded Theme.radius.md
    , Border.width 1
    , Border.color palette.border
    , Element.mouseOver
        [ Background.color palette.codeSurface
        , Border.color palette.primary
        ]
    ]
