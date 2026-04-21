module Page.Home exposing
    ( HeroState
    , Msg
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


{-| State for the hero REPL.

Mirrors RStudio's pane: an accumulating list of past commands and
their outcomes (the `history`, oldest first) and the current
in-flight state (`compileState`, only `HeroIdle` or `HeroCompiling`).

The pending `> quone::compile("…")` line is derived from
`snippetIndex` -- there is no editable command, so we don't keep one
in state. The REPL shows that pending line as the first row of the
scrollback before any run, then appends executed entries with their
own command line and output underneath.

This is a **demo** only: nothing is sent to a real R interpreter.
Switching snippet tabs (or pressing Reset on the REPL) wipes the
history and drops back to `HeroIdle`. Submitting a command simulates
a short compile delay, then prints the snippet's golden R.
-}
type alias HeroState =
    { snippetIndex : Int
    , history : List HeroEntry
    , compileState : HeroCompileState
    }


type HeroEntry
    = HeroEntrySuccess { command : String, result : String }
    | HeroEntryError { command : String, message : String }


type HeroCompileState
    = HeroIdle
    | HeroCompiling { command : String }


compileDelayMs : Float
compileDelayMs =
    450


initHeroState : HeroState
initHeroState =
    { snippetIndex = 0
    , history = []
    , compileState = HeroIdle
    }


{-| Update the hero state in response to a `Msg`.
-}
updateHero : Msg -> HeroState -> ( HeroState, Cmd Msg )
updateHero msg state =
    case msg of
        SelectSnippet idx ->
            ( setSnippet idx state, Cmd.none )

        SubmitHeroCommand ->
            submitCommand state

        ResetHero ->
            ( { state | history = [], compileState = HeroIdle }
            , Cmd.none
            )

        HeroCompileFinished entry ->
            case state.compileState of
                HeroCompiling _ ->
                    ( { state
                        | compileState = HeroIdle
                        , history = state.history ++ [ entry ]
                      }
                    , Cmd.none
                    )

                HeroIdle ->
                    -- Stale completion after a snippet tab switched away
                    -- mid-flight; ignore quietly.
                    ( state, Cmd.none )


submitCommand : HeroState -> ( HeroState, Cmd Msg )
submitCommand state =
    if isCompiling state.compileState then
        ( state, Cmd.none )

    else
        let
            command =
                compileCommandFor (snippetAt state.snippetIndex)

            entry =
                compileDemoEntry command state.snippetIndex

            cmd =
                Process.sleep compileDelayMs
                    |> Task.andThen (\_ -> Task.succeed entry)
                    |> Task.perform HeroCompileFinished
        in
        ( { state | compileState = HeroCompiling { command = command } }
        , cmd
        )


compileDemoEntry : String -> Int -> HeroEntry
compileDemoEntry command snippetIdx =
    let
        trimmed =
            String.trim command

        suggestion =
            "Try: quone::compile(\"" ++ (snippetAt snippetIdx).filename ++ "\")"

        demoOnly =
            "This is a demo, not a real R interpreter.\n\n" ++ suggestion

        err msg =
            HeroEntryError { command = trimmed, message = msg }
    in
    case parseQuoneCompileQuotedFile trimmed of
        Just fname ->
            case findSnippetByFilename fname of
                Just snippet ->
                    HeroEntrySuccess { command = trimmed, result = snippet.r }

                Nothing ->
                    err demoOnly

        Nothing ->
            err demoOnly


parseQuoneCompileQuotedFile : String -> Maybe String
parseQuoneCompileQuotedFile raw =
    let
        lower =
            String.toLower raw
    in
    if String.contains "quone::compile" lower then
        firstQuotedSegment raw

    else
        Nothing


firstQuotedSegment : String -> Maybe String
firstQuotedSegment s =
    case String.indexes "\"" s of
        openIdx :: _ ->
            let
                afterOpen =
                    String.dropLeft (openIdx + 1) s
            in
            case String.indexes "\"" afterOpen of
                closeIdx :: _ ->
                    Just (String.left closeIdx afterOpen)

                [] ->
                    Nothing

        [] ->
            Nothing


findSnippetByFilename : String -> Maybe Examples.Snippet
findSnippetByFilename fname =
    List.head (List.filter (\sn -> sn.filename == fname) Examples.heroSnippets)


isCompiling : HeroCompileState -> Bool
isCompiling compileState =
    case compileState of
        HeroCompiling _ ->
            True

        _ ->
            False


snippetAt : Int -> Examples.Snippet
snippetAt idx =
    case List.drop idx Examples.heroSnippets of
        first :: _ ->
            first

        [] ->
            Examples.normalizeSnippet


compileCommandFor : Examples.Snippet -> String
compileCommandFor snippet =
    "quone::compile(\"" ++ snippet.filename ++ "\")"


type Msg
    = SelectSnippet Int
    | SubmitHeroCommand
    | ResetHero
    | HeroCompileFinished HeroEntry


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

        replHistory =
            List.map heroEntryToReplEntry heroState.history

        ( replEntries, replIsCompiling ) =
            case heroState.compileState of
                HeroIdle ->
                    ( replHistory, False )

                HeroCompiling { command } ->
                    ( replHistory
                        ++ [ Repl.EntryCompiling { command = command } ]
                    , True
                    )
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
                    { entries = replEntries
                    , isCompiling = replIsCompiling
                    , pendingCommand = compileCommandFor snippet
                    , onSubmit = SubmitHeroCommand
                    , onReset = ResetHero
                    }
                ]
            )
        ]


activeSnippet : HeroState -> Examples.Snippet
activeSnippet heroState =
    snippetAt heroState.snippetIndex


snippetTabs : Viewport.Viewport -> HeroState -> Element Msg
snippetTabs viewport heroState =
    let
        indexed =
            visibleHeroSnippets viewport
    in
    Element.html
        (Html.div
            [ Html.Attributes.class "snippet-tabs"
            , Html.Attributes.attribute "role" "tablist"
            , Html.Attributes.attribute "aria-label" "Quone snippets"
            , Html.Attributes.attribute "aria-orientation" "horizontal"
            ]
            (List.map (snippetTabHtml indexed heroState.snippetIndex) indexed)
        )


snippetTabHtml : List ( Int, Examples.Snippet ) -> Int -> ( Int, Examples.Snippet ) -> Html.Html Msg
snippetTabHtml visible activeIdx ( idx, snippet ) =
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
        , snippetTabKeyHandler (List.map Tuple.first visible) idx
        , Html.Events.onClick (SelectSnippet idx)
        ]
        [ Html.text snippet.filename ]


snippetTabKeyHandler : List Int -> Int -> Html.Attribute Msg
snippetTabKeyHandler visibleIndices idx =
    Html.Events.preventDefaultOn "keydown"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    case keyToSnippetSelection visibleIndices idx key of
                        Just nextIdx ->
                            Decode.succeed ( SelectSnippet nextIdx, True )

                        Nothing ->
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


mobileHeroSnippetLimit : Int
mobileHeroSnippetLimit =
    3


visibleHeroSnippets : Viewport.Viewport -> List ( Int, Examples.Snippet )
visibleHeroSnippets viewport =
    let
        indexed =
            List.indexedMap Tuple.pair Examples.heroSnippets
    in
    if Viewport.isHandset viewport then
        List.take mobileHeroSnippetLimit indexed

    else
        indexed


keyToSnippetSelection : List Int -> Int -> String -> Maybe Int
keyToSnippetSelection visibleIndices currentIdx key =
    case key of
        "ArrowLeft" ->
            wrappedVisibleIndex -1 visibleIndices currentIdx

        "ArrowRight" ->
            wrappedVisibleIndex 1 visibleIndices currentIdx

        "Home" ->
            List.head visibleIndices

        "End" ->
            List.reverse visibleIndices |> List.head

        _ ->
            Nothing


wrappedVisibleIndex : Int -> List Int -> Int -> Maybe Int
wrappedVisibleIndex delta visibleIndices currentIdx =
    case indexOf currentIdx visibleIndices of
        Just currentPos ->
            let
                count =
                    List.length visibleIndices

                nextPos =
                    modBy count (currentPos + delta)
            in
            List.drop nextPos visibleIndices |> List.head

        Nothing ->
            List.head visibleIndices


indexOf : comparable -> List comparable -> Maybe Int
indexOf target items =
    let
        walk idx remaining =
            case remaining of
                [] ->
                    Nothing

                first :: rest ->
                    if first == target then
                        Just idx

                    else
                        walk (idx + 1) rest
    in
    walk 0 items


heroEntryToReplEntry : HeroEntry -> Repl.Entry
heroEntryToReplEntry entry =
    case entry of
        HeroEntrySuccess { command, result } ->
            Repl.EntrySuccess { command = command, result = result }

        HeroEntryError { command, message } ->
            Repl.EntryError { command = command, message = message }


{-| Switch the snippet picker to `idx`. Wipes the scrollback, pre-fills
the live prompt with `quone::compile("that_file.Q")`, and drops back to
`HeroIdle` so any in-flight simulated compile finishes as a no-op.

Clicking the same tab the user is already on is a no-op, matching
every tabbed UI ever.
-}
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
        { state
            | snippetIndex = nextIdx
            , history = []
            , compileState = HeroIdle
        }


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
        , Font.family Theme.fontMono
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
