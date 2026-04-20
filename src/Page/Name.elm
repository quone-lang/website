module Page.Name exposing (view)

{-| The "About the name" section.

S begat R. R begat Quone. The name is a nod to a running Seinfeld joke
about an imaginary dictionary entry - fitting for a language that
exists because someone decided to invent one.

-}

import Element
    exposing
        ( Element
        , centerX
        , column
        , el
        , fill
        , maximum
        , newTabLink
        , paddingEach
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
import Ui.Theme as Theme exposing (palette, type_)


view : Element msg
view =
    column
        [ width (fill |> maximum 720)
        , centerX
        , spacing Theme.space.lg
        ]
        [ paragraph
            [ Font.size type_.bodyLargeSize
            , Font.color palette.textSecondary
            , Element.spacing 6
            ]
            [ text "S begat R. R begat Quone. The name is a nod to a running Seinfeld joke about an imaginary dictionary entry - fitting for a language that exists because someone decided to invent one." ]
        , quote
        ]


quote : Element msg
quote =
    column
        [ width fill
        , Background.color palette.surface
        , Border.widthEach { top = 0, right = 0, bottom = 0, left = 3 }
        , Border.color palette.secondary
        , paddingEach
            { top = Theme.space.md
            , right = Theme.space.lg
            , bottom = Theme.space.md
            , left = Theme.space.lg
            }
        , spacing Theme.space.sm
        ]
        [ el
            [ Font.family Theme.fontDisplay
            , Font.size 22
            , Font.color palette.textPrimary
            , Font.italic
            ]
            (text "\u{201C}I'm pretty sure quoning is an actual word.\u{201D}")
        , row
            [ spacing Theme.space.xs
            , Font.size type_.smallSize
            , Font.color palette.textMuted
            ]
            [ text "George Costanza ·"
            , newTabLink
                [ Font.color palette.primary
                , Font.medium
                ]
                { url = "https://www.youtube.com/watch?v=fzPy8kSn7o0"
                , label = text "The Bookstore (Seinfeld, 1998) ↗"
                }
            ]
        ]
