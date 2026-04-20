module Ui.Repl exposing
    ( Output(..)
    , view
    )

{-| A small visual stand-in for the R REPL.

The REPL is decorative: it shows a Quone-package call (`quone::compile`)
that the user can "run" via a green play button. The site supplies the
output state (idle, compiling, or compiled with a generated R block),
and this module renders the chrome around it.

The REPL is not a real terminal; it just *looks* like one so the
"compile to R" interaction feels tangible without forcing the user to
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
import Ui.Theme as Theme exposing (palette, type_)
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
    Viewport.Viewport
    ->
        { command : String
        , output : Output
        , onRun : msg
        }
    -> Element msg
view viewport config =
    column
        [ width fill
        , Background.color reSurface
        , Border.rounded Theme.radius.md
        , Border.width 1
        , Border.color palette.border
        , htmlAttribute (Html.Attributes.class "repl-window")
        , htmlAttribute (Html.Attributes.style "overflow" "hidden")
        ]
        [ titleBar viewport
        , inputRow viewport
            { command = config.command
            , output = config.output
            , onRun = config.onRun
            }
        , outputArea viewport config.output
        ]



-- INTERNALS


reSurface : Element.Color
reSurface =
    rgb255 0xFB 0xFA 0xF7


reSurfaceDark : Element.Color
reSurfaceDark =
    rgb255 0xF1 0xEE 0xE8


runGreen : Element.Color
runGreen =
    rgb255 0x2E 0x7D 0x32


runGreenHover : Element.Color
runGreenHover =
    rgb255 0x38 0x96 0x3C


titleBar : Viewport.Viewport -> Element msg
titleBar viewport =
    if Viewport.isHandset viewport then
        row
            [ width fill
            , Background.color reSurfaceDark
            , paddingXY Theme.space.md (Theme.space.sm + 2)
            , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
            , Border.color palette.border
            , spacing Theme.space.sm
            ]
            [ trafficLights ]

    else
        row
            [ width fill
            , Background.color reSurfaceDark
            , paddingXY Theme.space.md (Theme.space.sm + 2)
            , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
            , Border.color palette.border
            , spacing Theme.space.md
            ]
            [ trafficLights
            , el
                [ Font.family [ Theme.fontMono, Font.monospace ]
                , Font.size type_.codeSmallSize
                , Font.color palette.textMuted
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
    Viewport.Viewport
    ->
        { command : String
        , output : Output
        , onRun : msg
        }
    -> Element msg
inputRow viewport { command, output, onRun } =
    let
        isRunning =
            output == Compiling

        compact =
            Viewport.isHandset viewport

        commandCell =
            el
                [ width fill
                , htmlAttribute (Html.Attributes.style "min-width" "0")
                , htmlAttribute (Html.Attributes.style "overflow-x" "auto")
                , htmlAttribute (Html.Attributes.class "repl-command-cell")
                ]
                (commandLine viewport command)

        promptRow =
            row
                [ width fill, spacing Theme.space.sm ]
                [ promptGlyph, commandCell ]

        button =
            runButton
                { isRunning = isRunning
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
            , Border.color palette.border
            , Background.color palette.surface
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
            , Border.color palette.border
            , Background.color palette.surface
            ]
            [ promptGlyph, commandCell, button ]


promptGlyph : Element msg
promptGlyph =
    el
        [ Font.family [ Theme.fontMono, Font.monospace ]
        , Font.size type_.codeSize
        , Font.color (rgb255 0x27 0x6D 0xC3)
        , Font.semiBold
        , centerY
        ]
        (text ">")


commandLine : Viewport.Viewport -> String -> Element msg
commandLine viewport command =
    el
        [ Font.family [ Theme.fontMono, Font.monospace ]
        , Font.size
            (if Viewport.isHandset viewport then
                type_.codeSmallSize

             else
                type_.codeSize
            )
        , Font.color palette.textPrimary
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
    { isRunning : Bool
    , onRun : msg
    , compact : Bool
    }
    -> Element msg
runButton { isRunning, onRun, compact } =
    let
        label =
            Element.html
                (Html.span
                    [ Html.Attributes.class "repl-run-label" ]
                    [ playGlyphHtml, Html.text "Run" ]
                )

        baseAttrs =
            [ Background.color runGreen
            , Font.color palette.textOnPrimary
            , Font.size type_.smallSize
            , Font.medium
            , Border.rounded Theme.radius.sm
            , paddingXY Theme.space.md
                (if compact then
                    Theme.space.sm + 2

                 else
                    Theme.space.xs + 2
                )
            , Element.mouseOver [ Background.color runGreenHover ]
            , htmlAttribute (Html.Attributes.class "repl-run")
            , htmlAttribute
                (Html.Attributes.attribute "aria-label"
                    (if isRunning then
                        "Compiling, please wait"

                     else
                        "Run quone::compile"
                    )
                )
            , htmlAttribute
                (Html.Attributes.style "min-height"
                    (if compact then
                        "40px"

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


outputArea : Viewport.Viewport -> Output -> Element msg
outputArea viewport output =
    let
        pad =
            replPadding viewport

        baseAttrs =
            [ width fill
            , paddingXY pad (Theme.space.md - 2)
            , Background.color reSurface
            , Font.family [ Theme.fontMono, Font.monospace ]
            , Font.size
                (if Viewport.isHandset viewport then
                    type_.codeSmallSize

                 else
                    type_.codeSize
                )
            , Font.color palette.textPrimary
            , spacing 6
            , htmlAttribute (Html.Attributes.style "overflow-x" "auto")
            , htmlAttribute (Html.Attributes.style "min-width" "0")
            ]
    in
    case output of
        Idle ->
            column baseAttrs
                [ idleHint ]

        Compiling ->
            column baseAttrs
                [ compilingLine ]

        Compiled rSource ->
            column baseAttrs
                [ compiledBlock viewport rSource ]


idleHint : Element msg
idleHint =
    el
        [ Font.color palette.textMuted
        , Font.italic
        , htmlAttribute (Html.Attributes.class "repl-hint")
        ]
        (text "# Click Run to compile to R")


compilingLine : Element msg
compilingLine =
    el
        [ htmlAttribute (Html.Attributes.class "repl-compiling")
        , Font.color palette.textSecondary
        , htmlAttribute (Html.Attributes.style "white-space" "pre")
        ]
        (Element.html
            (Html.span
                [ Html.Attributes.attribute "role" "status"
                , Html.Attributes.attribute "aria-label" "Compiling Quone"
                ]
                [ Html.text "Compiling Quone"
                , Html.span [ Html.Attributes.class "repl-dot repl-dot-1" ] [ Html.text "." ]
                , Html.span [ Html.Attributes.class "repl-dot repl-dot-2" ] [ Html.text "." ]
                , Html.span [ Html.Attributes.class "repl-dot repl-dot-3" ] [ Html.text "." ]
                ]
            )
        )


compiledBlock : Viewport.Viewport -> String -> Element msg
compiledBlock viewport rSource =
    el
        [ width fill
        , htmlAttribute (Html.Attributes.class "repl-output")
        , paddingEach { top = 6, right = 0, bottom = 4, left = 0 }
        ]
        (CodeBlock.viewBare viewport CodeBlock.R rSource)


replPadding : Viewport.Viewport -> Int
replPadding viewport =
    if Viewport.isHandset viewport then
        Theme.space.md

    else
        Theme.space.lg
