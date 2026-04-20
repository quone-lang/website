module Ui.Repl exposing
    ( Output(..)
    , view
    )

{-| A small visual stand-in for the R REPL.

The REPL is decorative: it shows a Quone-package call (`quone::compile`)
that the user can preview via a green button. The site supplies the
output state (idle, loading preview, or showing a generated R block),
and this module renders the chrome around it.

The REPL is not a real terminal; it just *looks* like one so the
"preview generated R" interaction feels tangible without forcing the user to
read documentation. Animations (cursor blink, output reveal, spinner)
live in `static/index.html`.

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
import Ui.CodeBlock as CodeBlock
import Ui.Theme as Theme exposing (type_)
import Ui.Viewport as Viewport



-- PUBLIC API


{-| What the REPL currently shows under the input row.

  - `Idle`: a muted hint, waiting for the user to click Run.
  - `Compiling`: an animated "Compiling Quone..." line.
  - `Compiled`: the generated R source, printed plain like real R
    console output (no command echo).

-}
type Output
    = Idle
    | Compiling
    | Compiled String


view :
    Theme.Mode
    -> Viewport.Viewport
    ->
        { command : String
        , output : Output
        , onRun : msg
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
        , inputRow themeMode viewport
            { command = config.command
            , output = config.output
            , onRun = config.onRun
            }
        , outputArea themeMode viewport config.output
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
                [ Font.family [ Theme.fontMono, Font.monospace ]
                , Font.size type_.smallSize
                , Font.color colors.textMuted
                ]
                (text "R preview")
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
                [ Font.family [ Theme.fontMono, Font.monospace ]
                , Font.size type_.codeSmallSize
                , Font.color colors.textMuted
                , Element.centerX
                ]
                (text "R 4.4.1 - Console")
            , el [ width (px 56) ] Element.none
            ]


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


inputRow :
    Theme.Mode
    -> Viewport.Viewport
    ->
        { command : String
        , output : Output
        , onRun : msg
        }
    -> Element msg
inputRow themeMode viewport { command, output, onRun } =
    let
        colors =
            Theme.paletteFor themeMode

        isRunning =
            output == Compiling

        compact =
            Viewport.isHandset viewport

        commandCell =
            el
                [ width fill
                , htmlAttribute (Html.Attributes.style "min-width" "0")
                , htmlAttribute (Html.Attributes.style "overflow-x" "auto")
                , htmlAttribute (Html.Attributes.style "overflow-y" "hidden")
                , htmlAttribute (Html.Attributes.style "-webkit-overflow-scrolling" "touch")
                , htmlAttribute (Html.Attributes.class "repl-command-cell")
                ]
                (commandLine themeMode viewport command)

        promptRow =
            row
                [ width fill, spacing Theme.space.sm ]
                [ promptGlyph themeMode, commandCell ]

        button =
            runButton
                { themeMode = themeMode
                , isRunning = isRunning
                , onRun = onRun
                , compact = compact
                }
    in
    if compact then
        column
            [ width fill
            , paddingXY (replPadding viewport) (Theme.space.sm + 2)
            , spacing Theme.space.sm
            , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
            , Border.color colors.border
            , Background.color colors.surface
            ]
            [ promptRow
            , el [ width fill ] button
            ]

    else
        row
            [ width fill
            , paddingXY (replPadding viewport) (Theme.space.sm + 2)
            , spacing Theme.space.sm
            , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
            , Border.color colors.border
            , Background.color colors.surface
            ]
            [ promptGlyph themeMode, commandCell, button ]


promptGlyph : Theme.Mode -> Element msg
promptGlyph themeMode =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.family [ Theme.fontMono, Font.monospace ]
        , Font.size type_.codeSize
        , Font.color colors.primary
        , Font.semiBold
        , centerY
        ]
        (text ">")


commandLine : Theme.Mode -> Viewport.Viewport -> String -> Element msg
commandLine themeMode viewport command =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.family [ Theme.fontMono, Font.monospace ]
        , Font.size
            (if Viewport.isHandset viewport then
                type_.codeSmallSize

             else
                type_.codeSize
            )
        , Font.color colors.textPrimary
        , htmlAttribute (Html.Attributes.style "white-space" "pre")
        , centerY
        ]
        (renderRCommand command)


renderRCommand : String -> Element msg
renderRCommand command =
    Element.html
        (Html.span
            [ Html.Attributes.class "repl-command" ]
            (highlightRCall command)
        )


{-| Tiny syntax-highlight pass for the literal `quone::compile("hero.Q")`
command. Keeping it specialised (rather than reusing the full R
tokeniser) avoids dragging in dependencies and means the colours are
exactly what we want for one specific demo line.
-}
highlightRCall : String -> List (Html.Html msg)
highlightRCall input =
    case String.split "::" input of
        [ pkg, rest ] ->
            case String.split "(" rest of
                fn :: argParts ->
                    let
                        args =
                            String.join "(" argParts
                    in
                    [ Html.span [ Html.Attributes.class "tok-pkg" ] [ Html.text pkg ]
                    , Html.span [ Html.Attributes.class "tok-op" ] [ Html.text "::" ]
                    , Html.span [ Html.Attributes.class "tok-fn" ] [ Html.text fn ]
                    , Html.span [ Html.Attributes.class "tok-paren" ] [ Html.text "(" ]
                    , Html.span [ Html.Attributes.class "tok-str" ] [ Html.text (stripCloseParen args) ]
                    , Html.span [ Html.Attributes.class "tok-paren" ] [ Html.text ")" ]
                    ]

                [] ->
                    [ Html.text input ]

        _ ->
            [ Html.text input ]


stripCloseParen : String -> String
stripCloseParen s =
    if String.endsWith ")" s then
        String.dropRight 1 s

    else
        s


runButton :
    { themeMode : Theme.Mode
    , isRunning : Bool
    , onRun : msg
    , compact : Bool
    }
    -> Element msg
runButton { themeMode, isRunning, onRun, compact } =
    let
        colors =
            Theme.paletteFor themeMode

        label =
            Element.html
                (Html.span
                    [ Html.Attributes.class "repl-run-label" ]
                    (if compact then
                        [ Html.text "Preview" ]

                     else
                        [ playGlyphHtml, Html.text "Preview R" ]
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
            , htmlAttribute
                (Html.Attributes.attribute "aria-label"
                    (if isRunning then
                        "Loading preview, please wait"

                     else
                        "Preview generated R output"
                    )
                )
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
        { onPress =
            if isRunning then
                Nothing

            else
                Just onRun
        , label = label
        }


playGlyphHtml : Html.Html msg
playGlyphHtml =
    Html.span
        [ Html.Attributes.class "repl-play"
        , Html.Attributes.attribute "aria-hidden" "true"
        ]
        [ Html.text "\u{25B6}" ]


outputArea : Theme.Mode -> Viewport.Viewport -> Output -> Element msg
outputArea themeMode viewport output =
    let
        colors =
            Theme.paletteFor themeMode

        pad =
            replPadding viewport

        baseAttrs =
            [ width fill
            , paddingXY pad (Theme.space.md - 2)
            , Background.color (reSurface themeMode)
            , Font.family [ Theme.fontMono, Font.monospace ]
            , Font.size
                (if Viewport.isHandset viewport then
                    type_.codeSmallSize

                 else
                    type_.codeSize
                )
            , Font.color colors.textPrimary
            , spacing 6
            , htmlAttribute (Html.Attributes.style "overflow-x" "auto")
            , htmlAttribute (Html.Attributes.style "min-width" "0")
            , htmlAttribute (Html.Attributes.style "-webkit-overflow-scrolling" "touch")
            ]
    in
    case output of
        Idle ->
            column baseAttrs
                [ idleHint themeMode ]

        Compiling ->
            column baseAttrs
                [ compilingLine themeMode ]

        Compiled rSource ->
            column baseAttrs
                [ compiledBlock themeMode viewport rSource ]


idleHint : Theme.Mode -> Element msg
idleHint themeMode =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.color colors.textMuted
        , Font.italic
        , htmlAttribute (Html.Attributes.class "repl-hint")
        ]
        (text "# Click Preview to show generated R")


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
                , Html.Attributes.attribute "aria-label" "Loading preview"
                ]
                [ Html.text "Loading preview"
                , Html.span [ Html.Attributes.class "repl-dot repl-dot-1" ] [ Html.text "." ]
                , Html.span [ Html.Attributes.class "repl-dot repl-dot-2" ] [ Html.text "." ]
                , Html.span [ Html.Attributes.class "repl-dot repl-dot-3" ] [ Html.text "." ]
                ]
            )
        )


compiledBlock : Theme.Mode -> Viewport.Viewport -> String -> Element msg
compiledBlock themeMode viewport rSource =
    el
        [ width fill
        , htmlAttribute (Html.Attributes.class "repl-output")
        , paddingEach { top = 6, right = 0, bottom = 4, left = 0 }
        ]
        (CodeBlock.viewBare themeMode viewport CodeBlock.R rSource)


replPadding : Viewport.Viewport -> Int
replPadding viewport =
    if Viewport.isHandset viewport then
        Theme.space.md

    else
        Theme.space.lg
