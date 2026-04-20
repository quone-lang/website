module Ui.Layout exposing
    ( page
    , section
    , wideSection
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
import Ui.Theme as Theme exposing (type_)
import Ui.Viewport as Viewport



-- PAGE


{-| Whole-page wrapper: header, content column, footer.

The header is responsive: compact viewports show a menu button that
toggles a stacked panel of nav links; wider viewports show a single
horizontal row.

-}
page :
    { themeMode : Theme.Mode
    , isFollowingSystem : Bool
    , viewport : Viewport.Viewport
    , currentPath : String
    , isMenuOpen : Bool
    , onToggleMenu : msg
    , onToggleTheme : msg
    , content : Element msg
    }
    -> Element msg
page { themeMode, isFollowingSystem, viewport, currentPath, isMenuOpen, onToggleMenu, onToggleTheme, content } =
    let
        colors =
            Theme.paletteFor themeMode
    in
    column
        [ width fill
        , height fill
        , Background.color colors.background
        , Font.color colors.textPrimary
        , Font.family Theme.fontSans
        , Font.size type_.bodySize
        ]
        [ header
            { themeMode = themeMode
            , isFollowingSystem = isFollowingSystem
            , viewport = viewport
            , currentPath = currentPath
            , isMenuOpen = isMenuOpen
            , onToggleMenu = onToggleMenu
            , onToggleTheme = onToggleTheme
            }
        , column
            [ width fill
            , spacing (pageSpacing viewport)
            , paddingXY 0 (pageSpacing viewport)
            ]
            [ content ]
        , footer themeMode viewport
        ]



-- HEADER


header :
    { themeMode : Theme.Mode
    , isFollowingSystem : Bool
    , viewport : Viewport.Viewport
    , currentPath : String
    , isMenuOpen : Bool
    , onToggleMenu : msg
    , onToggleTheme : msg
    }
    -> Element msg
header { themeMode, isFollowingSystem, viewport, currentPath, isMenuOpen, onToggleMenu, onToggleTheme } =
    let
        colors =
            Theme.paletteFor themeMode

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
        , Background.color colors.surface
        , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
        , Border.color colors.border
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
                        , label = Logo.full themeMode { wordmarkSize = 22, markSize = 34 }
                        }
                    , row [ alignRight, spacing Theme.space.sm, centerY ]
                        [ themeToggleButton
                            { themeMode = themeMode
                            , isFollowingSystem = isFollowingSystem
                            , onPress = onToggleTheme
                            }
                        , menuButton
                            { themeMode = themeMode
                            , isOpen = isMenuOpen
                            , onPress = onToggleMenu
                            }
                        ]
                    ]
                , if isMenuOpen then
                    column
                        [ width fill
                        , spacing Theme.space.sm
                        , paddingXY 0 Theme.space.sm
                        , htmlAttribute (Html.Attributes.id "site-nav-panel")
                        , htmlAttribute (Html.Attributes.attribute "role" "navigation")
                        , htmlAttribute (Html.Attributes.attribute "aria-label" "Primary navigation")
                        , Border.widthEach { top = 1, right = 0, bottom = 0, left = 0 }
                        , Border.color colors.border
                        ]
                        (List.map (mobileNavItem themeMode currentPath) navItems)

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
                    , label = Logo.full themeMode { wordmarkSize = 22, markSize = 38 }
                    }
                , row
                    [ alignRight, spacing Theme.space.md, centerY ]
                    [ row
                        [ spacing Theme.space.lg, centerY ]
                        (List.map (desktopNavItem themeMode currentPath) navItems)
                    , themeToggleButton
                        { themeMode = themeMode
                        , isFollowingSystem = isFollowingSystem
                        , onPress = onToggleTheme
                        }
                    ]
                ]
        )


type LinkKind
    = Internal
    | External


desktopNavItem : Theme.Mode -> String -> ( String, String, LinkKind ) -> Element msg
desktopNavItem themeMode currentPath ( url, label, kind ) =
    case kind of
        Internal ->
            navLink themeMode currentPath url label

        External ->
            externalLink themeMode url label


mobileNavItem : Theme.Mode -> String -> ( String, String, LinkKind ) -> Element msg
mobileNavItem themeMode currentPath ( url, label, kind ) =
    let
        colors =
            Theme.paletteFor themeMode

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
            link (attrs ++ [ Font.color (if isActive then colors.primary else colors.textSecondary) ])
                { url = url, label = text label }

        External ->
            newTabLink (attrs ++ [ Font.color colors.textSecondary ])
                { url = url, label = text label }


themeToggleButton :
    { themeMode : Theme.Mode
    , isFollowingSystem : Bool
    , onPress : msg
    }
    -> Element msg
themeToggleButton { themeMode, isFollowingSystem, onPress } =
    let
        colors =
            Theme.paletteFor themeMode

        ( glyph, nextLabel ) =
            case themeMode of
                Theme.Light ->
                    ( "\u{263D}", "Switch to dark theme" )

                Theme.Dark ->
                    ( "\u{2600}", "Switch to light theme" )

        hint =
            if isFollowingSystem then
                nextLabel ++ " (currently following system)"

            else
                nextLabel
    in
    Input.button
        [ paddingXY Theme.space.xs Theme.space.xs
        , Border.rounded Theme.radius.pill
        , Border.width 1
        , Border.color
            (if isFollowingSystem then
                colors.border

             else
                colors.primary
            )
        , Background.color colors.surface
        , Font.color
            (if isFollowingSystem then
                colors.textMuted

             else
                colors.primary
            )
        , Element.mouseOver
            [ Background.color colors.codeSurface
            , Font.color colors.textPrimary
            ]
        , htmlAttribute (Html.Attributes.attribute "aria-label" hint)
        , htmlAttribute (Html.Attributes.title hint)
        ]
        { onPress = Just onPress
        , label =
            el
                [ Font.size 16
                , Font.semiBold
                , htmlAttribute (Html.Attributes.attribute "aria-hidden" "true")
                ]
                (text glyph)
        }


menuButton : { themeMode : Theme.Mode, isOpen : Bool, onPress : msg } -> Element msg
menuButton { themeMode, isOpen, onPress } =
    let
        colors =
            Theme.paletteFor themeMode
    in
    Input.button
        [ paddingXY Theme.space.sm Theme.space.xs
        , htmlAttribute
            (Html.Attributes.attribute "aria-expanded"
                (if isOpen then
                    "true"

                 else
                    "false"
                )
            )
        , htmlAttribute (Html.Attributes.attribute "aria-controls" "site-nav-panel")
        , Border.rounded Theme.radius.sm
        , Border.width 1
        , Border.color
            (if isOpen then
                colors.primary

             else
                colors.border
            )
        , Background.color colors.surface
        , Font.size type_.bodySize
        , Font.color colors.textPrimary
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


navLink : Theme.Mode -> String -> String -> String -> Element msg
navLink themeMode currentPath path label =
    let
        colors =
            Theme.paletteFor themeMode

        isActive =
            currentPath == path

        color =
            if isActive then
                colors.primary

            else
                colors.textSecondary
    in
    link
        [ Font.color color
        , Font.medium
        , Element.mouseOver [ Font.color colors.primary ]
        ]
        { url = path, label = text label }


externalLink : Theme.Mode -> String -> String -> Element msg
externalLink themeMode url label =
    let
        colors =
            Theme.paletteFor themeMode
    in
    newTabLink
        [ Font.color colors.textSecondary
        , Font.medium
        , Element.mouseOver [ Font.color colors.primary ]
        ]
        { url = url, label = text label }



-- FOOTER


footer : Theme.Mode -> Viewport.Viewport -> Element msg
footer themeMode viewport =
    let
        colors =
            Theme.paletteFor themeMode

        brandBlock =
            column
                [ alignTop
                , alignLeft
                , spacing Theme.space.sm
                , width fill
                ]
                [ Logo.full themeMode { wordmarkSize = 18, markSize = 30 }
                ]

        projectBlock =
            footerColumn themeMode "Project"
                [ ( "https://github.com/quone-lang", "GitHub" )
                , ( "https://github.com/quone-lang/quone/issues", "Issue tracker" )
                ]

        learnBlock =
            footerColumn themeMode "Learn"
                [ ( "https://github.com/quone-lang/quone/blob/main/compiler/docs/LANGUAGE.md"
                  , "Language reference"
                  )
                , ( "https://github.com/quone-lang/quone/tree/main/examples", "Examples" )
                ]

        builtOnBlock =
            footerColumn themeMode "Built on"
                [ ( "https://www.r-project.org/", "R" )
                , ( "https://www.haskell.org/", "Haskell" )
                , ( "https://elm-lang.org/", "Elm" )
                ]

        columns =
            [ brandBlock, projectBlock, learnBlock, builtOnBlock ]
    in
    el
        [ width fill
        , Background.color colors.surface
        , Border.widthEach { top = 1, right = 0, bottom = 0, left = 0 }
        , Border.color colors.border
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
                , Border.color colors.border
                ]
                none
            , paragraph
                -- `paragraph` not `el`: on iPhone (390px viewport) the
                -- single 78-character pre-release banner reports its
                -- content width to the layout, pushing the page wider
                -- than the viewport. `paragraph` wraps to multiple
                -- lines and the page width stays bounded.
                [ alignLeft
                , width fill
                , Font.color colors.textMuted
                , Font.size type_.smallSize
                ]
                [ text "Quone v0.0.1 - pre-release work in progress. APIs and syntax may change." ]
            ]
        )


footerColumn : Theme.Mode -> String -> List ( String, String ) -> Element msg
footerColumn themeMode heading links =
    column
        [ alignTop
        , spacing Theme.space.sm
        , width fill
        ]
        (footerHeading themeMode heading
            :: List.map (\( url, label ) -> footerLink themeMode url label) links
        )


footerHeading : Theme.Mode -> String -> Element msg
footerHeading themeMode label =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.color colors.textPrimary
        , Font.semiBold
        , Font.size type_.smallSize
        ]
        (text label)


footerLink : Theme.Mode -> String -> String -> Element msg
footerLink themeMode url label =
    let
        colors =
            Theme.paletteFor themeMode
    in
    newTabLink
        [ Font.color colors.textSecondary
        , Font.size type_.smallSize
        , Element.mouseOver [ Font.color colors.primary ]
        ]
        { url = url, label = text label }



-- SECTIONS


{-| A standard centred section with the default content max width.
-}
section :
    Theme.Mode
    -> Viewport.Viewport
    -> { title : Maybe String, kicker : Maybe String, body : Element msg }
    -> Element msg
section themeMode viewport { title, kicker, body } =
    el
        [ width fill, paddingXY (horizontalPadding viewport) 0 ]
        (column
            [ width (fill |> maximum Theme.maxContentWidth)
            , centerX
            , spacing (sectionHeaderSpacing viewport)
            ]
            (List.filterMap identity
                [ Maybe.map (\k -> el [ centerX ] (sectionKicker themeMode k)) kicker
                , Maybe.map (sectionTitle themeMode viewport) title
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


sectionTitle : Theme.Mode -> Viewport.Viewport -> String -> Element msg
sectionTitle themeMode viewport s =
    let
        colors =
            Theme.paletteFor themeMode
    in
    paragraph
        [ Font.size
            (if Viewport.isHandset viewport then
                28

             else
                type_.h2Size
            )
        , Font.semiBold
        , Font.color colors.textPrimary
        , Font.family Theme.fontDisplay
        , Font.letterSpacing -0.6
        , Font.center
        , Region.heading 2
        ]
        [ text s ]


sectionKicker : Theme.Mode -> String -> Element msg
sectionKicker themeMode s =
    Eyebrow.view themeMode s


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
