module Page.Home exposing
    ( HeroCompileState
    , HeroState
    , Msg(..)
    , initHeroState
    , updateHero
    , view
    )

{-| The marketing home page.

Layout, top to bottom:

1.  Hero - tagline, subtagline, CTAs, and an interactive REPL where the
    user can pick a Quone snippet and "compile" it to R.
2.  Why Quone - three accent cards summarising the value prop.
3.  Status - pre-release note + closing CTAs.

-}

import Content.Examples as Examples
import Content.Pitch as Pitch
import Element
    exposing
        ( Element
        , alignTop
        , centerX
        , column
        , el
        , fill
        , height
        , htmlAttribute
        , maximum
        , minimum
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
import Element.Region as Region
import Html
import Html.Attributes
import Html.Events
import Process
import Task
import Ui.Button as Button
import Ui.CodeBlock as CodeBlock
import Ui.Layout as Layout
import Ui.Repl as Repl
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport


{-| The hero REPL is keyed on which snippet is selected. Switching
snippets resets the compile state so each tab starts at `HeroIdle`.
-}
type alias HeroState =
    { snippetIndex : Int
    , compileState : HeroCompileState
    }


type HeroCompileState
    = HeroIdle
    | HeroCompiling
    | HeroCompiled


initHeroState : HeroState
initHeroState =
    { snippetIndex = 0
    , compileState = HeroIdle
    }


{-| Update the hero state in response to a `Msg`. -}
updateHero : Msg -> HeroState -> ( HeroState, Cmd Msg )
updateHero msg state =
    case msg of
        SelectSnippet idx ->
            if idx == state.snippetIndex then
                ( state, Cmd.none )

            else
                ( { state | snippetIndex = idx, compileState = HeroIdle }
                , Cmd.none
                )

        RunHeroCompile ->
            if state.compileState == HeroCompiling then
                ( state, Cmd.none )

            else
                ( { state | compileState = HeroCompiling }
                , Process.sleep heroCompileDelayMs
                    |> Task.perform (\_ -> HeroCompileFinished state.snippetIndex)
                )

        HeroCompileFinished idx ->
            if idx == state.snippetIndex && state.compileState == HeroCompiling then
                ( { state | compileState = HeroCompiled }, Cmd.none )

            else
                ( state, Cmd.none )


{-| Artificial delay so the spinner is visible long enough to register
as feedback.
-}
heroCompileDelayMs : Float
heroCompileDelayMs =
    1000


type Msg
    = SelectSnippet Int
    | RunHeroCompile
    | HeroCompileFinished Int


view : Viewport.Viewport -> HeroState -> Element Msg
view viewport heroState =
    column
        [ width fill, spacing (sectionSpacing viewport) ]
        [ heroSection viewport heroState
        , featuresSection viewport
        , closingSection viewport
        ]



-- HERO


heroSection : Viewport.Viewport -> HeroState -> Element Msg
heroSection viewport heroState =
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
                , heroCode viewport heroState
                ]
        }


heroText : Viewport.Viewport -> Element msg_
heroText viewport =
    let
        actions =
            [ Button.linkPrimary { url = "/install", label = "Install the R package" }
            , Button.linkSecondary { url = "https://github.com/quone-lang", label = "View on GitHub" }
            ]
    in
    column
        [ centerX
        , spacing Theme.space.lg
        , width (fill |> maximum 920)
        ]
        [ kicker "v0.0.1 WIP"
        , paragraph
            [ Font.size (heroDisplaySize viewport)
            , Font.semiBold
            , Font.color palette.textPrimary
            , Font.center
            , Element.spacing 8
            , Region.heading 1
            ]
            [ text (Pitch.taglinePrefix ++ " ")
            , heroSwapToken
            ]
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
                (List.map (\button -> el [ centerX ] button) actions)

          else
            row
                [ centerX
                , spacing Theme.space.md
                , paddingEach { top = Theme.space.md, right = 0, bottom = 0, left = 0 }
                ]
                actions
        ]


heroSwapToken : Element msg_
heroSwapToken =
    Element.html
        (Html.span
            [ Html.Attributes.class "hero-swap" ]
            [ Html.span
                [ Html.Attributes.class "hero-swap-default" ]
                [ Html.text "R" ]
            , Html.span
                [ Html.Attributes.class "hero-swap-alt"
                , Html.Attributes.attribute "aria-hidden" "true"
                ]
                [ Html.text "Q" ]
            ]
        )


heroCode : Viewport.Viewport -> HeroState -> Element Msg
heroCode viewport heroState =
    let
        snippet =
            activeSnippet heroState

        replOutput =
            case heroState.compileState of
                HeroIdle ->
                    Repl.Idle

                HeroCompiling ->
                    Repl.Compiling

                HeroCompiled ->
                    Repl.Compiled snippet.r
    in
    column
        [ width (fill |> maximum 760)
        , centerX
        , spacing (replGap viewport)
        , paddingEach { top = Theme.space.lg, right = 0, bottom = 0, left = 0 }
        ]
        [ column [ width fill, spacing (tabGap viewport) ]
            [ snippetTabs viewport heroState
            , CodeBlock.view viewport CodeBlock.Quone snippet.quone
            ]
        , Repl.view viewport
            { command = "quone::compile(\"" ++ snippet.filename ++ "\")"
            , output = replOutput
            , onRun = RunHeroCompile
            }
        ]


activeSnippet : HeroState -> Examples.Snippet
activeSnippet heroState =
    case List.drop heroState.snippetIndex Examples.heroSnippets of
        first :: _ ->
            first

        [] ->
            Examples.normalizeSnippet


snippetTabs : Viewport.Viewport -> HeroState -> Element Msg
snippetTabs _ heroState =
    let
        indexed =
            List.indexedMap Tuple.pair Examples.heroSnippets
    in
    Element.html
        (Html.div
            [ Html.Attributes.class "snippet-tabs"
            , Html.Attributes.attribute "role" "tablist"
            , Html.Attributes.attribute "aria-label" "Quone snippets"
            ]
            (List.map (snippetTabHtml heroState.snippetIndex) indexed)
        )


snippetTabHtml : Int -> ( Int, Examples.Snippet ) -> Html.Html Msg
snippetTabHtml activeIdx ( idx, snippet ) =
    let
        isActive =
            idx == activeIdx

        cls =
            if isActive then
                "snippet-tab snippet-tab-active"

            else
                "snippet-tab"
    in
    Html.button
        [ Html.Attributes.class cls
        , Html.Attributes.type_ "button"
        , Html.Attributes.attribute "role" "tab"
        , Html.Attributes.attribute "aria-selected"
            (if isActive then
                "true"

             else
                "false"
            )
        , Html.Events.onClick (SelectSnippet idx)
        ]
        [ Html.text snippet.filename ]


replGap : Viewport.Viewport -> Int
replGap viewport =
    if Viewport.isHandset viewport then
        Theme.space.md

    else
        Theme.space.lg


tabGap : Viewport.Viewport -> Int
tabGap viewport =
    if Viewport.isHandset viewport then
        Theme.space.sm + 2

    else
        Theme.space.md - 4



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
    let
        ( badgeBackground, badgeColor ) =
            accentColors f.accent
    in
    column
        [ width (Element.fill |> Element.minimum 280 |> Element.maximum 360)
        , height fill
        , Background.color palette.surface
        , Border.rounded Theme.radius.lg
        , Border.width 1
        , Border.color palette.border
        , padding Theme.space.lg
        , spacing Theme.space.md
        , alignTop
        ]
        [ featureBadge { background = badgeBackground, color = badgeColor, glyph = f.glyph }
        , paragraph
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


featureBadge : { background : Element.Color, color : Element.Color, glyph : String } -> Element msg
featureBadge { background, color, glyph } =
    el
        [ width (Element.px 40)
        , height (Element.px 40)
        , Border.rounded Theme.radius.md
        , Background.color background
        , Font.family [ Theme.fontMono, Font.monospace ]
        , Font.size 20
        , Font.semiBold
        , Font.color color
        , htmlAttribute (Html.Attributes.attribute "aria-hidden" "true")
        ]
        (el [ centerX, Element.centerY ] (text glyph))


accentColors : Pitch.Accent -> ( Element.Color, Element.Color )
accentColors accent =
    case accent of
        Pitch.AccentPrimary ->
            ( Element.rgba255 0x27 0x6D 0xC3 0.10, palette.primaryDark )

        Pitch.AccentSecondary ->
            ( Element.rgba255 0xE0 0x60 0x4C 0.12, palette.secondary )

        Pitch.AccentNeutral ->
            ( palette.codeSurface, palette.textPrimary )



-- CLOSING


closingSection : Viewport.Viewport -> Element msg_
closingSection viewport =
    let
        primaryAction =
            Button.linkPrimary { url = "/install", label = "Install the R package" }

        secondaryAction =
            Button.linkSecondary
                { url = "https://github.com/quone-lang/quone/blob/main/compiler/docs/LANGUAGE.md"
                , label = "Language reference"
                }

        actionRow =
            if Viewport.isCompact viewport then
                column
                    [ centerX
                    , paddingEach { top = Theme.space.lg, right = 0, bottom = 0, left = 0 }
                    , spacing Theme.space.md
                    ]
                    [ el [ centerX ] primaryAction
                    , el [ centerX ] secondaryAction
                    ]

            else
                row
                    [ centerX
                    , paddingEach { top = Theme.space.lg, right = 0, bottom = 0, left = 0 }
                    , spacing Theme.space.md
                    ]
                    [ primaryAction
                    , secondaryAction
                    ]

        title =
            paragraph
                [ Font.size
                    (if Viewport.isHandset viewport then
                        28

                     else
                        type_.h2Size
                    )
                , Font.semiBold
                , Font.color palette.textPrimary
                , Font.family [ Theme.fontDisplay, Font.sansSerif ]
                , Font.letterSpacing -0.6
                , Font.center
                , Region.heading 2
                ]
                [ text "Early, useful, and still small enough to learn fast." ]
    in
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
                [ kicker "Status"
                , el [ centerX, width (fill |> maximum 760) ] title
                , column
                    [ width (fill |> maximum 760)
                    , centerX
                    , spacing Theme.space.lg
                    ]
                    (List.map prose Pitch.whyQuone ++ [ actionRow ])
                ]
        }


prose : String -> Element msg_
prose s =
    paragraph
        [ Font.size type_.bodyLargeSize
        , Font.color palette.textSecondary
        , Font.center
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
