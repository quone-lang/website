module Page.Comparison exposing (view)

{-| A lighter "How it compares" section.

The original five-column matrix was precise, but it asked visitors to do
too much parsing for a marketing page. These cards keep the message
while making the section scannable on both desktop and mobile.
-}

import Element
    exposing
        ( Element
        , alignTop
        , column
        , el
        , fill
        , maximum
        , minimum
        , padding
        , paragraph
        , spacing
        , text
        , width
        , wrappedRow
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport


type alias Point =
    { title : String
    , typicalR : String
    , quone : String
    }


points : List Point
points =
    [ { title = "Catch dataframe mistakes earlier"
      , typicalR =
            "Misspelled columns and schema mismatches usually show up when the script runs, after a linter pass, or in code review."
      , quone =
            "Dataframe shape is part of the program, so column references are checked before you ship generated R."
      }
    , { title = "Make absence and failure explicit"
      , typicalR =
            "Missing values and fallible loading code are easy to leave implicit until an analysis goes sideways."
      , quone =
            "Maybe- and Result-shaped flows make those cases visible in the source instead of hiding them in conventions."
      }
    , { title = "Refactor with a compiler beside you"
      , typicalR =
            "Renaming fields, splitting modules, or reworking a pipeline is often a search-and-pray exercise."
      , quone =
            "Signatures, custom types, and dataframe fields stay checked together, so refactors fail loudly instead of drifting."
      }
    , { title = "Still hand off plain R"
      , typicalR =
            "Your team already knows how to run, diff, debug, and package R."
      , quone =
            "Quone keeps that workflow intact: the output is readable R that fits the ecosystem you already use."
      }
    ]


view : Viewport.Viewport -> Element msg
view viewport =
    let
        cards =
            List.map pointCard points
    in
    if Viewport.isCompact viewport then
        column
            [ width fill
            , spacing Theme.space.lg
            ]
            cards

    else
        wrappedRow
            [ width fill
            , spacing Theme.space.lg
            ]
            cards


pointCard : Point -> Element msg
pointCard point =
    column
        [ width (fill |> minimum 280 |> maximum 540)
        , alignTop
        , Background.color palette.surface
        , Border.rounded Theme.radius.lg
        , Border.width 1
        , Border.color palette.border
        , padding Theme.space.lg
        , spacing Theme.space.md
        ]
        [ paragraph
            [ Font.size type_.h3Size
            , Font.semiBold
            , Font.color palette.textPrimary
            ]
            [ text point.title ]
        , comparisonBlock
            { label = "Typical R"
            , labelColor = palette.textMuted
            , bodyColor = palette.textSecondary
            , background = palette.codeSurface
            , copy = point.typicalR
            }
        , comparisonBlock
            { label = "Quone"
            , labelColor = palette.primary
            , bodyColor = palette.primaryDark
            , background = Element.rgba255 0x27 0x6D 0xC3 0.06
            , copy = point.quone
            }
        ]


comparisonBlock :
    { label : String
    , labelColor : Element.Color
    , bodyColor : Element.Color
    , background : Element.Color
    , copy : String
    }
    -> Element msg
comparisonBlock config =
    column
        [ spacing Theme.space.xs
        , Background.color config.background
        , Border.rounded Theme.radius.md
        , padding Theme.space.md
        ]
        [ el
            [ Font.size type_.smallSize
            , Font.semiBold
            , Font.color config.labelColor
            , Font.letterSpacing 0.8
            ]
            (text (String.toUpper config.label))
        , paragraph
            [ Font.size type_.bodySize
            , Font.color config.bodyColor
            , Element.spacing 6
            ]
            [ text config.copy ]
        ]
