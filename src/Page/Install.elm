module Page.Install exposing (view)

{-| The install page. Most users will reach Quone through the R
package - a thin wrapper around the compiler that exposes a single
`quone::compile()` function. The page leads with that path, then keeps
a compact "build the compiler yourself" section for power users and
contributors.
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
                , installPackage viewport
                , quickstartR viewport
                , buildFromSource viewport
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
        [ text "Install the Quone R package." ]


intro : Element msg
intro =
    column
        [ width (fill |> maximum 760), spacing Theme.space.md ]
        [ paragraph
            [ Font.size type_.bodyLargeSize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "Most users reach Quone through the "
            , CodeBlock.viewInline "quone"
            , text " R package. It bundles the compiler and exposes a single function, "
            , CodeBlock.viewInline "quone::compile()"
            , text ", so you can compile a Quone source file from the same R session you already use for analysis."
            ]
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textMuted
            , Element.spacing 6
            ]
            [ text "v0.0.1 is GitHub-only. CRAN release will follow once the API stabilises." ]
        ]


prerequisites : Viewport.Viewport -> Element msg
prerequisites viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Prerequisites"
        , bulleted
            [ paragraphWith
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
                , text " (pulled in as dependencies, but you can install them up front if you prefer)."
                ]
            , paragraphWith
                [ text "Either "
                , CodeBlock.viewInline "pak"
                , text " or "
                , CodeBlock.viewInline "remotes"
                , text " to install from GitHub."
                ]
            ]
        ]


installPackage : Viewport.Viewport -> Element msg
installPackage viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Install from GitHub"
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "From your R console, install with "
            , CodeBlock.viewInline "pak"
            , text ":"
            ]
        , codeShell viewport """pak::pak("quone-lang/quone")"""
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "Or, equivalently, with "
            , CodeBlock.viewInline "remotes"
            , text ":"
            ]
        , codeShell viewport """remotes::install_github("quone-lang/quone")"""
        ]


quickstartR : Viewport.Viewport -> Element msg
quickstartR viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Compile your first file"
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "Save a Quone source file (the convention is the "
            , CodeBlock.viewInline ".Q"
            , text " extension) and call "
            , CodeBlock.viewInline "quone::compile()"
            , text " on it from R. The function writes the generated R alongside the source and returns its path."
            ]
        , codeShell viewport """library(quone)

# normalize.Q -> normalize.R
out <- quone::compile("normalize.Q")

source(out)
normalize(100, 87)
#> [1] 0.87"""
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "Pass "
            , CodeBlock.viewInline "package = TRUE"
            , text " for a multi-module project and Quone will emit a full R-package skeleton ("
            , CodeBlock.viewInline "DESCRIPTION"
            , text ", "
            , CodeBlock.viewInline "NAMESPACE"
            , text ", and roxygen-driven "
            , CodeBlock.viewInline "man/"
            , text " pages) from your "
            , CodeBlock.viewInline "module"
            , text " headers and "
            , CodeBlock.viewInline "@export"
            , text " tags."
            ]
        ]


buildFromSource : Viewport.Viewport -> Element msg
buildFromSource viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Build the compiler from source"
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textMuted
            , Element.spacing 6
            ]
            [ text "Most users do not need this section. The R package above ships the compiler binary it needs. Build from source if you want to hack on the compiler itself, run the test suite, or use Quone outside an R session." ]
        , subheading viewport "Compiler prerequisites"
        , bulleted
            [ paragraphWith
                [ text "GHC and Cabal. We recommend "
                , link "https://www.haskell.org/ghcup/" "ghcup"
                , text " to install both: pick the latest stable GHC and Cabal."
                ]
            ]
        , subheading viewport "Build"
        , codeShell viewport """git clone https://github.com/quone-lang/quone.git
cd quone/compiler
cabal build
cabal install --installdir=$HOME/.local/bin --overwrite-policy=always"""
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "This produces the "
            , CodeBlock.viewInline "quonec"
            , text " executable on your $PATH. The R package looks for it before falling back to its bundled binary, so a freshly-built "
            , CodeBlock.viewInline "quonec"
            , text " is what every "
            , CodeBlock.viewInline "quone::compile()"
            , text " call will use."
            ]
        ]


next : Viewport.Viewport -> Element msg
next viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading viewport "Next"
        , bulleted
            [ paragraphWith
                [ text "Read the "
                , link "https://github.com/quone-lang/quone/blob/main/compiler/docs/LANGUAGE.md" "language reference"
                , text " for the full specification of v0.0.1."
                ]
            , paragraphWith
                [ text "Browse "
                , link "https://github.com/quone-lang/quone/tree/main/examples" "example projects"
                , text " for working scripts and a multi-module package."
                ]
            , paragraphWith
                [ text "File issues or feature requests on "
                , link "https://github.com/quone-lang/quone/issues" "GitHub"
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


subheading : Viewport.Viewport -> String -> Element msg
subheading viewport label =
    el
        [ Font.size
            (if Viewport.isHandset viewport then
                18

             else
                type_.h3Size
            )
        , Font.semiBold
        , Font.color palette.textPrimary
        , Region.heading 3
        , paddingEach
            { top = Theme.space.sm
            , right = 0
            , bottom = 0
            , left = 0
            }
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
