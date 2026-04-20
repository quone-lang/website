module Main exposing (main)

{-| Entry point for the Quone marketing site.

A two-page Browser.application:

  - "/" -> Page.Home
  - "/install" -> Page.Install

Anything else falls through to a 404 element. Routing is intentionally
trivial: there are only two pages, and `Browser.application` gives us
real URLs for free (Netlify rewrites every path to /index.html so the
SPA can resolve them).

-}

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Element exposing (Element, fill, height, layout, width)
import Element.Background as Background
import Element.Font as Font
import Page.Home as Home
import Page.Install as Install
import Ui.Layout as Layout
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport
import Url exposing (Url)



-- PROGRAM


main : Program Viewport.Flags Model Msg
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
    }


type Page
    = HomePage
    | InstallPage
    | NotFoundPage


init : Viewport.Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , page = pageFromUrl url
      , heroState = Home.initHeroState
      , viewport = Viewport.fromFlags flags
      , isMenuOpen = False
      }
    , Cmd.none
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
    | ViewportChanged Int Int


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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize ViewportChanged



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = pageTitle model.page
    , body =
        [ layout
            [ width fill
            , height fill
            , Background.color palette.background
            , Font.family [ Theme.fontSans, Font.sansSerif ]
            , Font.size type_.bodySize
            , Font.color palette.textPrimary
            ]
            (Layout.page
                { viewport = model.viewport
                , currentPath = currentPath model.page
                , isMenuOpen = model.isMenuOpen
                , onToggleMenu = ToggleMenu
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
                (Home.view model.viewport model.heroState)

        InstallPage ->
            Install.view model.viewport

        NotFoundPage ->
            notFound


notFound : Element msg
notFound =
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
            , Font.color palette.textPrimary
            ]
            (Element.text "Page not found")
        , Element.el
            [ Element.centerX
            , Font.color palette.textSecondary
            ]
            (Element.text "That URL doesn't exist on quone-lang.org.")
        ]
