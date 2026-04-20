module Ui.Repl exposing
    ( Entry(..)
    , view
    )

{-| A small visual stand-in for the R REPL.

The widget mimics RStudio's console pane: a scrollback area listing
all past commands in order with their results (printed R, errors, or
a live spinner for an in-flight compile), and a live `>` prompt at
the bottom that the user can actually type into.

The host page owns the history list -- successive runs simply append
new `Entry` values to it, which makes the REPL feel like a real
session ("the next result appears under the previous one"). When the
host wants to "reset" -- e.g. after a snippet tab change -- it passes
an empty list and the scrollback collapses.

The REPL is decorative in the sense that it is not attached to a real
R interpreter; the host page evaluates submitted commands itself and
feeds the resulting `Entry`s back in. The title bar carries a "demo -
not a live R session" marker so users can tell.

Animations (output reveal, spinner) live in `static/index.html`.

-}

import Element
    exposing
        ( Element
        , centerY
        , column
        , el
        , fill
        , height
        , htmlAttribute
        , paddingEach
        , paddingXY
        , px
        , rgb255
        , row
        , shrink
        , spacing
        , text
        , width
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Ui.CodeBlock as CodeBlock
import Ui.Theme as Theme exposing (type_)
import Ui.Viewport as Viewport



-- PUBLIC API


{-| One past or in-flight entry in the REPL scrollback.

  - `EntrySuccess`: the user ran something and the demo printed R back
    -- like a real evaluated R expression.
  - `EntryError`: the user ran something invalid and the demo printed
    a red R-style error (e.g. `Error: could not find function "mean"`).
  - `EntryCompiling`: the user just submitted; the command line is
    shown plainly with a spinner underneath. Replaced by `EntrySuccess`
    when the (fake) compile finishes.

-}
type Entry
    = EntrySuccess { command : String, result : String }
    | EntryError { command : String, message : String }
    | EntryCompiling { command : String }


view :
    Theme.Mode
    -> Viewport.Viewport
    ->
        { entries : List Entry
        , isCompiling : Bool
        , value : String
        , onInput : String -> msg
        , onSubmit : msg
        , inputId : String
        }
    -> Element msg
view themeMode viewport config =
    let
        colors =
            Theme.paletteFor themeMode
    in
    column
        [ width fill
        , height shrink
        , htmlAttribute (Html.Attributes.style "flex-basis" "auto")
        , htmlAttribute (Html.Attributes.style "flex-shrink" "0")
        , Background.color (reSurface themeMode)
        , Border.rounded Theme.radius.md
        , Border.width 1
        , Border.color colors.border
        , htmlAttribute (Html.Attributes.class "repl-window")
        , htmlAttribute (Html.Attributes.style "overflow" "hidden")
        ]
        [ titleBar themeMode viewport
        , consoleBody themeMode viewport config
        ]



-- INTERNALS


reSurface : Theme.Mode -> Element.Color
reSurface themeMode =
    if Theme.isDark themeMode then
        rgb255 0x12 0x18 0x20

    else
        rgb255 0xFB 0xFA 0xF7


reSurfaceDark : Theme.Mode -> Element.Color
reSurfaceDark themeMode =
    if Theme.isDark themeMode then
        rgb255 0x0D 0x13 0x1A

    else
        rgb255 0xF1 0xEE 0xE8


runGreen : Theme.Mode -> Element.Color
runGreen themeMode =
    if Theme.isDark themeMode then
        rgb255 0x37 0x8E 0x48

    else
        rgb255 0x2E 0x7D 0x32


runGreenHover : Theme.Mode -> Element.Color
runGreenHover themeMode =
    if Theme.isDark themeMode then
        rgb255 0x45 0xA4 0x56

    else
        rgb255 0x38 0x96 0x3C


titleBar : Theme.Mode -> Viewport.Viewport -> Element msg
titleBar themeMode viewport =
    let
        colors =
            Theme.paletteFor themeMode
    in
    if Viewport.isHandset viewport then
        row
            [ width fill
            , Background.color (reSurfaceDark themeMode)
            , paddingXY Theme.space.md (Theme.space.sm + 2)
            , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
            , Border.color colors.border
            , spacing Theme.space.sm
            ]
            [ trafficLights
            , el
                [ Font.family Theme.fontMono
                , Font.size type_.smallSize
                , Font.color colors.textMuted
                ]
                (text "R 4.4.1")
            , el [ Element.alignRight ] (demoNote themeMode True)
            ]

    else
        row
            [ width fill
            , Background.color (reSurfaceDark themeMode)
            , paddingXY Theme.space.md (Theme.space.sm + 2)
            , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
            , Border.color colors.border
            , spacing Theme.space.md
            ]
            [ trafficLights
            , el
                [ Font.family Theme.fontMono
                , Font.size type_.codeSmallSize
                , Font.color colors.textMuted
                ]
                (Element.html
                    (Html.span []
                        [ Html.text "R 4.4.1"
                        , Html.span
                            [ Html.Attributes.class "repl-title-sep" ]
                            [ Html.text " \u{00B7} " ]
                        , Html.text "~/quone-demo"
                        ]
                    )
                )
            , el [ Element.alignRight ] (demoNote themeMode False)
            ]


{-| Small italic note that lives in the title bar so the user can tell
this is a marketing demo, not a live R session attached to a real
interpreter.
-}
demoNote : Theme.Mode -> Bool -> Element msg
demoNote themeMode compact =
    let
        colors =
            Theme.paletteFor themeMode

        labelText =
            if compact then
                "demo"

            else
                "demo \u{00B7} not a live R session"
    in
    el
        [ Font.family Theme.fontSans
        , Font.size type_.smallSize
        , Font.color colors.textMuted
        , Font.italic
        , htmlAttribute (Html.Attributes.class "repl-demo-note")
        , htmlAttribute (Html.Attributes.attribute "title" "Marketing demo - not a live R session")
        ]
        (text labelText)


trafficLights : Element msg
trafficLights =
    row [ spacing 6 ]
        [ trafficDot (rgb255 0xFF 0x60 0x57)
        , trafficDot (rgb255 0xFF 0xBD 0x2E)
        , trafficDot (rgb255 0x27 0xC9 0x3F)
        ]


trafficDot : Element.Color -> Element msg
trafficDot color =
    el
        [ width (px 12)
        , height (px 12)
        , Border.rounded 6
        , Background.color color
        ]
        Element.none


{-| The body below the title bar: an accumulating scrollback of past
entries, then a live input prompt with a Run button. When a compile
is in flight we hide the input -- in a real R session you can't type
the next command until the prompt comes back.
-}
consoleBody :
    Theme.Mode
    -> Viewport.Viewport
    ->
        { entries : List Entry
        , isCompiling : Bool
        , value : String
        , onInput : String -> msg
        , onSubmit : msg
        , inputId : String
        }
    -> Element msg
consoleBody themeMode viewport config =
    let
        pad =
            replPadding viewport

        scrollback =
            scrollbackArea themeMode viewport config.entries

        inputBar =
            if config.isCompiling then
                Element.none

            else
                livePrompt themeMode viewport
                    { value = config.value
                    , onInput = config.onInput
                    , onSubmit = config.onSubmit
                    , inputId = config.inputId
                    }
    in
    column
        [ width fill
        -- Same iOS WebKit hygiene as in `view`: without these, the
        -- console body collapses to its smallest possible height
        -- (around 65px) on iPhone, leaving the REPL window looking
        -- like just a title bar with no console.
        , height shrink
        , htmlAttribute (Html.Attributes.style "flex-basis" "auto")
        , htmlAttribute (Html.Attributes.style "flex-shrink" "0")
        , Background.color (reSurface themeMode)
        , paddingXY pad (Theme.space.md - 2)
        , spacing (Theme.space.sm - 2)
        , htmlAttribute (Html.Attributes.style "min-width" "0")
        , htmlAttribute (Html.Attributes.style "overflow-x" "auto")
        , htmlAttribute (Html.Attributes.style "-webkit-overflow-scrolling" "touch")
        ]
        [ scrollback
        , inputBar
        ]


{-| Renders the entire scrollback: one block per past entry, oldest
first, like a real REPL. Returns `Element.none` when empty so the
console pane collapses to just the live prompt.
-}
scrollbackArea :
    Theme.Mode
    -> Viewport.Viewport
    -> List Entry
    -> Element msg
scrollbackArea themeMode viewport entries =
    case entries of
        [] ->
            Element.none

        _ ->
            column
                [ width fill
                , spacing (Theme.space.sm + 2)
                , htmlAttribute (Html.Attributes.class "repl-scrollback")
                ]
                (List.map (entryBlock themeMode viewport) entries)


{-| One scrollback block: the prior `>` command line on top, with the
result (printed R), error (red), or spinner (still compiling) just
below it. Each block is its own little stanza, stacked into the
scrollback by `spacing` above. -}
entryBlock : Theme.Mode -> Viewport.Viewport -> Entry -> Element msg
entryBlock themeMode viewport entry =
    let
        ( cmd, body ) =
            case entry of
                EntrySuccess success ->
                    ( success.command
                    , compiledOutput themeMode viewport success.result
                    )

                EntryError failure ->
                    ( failure.command
                    , errorLine themeMode viewport failure.message
                    )

                EntryCompiling pending ->
                    ( pending.command
                    , compilingLine themeMode
                    )
    in
    column
        [ width fill
        , spacing (Theme.space.sm - 4)
        ]
        [ historyLine themeMode viewport cmd
        , body
        ]


{-| The submitted command, frozen as plain monospaced text the way
RStudio shows previously-evaluated input. No syntax highlighting, no
caret.
-}
historyLine : Theme.Mode -> Viewport.Viewport -> String -> Element msg
historyLine themeMode viewport command =
    let
        colors =
            Theme.paletteFor themeMode
    in
    row
        [ width fill
        , spacing Theme.space.sm
        , htmlAttribute (Html.Attributes.class "repl-history")
        ]
        [ promptGlyph themeMode viewport
        , el
            [ Font.family Theme.fontMono
            , Font.size (commandFontSize viewport)
            , Font.color colors.textPrimary
            , htmlAttribute (Html.Attributes.style "white-space" "pre-wrap")
            , htmlAttribute (Html.Attributes.style "word-break" "break-word")
            , centerY
            ]
            (text command)
        ]


compiledOutput : Theme.Mode -> Viewport.Viewport -> String -> Element msg
compiledOutput themeMode viewport rSource =
    el
        [ width fill
        -- iOS WebKit collapses unconstrained flex children inside a
        -- column to a single visible row unless we pin the basis and
        -- forbid shrinking. Without these styles the generated R
        -- shows up as one truncated line on iPhone. (Same family of
        -- fixes used elsewhere in the REPL chrome.)
        , height shrink
        , htmlAttribute (Html.Attributes.style "flex-basis" "auto")
        , htmlAttribute (Html.Attributes.style "flex-shrink" "0")
        , htmlAttribute (Html.Attributes.style "min-width" "0")
        , htmlAttribute (Html.Attributes.style "overflow-x" "auto")
        , htmlAttribute
            (Html.Attributes.style "-webkit-overflow-scrolling" "touch")
        , htmlAttribute (Html.Attributes.class "repl-output")
        , paddingEach { top = 4, right = 0, bottom = 0, left = 0 }
        ]
        (CodeBlock.viewBare themeMode viewport CodeBlock.R rSource)


errorLine : Theme.Mode -> Viewport.Viewport -> String -> Element msg
errorLine themeMode viewport message =
    el
        [ Font.family Theme.fontMono
        , Font.size (commandFontSize viewport)
        , Font.color (errorRed themeMode)
        , Font.semiBold
        , htmlAttribute (Html.Attributes.class "repl-error")
        , htmlAttribute (Html.Attributes.style "white-space" "pre-wrap")
        , htmlAttribute (Html.Attributes.style "word-break" "break-word")
        , paddingEach { top = 4, right = 0, bottom = 0, left = 0 }
        ]
        (text message)


{-| RStudio-flavoured red used for the `Error: ...` line. We pick
saturated values that read clearly on each theme background -- the
darker red on light mode mirrors RStudio Desktop, the brighter red on
dark mode keeps contrast acceptable on near-black surfaces. -}
errorRed : Theme.Mode -> Element.Color
errorRed themeMode =
    if Theme.isDark themeMode then
        rgb255 0xFF 0x6B 0x6B

    else
        rgb255 0xC6 0x28 0x28


{-| The live `>` prompt at the bottom of the console: prompt glyph,
the editable text input, and the Run R button. This is what the user
actually interacts with -- everything above it is read-only history.
-}
livePrompt :
    Theme.Mode
    -> Viewport.Viewport
    ->
        { value : String
        , onInput : String -> msg
        , onSubmit : msg
        , inputId : String
        }
    -> Element msg
livePrompt themeMode viewport { value, onInput, onSubmit, inputId } =
    let
        compact =
            Viewport.isHandset viewport

        promptInput =
            row
                [ width fill
                , spacing Theme.space.sm
                , htmlAttribute (Html.Attributes.class "repl-prompt repl-prompt-live")
                ]
                [ promptGlyph themeMode viewport
                , consoleInput viewport
                    { value = value
                    , onInput = onInput
                    , onSubmit = onSubmit
                    , inputId = inputId
                    }
                ]

        run =
            runButton
                { themeMode = themeMode
                , onRun = onSubmit
                , compact = compact
                }
    in
    if compact then
        column
            [ width fill, spacing Theme.space.sm ]
            [ promptInput
            , el [ width fill ] run
            ]

    else
        row
            [ width fill, spacing Theme.space.sm ]
            [ promptInput
            , run
            ]


promptGlyph : Theme.Mode -> Viewport.Viewport -> Element msg
promptGlyph themeMode viewport =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.family Theme.fontMono
        , Font.size (commandFontSize viewport)
        , Font.color colors.primary
        , Font.semiBold
        , centerY
        ]
        (text ">")


commandFontSize : Viewport.Viewport -> Int
commandFontSize viewport =
    if Viewport.isHandset viewport then
        type_.codeSmallSize

    else
        type_.codeSize


{-| The transparent text input that lives where the live `>` prompt
caret would be. We layer a syntax-highlighted overlay on top of an
otherwise transparent native `<input>`, so the user gets RStudio-style
colour on whatever they have typed without losing the native caret,
selection, IME, autofill suppression, or accessibility behaviour.

When the typed text matches the demo's only recognised function shape
(`quone::compile("…")`), `highlightRCall` colours the tokens; for any
other text the overlay shows the raw characters in the body colour,
which still feels right because RStudio also leaves unrecognised
input plain.

The overlay is `aria-hidden`; the real input keeps the accessible
name. We drop down to raw HTML here because elm-ui's `Input.text`
doesn't expose enough hooks for the overlay layout.
-}
consoleInput :
    Viewport.Viewport
    ->
        { value : String
        , onInput : String -> msg
        , onSubmit : msg
        , inputId : String
        }
    -> Element msg
consoleInput viewport { value, onInput, onSubmit, inputId } =
    let
        sizeClass =
            if Viewport.isHandset viewport then
                "repl-input-wrap repl-input-wrap-sm"

            else
                "repl-input-wrap"

        overlay =
            if String.isEmpty value then
                Html.text ""

            else
                Html.span
                    [ Html.Attributes.class "repl-input-overlay"
                    , Html.Attributes.attribute "aria-hidden" "true"
                    ]
                    (highlightRCall value)
    in
    el
        [ width fill
        , centerY
        , htmlAttribute (Html.Attributes.style "min-width" "0")
        ]
        (Element.html
            (Html.div
                [ Html.Attributes.class sizeClass ]
                [ overlay
                , Html.input
                    [ Html.Attributes.class "repl-input"
                    , Html.Attributes.id inputId
                    , Html.Attributes.type_ "text"
                    , Html.Attributes.value value
                    , Html.Attributes.placeholder "quone::compile(\"normalize.Q\")"
                    , Html.Attributes.attribute "aria-label" "R prompt input"
                    , Html.Attributes.attribute "spellcheck" "false"
                    , Html.Attributes.attribute "autocomplete" "off"
                    , Html.Attributes.attribute "autocorrect" "off"
                    , Html.Attributes.attribute "autocapitalize" "off"
                    , Html.Events.onInput onInput
                    , onEnter onSubmit
                    ]
                    []
                ]
            )
        )


onEnter : msg -> Html.Attribute msg
onEnter msg =
    Html.Events.preventDefaultOn "keydown"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    if key == "Enter" then
                        Decode.succeed ( msg, True )

                    else
                        Decode.fail "not Enter"
                )
        )


{-| Tiny syntax-highlight pass for the literal `quone::compile("…")`
form that the live prompt accepts. Falls back to plain text for
anything that doesn't parse, which keeps the overlay safe even while
the user is mid-keystroke.
-}
highlightRCall : String -> List (Html.Html msg)
highlightRCall input =
    case splitAtFirst "::" input of
        Just ( pkg, afterPkg ) ->
            case splitAtFirst "(" afterPkg of
                Just ( fn, afterParen ) ->
                    let
                        ( inside, closeParen ) =
                            if String.endsWith ")" afterParen then
                                ( String.dropRight 1 afterParen, ")" )

                            else
                                ( afterParen, "" )
                    in
                    [ tokSpan "tok-pkg" pkg
                    , tokSpan "tok-op" "::"
                    , tokSpan "tok-fn" fn
                    , tokSpan "tok-paren" "("
                    ]
                        ++ highlightInside inside
                        ++ (if closeParen == "" then
                                []

                            else
                                [ tokSpan "tok-paren" ")" ]
                           )

                Nothing ->
                    [ tokSpan "tok-pkg" pkg
                    , tokSpan "tok-op" "::"
                    , Html.text afterPkg
                    ]

        Nothing ->
            [ Html.text input ]


highlightInside : String -> List (Html.Html msg)
highlightInside inside =
    let
        trimmed =
            String.trim inside
    in
    if String.isEmpty trimmed then
        if String.isEmpty inside then
            []

        else
            [ Html.text inside ]

    else if isQuoted trimmed then
        let
            leading =
                takeLeading isWhitespace inside

            trailing =
                takeTrailing isWhitespace inside

            literal =
                inside
                    |> String.dropLeft (String.length leading)
                    |> String.dropRight (String.length trailing)
        in
        [ Html.text leading
        , tokSpan "tok-str" literal
        , Html.text trailing
        ]

    else
        [ Html.text inside ]


tokSpan : String -> String -> Html.Html msg
tokSpan cls textValue =
    Html.span [ Html.Attributes.class cls ] [ Html.text textValue ]


splitAtFirst : String -> String -> Maybe ( String, String )
splitAtFirst needle haystack =
    case String.indexes needle haystack of
        i :: _ ->
            Just
                ( String.left i haystack
                , String.dropLeft (i + String.length needle) haystack
                )

        [] ->
            Nothing


isQuoted : String -> Bool
isQuoted s =
    String.length s
        >= 2
        && (String.startsWith "\"" s && String.endsWith "\"" s)
        || (String.startsWith "'" s && String.endsWith "'" s)


takeLeading : (Char -> Bool) -> String -> String
takeLeading predicate input =
    input
        |> String.toList
        |> takeWhile predicate
        |> String.fromList


takeTrailing : (Char -> Bool) -> String -> String
takeTrailing predicate input =
    input
        |> String.toList
        |> List.reverse
        |> takeWhile predicate
        |> List.reverse
        |> String.fromList


takeWhile : (a -> Bool) -> List a -> List a
takeWhile predicate list =
    case list of
        [] ->
            []

        x :: xs ->
            if predicate x then
                x :: takeWhile predicate xs

            else
                []


isWhitespace : Char -> Bool
isWhitespace c =
    c == ' ' || c == '\t' || c == '\n' || c == '\u{000D}'


compilingLine : Theme.Mode -> Element msg
compilingLine themeMode =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ htmlAttribute (Html.Attributes.class "repl-compiling")
        , Font.color colors.textSecondary
        , htmlAttribute (Html.Attributes.style "white-space" "pre")
        , paddingEach { top = 4, right = 0, bottom = 0, left = 0 }
        ]
        (Element.html
            (Html.span
                [ Html.Attributes.attribute "role" "status"
                , Html.Attributes.attribute "aria-label" "Compiling"
                ]
                [ Html.span
                    [ Html.Attributes.class "repl-spinner"
                    , Html.Attributes.attribute "aria-hidden" "true"
                    ]
                    []
                , Html.span
                    [ Html.Attributes.class "repl-compiling-label" ]
                    [ Html.text "Compiling" ]
                ]
            )
        )


runButton :
    { themeMode : Theme.Mode
    , onRun : msg
    , compact : Bool
    }
    -> Element msg
runButton { themeMode, onRun, compact } =
    let
        colors =
            Theme.paletteFor themeMode

        label =
            Element.html
                (Html.span
                    [ Html.Attributes.class "repl-run-label" ]
                    (if compact then
                        [ Html.text "Run" ]

                     else
                        [ playGlyphHtml, Html.text "Run R" ]
                    )
                )

        baseAttrs =
            [ Background.color (runGreen themeMode)
            , Font.color colors.textOnPrimary
            , Font.size type_.smallSize
            , Font.semiBold
            , Border.rounded
                (if compact then
                    Theme.radius.md

                 else
                    Theme.radius.sm
                )
            , paddingXY Theme.space.md
                (if compact then
                    Theme.space.sm + 4

                 else
                    Theme.space.xs + 2
                )
            , Element.mouseOver [ Background.color (runGreenHover themeMode) ]
            , htmlAttribute (Html.Attributes.class "repl-run")
            , htmlAttribute (Html.Attributes.attribute "aria-label" "Run R")
            , htmlAttribute
                (Html.Attributes.style "min-height"
                    (if compact then
                        "44px"

                     else
                        "auto"
                    )
                )
            , centerY
            ]
                ++ (if compact then
                        [ width fill
                        , Font.center
                        ]

                    else
                        []
                   )
    in
    Input.button
        baseAttrs
        { onPress = Just onRun
        , label = label
        }


playGlyphHtml : Html.Html msg
playGlyphHtml =
    Html.span
        [ Html.Attributes.class "repl-play"
        , Html.Attributes.attribute "aria-hidden" "true"
        ]
        [ Html.text "\u{25B6}" ]


replPadding : Viewport.Viewport -> Int
replPadding viewport =
    if Viewport.isHandset viewport then
        Theme.space.md

    else
        Theme.space.lg
