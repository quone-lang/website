module Ui.Button exposing
    ( linkPrimary
    , linkSecondary
    )

{-| Link-buttons in primary and secondary variants.
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
import Ui.Theme as Theme exposing (type_)



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
