module Ui.Logo exposing (mark, full)

{-| The Quone logo: a stylised "Q" set in Bitcount Grid Double (a
distinctive grid/dot-matrix display face) followed by the lowercase
"quone" wordmark in Space Grotesk.

The grid font evokes early statistical computing without being kitsch;
keeping it large beside a clean wordmark gives the brand a recognisable
silhouette without needing an SVG.

-}

import Element
    exposing
        ( Element
        , centerY
        , el
        , moveDown
        , row
        , spacing
        , text
        )
import Element.Font as Font
import Ui.Theme as Theme


{-| Just the "Q" mark, used for favicon-style placements.
-}
mark : Theme.Mode -> Int -> Element msg
mark themeMode size =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.family Theme.fontLogo
        , Font.color colors.primary
        , Font.size size
        , Font.regular
        , centerY
        ]
        (text "Q")


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
        [ el [ centerY, moveDown 3 ] (mark themeMode markSize)
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
