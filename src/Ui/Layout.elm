module Ui.Layout exposing
    ( page
    , section
    , wideSection
    , header
    , footer
    )

{-| Top-level page chrome: header, footer, and section containers.
-}

import Element
    exposing
        ( Element
        , alignLeft
        , alignRight
        , centerX
        , centerY
        , column
        , el
        , fill
        , height
        , link
        , maximum
        , newTabLink
        , none
        , paddingXY
        , paragraph
        , row
        , spacing
        , text
        , width
        , wrappedRow
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Ui.Eyebrow as Eyebrow
import Ui.Logo as Logo
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport



-- PAGE


{-| Whole-page wrapper: header, content column, footer.
-}
page :
    { viewport : Viewport.Viewport
    , currentPath : String
    , content : Element msg
    }
    -> Element msg
page { viewport, currentPath, content } =
    column
        [ width fill
        , height fill
        , Background.color palette.background
        , Font.color palette.textPrimary
        , Font.family [ Theme.fontSans, Font.sansSerif ]
        , Font.size type_.bodySize
        ]
        [ header viewport currentPath
        , column
            [ width fill
            , spacing (pageSpacing viewport)
            , paddingXY 0 (pageSpacing viewport)
            ]
            [ content ]
        , footer viewport
        ]



-- HEADER


header : Viewport.Viewport -> String -> Element msg
header viewport currentPath =
    let
        navLinks =
            [ navLink currentPath "/" "Home"
            , navLink currentPath "/install" "Install"
            , externalLink
                "https://github.com/armcn/quone-lang/blob/main/compiler/docs/LANGUAGE.md"
                "Reference"
            , externalLink
                "https://github.com/armcn/quone-lang"
                "GitHub"
            ]

        contentPadding =
            horizontalPadding viewport
    in
    el
        [ width fill
        , Background.color palette.surface
        , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
        , Border.color palette.border
        ]
        (if Viewport.isCompact viewport then
            column
                [ width (fill |> maximum Theme.maxContentWidth)
                , centerX
                , paddingXY contentPadding Theme.space.md
                , spacing Theme.space.sm
                ]
                [ row [ width fill, centerY ]
                    [ link [ alignLeft ]
                        { url = "/"
                        , label = Logo.full { wordmarkSize = 22, markSize = 34 }
                        }
                    ]
                , wrappedRow
                    [ width fill
                    , spacing Theme.space.md
                    ]
                    navLinks
                ]

         else
            row
                [ width (fill |> maximum Theme.maxContentWidth)
                , centerX
                , paddingXY contentPadding Theme.space.md
                , spacing Theme.space.xl
                ]
                [ link [ alignLeft ]
                    { url = "/"
                    , label = Logo.full { wordmarkSize = 22, markSize = 38 }
                    }
                , row
                    [ alignRight, spacing Theme.space.lg, centerY ]
                    navLinks
                ]
        )


navLink : String -> String -> String -> Element msg
navLink currentPath path label =
    let
        isActive =
            currentPath == path

        color =
            if isActive then
                palette.primary

            else
                palette.textSecondary
    in
    link
        [ Font.color color
        , Font.medium
        , Element.mouseOver [ Font.color palette.primary ]
        ]
        { url = path, label = text label }


externalLink : String -> String -> Element msg
externalLink url label =
    newTabLink
        [ Font.color palette.textSecondary
        , Font.medium
        , Element.mouseOver [ Font.color palette.primary ]
        ]
        { url = url, label = text label }



-- FOOTER


footer : Viewport.Viewport -> Element msg
footer viewport =
    let
        brandBlock =
            column
                [ alignLeft
                , spacing Theme.space.sm
                ]
                [ Logo.full { wordmarkSize = 18, markSize = 30 }
                , el
                    [ Font.color palette.textMuted
                    , Font.size type_.smallSize
                    ]
                    (text "A typed functional language for R.")
                ]

        projectBlock =
            column
                [ spacing Theme.space.sm
                ]
                [ footerHeading "Project"
                , footerLink
                    "https://github.com/armcn/quone-lang"
                    "GitHub"
                , footerLink
                    "https://github.com/armcn/quone-lang/blob/main/compiler/docs/LANGUAGE.md"
                    "Language reference"
                , footerLink
                    "https://github.com/armcn/quone-lang/issues"
                    "Issue tracker"
                ]

        builtOnBlock =
            column
                [ spacing Theme.space.sm
                ]
                [ footerHeading "Built on"
                , footerLink "https://www.r-project.org/" "R"
                , footerLink "https://elm-lang.org/" "Elm (this site)"
                ]
    in
    el
        [ width fill
        , Background.color palette.surface
        , Border.widthEach { top = 1, right = 0, bottom = 0, left = 0 }
        , Border.color palette.border
        , paddingXY (horizontalPadding viewport) Theme.space.xl
        ]
        (column
            [ width (fill |> maximum Theme.maxContentWidth)
            , centerX
            , spacing Theme.space.lg
            ]
            [ if Viewport.isCompact viewport then
                column
                    [ width fill
                    , spacing Theme.space.lg
                    ]
                    [ brandBlock
                    , projectBlock
                    , builtOnBlock
                    ]

              else
                row
                    [ width fill
                    , spacing Theme.space.xl
                    ]
                    [ brandBlock
                    , column [ alignRight, spacing Theme.space.sm ]
                        [ footerHeading "Project"
                        , footerLink
                            "https://github.com/armcn/quone-lang"
                            "GitHub"
                        , footerLink
                            "https://github.com/armcn/quone-lang/blob/main/compiler/docs/LANGUAGE.md"
                            "Language reference"
                        , footerLink
                            "https://github.com/armcn/quone-lang/issues"
                            "Issue tracker"
                        ]
                    , column [ alignRight, spacing Theme.space.sm ]
                        [ footerHeading "Built on"
                        , footerLink "https://www.r-project.org/" "R"
                        , footerLink "https://elm-lang.org/" "Elm (this site)"
                        ]
                    ]
            , el
                [ width fill
                , Border.widthEach { top = 1, right = 0, bottom = 0, left = 0 }
                , Border.color palette.border
                ]
                none
            , el
                [ Font.color palette.textMuted
                , Font.size type_.smallSize
                ]
                (text "Quone is an early-release language. v0.0.1.")
            ]
        )


footerHeading : String -> Element msg
footerHeading label =
    el
        [ Font.color palette.textPrimary
        , Font.semiBold
        , Font.size type_.smallSize
        ]
        (text label)


footerLink : String -> String -> Element msg
footerLink url label =
    newTabLink
        [ Font.color palette.textSecondary
        , Font.size type_.smallSize
        , Element.mouseOver [ Font.color palette.primary ]
        ]
        { url = url, label = text label }



-- SECTIONS


{-| A standard centred section with the default content max width.
-}
section :
    Viewport.Viewport
    -> { title : Maybe String, kicker : Maybe String, body : Element msg }
    -> Element msg
section viewport { title, kicker, body } =
    el
        [ width fill, paddingXY (horizontalPadding viewport) 0 ]
        (column
            [ width (fill |> maximum Theme.maxContentWidth)
            , centerX
            , spacing (sectionHeaderSpacing viewport)
            ]
            (List.filterMap identity
                [ Maybe.map sectionKicker kicker
                , Maybe.map (sectionTitle viewport) title
                , Just body
                ]
            )
        )


{-| A wider section for hero-style content (still centred).
-}
wideSection : Viewport.Viewport -> { body : Element msg } -> Element msg
wideSection viewport { body } =
    el
        [ width fill, paddingXY (horizontalPadding viewport) 0 ]
        (el
            [ width (fill |> maximum 1280)
            , centerX
            ]
            body
        )


sectionTitle : Viewport.Viewport -> String -> Element msg
sectionTitle viewport s =
    paragraph
        [ Font.size
            (if Viewport.isHandset viewport then
                28

             else
                type_.h2Size
            )
        , Font.semiBold
        , Font.color palette.textPrimary
        , Font.family [ Theme.fontDisplay, Font.sansSerif ]
        , Font.letterSpacing -0.6
        , Region.heading 2
        ]
        [ text s ]


sectionKicker : String -> Element msg
sectionKicker s =
    Eyebrow.view s


horizontalPadding : Viewport.Viewport -> Int
horizontalPadding viewport =
    if Viewport.isHandset viewport then
        Theme.space.md

    else
        Theme.space.lg


pageSpacing : Viewport.Viewport -> Int
pageSpacing viewport =
    if Viewport.isHandset viewport then
        72

    else
        Theme.space.section


sectionHeaderSpacing : Viewport.Viewport -> Int
sectionHeaderSpacing viewport =
    if Viewport.isHandset viewport then
        Theme.space.lg

    else
        Theme.space.xl
