module Ui.Repl exposing
    ( Entry(..)
    , view
    )

{-| A small visual stand-in for the R REPL.

The widget mimics RStudio's console pane. The host always provides a
`pendingCommand` (the `> quone::compile("…")` line for the active
snippet); the REPL renders that line at the top of the scrollback so
the user can see "the next thing about to run" the way they would in
a real R console with a recalled history command. After the user
clicks Run, the host appends an `Entry` that pairs the same command
text with its compiled R (or error), and the scrollback shows the
output directly underneath.

The action row at the bottom is a single button:

  - Before any run: a green Run button.
  - After a run: a small Reset button that asks the host to wipe the
    history back to the pending state.
  - During an in-flight compile: the Run button hides (the spinner in
    the scrollback is enough signal).

The REPL is decorative in the sense that it is not attached to a real
R interpreter; the host page evaluates submitted commands itself and
feeds the resulting `Entry`s back in. The title bar carries a short
"demo" marker so users can tell.

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
        , pendingCommand : String
        , onSubmit : msg
        , onReset : msg
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


{-| Title-bar hint that this console is simulated, not a real R session.
-}
demoNote : Theme.Mode -> Bool -> Element msg
demoNote themeMode compact =
    let
        colors =
            Theme.paletteFor themeMode

        fullLabel =
            "Demo \u{00B7} not a live R session"

        shortLabel =
            "demo"

        labelText =
            if compact then
                shortLabel

            else
                fullLabel

        dotColor =
            rgb255 0x8A 0x8A 0x8A
    in
    row
        [ spacing 6
        , htmlAttribute (Html.Attributes.class "repl-demo-note")
        , htmlAttribute (Html.Attributes.attribute "title" labelText)
        ]
        [ liveDot dotColor
        , el
            [ Font.family Theme.fontSans
            , Font.size type_.smallSize
            , Font.color colors.textMuted
            ]
            (text labelText)
        ]


liveDot : Element.Color -> Element msg
liveDot color =
    el
        [ width (Element.px 7)
        , height (Element.px 7)
        , Border.rounded 4
        , Background.color color
        , htmlAttribute (Html.Attributes.attribute "aria-hidden" "true")
        ]
        Element.none


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


{-| The body below the title bar: a single scrollback column whose
first entry block carries the action button (Run before any
execution, Reset afterwards) inline with its prompt line. That keeps
the button vertically aligned with the `> quone::compile("…")` line
the user is acting on -- there is no separate "input bar" below the
console.
-}
consoleBody :
    Theme.Mode
    -> Viewport.Viewport
    ->
        { entries : List Entry
        , isCompiling : Bool
        , pendingCommand : String
        , onSubmit : msg
        , onReset : msg
        }
    -> Element msg
consoleBody themeMode viewport config =
    let
        pad =
            replPadding viewport
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
        , spacing (Theme.space.lg - 2)
        , htmlAttribute (Html.Attributes.style "min-width" "0")
        , htmlAttribute (Html.Attributes.style "overflow-x" "auto")
        , htmlAttribute (Html.Attributes.style "-webkit-overflow-scrolling" "touch")
        ]
        [ scrollbackArea themeMode
            viewport
            { pendingCommand = config.pendingCommand
            , entries = config.entries
            , isCompiling = config.isCompiling
            , onSubmit = config.onSubmit
            , onReset = config.onReset
            }
        ]


{-| Renders the scrollback as a stack of entry blocks. The very
first block is "live": its prompt row carries the action button
(Run, Reset, or none while a compile is in flight) on the right,
vertically aligned with the prompt text. Subsequent blocks (rare in
practice -- only ever appear if you wire the host to keep history
across runs) get a normal prompt row with no button.
-}
scrollbackArea :
    Theme.Mode
    -> Viewport.Viewport
    ->
        { pendingCommand : String
        , entries : List Entry
        , isCompiling : Bool
        , onSubmit : msg
        , onReset : msg
        }
    -> Element msg
scrollbackArea themeMode viewport { pendingCommand, entries, isCompiling, onSubmit, onReset } =
    let
        blocks =
            if isCompiling then
                -- During a compile the host appends an EntryCompiling
                -- spinner at the end of `entries`. We render every
                -- entry as a plain history row with no button -- the
                -- spinner is its own visual signal.
                List.map
                    (\entry ->
                        entryBlock themeMode
                            viewport
                            { entry = EntryRun entry
                            , action = ActionNone
                            }
                    )
                    entries

            else
                case List.reverse entries of
                    [] ->
                        -- Pre-Run: no history yet. Show the pending
                        -- prompt with the Run button anchored to it.
                        [ entryBlock themeMode
                            viewport
                            { entry = EntryPending { command = pendingCommand }
                            , action = ActionRun onSubmit
                            }
                        ]

                    latest :: olderReversed ->
                        -- Post-Run: older entries (in chronological
                        -- order) read as frozen scrollback, then the
                        -- latest entry carries the Reset button.
                        let
                            older =
                                olderReversed
                                    |> List.reverse
                                    |> List.map
                                        (\entry ->
                                            entryBlock themeMode
                                                viewport
                                                { entry = EntryRun entry
                                                , action = ActionNone
                                                }
                                        )

                            live =
                                entryBlock themeMode
                                    viewport
                                    { entry = EntryRun latest
                                    , action = ActionReset onReset
                                    }
                        in
                        older ++ [ live ]
    in
    column
        [ width fill
        , spacing (Theme.space.lg - 2)
        , htmlAttribute (Html.Attributes.class "repl-scrollback")
        ]
        blocks


{-| Internal entry shape used by `entryBlock`. `Entry` from the
public API doesn't have a "pending, no body" variant, so we add one
here for the pre-Run prompt row. -}
type EntryView
    = EntryPending { command : String }
    | EntryRun Entry


{-| Which action button -- if any -- to render inline with this
block's prompt line. `ActionNone` is used for older history rows and
the in-flight (spinner) state. -}
type Action msg
    = ActionRun msg
    | ActionReset msg
    | ActionNone


{-| One scrollback block: the prompt line on top (with an optional
action button on its right), and the result body underneath. The
button is anchored to the prompt row so it stays vertically aligned
with the `> quone::compile("…")` text the user is acting on. -}
entryBlock :
    Theme.Mode
    -> Viewport.Viewport
    ->
        { entry : EntryView
        , action : Action msg
        }
    -> Element msg
entryBlock themeMode viewport { entry, action } =
    let
        ( cmd, maybeBody ) =
            case entry of
                EntryPending pending ->
                    ( pending.command, Nothing )

                EntryRun (EntrySuccess success) ->
                    ( success.command
                    , Just (compiledOutput themeMode viewport success.result)
                    )

                EntryRun (EntryError failure) ->
                    ( failure.command
                    , Just (errorLine themeMode viewport failure.message)
                    )

                EntryRun (EntryCompiling pending) ->
                    ( pending.command
                    , Just (compilingLine themeMode)
                    )

        promptRow =
            historyRow themeMode viewport cmd action
    in
    case maybeBody of
        Nothing ->
            promptRow

        Just body ->
            column
                [ width fill
                , spacing (Theme.space.md + 2)
                ]
                [ promptRow
                , body
                ]


{-| The prompt row: `> quone::compile("…")` on the left (with R-style
syntax highlighting on the call), and the action button (Run or
Reset) anchored to the right, vertically centered against the prompt
text so the two read as one row.

On a handset the row stacks: the prompt above, a full-width button
below, so the touch target stays comfortable.
-}
historyRow :
    Theme.Mode
    -> Viewport.Viewport
    -> String
    -> Action msg
    -> Element msg
historyRow themeMode viewport command action =
    let
        compact =
            Viewport.isHandset viewport

        prompt =
            historyLine themeMode viewport command

        button =
            actionButton themeMode { action = action, compact = compact }
    in
    case ( action, button ) of
        ( ActionNone, _ ) ->
            prompt

        ( _, Nothing ) ->
            prompt

        ( _, Just btn ) ->
            if compact then
                column
                    [ width fill
                    , spacing Theme.space.sm
                    ]
                    [ prompt
                    , el [ width fill ] btn
                    ]

            else
                row
                    [ width fill
                    , spacing Theme.space.md
                    ]
                    [ el [ width fill ] prompt
                    , el [ Element.alignRight, centerY ] btn
                    ]


{-| The submitted command, rendered RStudio-style: the `>` glyph and
the command text live in the same line as a single piece of inline
HTML. Doing the prompt as a real character (rather than a separate
flex sibling) means the gap between glyph and text is exactly one
mono space wide -- the same way an R console paints it -- and we
don't fight elm-ui's `row` spacing for ownership of the gap.
-}
historyLine : Theme.Mode -> Viewport.Viewport -> String -> Element msg
historyLine themeMode viewport command =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ width fill
        , Font.family Theme.fontMono
        , Font.size (commandFontSize viewport)
        , Font.color colors.textPrimary
        , htmlAttribute (Html.Attributes.style "white-space" "pre-wrap")
        , htmlAttribute (Html.Attributes.style "word-break" "break-word")
        , htmlAttribute (Html.Attributes.class "repl-history")
        ]
        (Element.html
            (Html.span []
                (Html.span
                    [ Html.Attributes.class "repl-prompt-glyph"
                    , Html.Attributes.attribute "aria-hidden" "true"
                    ]
                    [ Html.text ">" ]
                    :: Html.text " "
                    :: highlightRCall command
                )
            )
        )


{-| Tokenise an R call like `quone::compile("file.Q")` into spans
that match the same `tok-*` palette the R code blocks use. Anything
the regex doesn't recognise (whitespace, identifiers without a
following `(`, etc.) falls through as plain text so the highlighter
degrades gracefully on commands we don't anticipate.

The regex captures, in order: a package prefix (`pkg::`), a function
name immediately followed by `(`, an opening or closing paren, a
`::` operator, or a quoted string literal. -}
highlightRCall : String -> List (Html.Html msg)
highlightRCall input =
    let
        chunks =
            tokenizeRCall input
    in
    List.map renderToken chunks


type RToken
    = TPkg String
    | TOp String
    | TFn String
    | TParen String
    | TStr String
    | TPlain String


renderToken : RToken -> Html.Html msg
renderToken token =
    case token of
        TPkg name ->
            Html.span [ Html.Attributes.class "tok-pkg" ] [ Html.text name ]

        TOp op ->
            Html.span [ Html.Attributes.class "tok-op" ] [ Html.text op ]

        TFn name ->
            Html.span [ Html.Attributes.class "tok-fn" ] [ Html.text name ]

        TParen p ->
            Html.span [ Html.Attributes.class "tok-paren" ] [ Html.text p ]

        TStr s ->
            Html.span [ Html.Attributes.class "tok-str" ] [ Html.text s ]

        TPlain s ->
            Html.text s


{-| Hand-rolled tokenizer for the small grammar we actually emit:

    pkgname::fnname(  "string literal" , "string literal" )

We walk the input left-to-right; at each step we look at the next few
characters and decide which token (if any) starts here. Anything we
don't recognise we accumulate into a `TPlain` chunk so it's rendered
verbatim.

This is intentionally tiny -- the prompt text is always a generated
`quone::compile("…")` call. The point is just to colour it the same
way the rest of the site does, not to be a real R parser. -}
tokenizeRCall : String -> List RToken
tokenizeRCall src =
    tokenizeHelp (String.toList src) "" []


tokenizeHelp : List Char -> String -> List RToken -> List RToken
tokenizeHelp chars buffer acc =
    case chars of
        [] ->
            List.reverse (flushPlain buffer acc)

        '"' :: rest ->
            let
                ( literal, after ) =
                    consumeString rest [ '"' ]

                acc1 =
                    flushPlain buffer acc
            in
            tokenizeHelp after "" (TStr literal :: acc1)

        ':' :: ':' :: rest ->
            let
                ( pkgName, beforeOp ) =
                    splitTrailingIdent buffer

                acc1 =
                    flushPlain beforeOp acc

                acc2 =
                    if String.isEmpty pkgName then
                        TOp "::" :: acc1

                    else
                        TOp "::" :: TPkg pkgName :: acc1
            in
            tokenizeHelp rest "" acc2

        '(' :: rest ->
            let
                ( fnName, beforeFn ) =
                    splitTrailingIdent buffer

                acc1 =
                    flushPlain beforeFn acc

                acc2 =
                    if String.isEmpty fnName then
                        TParen "(" :: acc1

                    else
                        TParen "(" :: TFn fnName :: acc1
            in
            tokenizeHelp rest "" acc2

        ')' :: rest ->
            let
                acc1 =
                    flushPlain buffer acc
            in
            tokenizeHelp rest "" (TParen ")" :: acc1)

        ch :: rest ->
            tokenizeHelp rest (buffer ++ String.fromChar ch) acc


flushPlain : String -> List RToken -> List RToken
flushPlain buffer acc =
    if String.isEmpty buffer then
        acc

    else
        TPlain buffer :: acc


{-| Walk back from the end of `buffer` collecting an R identifier
(letters, digits, `.`, `_`). Returns `(ident, prefix)` where
`buffer == prefix ++ ident`. Used to peel `pkg` off "...someprefix
pkg" before a `::` and to peel `fn` off "...stuff fn" before a `(`.
-}
splitTrailingIdent : String -> ( String, String )
splitTrailingIdent buffer =
    let
        -- Walk the buffer right-to-left collecting identifier
        -- characters. `takeIdentFromEnd` gives us the identifier
        -- already in correct order, plus the still-reversed prefix
        -- (it iterated over the reversed input).
        ( identChars, reversedPrefix ) =
            takeIdentFromEnd
                (List.reverse (String.toList buffer))
                []

        ident =
            String.fromList identChars

        prefix =
            String.fromList (List.reverse reversedPrefix)
    in
    ( ident, prefix )


takeIdentFromEnd : List Char -> List Char -> ( List Char, List Char )
takeIdentFromEnd reversedChars taken =
    case reversedChars of
        ch :: rest ->
            if isIdentChar ch then
                -- `taken` accumulates identifier chars. Because we're
                -- consuming the buffer from its right edge, prepending
                -- each new char keeps `taken` in left-to-right order.
                takeIdentFromEnd rest (ch :: taken)

            else
                ( taken, ch :: rest )

        [] ->
            ( taken, [] )


isIdentChar : Char -> Bool
isIdentChar ch =
    Char.isAlphaNum ch || ch == '_' || ch == '.'


{-| Walks forward through a string literal that started with `"`. The
opening quote is already in `acc` (passed in by the caller). We
consume characters until we see an unescaped closing `"`, returning
the full literal (including both quotes) and the remaining input. -}
consumeString : List Char -> List Char -> ( String, List Char )
consumeString chars acc =
    case chars of
        '\\' :: next :: rest ->
            consumeString rest (next :: '\\' :: acc)

        '"' :: rest ->
            ( String.fromList (List.reverse ('"' :: acc)), rest )

        ch :: rest ->
            consumeString rest (ch :: acc)

        [] ->
            ( String.fromList (List.reverse acc), [] )


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


{-| Pick the right inline action button for a prompt row, or
`Nothing` when the row should sit on its own (older history rows or
the in-flight compile state).
-}
actionButton :
    Theme.Mode
    ->
        { action : Action msg
        , compact : Bool
        }
    -> Maybe (Element msg)
actionButton themeMode { action, compact } =
    case action of
        ActionRun onRun ->
            Just
                (runButton
                    { themeMode = themeMode
                    , onRun = onRun
                    , compact = compact
                    }
                )

        ActionReset onReset ->
            Just
                (resetButton
                    { themeMode = themeMode
                    , onReset = onReset
                    , compact = compact
                    }
                )

        ActionNone ->
            Nothing


commandFontSize : Viewport.Viewport -> Int
commandFontSize viewport =
    if Viewport.isHandset viewport then
        type_.codeSmallSize

    else
        type_.codeSize


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


{-| Quiet button shown after a run, in the same slot the green Run
button used to occupy. Clicking it asks the host to wipe the
scrollback so the user can re-play the demo on the same snippet (or
another) without reloading the page. -}
resetButton :
    { themeMode : Theme.Mode
    , onReset : msg
    , compact : Bool
    }
    -> Element msg
resetButton { themeMode, onReset, compact } =
    let
        colors =
            Theme.paletteFor themeMode

        label =
            Element.html
                (Html.span
                    [ Html.Attributes.class "repl-reset-label" ]
                    (if compact then
                        [ Html.text "Reset" ]

                     else
                        [ resetGlyphHtml, Html.text "Reset" ]
                    )
                )

        baseAttrs =
            [ Background.color (resetSurface themeMode)
            , Font.color colors.textSecondary
            , Font.size type_.smallSize
            , Font.semiBold
            , Border.rounded
                (if compact then
                    Theme.radius.md

                 else
                    Theme.radius.sm
                )
            , Border.width 1
            , Border.color colors.border
            , paddingXY Theme.space.md
                (if compact then
                    Theme.space.sm + 4

                 else
                    Theme.space.xs + 2
                )
            , Element.mouseOver
                [ Background.color (resetSurfaceHover themeMode)
                , Font.color colors.textPrimary
                ]
            , htmlAttribute (Html.Attributes.class "repl-reset")
            , htmlAttribute (Html.Attributes.attribute "aria-label" "Reset console")
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
        { onPress = Just onReset
        , label = label
        }


resetSurface : Theme.Mode -> Element.Color
resetSurface themeMode =
    if Theme.isDark themeMode then
        rgb255 0x1B 0x22 0x2C

    else
        rgb255 0xF1 0xEE 0xE8


resetSurfaceHover : Theme.Mode -> Element.Color
resetSurfaceHover themeMode =
    if Theme.isDark themeMode then
        rgb255 0x24 0x2C 0x37

    else
        rgb255 0xE6 0xE2 0xDA


resetGlyphHtml : Html.Html msg
resetGlyphHtml =
    Html.span
        [ Html.Attributes.class "repl-reset-glyph"
        , Html.Attributes.attribute "aria-hidden" "true"
        ]
        [ Html.text "\u{21BA}" ]


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
