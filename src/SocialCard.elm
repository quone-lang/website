module SocialCard exposing (main)

{-| A standalone Elm program whose only job is to render the Quone
social card at exactly 1200x630, ready to be screenshotted by
scripts/render-social-card.cjs into static/social-card-share.png.

It deliberately reuses the same theme, fonts, code highlighter and
logo lockup as the marketing site itself, so the card stays in lock
step with the brand without any duplicated styling.

The design is dark and minimal: solid black background, a single
header line (wordmark + URL), a tight headline, and the Quone source
on the left compiling via a thin arrow to the R source on the
right. No card chrome, no pills, no badges.

-}

import Browser
import Element
    exposing
        ( Element
        , centerY
        , column
        , el
        , fill
        , height
        , layout
        , paddingEach
        , paddingXY
        , px
        , rgb255
        , row
        , spacing
        , text
        , width
        )
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes
import Ui.CodeBlock as CodeBlock
import Ui.Logo as Logo
import Ui.Theme as Theme
import Ui.Viewport as Viewport



-- ENTRY POINT


main : Program () () msg
main =
    Browser.sandbox
        { init = ()
        , view = view
        , update = \_ model -> model
        }



-- THEME OVERRIDES


themeMode : Theme.Mode
themeMode =
    Theme.Dark


pageBg : Element.Color
pageBg =
    rgb255 0 0 0


textColor : Element.Color
textColor =
    rgb255 0xF5 0xF5 0xF5


mutedColor : Element.Color
mutedColor =
    rgb255 0x7A 0x82 0x8E


accentColor : Element.Color
accentColor =
    rgb255 0x6F 0xB2 0xFF



-- VIEW


view : () -> Html msg
view _ =
    let
        viewport =
            Viewport.fromSize 1200 630
    in
    layout
        [ width (px 1200)
        , height (px 630)
        , Background.color pageBg
        , Font.family Theme.fontSans
        , Font.color textColor
        ]
        (cardBody viewport)


cardBody : Viewport.Viewport -> Element msg
cardBody viewport =
    column
        [ width fill
        , height fill
        , paddingEach { top = 48, right = 72, bottom = 48, left = 72 }
        ]
        [ headerRow
        , el
            [ width fill
            , height fill
            ]
            (column
                [ width fill
                , centerY
                , spacing 38
                ]
                [ headline
                , compileRow viewport
                ]
            )
        , footer
        ]



-- HEADER


headerRow : Element msg
headerRow =
    el [ Element.centerX ] (Logo.full themeMode { wordmarkSize = 26, markSize = 30 })


footer : Element msg
footer =
    el
        [ Element.centerX
        , Font.color mutedColor
        , Font.size 15
        , Font.family Theme.fontMono
        , Font.letterSpacing 0.4
        ]
        (text "quone-lang.org")



-- HEADLINE


headline : Element msg
headline =
    column
        [ width fill
        , spacing 0
        ]
        [ Element.paragraph
            [ width fill
            , Font.family Theme.fontDisplay
            , Font.size 62
            , Font.semiBold
            , Font.letterSpacing -1.5
            , Font.color textColor
            , Font.center
            , Element.htmlAttribute (htmlStyle "line-height" "1.05")
            ]
            [ text "Typed dataframe pipelines that compile to "
            , el [ Font.color accentColor ] (text "R.")
            ]
        ]



-- COMPILE ROW


compileRow : Viewport.Viewport -> Element msg
compileRow viewport =
    row
        [ Element.centerX
        , spacing 42
        , centerY
        ]
        [ codeColumn viewport "Quone" CodeBlock.Quone quoneSource
        , compileArrow
        , codeColumn viewport "R" CodeBlock.R rSource
        ]


codeColumn :
    Viewport.Viewport
    -> String
    -> CodeBlock.Language
    -> String
    -> Element msg
codeColumn viewport label lang source =
    column
        [ width (px 466)
        , centerY
        , spacing 16
        ]
        [ codeLabel label
        , el
            [ width fill
            , paddingXY 0 4
            , Element.htmlAttribute (htmlStyle "zoom" "1.12")
            , Element.htmlAttribute (htmlStyle "line-height" "1.52")
            ]
            (CodeBlock.viewBare themeMode viewport lang (String.trim source))
        ]


codeLabel : String -> Element msg
codeLabel label =
    row
        [ width fill
        , centerY
        , spacing 14
        ]
        [ labelRule
        , el
            [ Font.family Theme.fontMono
            , Font.size 12
            , Font.color accentColor
            , Font.semiBold
            , Font.letterSpacing 2.4
            ]
            (text (String.toUpper label))
        , labelRule
        ]


labelRule : Element msg
labelRule =
    el
        [ width fill
        , height (px 1)
        , Background.color (rgb255 0x18 0x22 0x2E)
        ]
        Element.none


compileArrow : Element msg
compileArrow =
    el
        [ centerY
        , Element.moveDown 18
        , Font.color accentColor
        , Font.size 30
        , Font.family Theme.fontMono
        ]
        (text "→")



-- SOURCE SAMPLES


quoneSource : String
quoneSource =
    """
top_scores : Students -> Students
top_scores students <-
    students
        |> filter (score >= 70)
        |> arrange { desc score }
        |> select { name, score }
"""


rSource : String
rSource =
    """
top_scores <- function(students) {
  students |>
    dplyr::filter(score >= 70) |>
    dplyr::arrange(dplyr::desc(score)) |>
    dplyr::select(name, score)
}
"""



-- HTML STYLE HELPER


htmlStyle : String -> String -> Html.Attribute msg
htmlStyle =
    Html.Attributes.style
