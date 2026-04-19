module Page.Home exposing (Msg(..), ShowcaseId(..), view)

{-| The marketing home page.

Layout, top to bottom:

1.  Hero - tagline, subtagline, side-by-side Quone/R, primary CTA.
2.  Feature grid - six cards summarising the value proposition.
3.  Interactive explorer - click any group to see its lowering.
4.  Comparison table - Quone vs base R / tidyverse / lintr.
5.  Long-form code examples - script, dataframe pipeline, decoder, package.
6.  About-the-name aside - the Seinfeld reference.
7.  Closing pitch - status statement and primary CTAs.

-}

import Content.Examples as Examples
import Content.Pitch as Pitch
import Element
    exposing
        ( Element
        , alignTop
        , centerX
        , clip
        , column
        , el
        , fill
        , height
        , htmlAttribute
        , maximum
        , minimum
        , none
        , padding
        , paddingEach
        , paragraph
        , row
        , spacing
        , text
        , width
        , wrappedRow
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Page.Explorer as Explorer
import Html.Attributes
import Ui.Button as Button
import Ui.CodeBlock as CodeBlock
import Ui.Layout as Layout
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport


type ShowcaseId
    = ShowcaseScript
    | ShowcaseDecoder


type Msg
    = ExplorerMsg Explorer.Msg
    | ToggleShowcase ShowcaseId


type alias Showcase =
    { id : ShowcaseId
    , example : Examples.Example
    }


showcases : List Showcase
showcases =
    [ { id = ShowcaseScript, example = Examples.script }
    , { id = ShowcaseDecoder, example = Examples.decoder }
    ]


view : Viewport.Viewport -> Maybe ShowcaseId -> Explorer.Model -> Element Msg
view viewport expandedShowcase explorerModel =
    column
        [ width fill, spacing (sectionSpacing viewport) ]
        [ heroSection viewport
        , explorerSection viewport explorerModel
        , featuresSection viewport
        , showcaseSection viewport expandedShowcase
        , closingSection viewport
        ]



-- HERO


heroSection : Viewport.Viewport -> Element msg_
heroSection viewport =
    Layout.wideSection viewport
        { body =
            column
                [ width fill
                , centerX
                , spacing
                    (if Viewport.isHandset viewport then
                        Theme.space.lg

                     else
                        Theme.space.xl
                    )
                ]
                [ heroText viewport
                , heroCode viewport
                ]
        }


heroText : Viewport.Viewport -> Element msg_
heroText viewport =
    let
        actions =
            [ Button.linkPrimary { url = "#explorer", label = "Try the explorer" }
            , Button.linkSecondary { url = "/install", label = "Install from source" }
            ]
    in
    column
        [ centerX
        , spacing Theme.space.lg
        , width (fill |> maximum 920)
        ]
        [ kicker "v0.0.1"
        , paragraph
            [ Font.size (heroDisplaySize viewport)
            , Font.semiBold
            , Font.color palette.textPrimary
            , Font.center
            , Element.spacing 8
            , Region.heading 1
            ]
            [ text Pitch.tagline ]
        , paragraph
            [ Font.size
                (if Viewport.isHandset viewport then
                    18

                 else
                    type_.bodyLargeSize
                )
            , Font.color palette.textSecondary
            , Font.center
            , Element.spacing 6
            , width (fill |> maximum 720)
            , centerX
            ]
            [ text Pitch.subtagline ]
        , if Viewport.isCompact viewport then
            column
                [ centerX
                , spacing Theme.space.md
                , paddingEach { top = Theme.space.md, right = 0, bottom = 0, left = 0 }
                ]
                (List.map (\button -> el [ centerX ] button) actions
                    ++ [ el [ centerX ] (referenceLink viewport) ]
                )

          else
            column
                [ centerX
                , spacing Theme.space.sm
                , paddingEach { top = Theme.space.md, right = 0, bottom = 0, left = 0 }
                ]
                [ row
                    [ centerX
                    , spacing Theme.space.md
                    ]
                    actions
                , el [ centerX ] (referenceLink viewport)
                ]
        ]


referenceLink : Viewport.Viewport -> Element msg_
referenceLink _ =
    Element.link
        [ Font.size type_.smallSize
        , Font.color palette.textMuted
        , Element.mouseOver [ Font.color palette.primary ]
        ]
        { url = "https://github.com/quone-lang/compiler/blob/main/docs/LANGUAGE.md"
        , label = text "or read the language reference"
        }


heroCode : Viewport.Viewport -> Element msg_
heroCode viewport =
    let
        ex =
            Examples.hero
    in
    el
        [ width fill, paddingEach { top = Theme.space.lg, right = 0, bottom = 0, left = 0 } ]
        (CodeBlock.viewSideBySide viewport { quone = ex.quone, r = ex.r })



-- FEATURES


featuresSection : Viewport.Viewport -> Element msg_
featuresSection viewport =
    Layout.section viewport
        { kicker = Just "Why Quone"
        , title = Just "Compiler help without giving up R."
        , body =
            wrappedRow
                [ width fill
                , spacing Theme.space.lg
                ]
                (List.map featureCard Pitch.features)
        }


featureCard : Pitch.Feature -> Element msg_
featureCard f =
    column
        [ width (Element.fill |> Element.minimum 280 |> Element.maximum 360)
        , height fill
        , Background.color palette.surface
        , Border.rounded Theme.radius.lg
        , Border.width 1
        , Border.color palette.border
        , padding Theme.space.lg
        , spacing Theme.space.sm
        , alignTop
        ]
        [ paragraph
            [ Font.size type_.h3Size
            , Font.semiBold
            , Font.color palette.textPrimary
            ]
            [ text f.title ]
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text f.body ]
        ]



-- INTERACTIVE EXPLORER


explorerSection : Viewport.Viewport -> Explorer.Model -> Element Msg
explorerSection viewport explorerModel =
    el
        [ width fill
        , htmlAttribute (Html.Attributes.id "explorer")
        ]
        (Layout.section viewport
            { kicker = Just "Try it"
            , title = Just "See what Quone emits."
            , body =
                column [ width fill, spacing Theme.space.lg ]
                    [ paragraph
                        [ Font.size type_.bodyLargeSize
                        , Font.color palette.textSecondary
                        , Element.spacing 6
                        , width (fill |> maximum 760)
                        ]
                        [ text "Pick an example, then inspect the generated R chunk by chunk. It is the quickest way to understand the pitch without reading the full reference." ]
                    , Element.map ExplorerMsg (Explorer.view viewport explorerModel)
                    ]
            }
        )


-- COLLAPSED SHOWCASES


showcaseSection : Viewport.Viewport -> Maybe ShowcaseId -> Element Msg
showcaseSection viewport expandedShowcase =
    Layout.section viewport
        { kicker = Just "More examples"
        , title = Just "Open only the code you want to inspect."
        , body =
            column
                [ width fill
                , spacing Theme.space.lg
                ]
                (List.map (showcaseCard viewport expandedShowcase) showcases)
        }


showcaseCard : Viewport.Viewport -> Maybe ShowcaseId -> Showcase -> Element Msg
showcaseCard viewport expandedShowcase showcase =
    let
        isExpanded =
            expandedShowcase == Just showcase.id
    in
    column
        [ width fill
        , Background.color palette.surface
        , Border.rounded Theme.radius.lg
        , Border.width 1
        , Border.color
            (if isExpanded then
                palette.primary

             else
                palette.border
            )
        , clip
        ]
        [ Input.button
            [ width fill
            , padding Theme.space.lg
            , Background.color
                (if isExpanded then
                    Element.rgba255 0x27 0x6D 0xC3 0.04

                 else
                    palette.surface
                )
            , htmlAttribute
                (Html.Attributes.attribute
                    "aria-expanded"
                    (if isExpanded then
                        "true"

                     else
                        "false"
                    )
                )
            ]
            { onPress = Just (ToggleShowcase showcase.id)
            , label = showcaseSummary isExpanded showcase
            }
        , if isExpanded then
            el
                [ width fill
                , paddingEach
                    { top = 0
                    , right = Theme.space.lg
                    , bottom = Theme.space.lg
                    , left = Theme.space.lg
                    }
                ]
                (CodeBlock.viewSideBySide viewport
                    { quone = showcase.example.quone
                    , r = showcase.example.r
                    }
                )

          else
            none
        ]


showcaseSummary : Bool -> Showcase -> Element msg
showcaseSummary isExpanded showcase =
    let
        action =
            if isExpanded then
                "Hide code"

            else
                "Show code"
    in
    row
        [ width fill
        , spacing Theme.space.md
        , alignTop
        ]
        [ column
            [ width fill
            , spacing Theme.space.sm
            ]
            [ paragraph
                [ Font.size type_.h3Size
                , Font.semiBold
                , Font.color palette.textPrimary
                , Region.heading 3
                ]
                [ text showcase.example.title ]
            , paragraph
                [ Font.size type_.bodySize
                , Font.color palette.textSecondary
                , Element.spacing 6
                ]
                [ text showcase.example.blurb ]
            , row
                [ spacing Theme.space.xs
                , Font.size type_.smallSize
                , Font.semiBold
                , Font.color palette.primary
                ]
                [ text action
                , chevron isExpanded
                ]
            ]
        , el
            [ alignTop
            , Element.alignRight
            , htmlAttribute (Html.Attributes.attribute "aria-hidden" "true")
            ]
            (chevronCircle isExpanded)
        ]


chevron : Bool -> Element msg
chevron isExpanded =
    let
        glyph =
            if isExpanded then
                "\u{2212}"

            else
                "\u{002B}"
    in
    el
        [ Font.size type_.smallSize
        , Font.color palette.primary
        , Font.semiBold
        ]
        (text glyph)


chevronCircle : Bool -> Element msg
chevronCircle isExpanded =
    let
        glyph =
            if isExpanded then
                "\u{2212}"

            else
                "\u{002B}"
    in
    el
        [ width (Element.px 32)
        , height (Element.px 32)
        , Border.rounded 16
        , Border.width 1
        , Border.color palette.border
        , Background.color palette.surface
        , Font.size 18
        , Font.semiBold
        , Font.color palette.primary
        ]
        (el [ centerX, Element.centerY ] (text glyph))



-- CLOSING


closingSection : Viewport.Viewport -> Element msg_
closingSection viewport =
    let
        primaryAction =
            Button.linkPrimary { url = "/install", label = "Install from source" }

        secondaryAction =
            Button.linkSecondary
                { url = "https://github.com/quone-lang/compiler/blob/main/docs/LANGUAGE.md"
                , label = "Language reference"
                }

        actionRow =
            if Viewport.isCompact viewport then
                column
                    [ paddingEach { top = Theme.space.lg, right = 0, bottom = 0, left = 0 }
                    , spacing Theme.space.md
                    ]
                    [ el [ centerX ] primaryAction
                    , el [ centerX ] secondaryAction
                    ]

            else
                row
                    [ paddingEach { top = Theme.space.lg, right = 0, bottom = 0, left = 0 }
                    , spacing Theme.space.md
                    ]
                    [ primaryAction
                    , secondaryAction
                    ]
    in
    Layout.section viewport
        { kicker = Just "Status"
        , title = Just "Early, useful, and still small enough to learn fast."
        , body =
            column
                [ width (fill |> maximum 760)
                , spacing Theme.space.lg
                ]
                (List.map prose Pitch.whyQuone ++ [ actionRow ])
        }


prose : String -> Element msg_
prose s =
    paragraph
        [ Font.size type_.bodyLargeSize
        , Font.color palette.textSecondary
        , Element.spacing 6
        ]
        [ text s ]


kicker : String -> Element msg_
kicker s =
    el
        [ centerX
        , Font.size type_.smallSize
        , Font.color palette.primary
        , Font.semiBold
        , Font.letterSpacing 1.4
        ]
        (text (String.toUpper s))


heroDisplaySize : Viewport.Viewport -> Int
heroDisplaySize viewport =
    if viewport.width < 420 then
        52

    else if Viewport.isHandset viewport then
        58

    else
        type_.displaySize


sectionSpacing : Viewport.Viewport -> Int
sectionSpacing viewport =
    if Viewport.isHandset viewport then
        72

    else
        Theme.space.section
