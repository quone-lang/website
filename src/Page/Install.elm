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
import Ui.Theme as Theme exposing (type_)
import Ui.Viewport as Viewport


view : Theme.Mode -> Viewport.Viewport -> Element msg
view themeMode viewport =
    Layout.section themeMode viewport
        { kicker = Just "Install"
        , title = Nothing
        , body =
            column
                [ width fill, spacing Theme.space.xl ]
                [ pageTitle themeMode viewport
                , intro themeMode
                , prerequisites themeMode viewport
                , installPackage themeMode viewport
                , quickstartR themeMode viewport
                , buildFromSource themeMode viewport
                , next themeMode viewport
                ]
        }


pageTitle : Theme.Mode -> Viewport.Viewport -> Element msg
pageTitle themeMode viewport =
    let
        colors =
            Theme.paletteFor themeMode
    in
    paragraph
        [ Font.size
            (if Viewport.isHandset viewport then
                40

             else
                type_.h1Size
            )
        , Font.semiBold
        , Font.color colors.textPrimary
        , Font.family [ Theme.fontDisplay, Font.sansSerif ]
        , Font.letterSpacing -0.6
        , Region.heading 1
        ]
        [ text "Install the Quone R package." ]


intro : Theme.Mode -> Element msg
intro themeMode =
    let
        colors =
            Theme.paletteFor themeMode
    in
    column
        [ width (fill |> maximum 760), spacing Theme.space.md ]
        [ paragraph
            [ Font.size type_.bodyLargeSize
            , Font.color colors.textSecondary
            , Element.spacing 6
            ]
            [ text "Most users reach Quone through the "
            , CodeBlock.viewInline themeMode "quone"
            , text " R package. It bundles the compiler and exposes a single function, "
            , CodeBlock.viewInline themeMode "quone::compile()"
            , text ", so you can compile a Quone source file from the same R session you already use for analysis."
            ]
        , paragraph
            [ Font.size type_.bodySize
            , Font.color colors.textMuted
            , Element.spacing 6
            ]
            [ text "v0.0.1 is GitHub-only. CRAN release will follow once the API stabilises." ]
        ]


prerequisites : Theme.Mode -> Viewport.Viewport -> Element msg
prerequisites themeMode viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading themeMode viewport "Prerequisites"
        , bulleted themeMode
            [ paragraphWith themeMode
                [ text "R 4.1 or newer. Quone uses R's native pipe; older R versions are not supported." ]
            , paragraphWith themeMode
                [ text "The R packages "
                , CodeBlock.viewInline themeMode "dplyr"
                , text ", "
                , CodeBlock.viewInline themeMode "purrr"
                , text ", "
                , CodeBlock.viewInline themeMode "readr"
                , text ", and "
                , CodeBlock.viewInline themeMode "roxygen2"
                , text " (pulled in as dependencies, but you can install them up front if you prefer)."
                ]
            , paragraphWith themeMode
                [ text "Either "
                , CodeBlock.viewInline themeMode "pak"
                , text " or "
                , CodeBlock.viewInline themeMode "remotes"
                , text " to install from GitHub."
                ]
            ]
        ]


installPackage : Theme.Mode -> Viewport.Viewport -> Element msg
installPackage themeMode viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading themeMode viewport "Install from GitHub"
        , paragraph
            [ Font.size type_.bodySize
            , Font.color (Theme.paletteFor themeMode).textSecondary
            , Element.spacing 6
            ]
            [ text "From your R console, install with "
            , CodeBlock.viewInline themeMode "pak"
            , text ":"
            ]
        , codeShell themeMode viewport """pak::pak("quone-lang/quone")"""
        , paragraph
            [ Font.size type_.bodySize
            , Font.color (Theme.paletteFor themeMode).textSecondary
            , Element.spacing 6
            ]
            [ text "Or, equivalently, with "
            , CodeBlock.viewInline themeMode "remotes"
            , text ":"
            ]
        , codeShell themeMode viewport """remotes::install_github("quone-lang/quone")"""
        ]


quickstartR : Theme.Mode -> Viewport.Viewport -> Element msg
quickstartR themeMode viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading themeMode viewport "Compile your first file"
        , paragraph
            [ Font.size type_.bodySize
            , Font.color (Theme.paletteFor themeMode).textSecondary
            , Element.spacing 6
            ]
            [ text "Save a Quone source file (the convention is the "
            , CodeBlock.viewInline themeMode ".Q"
            , text " extension) and call "
            , CodeBlock.viewInline themeMode "quone::compile()"
            , text " on it from R. The function writes the generated R alongside the source and returns its path."
            ]
        , codeShell themeMode viewport """library(quone)

# normalize.Q -> normalize.R
out <- quone::compile("normalize.Q")

source(out)
normalize(100, 87)
#> [1] 0.87"""
        , paragraph
            [ Font.size type_.bodySize
            , Font.color (Theme.paletteFor themeMode).textSecondary
            , Element.spacing 6
            ]
            [ text "Pass "
            , CodeBlock.viewInline themeMode "package = TRUE"
            , text " for a multi-module project and Quone will emit a full R-package skeleton ("
            , CodeBlock.viewInline themeMode "DESCRIPTION"
            , text ", "
            , CodeBlock.viewInline themeMode "NAMESPACE"
            , text ", and roxygen-driven "
            , CodeBlock.viewInline themeMode "man/"
            , text " pages) from your "
            , CodeBlock.viewInline themeMode "module"
            , text " headers and "
            , CodeBlock.viewInline themeMode "@export"
            , text " tags."
            ]
        ]


buildFromSource : Theme.Mode -> Viewport.Viewport -> Element msg
buildFromSource themeMode viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading themeMode viewport "Build the compiler from source"
        , paragraph
            [ Font.size type_.bodySize
            , Font.color (Theme.paletteFor themeMode).textMuted
            , Element.spacing 6
            ]
            [ text "Most users do not need this section. The R package above ships the compiler binary it needs. Build from source if you want to hack on the compiler itself, run the test suite, or use Quone outside an R session." ]
        , subheading themeMode viewport "Compiler prerequisites"
        , bulleted themeMode
            [ paragraphWith themeMode
                [ text "GHC and Cabal. We recommend "
                , link themeMode "https://www.haskell.org/ghcup/" "ghcup"
                , text " to install both: pick the latest stable GHC and Cabal."
                ]
            ]
        , subheading themeMode viewport "Build"
        , codeShell themeMode viewport """git clone https://github.com/quone-lang/quone.git
cd quone/compiler
cabal build
cabal install --installdir=$HOME/.local/bin --overwrite-policy=always"""
        , paragraph
            [ Font.size type_.bodySize
            , Font.color (Theme.paletteFor themeMode).textSecondary
            , Element.spacing 6
            ]
            [ text "This produces the "
            , CodeBlock.viewInline themeMode "quonec"
            , text " executable on your $PATH. The R package looks for it before falling back to its bundled binary, so a freshly-built "
            , CodeBlock.viewInline themeMode "quonec"
            , text " is what every "
            , CodeBlock.viewInline themeMode "quone::compile()"
            , text " call will use."
            ]
        ]


next : Theme.Mode -> Viewport.Viewport -> Element msg
next themeMode viewport =
    column
        [ width fill, spacing Theme.space.md ]
        [ heading themeMode viewport "Next"
        , bulleted themeMode
            [ paragraphWith themeMode
                [ text "Read the "
                , link themeMode "https://github.com/quone-lang/quone/blob/main/compiler/docs/LANGUAGE.md" "language reference"
                , text " for the full specification of v0.0.1."
                ]
            , paragraphWith themeMode
                [ text "Browse "
                , link themeMode "https://github.com/quone-lang/quone/tree/main/examples" "example projects"
                , text " for working scripts and a multi-module package."
                ]
            , paragraphWith themeMode
                [ text "File issues or feature requests on "
                , link themeMode "https://github.com/quone-lang/quone/issues" "GitHub"
                , text "."
                ]
            ]
        ]



-- HELPERS


heading : Theme.Mode -> Viewport.Viewport -> String -> Element msg
heading themeMode viewport label =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.size
            (if Viewport.isHandset viewport then
                28

             else
                type_.h2Size
            )
        , Font.semiBold
        , Font.color colors.textPrimary
        , Region.heading 2
        ]
        (text label)


subheading : Theme.Mode -> Viewport.Viewport -> String -> Element msg
subheading themeMode viewport label =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.size
            (if Viewport.isHandset viewport then
                18

             else
                type_.h3Size
            )
        , Font.semiBold
        , Font.color colors.textPrimary
        , Region.heading 3
        , paddingEach
            { top = Theme.space.sm
            , right = 0
            , bottom = 0
            , left = 0
            }
        ]
        (text label)


paragraphWith : Theme.Mode -> List (Element msg) -> Element msg
paragraphWith themeMode parts =
    let
        colors =
            Theme.paletteFor themeMode
    in
    paragraph
        [ Font.size type_.bodySize
        , Font.color colors.textSecondary
        , Element.spacing 6
        ]
        parts


bulleted : Theme.Mode -> List (Element msg) -> Element msg
bulleted themeMode items =
    column
        [ width (fill |> maximum 760)
        , spacing Theme.space.sm
        , paddingEach { top = 0, right = 0, bottom = 0, left = Theme.space.sm + 4 }
        ]
        (List.map (bullet themeMode) items)


bullet : Theme.Mode -> Element msg -> Element msg
bullet themeMode item =
    let
        colors =
            Theme.paletteFor themeMode
    in
    Element.row
        [ width fill, spacing Theme.space.sm, Element.alignTop ]
        [ el
            [ Font.color colors.primary
            , Font.size type_.bodyLargeSize
            , Element.alignTop
            , paddingEach { top = 2, right = 0, bottom = 0, left = 0 }
            ]
            (text "\u{2022}")
        , el [ width fill ] item
        ]


codeShell : Theme.Mode -> Viewport.Viewport -> String -> Element msg
codeShell themeMode viewport source =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ width (fill |> maximum 720)
        , Background.color colors.codeSurface
        , Border.rounded Theme.radius.md
        , Border.width 1
        , Border.color colors.border
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
                , Font.color colors.textPrimary
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


link : Theme.Mode -> String -> String -> Element msg
link themeMode url label =
    let
        colors =
            Theme.paletteFor themeMode
    in
    newTabLink
        [ Font.color colors.primary
        , Font.medium
        , Element.mouseOver [ Font.color colors.primaryHover ]
        ]
        { url = url, label = text label }
