module Ui.Logo exposing (full)

{-| The Quone logo lock-up.

-}

import Element
    exposing
        ( Element
        , centerY
        , el
        , image
        , row
        , spacing
        , text
        , width
        )
import Element.Font as Font
import Ui.Theme as Theme


{-| Just the "Q" mark, used for favicon-style placements.
-}
mark : Theme.Mode -> Int -> Element msg
mark _ size =
    image
        [ width (Element.px size)
        , centerY
        ]
        { src = "/q-logo.png"
        , description = "Quone logo"
        }


{-| The full lock-up: "Q" mark plus the "quone" wordmark, sized for
the header (and a smaller variant for the footer).
-}
full : Theme.Mode -> { wordmarkSize : Int, markSize : Int } -> Element msg
full themeMode { wordmarkSize, markSize } =
    let
        colors =
            Theme.paletteFor themeMode
    in
    row
        [ spacing 6
        , centerY
        ]
        [ el [ centerY ] (mark themeMode markSize)
        , el
            [ Font.family Theme.fontDisplay
            , Font.color colors.textPrimary
            , Font.size wordmarkSize
            , Font.semiBold
            , Font.letterSpacing -0.4
            , centerY
            ]
            (text "quone")
        ]
