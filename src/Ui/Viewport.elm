module Ui.Viewport exposing
    ( Flags
    , Viewport
    , fromFlags
    , fromSize
    , isCompact
    , isHandset
    , isTabletDown
    )

{-| Shared viewport helpers used for responsive layout decisions.
-}


type alias Flags =
    { width : Int
    , height : Int
    }


type alias Viewport =
    { width : Int
    , height : Int
    }


fromFlags : Flags -> Viewport
fromFlags flags =
    fromSize flags.width flags.height


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


isTabletDown : Viewport -> Bool
isTabletDown viewport =
    viewport.width < 960
