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
        , padding
        , paddingEach
        , paragraph
        , row
        , shrink
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
import Json.Decode as Decode
import Process
import Task
import Ui.Button as Button
import Ui.CodeBlock as CodeBlock
import Ui.Layout as Layout
import Ui.Repl as Repl
import Ui.Theme as Theme exposing (type_)
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
            ( setSnippet idx state, Cmd.none )

        MoveSnippet delta ->
            ( setSnippet (state.snippetIndex + delta) state, Cmd.none )

        SelectFirstSnippet ->
            ( setSnippet 0 state, Cmd.none )

        SelectLastSnippet ->
            ( setSnippet (heroSnippetCount - 1) state, Cmd.none )

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
    | MoveSnippet Int
    | SelectFirstSnippet
    | SelectLastSnippet
    | RunHeroCompile
    | HeroCompileFinished Int


view : Theme.Mode -> Viewport.Viewport -> HeroState -> Element Msg
view themeMode viewport heroState =
    column
        [ width fill, spacing (sectionSpacing viewport) ]
        [ heroSection themeMode viewport heroState
        , featuresSection themeMode viewport
        , closingSection themeMode viewport
        ]



-- HERO


heroSection : Theme.Mode -> Viewport.Viewport -> HeroState -> Element Msg
heroSection themeMode viewport heroState =
    Layout.wideSection themeMode viewport
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
                [ heroText themeMode viewport
                , heroCode themeMode viewport heroState
                ]
        }


heroText : Theme.Mode -> Viewport.Viewport -> Element msg_
heroText themeMode viewport =
    let
        colors =
            Theme.paletteFor themeMode

        actions =
            [ Button.linkPrimary themeMode { url = "/install", label = "Install the R package" }
            , Button.linkSecondary themeMode { url = "https://github.com/quone-lang", label = "View on GitHub" }
            ]
    in
    column
        [ centerX
        , spacing Theme.space.lg
        , width (fill |> maximum 920)
        ]
        [ kicker themeMode "v0.0.1 WIP"
        , paragraph
            [ Font.size (heroDisplaySize viewport)
            , Font.semiBold
            , Font.color colors.textPrimary
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
            , Font.color colors.textSecondary
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


heroCode : Theme.Mode -> Viewport.Viewport -> HeroState -> Element Msg
heroCode themeMode viewport heroState =
    let
        snippet =
            activeSnippet heroState

        selectedTabId =
            snippetTabId heroState.snippetIndex

        selectedPanelId =
            snippetPanelId heroState.snippetIndex

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
        , spacing 0
        , paddingEach { top = Theme.space.lg, right = 0, bottom = 0, left = 0 }
        ]
        [ snippetTabs viewport heroState
        , el
            [ width fill
            , height shrink
            , htmlAttribute (Html.Attributes.style "flex-basis" "auto")
            , htmlAttribute (Html.Attributes.style "flex-shrink" "0")
            , paddingEach { top = tabGap viewport, right = 0, bottom = 0, left = 0 }
            ]
            (column
                [ width fill
                , height shrink
                , htmlAttribute (Html.Attributes.style "flex-basis" "auto")
                , htmlAttribute (Html.Attributes.style "flex-shrink" "0")
                , spacing (replGap viewport)
                , htmlAttribute (Html.Attributes.id selectedPanelId)
                , htmlAttribute (Html.Attributes.attribute "role" "tabpanel")
                , htmlAttribute (Html.Attributes.attribute "aria-labelledby" selectedTabId)
                ]
                [ CodeBlock.view themeMode viewport CodeBlock.Quone snippet.quone
                , Repl.view themeMode viewport
                    { command = "quone::compile(\"" ++ snippet.filename ++ "\")"
                    , output = replOutput
                    , onRun = RunHeroCompile
                    }
                ]
            )
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
            , Html.Attributes.attribute "aria-orientation" "horizontal"
            ]
            (List.map (snippetTabHtml heroState.snippetIndex) indexed)
        )


snippetTabHtml : Int -> ( Int, Examples.Snippet ) -> Html.Html Msg
snippetTabHtml activeIdx ( idx, snippet ) =
    let
        isActive =
            idx == activeIdx

        tabId =
            snippetTabId idx

        panelId =
            snippetPanelId idx

        cls =
            if isActive then
                "snippet-tab snippet-tab-active"

            else
                "snippet-tab"
    in
    Html.button
        [ Html.Attributes.class cls
        , Html.Attributes.id tabId
        , Html.Attributes.type_ "button"
        , Html.Attributes.attribute "role" "tab"
        , Html.Attributes.attribute "aria-controls" panelId
        , Html.Attributes.attribute "aria-selected"
            (if isActive then
                "true"

             else
                "false"
            )
        , Html.Attributes.tabindex
            (if isActive then
                0

             else
                -1
            )
        , snippetTabKeyHandler
        , Html.Events.onClick (SelectSnippet idx)
        ]
        [ Html.text snippet.filename ]


snippetTabKeyHandler : Html.Attribute Msg
snippetTabKeyHandler =
    Html.Events.preventDefaultOn "keydown"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    case key of
                        "ArrowLeft" ->
                            Decode.succeed ( MoveSnippet -1, True )

                        "ArrowRight" ->
                            Decode.succeed ( MoveSnippet 1, True )

                        "Home" ->
                            Decode.succeed ( SelectFirstSnippet, True )

                        "End" ->
                            Decode.succeed ( SelectLastSnippet, True )

                        _ ->
                            Decode.fail "Unhandled tab key"
                )
        )


snippetTabId : Int -> String
snippetTabId idx =
    "hero-snippet-tab-" ++ String.fromInt idx


snippetPanelId : Int -> String
snippetPanelId idx =
    "hero-snippet-panel-" ++ String.fromInt idx


heroSnippetCount : Int
heroSnippetCount =
    List.length Examples.heroSnippets


setSnippet : Int -> HeroState -> HeroState
setSnippet idx state =
    let
        nextIdx =
            if heroSnippetCount < 1 then
                0

            else
                modBy heroSnippetCount idx
    in
    if nextIdx == state.snippetIndex then
        state

    else
        { state | snippetIndex = nextIdx, compileState = HeroIdle }


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


featuresSection : Theme.Mode -> Viewport.Viewport -> Element msg_
featuresSection themeMode viewport =
    Layout.section themeMode viewport
        { kicker = Just "Why Quone"
        , title = Just "Compiler help without giving up R."
        , body =
            wrappedRow
                [ width fill
                , spacing Theme.space.lg
                ]
                (List.map (featureCard themeMode) Pitch.features)
        }


featureCard : Theme.Mode -> Pitch.Feature -> Element msg_
featureCard themeMode f =
    let
        colors =
            Theme.paletteFor themeMode

        ( badgeBackground, badgeColor ) =
            accentColors themeMode f.accent
    in
    column
        [ width (Element.fill |> Element.minimum 280 |> Element.maximum 360)
        , height fill
        , Background.color colors.surface
        , Border.rounded Theme.radius.lg
        , Border.width 1
        , Border.color colors.border
        , padding Theme.space.lg
        , spacing Theme.space.md
        , alignTop
        ]
        [ featureBadge { background = badgeBackground, color = badgeColor, glyph = f.glyph }
        , paragraph
            [ Font.size type_.h3Size
            , Font.semiBold
            , Font.color colors.textPrimary
            ]
            [ text f.title ]
        , paragraph
            [ Font.size type_.bodySize
            , Font.color colors.textSecondary
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


accentColors : Theme.Mode -> Pitch.Accent -> ( Element.Color, Element.Color )
accentColors themeMode accent =
    let
        colors =
            Theme.paletteFor themeMode
    in
    case accent of
        Pitch.AccentPrimary ->
            ( Element.rgba255 0x27 0x6D 0xC3 (if Theme.isDark themeMode then 0.18 else 0.10), colors.primaryDark )

        Pitch.AccentSecondary ->
            ( Element.rgba255 0xE0 0x60 0x4C (if Theme.isDark themeMode then 0.18 else 0.12), colors.secondary )

        Pitch.AccentNeutral ->
            ( colors.codeSurface, colors.textPrimary )



-- CLOSING


closingSection : Theme.Mode -> Viewport.Viewport -> Element msg_
closingSection themeMode viewport =
    let
        primaryAction =
            Button.linkPrimary themeMode { url = "/install", label = "Install the R package" }

        secondaryAction =
            Button.linkSecondary themeMode
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
    in
    Layout.section themeMode viewport
        { kicker = Just "Status"
        , title = Just "Early, useful, and still small enough to learn fast."
        , body =
            column
                [ width (fill |> maximum 760)
                , centerX
                , spacing Theme.space.lg
                ]
                (List.map (prose themeMode) Pitch.whyQuone ++ [ actionRow ])
        }


prose : Theme.Mode -> String -> Element msg_
prose themeMode s =
    let
        colors =
            Theme.paletteFor themeMode
    in
    paragraph
        [ Font.size type_.bodyLargeSize
        , Font.color colors.textSecondary
        , Font.center
        , Element.spacing 6
        ]
        [ text s ]


kicker : Theme.Mode -> String -> Element msg_
kicker themeMode s =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ centerX
        , Font.size type_.smallSize
        , Font.color colors.primary
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
