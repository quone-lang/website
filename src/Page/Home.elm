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
their outcomes (the `history`, oldest first), the current in-flight
state (`compileState`, only `HeroIdle` or `HeroCompiling`), and the
text the user is currently typing on the live `>` prompt
(`commandText`).

Switching snippet tabs wipes the history, resets to `HeroIdle`, and
pre-fills `commandText` with the new snippet's `quone::compile("…")`
invocation -- effectively "starting a fresh R session focused on this
file." Submitting a command clears `commandText` and appends the
outcome to `history`, so successive runs stack up like a real console.
-}
type alias HeroState =
    { snippetIndex : Int
    , commandText : String
    , history : List HeroEntry
    , compileState : HeroCompileState
    }


{-| One past command in the REPL scrollback. Successes carry the
generated R; errors carry an R-flavoured error string. -}
type HeroEntry
    = HeroEntrySuccess { command : String, result : String }
    | HeroEntryError { command : String, message : String }


type HeroCompileState
    = HeroIdle
    | HeroCompiling { command : String, snippetIndex : Int }


initHeroState : HeroState
initHeroState =
    let
        idx =
            0
    in
    { snippetIndex = idx
    , commandText = compileCommandFor (snippetAt idx)
    , history = []
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

        SetHeroCommand newText ->
            ( { state | commandText = newText }, Cmd.none )

        SubmitHeroCommand ->
            submitCommand state

        HeroCompileFinished submittedCommand ->
            ( finishCompile submittedCommand state, Cmd.none )


submitCommand : HeroState -> ( HeroState, Cmd Msg )
submitCommand state =
    if isCompiling state.compileState then
        ( state, Cmd.none )

    else
        let
            trimmed =
                String.trim state.commandText
        in
        if String.isEmpty trimmed then
            ( state, Cmd.none )

        else
            case snippetIndexForCommand trimmed of
                Just snippetIdx ->
                    ( { state
                        | commandText = ""
                        , compileState =
                            HeroCompiling
                                { command = trimmed
                                , snippetIndex = snippetIdx
                                }
                      }
                    , Process.sleep heroCompileDelayMs
                        |> Task.perform (\_ -> HeroCompileFinished trimmed)
                    )

                Nothing ->
                    ( { state
                        | commandText = ""
                        , history =
                            state.history
                                ++ [ HeroEntryError
                                        { command = trimmed
                                        , message = demoOnlyError state
                                        }
                                   ]
                      }
                    , Cmd.none
                    )


{-| When a successful compile finishes we append a `HeroEntrySuccess`
to the scrollback (so the result lives under the previous run, just
like a real REPL) and return to `HeroIdle`. We do *not* touch
`snippetIndex` or `commandText` -- the user stays on whatever snippet
they were on, with an empty prompt ready for the next thing they want
to type.
-}
finishCompile : String -> HeroState -> HeroState
finishCompile submittedCommand state =
    case state.compileState of
        HeroCompiling pending ->
            if pending.command == submittedCommand then
                { state
                    | compileState = HeroIdle
                    , history =
                        state.history
                            ++ [ HeroEntrySuccess
                                    { command = pending.command
                                    , result = (snippetAt pending.snippetIndex).r
                                    }
                               ]
                }

            else
                state

        _ ->
            state


isCompiling : HeroCompileState -> Bool
isCompiling compileState =
    case compileState of
        HeroCompiling _ ->
            True

        _ ->
            False


{-| The hero REPL is a demo, not a real R interpreter. The only
thing it actually knows how to do is recognise the literal pattern
`quone::compile("file.Q")` for one of the snippets in the tabs above
and "compile" it (i.e. show the canned R the snippet ships with).

We don't try to be clever about R syntax for anything else; every
other input shape just produces the same friendly "demo only" error
through `demoOnlyError`.
-}
snippetIndexForCommand : String -> Maybe Int
snippetIndexForCommand input =
    input
        |> String.trim
        |> stripPrefix "quone::compile"
        |> Maybe.map String.trim
        |> Maybe.andThen (stripPrefix "(")
        |> Maybe.map String.trim
        |> Maybe.andThen (stripSuffix ")")
        |> Maybe.map String.trim
        |> Maybe.andThen parseStringLiteral
        |> Maybe.andThen snippetIndexByFilename


parseStringLiteral : String -> Maybe String
parseStringLiteral raw =
    let
        wrappedIn ch =
            String.length raw >= 2
                && String.startsWith ch raw
                && String.endsWith ch raw
    in
    if wrappedIn "\"" || wrappedIn "'" then
        Just (String.slice 1 (String.length raw - 1) raw)

    else
        Nothing


stripPrefix : String -> String -> Maybe String
stripPrefix prefix input =
    if String.startsWith prefix input then
        Just (String.dropLeft (String.length prefix) input)

    else
        Nothing


stripSuffix : String -> String -> Maybe String
stripSuffix suffix input =
    if String.endsWith suffix input then
        Just (String.dropRight (String.length suffix) input)

    else
        Nothing


{-| The single error the demo emits for any input it doesn't know
how to handle. We point the user at the active snippet so the hint
is something they can actually try right now -- click and re-run.
-}
demoOnlyError : HeroState -> String
demoOnlyError state =
    "This is a demo, not a real R interpreter.\nTry: "
        ++ compileCommandFor (snippetAt state.snippetIndex)


snippetIndexByFilename : String -> Maybe Int
snippetIndexByFilename filename =
    Examples.heroSnippets
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, snippet ) -> snippet.filename == filename)
        |> List.head
        |> Maybe.map Tuple.first


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
    | SetHeroCommand String
    | SubmitHeroCommand
    | HeroCompileFinished String


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
        [ snippetTabs heroState
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
                    , value = heroState.commandText
                    , onInput = SetHeroCommand
                    , onSubmit = SubmitHeroCommand
                    , inputId = "hero-repl-input"
                    }
                ]
            )
        ]


activeSnippet : HeroState -> Examples.Snippet
activeSnippet heroState =
    snippetAt heroState.snippetIndex


snippetTabs : HeroState -> Element Msg
snippetTabs heroState =
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


heroEntryToReplEntry : HeroEntry -> Repl.Entry
heroEntryToReplEntry entry =
    case entry of
        HeroEntrySuccess { command, result } ->
            Repl.EntrySuccess { command = command, result = result }

        HeroEntryError { command, message } ->
            Repl.EntryError { command = command, message = message }


{-| Switch the snippet picker to `idx`. We treat this as "start a
fresh R session focused on this file": wipe the scrollback, pre-fill
the live prompt with `quone::compile("that_file.Q")`, and cancel any
in-flight compile (its delayed `HeroCompileFinished` will arrive into
`HeroIdle` and quietly no-op).

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
            , commandText = compileCommandFor (snippetAt nextIdx)
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
