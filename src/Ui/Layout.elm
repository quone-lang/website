module Ui.Layout exposing
    ( page
    , section
    , wideSection
    , footer
    )

{-| Top-level page chrome: header, footer, and section containers.
-}

import Element
    exposing
        ( Element
        , alignLeft
        , alignRight
        , alignTop
        , centerX
        , centerY
        , column
        , el
        , fill
        , height
        , htmlAttribute
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
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html.Attributes
import Ui.Eyebrow as Eyebrow
import Ui.Logo as Logo
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport



-- PAGE


{-| Whole-page wrapper: header, content column, footer.

The header is responsive: compact viewports show a menu button that
toggles a stacked panel of nav links; wider viewports show a single
horizontal row.

-}
page :
    { viewport : Viewport.Viewport
    , currentPath : String
    , isMenuOpen : Bool
    , onToggleMenu : msg
    , content : Element msg
    }
    -> Element msg
page { viewport, currentPath, isMenuOpen, onToggleMenu, content } =
    column
        [ width fill
        , height fill
        , Background.color palette.background
        , Font.color palette.textPrimary
        , Font.family [ Theme.fontSans, Font.sansSerif ]
        , Font.size type_.bodySize
        ]
        [ header
            { viewport = viewport
            , currentPath = currentPath
            , isMenuOpen = isMenuOpen
            , onToggleMenu = onToggleMenu
            }
        , column
            [ width fill
            , spacing (pageSpacing viewport)
            , paddingXY 0 (pageSpacing viewport)
            ]
            [ content ]
        , footer viewport
        ]



-- HEADER


header :
    { viewport : Viewport.Viewport
    , currentPath : String
    , isMenuOpen : Bool
    , onToggleMenu : msg
    }
    -> Element msg
header { viewport, currentPath, isMenuOpen, onToggleMenu } =
    let
        navItems =
            [ ( "/", "Home", Internal )
            , ( "/install", "Install", Internal )
            , ( "https://github.com/quone-lang/quone/blob/main/compiler/docs/LANGUAGE.md", "Reference", External )
            , ( "https://github.com/quone-lang/quone", "GitHub", External )
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
                , spacing Theme.space.md
                ]
                [ row [ width fill, centerY, spacing Theme.space.md ]
                    [ link [ alignLeft ]
                        { url = "/"
                        , label = Logo.full { wordmarkSize = 22, markSize = 34 }
                        }
                    , el [ alignRight ]
                        (menuButton
                            { isOpen = isMenuOpen
                            , onPress = onToggleMenu
                            }
                        )
                    ]
                , if isMenuOpen then
                    column
                        [ width fill
                        , spacing Theme.space.sm
                        , paddingXY 0 Theme.space.sm
                        , Border.widthEach { top = 1, right = 0, bottom = 0, left = 0 }
                        , Border.color palette.border
                        ]
                        (List.map (mobileNavItem currentPath) navItems)

                  else
                    none
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
                    (List.map (desktopNavItem currentPath) navItems)
                ]
        )


type LinkKind
    = Internal
    | External


desktopNavItem : String -> ( String, String, LinkKind ) -> Element msg
desktopNavItem currentPath ( url, label, kind ) =
    case kind of
        Internal ->
            navLink currentPath url label

        External ->
            externalLink url label


mobileNavItem : String -> ( String, String, LinkKind ) -> Element msg
mobileNavItem currentPath ( url, label, kind ) =
    let
        attrs =
            [ width fill
            , paddingXY Theme.space.sm Theme.space.sm
            , Border.rounded Theme.radius.sm
            , Font.size type_.bodySize
            , Font.medium
            ]
    in
    case kind of
        Internal ->
            let
                isActive =
                    currentPath == url
            in
            link (attrs ++ [ Font.color (if isActive then palette.primary else palette.textSecondary) ])
                { url = url, label = text label }

        External ->
            newTabLink (attrs ++ [ Font.color palette.textSecondary ])
                { url = url, label = text label }


menuButton : { isOpen : Bool, onPress : msg } -> Element msg
menuButton { isOpen, onPress } =
    Input.button
        [ paddingXY Theme.space.sm Theme.space.xs
        , Border.rounded Theme.radius.sm
        , Border.width 1
        , Border.color
            (if isOpen then
                palette.primary

             else
                palette.border
            )
        , Background.color palette.surface
        , Font.size type_.bodySize
        , Font.color palette.textPrimary
        ]
        { onPress = Just onPress
        , label = menuButtonLabel isOpen
        }


menuButtonLabel : Bool -> Element msg
menuButtonLabel isOpen =
    let
        glyph =
            if isOpen then
                "\u{2715}"

            else
                "\u{2630}"
    in
    row
        [ spacing Theme.space.xs, centerY ]
        [ el
            [ Font.size 18
            , Font.semiBold
            , htmlAttribute (Html.Attributes.attribute "aria-hidden" "true")
            ]
            (text glyph)
        , el [ Font.size type_.smallSize ]
            (text
                (if isOpen then
                    "Close"

                 else
                    "Menu"
                )
            )
        ]


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
                [ alignTop
                , alignLeft
                , spacing Theme.space.sm
                , width fill
                ]
                [ Logo.full { wordmarkSize = 18, markSize = 30 }
                ]

        projectBlock =
            footerColumn "Project"
                [ ( "https://github.com/quone-lang", "GitHub" )
                , ( "https://github.com/quone-lang/quone/issues", "Issue tracker" )
                ]

        learnBlock =
            footerColumn "Learn"
                [ ( "https://github.com/quone-lang/quone/blob/main/compiler/docs/LANGUAGE.md"
                  , "Language reference"
                  )
                , ( "https://github.com/quone-lang/quone/tree/main/examples", "Examples" )
                ]

        builtOnBlock =
            footerColumn "Built on"
                [ ( "https://www.r-project.org/", "R" )
                , ( "https://www.haskell.org/", "Haskell" )
                , ( "https://elm-lang.org/", "Elm" )
                ]

        columns =
            [ brandBlock, projectBlock, learnBlock, builtOnBlock ]
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
                    columns

              else
                row
                    [ width fill
                    , spacing Theme.space.xl
                    , alignTop
                    ]
                    columns
            , el
                [ width fill
                , Border.widthEach { top = 1, right = 0, bottom = 0, left = 0 }
                , Border.color palette.border
                ]
                none
            , el
                [ alignLeft
                , Font.color palette.textMuted
                , Font.size type_.smallSize
                ]
                (text "Quone v0.0.1 - pre-release work in progress. APIs and syntax may change.")
            ]
        )


footerColumn : String -> List ( String, String ) -> Element msg
footerColumn heading links =
    column
        [ alignTop
        , spacing Theme.space.sm
        , width fill
        ]
        (footerHeading heading
            :: List.map (\( url, label ) -> footerLink url label) links
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
