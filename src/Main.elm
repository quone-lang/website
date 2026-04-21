port module Main exposing (main)

{-| Entry point for the Quone marketing site.

A two-page Browser.application:

  - "/" -> Page.Home
  - "/install" -> Page.Install

Anything else falls through to a 404 element. Routing is intentionally
trivial: there are a handful of pages, and `Browser.application` gives
us real URLs for free (Netlify rewrites every path to /index.html so
the SPA can resolve them).

-}

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Element exposing (Element, fill, height, layout, map, width)
import Element.Background as Background
import Element.Font as Font
import Json.Encode as Encode
import Page.Home as Home
import Page.Install as Install
import Ui.Layout as Layout
import Ui.Theme as Theme exposing (type_)
import Ui.Viewport as Viewport
import Url exposing (Url)



-- PROGRAM


type alias Flags =
    { width : Int
    , height : Int
    , prefersDark : Bool
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , page : Page
    , heroState : Home.HeroState
    , viewport : Viewport.Viewport
    , isMenuOpen : Bool
    , systemPrefersDark : Bool
    , themePreference : ThemePreference
    , themeMode : Theme.Mode
    }


type ThemePreference
    = FollowSystem
    | Manual Theme.Mode


type Page
    = HomePage
    | InstallPage
    | NotFoundPage


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , page = pageFromUrl url
      , heroState = Home.initHeroState
      , viewport = Viewport.fromSize flags.width flags.height
      , isMenuOpen = False
      , systemPrefersDark = flags.prefersDark
      , themePreference = FollowSystem
      , themeMode = Theme.modeFromPrefersDark flags.prefersDark
      }
    , applyThemePreference FollowSystem
    )


pageFromUrl : Url -> Page
pageFromUrl url =
    case String.toLower url.path of
        "/" ->
            HomePage

        "" ->
            HomePage

        "/install" ->
            InstallPage

        "/install/" ->
            InstallPage

        _ ->
            NotFoundPage



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | HomeMsg Home.Msg
    | ToggleMenu
    | ToggleTheme
    | ViewportChanged Int Int
    | SystemThemeChanged Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        LinkClicked (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            ( { model | page = pageFromUrl url, isMenuOpen = False }, Cmd.none )

        HomeMsg subMsg ->
            let
                ( newHeroState, heroCmd ) =
                    Home.updateHero subMsg model.heroState
            in
            ( { model | heroState = newHeroState }
            , Cmd.map HomeMsg heroCmd
            )

        ToggleMenu ->
            ( { model | isMenuOpen = not model.isMenuOpen }, Cmd.none )

        ToggleTheme ->
            let
                nextMode =
                    if model.themeMode == Theme.Dark then
                        Theme.Light

                    else
                        Theme.Dark

                nextPreference =
                    if nextMode == Theme.modeFromPrefersDark model.systemPrefersDark then
                        FollowSystem

                    else
                        Manual nextMode
            in
            ( { model
                | themePreference = nextPreference
                , themeMode = resolveThemeMode model.systemPrefersDark nextPreference
              }
            , applyThemePreference nextPreference
            )

        ViewportChanged width height ->
            let
                newViewport =
                    Viewport.fromSize width height

                stillCompact =
                    Viewport.isCompact newViewport
            in
            ( { model
                | viewport = newViewport
                , isMenuOpen =
                    if stillCompact then
                        model.isMenuOpen

                    else
                        False
              }
            , Cmd.none
            )

        SystemThemeChanged prefersDark ->
            let
                nextMode =
                    resolveThemeMode prefersDark model.themePreference
            in
            ( { model
                | systemPrefersDark = prefersDark
                , themeMode = nextMode
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onResize ViewportChanged
        , systemThemeChanged SystemThemeChanged
        ]


port systemThemeChanged : (Bool -> msg) -> Sub msg


port setThemePreference : Encode.Value -> Cmd msg


applyThemePreference : ThemePreference -> Cmd msg
applyThemePreference preference =
    setThemePreference
        (Encode.string
            (case preference of
                FollowSystem ->
                    "system"

                Manual Theme.Light ->
                    "light"

                Manual Theme.Dark ->
                    "dark"
            )
        )


resolveThemeMode : Bool -> ThemePreference -> Theme.Mode
resolveThemeMode systemPrefersDark preference =
    case preference of
        FollowSystem ->
            Theme.modeFromPrefersDark systemPrefersDark

        Manual mode ->
            mode



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        colors =
            Theme.paletteFor model.themeMode
    in
    { title = pageTitle model.page
    , body =
        [ layout
            [ width fill
            , height fill
            , Background.color colors.background
            , Font.family Theme.fontSans
            , Font.size type_.bodySize
            , Font.color colors.textPrimary
            ]
            (Layout.page
                { themeMode = model.themeMode
                , isFollowingSystem = model.themePreference == FollowSystem
                , viewport = model.viewport
                , currentPath = currentPath model.page
                , isMenuOpen = model.isMenuOpen
                , onToggleMenu = ToggleMenu
                , onToggleTheme = ToggleTheme
                , content = pageContent model
                }
            )
        ]
    }


pageTitle : Page -> String
pageTitle page =
    case page of
        HomePage ->
            "Quone - a typed functional language for R"

        InstallPage ->
            "Install Quone"

        NotFoundPage ->
            "Page not found - Quone"


currentPath : Page -> String
currentPath page =
    case page of
        HomePage ->
            "/"

        InstallPage ->
            "/install"

        NotFoundPage ->
            ""


pageContent : Model -> Element Msg
pageContent model =
    case model.page of
        HomePage ->
            Element.map HomeMsg
                (Home.view model.themeMode model.viewport model.heroState)

        InstallPage ->
            Install.view model.themeMode model.viewport

        NotFoundPage ->
            notFound model.themeMode


notFound : Theme.Mode -> Element msg
notFound themeMode =
    let
        colors =
            Theme.paletteFor themeMode
    in
    Element.column
        [ width fill
        , Element.centerX
        , Element.spacing Theme.space.md
        , Element.paddingXY Theme.space.lg Theme.space.section
        ]
        [ Element.el
            [ Element.centerX
            , Font.size type_.h1Size
            , Font.semiBold
            , Font.color colors.textPrimary
            ]
            (Element.text "Page not found")
        , Element.el
            [ Element.centerX
            , Font.color colors.textSecondary
            ]
            (Element.text "That URL doesn't exist on quone-lang.org.")
        ]
