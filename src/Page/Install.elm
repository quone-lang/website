module Page.Install exposing (view)

{-| The install page. Plain, scannable, and prerequisite-aware: the
audience is R users who may have never installed a Haskell toolchain.
-}

import Element
    exposing
        ( Element
        , centerX
        , clip
        , column
        , el
        , fill
        , htmlAttribute
        , maximum
        , newTabLink
        , padding
        , paddingEach
        , paragraph
        , row
        , scrollbarX
        , spacing
        , text
        , width
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Html.Attributes
import Ui.CodeBlock as CodeBlock
import Ui.Layout as Layout
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport


view : Viewport.Viewport -> Element msg
view viewport =
    Layout.section viewport
        { kicker = Just "Install"
        , title = Nothing
        , body =
            column
                [ width fill, spacing Theme.space.xl ]
                [ pageTitle viewport
                , intro
                , prerequisites viewport
                , buildSteps viewport
                , quickstart viewport
                , next viewport
                ]
        }


pageTitle : Viewport.Viewport -> Element msg
pageTitle viewport =
    paragraph
        [ Font.size
            (if Viewport.isHandset viewport then
                40

             else
                type_.h1Size
            )
        , Font.semiBold
        , Font.color palette.textPrimary
        , Font.family [ Theme.fontDisplay, Font.sansSerif ]
        , Font.letterSpacing -0.6
        , Region.heading 1
        ]
        [ text "Build Quone from source." ]


intro : Element msg
intro =
    column
        [ width (fill |> maximum 760), spacing Theme.space.md ]
        [ paragraph
            [ Font.size type_.bodyLargeSize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text """v0.0.1 is a build-from-source release. The compiler is a single Cabal project; the only runtime dependency is R itself, plus the R packages dplyr, purrr, readr, and roxygen2.""" ]
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textMuted
            , Element.spacing 6
            ]
            [ text "If you are still evaluating Quone, the interactive explorer and code examples on the home page are a faster first stop than installing a Haskell toolchain." ]
        ]


prerequisites : Viewport.Viewport -> Element msg
prerequisites viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Prerequisites"
        , bulleted
            [ paragraphWith
                [ text "GHC and Cabal. We recommend "
                , link "https://www.haskell.org/ghcup/" "ghcup"
                , text " to install both: pick the latest stable GHC and Cabal."
                ]
            , paragraphWith
                [ text "R 4.1 or newer. Quone uses R's native pipe; older R versions are not supported." ]
            , paragraphWith
                [ text "The R packages "
                , CodeBlock.viewInline "dplyr"
                , text ", "
                , CodeBlock.viewInline "purrr"
                , text ", "
                , CodeBlock.viewInline "readr"
                , text ", and "
                , CodeBlock.viewInline "roxygen2"
                , text "."
                ]
            ]
        , codeShell viewport """install.packages(c("dplyr", "purrr", "readr", "roxygen2"))"""
        ]


buildSteps : Viewport.Viewport -> Element msg
buildSteps viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Build the compiler"
        , codeShell viewport """git clone https://github.com/quone-lang/compiler.git
cd compiler
cabal build
cabal install --installdir=$HOME/.local/bin --overwrite-policy=always"""
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "This produces the "
            , CodeBlock.viewInline "quonec"
            , text " executable on your $PATH."
            ]
        ]


quickstart : Viewport.Viewport -> Element msg
quickstart viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Quickstart"
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "Scaffold a project, build it, and run the result:" ]
        , codeShell viewport """quonec new my-stats
cd my-stats
quonec build
quonec run"""
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "Quone auto-detects whether your project is a single-file script or a multi-module package. To force one or the other:" ]
        , codeShell viewport """quonec build --script main.Q
quonec build --package"""
        ]


next : Viewport.Viewport -> Element msg
next viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Next"
        , bulleted
            [ paragraphWith
                [ text "Read the "
                , link "https://github.com/quone-lang/compiler/blob/main/docs/LANGUAGE.md" "language reference"
                , text " for the full specification of v0.0.1."
                ]
            , paragraphWith
                [ text "Browse "
                , link "https://github.com/quone-lang/compiler/tree/main/examples" "example projects"
                , text " for working scripts and a multi-module package."
                ]
            , paragraphWith
                [ text "File issues or feature requests on "
                , link "https://github.com/quone-lang/compiler/issues" "GitHub"
                , text "."
                ]
            ]
        ]



-- HELPERS


heading : Viewport.Viewport -> String -> Element msg
heading viewport label =
    el
        [ Font.size
            (if Viewport.isHandset viewport then
                28

             else
                type_.h2Size
            )
        , Font.semiBold
        , Font.color palette.textPrimary
        , Region.heading 2
        ]
        (text label)


paragraphWith : List (Element msg) -> Element msg
paragraphWith parts =
    paragraph
        [ Font.size type_.bodySize
        , Font.color palette.textSecondary
        , Element.spacing 6
        ]
        parts


bulleted : List (Element msg) -> Element msg
bulleted items =
    column
        [ width (fill |> maximum 760)
        , spacing Theme.space.sm
        , paddingEach { top = 0, right = 0, bottom = 0, left = Theme.space.sm + 4 }
        ]
        (List.map bullet items)


bullet : Element msg -> Element msg
bullet item =
    Element.row
        [ width fill, spacing Theme.space.sm, Element.alignTop ]
        [ el
            [ Font.color palette.primary
            , Font.size type_.bodyLargeSize
            , Element.alignTop
            , paddingEach { top = 2, right = 0, bottom = 0, left = 0 }
            ]
            (text "\u{2022}")
        , el [ width fill ] item
        ]


codeShell : Viewport.Viewport -> String -> Element msg
codeShell viewport source =
    el
        [ width (fill |> maximum 720)
        , Background.color palette.codeSurface
        , Border.rounded Theme.radius.md
        , Border.width 1
        , Border.color palette.border
        ]
        (el
            [ width fill
            , clip
            , scrollbarX
            ]
            (column
                [ padding
                    (if Viewport.isHandset viewport then
                        Theme.space.md

                     else
                        Theme.space.lg
                    )
                , Font.family [ Theme.fontMono, Font.monospace ]
                , Font.size
                    (if Viewport.isHandset viewport then
                        type_.codeSmallSize

                     else
                        type_.codeSize
                    )
                , Font.color palette.textPrimary
                , spacing 4
                ]
                (source
                    |> String.lines
                    |> List.map shellLine
                )
            )
        )


shellLine : String -> Element msg
shellLine line =
    row
        [ htmlAttribute (Html.Attributes.style "white-space" "pre") ]
        [ if String.isEmpty line then
            text "\u{00A0}"

          else
            text line
        ]


link : String -> String -> Element msg
link url label =
    newTabLink
        [ Font.color palette.primary
        , Font.medium
        , Element.mouseOver [ Font.color palette.primaryHover ]
        ]
        { url = url, label = text label }
