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
        , alignBottom
        , centerY
        , el
        , row
        , spacing
        , text
        )
import Element.Font as Font
import Ui.Theme as Theme exposing (palette)


{-| Just the "Q" mark, used for favicon-style placements.
-}
mark : Int -> Element msg
mark size =
    el
        [ Font.family [ Theme.fontLogo, Theme.fontMono, Font.monospace ]
        , Font.color palette.primary
        , Font.size size
        , Font.regular
        , centerY
        ]
        (text "Q")


{-| The full lock-up: "Q" mark plus the "quone" wordmark, sized for
the header (and a smaller variant for the footer).
-}
full : { wordmarkSize : Int, markSize : Int } -> Element msg
full { wordmarkSize, markSize } =
    row
        [ spacing 6
        , centerY
        ]
        [ mark markSize
        , el
            [ Font.family [ Theme.fontDisplay, Font.sansSerif ]
            , Font.color palette.textPrimary
            , Font.size wordmarkSize
            , Font.semiBold
            , Font.letterSpacing -0.4
            , alignBottom
            ]
            (text "quone")
        ]
