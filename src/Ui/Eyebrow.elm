module Ui.Eyebrow exposing (view)

{-| The "kicker" small-caps label used above each section heading,
preceded by a short coral dash. Mirrors the eyebrow treatment used on
elm-lang.org and roc-lang.org but in Quone's blue-and-coral palette.
-}

import Element
    exposing
        ( Element
        , centerY
        , el
        , height
        , px
        , row
        , spacing
        , text
        , width
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Ui.Theme as Theme exposing (type_)


view : Theme.Mode -> String -> Element msg
view themeMode label =
    let
        colors =
            Theme.paletteFor themeMode
    in
    row
        [ spacing 10
        , centerY
        ]
        [ el
            [ width (px 22)
            , height (px 2)
            , Background.color colors.secondary
            , Border.rounded 1
            , centerY
            ]
            Element.none
        , el
            [ Font.size type_.smallSize
            , Font.color colors.primary
            , Font.semiBold
            , Font.letterSpacing 1.6
            , centerY
            ]
            (text (String.toUpper label))
        ]
