module Ui.Viewport exposing
    ( Viewport
    , fromSize
    , isCompact
    , isHandset
    )

{-| Shared viewport helpers used for responsive layout decisions.
-}


type alias Viewport =
    { width : Int
    , height : Int
    }


fromSize : Int -> Int -> Viewport
fromSize width height =
    { width = max 320 width
    , height = max 480 height
    }


isHandset : Viewport -> Bool
isHandset viewport =
    viewport.width < 640


isCompact : Viewport -> Bool
isCompact viewport =
    viewport.width < 760
