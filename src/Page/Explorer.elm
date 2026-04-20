module Page.Explorer exposing
    ( Model
    , Msg
    , ExampleId(..)
    , init
    , update
    , view
    )

{-| The interactive code explorer.

A user picks a Quone example (a dplyr pipeline or an rmse function),
then clicks any group in the Quone source on the left to see the
corresponding R the compiler would emit, with a short explanation of
the lowering. Hovering also previews chunks without committing.

This is a port of the original quone-lang/website explorer, restructured
to fit the elm-ui foundation of the rest of the site.

-}

import Element
    exposing
        ( Element
        , alignTop
        , centerY
        , clip
        , column
        , el
        , fill
        , height
        , htmlAttribute
        , padding
        , paddingXY
        , paragraph
        , px
        , row
        , scrollbarX
        , spacing
        , text
        , width
        , wrappedRow
        )
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport



-- MODEL


type alias Model =
    { example : ExampleId
    , selectedChunk : Int
    , hoveredChunk : Maybe Int
    }


type ExampleId
    = ExDplyr
    | ExRmse
    | ExMaybe
    | ExPackage


init : Model
init =
    { example = ExDplyr
    , selectedChunk = 0
    , hoveredChunk = Nothing
    }



-- MSG / UPDATE


type Msg
    = SelectExample ExampleId
    | SelectChunk Int
    | HoverChunk (Maybe Int)


update : Msg -> Model -> Model
update msg model =
    case msg of
        SelectExample ex ->
            { model | example = ex, selectedChunk = 0, hoveredChunk = Nothing }

        SelectChunk i ->
            { model | selectedChunk = i }

        HoverChunk h ->
            { model | hoveredChunk = h }



-- TOKENS (mini highlighter local to the explorer; the main CodeBlock
-- module's tokeniser is keyword-driven, but the explorer uses
-- pre-tagged lines so the highlighting is exactly what the example
-- author intended.)


type Token
    = Plain String
    | Comment String
    | Keyword String
    | Ty String
    | Str String
    | Num String
    | Op String
    | Fn String


type alias Chunk =
    { id : Int
    , tag : String
    , quone : List (List Token)
    , r : List (List Token)
    , explain : String
    }


type alias Example =
    { id : ExampleId
    , label : String
    , caption : String
    , chunks : List Chunk
    }


examplesData : ExampleId -> Example
examplesData id =
    case id of
        ExDplyr ->
            dplyrExample

        ExRmse ->
            rmseExample

        ExMaybe ->
            maybeExample

        ExPackage ->
            packageExample


chunkAt : List Chunk -> Int -> Chunk
chunkAt chunks idx =
    case List.head (List.drop idx chunks) of
        Just c ->
            c

        Nothing ->
            case List.head chunks of
                Just c ->
                    c

                Nothing ->
                    { id = 0, tag = "—", quone = [], r = [], explain = "" }



-- VIEW


view : Viewport.Viewport -> Model -> Element Msg
view viewport model =
    let
        ex =
            examplesData model.example

        active =
            model.selectedChunk

        highlighted =
            model.hoveredChunk |> Maybe.withDefault active
    in
    column
        [ width fill, spacing Theme.space.lg ]
        [ controls viewport model
        , exampleCaption ex
        , wrappedRow
            [ width fill
            , spacing Theme.space.lg
            , alignTop
            ]
            [ pane
                { kind = QuonePane
                , filename = ex.label ++ ".q"
                , chunks = ex.chunks
                , highlighted = highlighted
                , isR = False
                }
            , pane
                { kind = RPane
                , filename = ex.label ++ ".R"
                , chunks = ex.chunks
                , highlighted = highlighted
                , isR = True
                }
            ]
        , explanation viewport (chunkAt ex.chunks active)
        ]


exampleCaption : Example -> Element msg
exampleCaption ex =
    let
        chunkCount =
            List.length ex.chunks

        chunkLabel =
            String.fromInt chunkCount
                ++ (if chunkCount == 1 then
                        " chunk"

                    else
                        " chunks"
                   )
    in
    paragraph
        [ Font.size type_.smallSize
        , Font.color palette.textMuted
        ]
        [ el [ Font.semiBold, Font.color palette.textPrimary ] (text ex.caption)
        , text " · "
        , text chunkLabel
        ]


controls : Viewport.Viewport -> Model -> Element Msg
controls viewport model =
    let
        tabButtons =
            [ exampleTab model ExDplyr "pipeline"
            , exampleTab model ExRmse "rmse"
            , exampleTab model ExMaybe "maybe"
            , exampleTab model ExPackage "package"
            ]

        tabs =
            if Viewport.isCompact viewport then
                wrappedRow
                    [ width fill
                    , spacing Theme.space.sm
                    ]
                    tabButtons

            else
                row
                    [ spacing Theme.space.sm ]
                    tabButtons

        helperCopy =
            if Viewport.isCompact viewport then
                "Tap a highlighted group to compare it with the generated R"

            else
                "Select a highlighted group to compare it with the generated R"

        helper =
            row
                [ spacing Theme.space.sm
                , centerY
                ]
                [ pulse
                , el
                    [ Font.size type_.smallSize
                    , Font.color palette.textMuted
                    ]
                    (text helperCopy)
                ]
    in
    if Viewport.isCompact viewport then
        column
            [ width fill
            , spacing Theme.space.md
            ]
            [ tabs
            , helper
            ]

    else
        row
            [ width fill
            , spacing Theme.space.md
            , centerY
            ]
            [ tabs
            , el [ Element.alignRight ] helper
            ]


exampleTab : Model -> ExampleId -> String -> Element Msg
exampleTab model id label =
    let
        isActive =
            model.example == id

        attrs =
            if isActive then
                [ Background.color palette.primary
                , Font.color palette.textOnPrimary
                , Border.color palette.primary
                , Border.width 1
                ]

            else
                [ Background.color palette.surface
                , Font.color palette.textPrimary
                , Border.color palette.border
                , Border.width 1
                , Element.mouseOver
                    [ Border.color palette.primary
                    , Background.color palette.codeSurface
                    ]
                ]
    in
    Input.button
        ([ paddingXY Theme.space.md (Theme.space.sm + 2)
         , Border.rounded Theme.radius.pill
         , Font.size type_.smallSize
         , Font.medium
         , htmlAttribute
            (Html.Attributes.attribute
                "aria-pressed"
                (if isActive then
                    "true"

                 else
                    "false"
                )
            )
         ]
            ++ attrs
        )
        { onPress = Just (SelectExample id)
        , label = text label
        }


pulse : Element msg
pulse =
    el
        [ width (px 8)
        , height (px 8)
        , Background.color palette.secondary
        , Border.rounded 4
        ]
        Element.none


type PaneKind
    = QuonePane
    | RPane


pane :
    { kind : PaneKind
    , filename : String
    , chunks : List Chunk
    , highlighted : Int
    , isR : Bool
    }
    -> Element Msg
pane { kind, filename, chunks, highlighted, isR } =
    let
        ( bg, fg, badgeColor ) =
            case kind of
                QuonePane ->
                    ( Element.rgb255 0x16 0x16 0x16
                    , Element.rgb255 0xE6 0xE6 0xE3
                    , palette.secondary
                    )

                RPane ->
                    ( palette.surface
                    , palette.textPrimary
                    , palette.primary
                    )

        badgeLabel =
            case kind of
                QuonePane ->
                    "Quone"

                RPane ->
                    "R"
    in
    column
        [ width fill
        , Background.color bg
        , Border.rounded Theme.radius.lg
        , Border.width 1
        , Border.color palette.border
        , clip
        , alignTop
        , Element.htmlAttribute (Html.Attributes.style "min-width" "0")
        , Element.htmlAttribute (Html.Attributes.style "flex" "1 1 340px")
        ]
        [ row
            [ width fill
            , paddingXY Theme.space.md (Theme.space.sm + 2)
            , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
            , Border.color (Element.rgba 1 1 1 0.06)
            , spacing Theme.space.sm
            ]
            [ el
                [ Font.family Theme.fontMono
                , Font.size type_.codeSmallSize
                , Font.color (paneHeaderColor kind)
                ]
                (text filename)
            , el
                [ Element.alignRight
                , Font.size 10
                , Font.semiBold
                , Font.letterSpacing 1.2
                , Font.color badgeColor
                , paddingXY 8 3
                , Border.width 1
                , Border.color badgeColor
                , Border.rounded Theme.radius.pill
                ]
                (text (String.toUpper badgeLabel))
            ]
        , el
            [ width fill
            , clip
            , scrollbarX
            ]
            (column
                [ width fill
                , paddingXY Theme.space.md Theme.space.md
                , spacing 2
                , Font.family Theme.fontMono
                , Font.size type_.codeSize
                , Font.color fg
                ]
                (List.map (chunkView highlighted isR kind) chunks)
            )
        ]


paneHeaderColor : PaneKind -> Element.Color
paneHeaderColor kind =
    case kind of
        QuonePane ->
            Element.rgb255 0x9A 0x9A 0x96

        RPane ->
            palette.textMuted


chunkView : Int -> Bool -> PaneKind -> Chunk -> Element Msg
chunkView highlighted isR kind chunk =
    let
        lines =
            if isR then
                chunk.r

            else
                chunk.quone

        isActive =
            chunk.id == highlighted

        state =
            case ( kind, isActive ) of
                ( QuonePane, True ) ->
                    { background = Element.rgba255 0xE0 0x60 0x4C 0.18
                    , hoverBackground = Element.rgba255 0xE0 0x60 0x4C 0.18
                    , borderColor = palette.secondary
                    , opacity = "1"
                    }

                ( QuonePane, False ) ->
                    { background = Element.rgba 0 0 0 0
                    , hoverBackground = Element.rgba255 0xE0 0x60 0x4C 0.08
                    , borderColor = Element.rgba 0 0 0 0
                    , opacity = "0.72"
                    }

                ( RPane, True ) ->
                    { background = Element.rgba255 0x27 0x6D 0xC3 0.10
                    , hoverBackground = Element.rgba255 0x27 0x6D 0xC3 0.10
                    , borderColor = palette.primary
                    , opacity = "1"
                    }

                ( RPane, False ) ->
                    { background = Element.rgba 0 0 0 0
                    , hoverBackground = Element.rgba255 0x27 0x6D 0xC3 0.05
                    , borderColor = Element.rgba 0 0 0 0
                    , opacity = "0.78"
                    }
    in
    Input.button
        [ width fill
        , Background.color state.background
        , paddingXY Theme.space.sm (Theme.space.xs + 2)
        , Border.rounded Theme.radius.sm
        , Border.width 1
        , Border.color state.borderColor
        , Events.onMouseEnter (HoverChunk (Just chunk.id))
        , Events.onMouseLeave (HoverChunk Nothing)
        , htmlAttribute (Html.Attributes.style "opacity" state.opacity)
        , htmlAttribute (Html.Attributes.style "transition" "opacity 0.15s ease, background-color 0.15s ease")
        , htmlAttribute
            (Html.Attributes.attribute
                "aria-pressed"
                (if isActive then
                    "true"

                 else
                    "false"
                )
            )
        , Element.mouseOver
            [ Background.color state.hoverBackground ]
        ]
        { onPress = Just (SelectChunk chunk.id)
        , label =
            column
                [ width fill
                , spacing 2
                ]
                (List.map (codeLine kind) lines)
        }


codeLine : PaneKind -> List Token -> Element msg
codeLine kind tokens =
    let
        children =
            case tokens of
                [] ->
                    [ el [] (text "\u{00A0}") ]

                _ ->
                    List.map (renderToken kind) tokens
    in
    row
        [ spacing 0
        , htmlAttribute (Html.Attributes.style "white-space" "pre")
        ]
        children


renderToken : PaneKind -> Token -> Element msg
renderToken kind tok =
    case tok of
        Plain s ->
            text s

        Comment s ->
            el
                [ Font.color (tokenColor kind .comment)
                , Font.italic
                ]
                (text s)

        Keyword s ->
            el [ Font.color (tokenColor kind .keyword), Font.semiBold ] (text s)

        Ty s ->
            el [ Font.color (tokenColor kind .ty), Font.medium ] (text s)

        Str s ->
            el [ Font.color (tokenColor kind .str) ] (text s)

        Num s ->
            el [ Font.color (tokenColor kind .num) ] (text s)

        Op s ->
            el [ Font.color (tokenColor kind .op) ] (text s)

        Fn s ->
            el [ Font.color (tokenColor kind .fn) ] (text s)


tokenColor :
    PaneKind
    -> ({ comment : Element.Color, keyword : Element.Color, ty : Element.Color, str : Element.Color, num : Element.Color, op : Element.Color, fn : Element.Color } -> Element.Color)
    -> Element.Color
tokenColor kind pick =
    case kind of
        QuonePane ->
            pick darkTokens

        RPane ->
            pick lightTokens


darkTokens :
    { comment : Element.Color
    , keyword : Element.Color
    , ty : Element.Color
    , str : Element.Color
    , num : Element.Color
    , op : Element.Color
    , fn : Element.Color
    }
darkTokens =
    { comment = Element.rgb255 0x8C 0x93 0xA0
    , keyword = Element.rgb255 0xFF 0xB3 0xA6
    , ty = Element.rgb255 0x6F 0xEC 0xDA
    , str = Element.rgb255 0xF7 0xD8 0x9A
    , num = Element.rgb255 0xCD 0xB1 0xFF
    , op = Element.rgb255 0xFF 0xB3 0xA6
    , fn = Element.rgb255 0x9D 0xC5 0xFF
    }


lightTokens :
    { comment : Element.Color
    , keyword : Element.Color
    , ty : Element.Color
    , str : Element.Color
    , num : Element.Color
    , op : Element.Color
    , fn : Element.Color
    }
lightTokens =
    { comment = palette.codeComment
    , keyword = palette.codeKeyword
    , ty = palette.codeType
    , str = palette.codeString
    , num = palette.codeNumber
    , op = palette.codeOperator
    , fn = palette.primaryDark
    }


explanation : Viewport.Viewport -> Chunk -> Element msg
explanation viewport chunk =
    column
        [ width fill
        , Background.color palette.surface
        , Border.rounded Theme.radius.lg
        , Border.width 1
        , Border.color palette.border
        , padding
            (if Viewport.isHandset viewport then
                Theme.space.md

             else
                Theme.space.lg
            )
        , spacing Theme.space.md
        ]
        [ el
            [ Font.size 10
            , Font.semiBold
            , Font.letterSpacing 1.4
            , Font.color palette.secondary
            , paddingXY 10 4
            , Border.rounded Theme.radius.pill
            , Background.color (Element.rgba255 0xE0 0x60 0x4C 0.10)
            ]
            (text (String.toUpper chunk.tag))
        , paragraph
            [ Font.size type_.bodySize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            (renderExplain chunk.explain)
        ]


renderExplain : String -> List (Element msg)
renderExplain s =
    let
        parts =
            String.split "`" s

        render idx str =
            if modBy 2 idx == 1 then
                el
                    [ Font.family Theme.fontMono
                    , Font.size type_.codeSmallSize
                    , Font.color palette.codeKeyword
                    , Background.color palette.codeSurface
                    , paddingXY 6 1
                    , Border.rounded Theme.radius.sm
                    ]
                    (text str)

            else
                text str
    in
    List.indexedMap render parts



-- DATA


dplyrExample : Example
dplyrExample =
    { id = ExDplyr
    , label = "pipeline"
    , caption = "A type-checked dplyr pipeline"
    , chunks =
        [ { id = 0
          , tag = "Pipe start"
          , quone =
                [ [ Plain "result ", Op "<-" ]
                , [ Plain "    students" ]
                ]
          , r =
                [ [ Plain "result ", Op "<-", Plain " students ", Op "|>" ]
                ]
          , explain = "Every Quone `|>` lowers to R's native pipe. The compiler already knows `students` is a dataframe with columns `name`, `score`, `dept`, so later stages of the pipeline get a real schema to type-check against - not just a vague `data.frame`."
          }
        , { id = 1
          , tag = "filter"
          , quone =
                [ [ Plain "        ", Op "|>", Plain " ", Fn "filter", Plain " (score ", Op ">", Plain " ", Num "70.0", Plain ")" ]
                ]
          , r =
                [ [ Plain "  ", Fn "dplyr::filter", Plain "(score ", Op ">", Plain " ", Num "70.0", Plain ") ", Op "|>" ]
                ]
          , explain = "`filter` becomes `dplyr::filter`. The predicate `score > 70.0` is type-checked against the row type of `students`, so a typo like `scroe` or comparing a `Character` to a `Double` is a compile-time error, not a mysterious warning at runtime."
          }
        , { id = 2
          , tag = "mutate"
          , quone =
                [ [ Plain "        ", Op "|>", Plain " ", Fn "mutate", Plain " { pct = score ", Op "/", Plain " ", Num "100.0", Plain " }" ]
                ]
          , r =
                [ [ Plain "  ", Fn "dplyr::mutate", Plain "(pct = score ", Op "/", Plain " ", Num "100.0", Plain ") ", Op "|>" ]
                ]
          , explain = "`mutate` takes a record of new columns. After this step the inferred type of the pipeline is `{ name, score, dept, pct : Vector Double }` - downstream stages see `pct` as a real column, so you can chain off of it safely."
          }
        , { id = 3
          , tag = "arrange"
          , quone =
                [ [ Plain "        ", Op "|>", Plain " ", Fn "arrange", Plain " { ", Keyword "desc", Plain " score }" ]
                ]
          , r =
                [ [ Plain "  ", Fn "dplyr::arrange", Plain "(", Fn "dplyr::desc", Plain "(score))" ]
                ]
          , explain = "`arrange { desc score }` recognises `desc` as a sort modifier (LANGUAGE.md section 9.5) and emits a fully qualified `dplyr::desc` call. Modifiers stay namespaced so they can't accidentally shadow anything in your global R environment."
          }
        ]
    }


rmseExample : Example
rmseExample =
    { id = ExRmse
    , label = "rmse"
    , caption = "A curried function with vectorised arithmetic"
    , chunks =
        [ { id = 0
          , tag = "Doc + signature"
          , quone =
                [ [ Comment "#' Root-mean-squared error of two vectors." ]
                , [ Comment "#' @export" ]
                , [ Fn "rmse", Plain " : ", Ty "Vector", Plain " ", Ty "Double", Plain " ", Op "->", Plain " ", Ty "Vector", Plain " ", Ty "Double", Plain " ", Op "->", Plain " ", Ty "Double" ]
                ]
          , r =
                [ [ Comment "#' Root-mean-squared error of two vectors." ]
                , [ Comment "#' @export" ]
                ]
          , explain = "`#'` doc blocks pass through verbatim - they're already in `roxygen2` format. The Quone type signature is checked, then dropped: in package mode `roxygen2::roxygenise` later turns the `@export` tag into a `NAMESPACE` entry."
          }
        , { id = 1
          , tag = "Definition"
          , quone =
                [ [ Fn "rmse", Plain " predicted actual ", Op "<-" ]
                ]
          , r =
                [ [ Plain "rmse ", Op "<-", Plain " ", Keyword "function", Plain "(predicted, actual) {" ]
                ]
          , explain = "A curried-looking Quone definition compiles to a plain R function with positional arguments. Quone is curried under the hood, but a fully-applied call lowers to a single multi-arg R call - no closure gymnastics unless you ask for them (LANGUAGE.md section 13.3)."
          }
        , { id = 2
          , tag = "Vectorised arithmetic"
          , quone =
                [ [ Plain "    predicted" ]
                , [ Plain "        ", Op "|>", Plain " ", Fn "map2", Plain " (", Op "\\", Plain "p a ", Op "->", Plain " (p ", Op "-", Plain " a) ", Op "^", Plain " ", Num "2.0", Plain ") actual" ]
                ]
          , r =
                [ [ Plain "  (predicted ", Op "-", Plain " actual) ", Op "^", Plain " ", Num "2.0" ]
                ]
          , explain = "The compiler spots that the lambda is pointwise arithmetic on two `Vector Double`s and lowers the whole thing to vectorised R - no `purrr::map2_dbl`, no allocation per element. This is the base-R exception called out in LANGUAGE.md section 13.3.2."
          }
        , { id = 3
          , tag = "Aggregate"
          , quone =
                [ [ Plain "        ", Op "|>", Plain " ", Fn "mean" ]
                , [ Plain "        ", Op "|>", Plain " ", Fn "sqrt" ]
                ]
          , r =
                [ [ Plain "  ", Op "|>", Plain " ", Fn "mean", Plain "()" ]
                , [ Plain "  ", Op "|>", Plain " ", Fn "sqrt", Plain "()" ]
                , [ Plain "}" ]
                ]
          , explain = "Pipelines of unary calls compile one-to-one. `mean` and `sqrt` are base R, so there's nothing new for an R reader to learn. The closing `}` matches the `function(...) {` opened in the definition step above."
          }
        ]
    }


maybeExample : Example
maybeExample =
    { id = ExMaybe
    , label = "maybe"
    , caption = "An exhaustive Maybe match"
    , chunks =
        [ { id = 0
          , tag = "Definition"
          , quone =
                [ [ Fn "fallback", Plain " : ", Ty "Maybe", Plain " ", Ty "Double", Plain " ", Op "->", Plain " ", Ty "Double" ]
                , [ Fn "fallback", Plain " maybe_score ", Op "<-" ]
                , [ Plain "    ", Keyword "case", Plain " maybe_score ", Keyword "of" ]
                ]
          , r =
                [ [ Plain "fallback ", Op "<-", Plain " ", Keyword "function", Plain "(maybe_score) {" ]
                ]
          , explain = "Custom types stay explicit in the source. This `Maybe Double` input compiles to an ordinary R function, but Quone still checks that every possible branch is handled."
          }
        , { id = 1
          , tag = "Just branch"
          , quone =
                [ [ Plain "        ", Ty "Just", Plain " score ", Op "->" ]
                , [ Plain "            score" ]
                ]
          , r =
                [ [ Plain "  ", Keyword "if", Plain " (maybe_score$tag == ", Str "\"Just\"", Plain ") {" ]
                , [ Plain "    maybe_score$value" ]
                ]
          , explain = "The `Just` branch becomes a straightforward `if` in the generated R. Quone knows this branch carries a real `Double`, so the body can use `score` directly."
          }
        , { id = 2
          , tag = "Nothing branch"
          , quone =
                [ [ Plain "        ", Ty "Nothing", Plain " ", Op "->" ]
                , [ Plain "            ", Num "0.0" ]
                ]
          , r =
                [ [ Plain "  } ", Keyword "else", Plain " {" ]
                , [ Plain "    ", Num "0.0" ]
                , [ Plain "  }" ]
                , [ Plain "}" ]
                ]
          , explain = "Because the `Nothing` branch is required, there is no silent missing-case fallthrough. The generated R stays simple, but the source was checked for exhaustiveness first."
          }
        ]
    }


packageExample : Example
packageExample =
    { id = ExPackage
    , label = "package"
    , caption = "A package-ready exported function"
    , chunks =
        [ { id = 0
          , tag = "Doc block"
          , quone =
                [ [ Comment "#' Normalize a score." ]
                , [ Comment "#' @export" ]
                ]
          , r =
                [ [ Comment "#' Normalize a score." ]
                , [ Comment "#' @export" ]
                ]
          , explain = "Roxygen-style comments pass through unchanged, so package-facing docs stay in the same place you define the function."
          }
        , { id = 1
          , tag = "Checked signature"
          , quone =
                [ [ Fn "normalize", Plain " : ", Ty "Double", Plain " ", Op "->", Plain " ", Ty "Double", Plain " ", Op "->", Plain " ", Ty "Double" ]
                ]
          , r =
                [ [ Comment "# type checked at compile time" ] ]
          , explain = "The type signature is for Quone and the compiler: it gets checked, then dropped from the emitted R so the output stays idiomatic."
          }
        , { id = 2
          , tag = "Exported function"
          , quone =
                [ [ Fn "normalize", Plain " max_score raw ", Op "<-" ]
                , [ Plain "    raw ", Op "/", Plain " max_score" ]
                ]
          , r =
                [ [ Plain "normalize ", Op "<-", Plain " ", Keyword "function", Plain "(max_score, raw) {" ]
                , [ Plain "  raw ", Op "/", Plain " max_score" ]
                , [ Plain "}" ]
                ]
          , explain = "The emitted function looks like ordinary package code. `@export` stays with it, ready for `roxygen2` to turn into the package `NAMESPACE` entry."
          }
        ]
    }
