module Content.Pitch exposing
    ( Feature
    , tagline
    , subtagline
    , features
    , whyQuone
    )

{-| Marketing copy for the home page. Kept as plain Elm strings so the
home-page module stays focused on layout.

The voice is direct, technical, and respectful of the R audience: no
breathless adjectives, no claims of being "better than" R - the pitch
is that Quone gives R users static checks and a uniform syntax while
producing code they could have written themselves.

-}


tagline : String
tagline =
    "A typed functional language for R."


subtagline : String
subtagline =
    "Quone adds static guarantees to R workflows, then compiles back to readable R your team can run, debug, and ship."



-- FEATURE CARDS


type alias Feature =
    { title : String
    , body : String
    }


features : List Feature
features =
    [ { title = "Readable R out"
      , body =
            "Generated R looks like code an R developer would actually write, with no runtime wrapper to decode first."
      }
    , { title = "Typed pipelines"
      , body =
            "Dataframe verbs stay dplyr-shaped, but column references and pipeline stages are checked before you ship."
      }
    , { title = "Fits existing teams"
      , body =
            "You still hand off plain R, package it the usual way, and keep using the ecosystem your collaborators already know."
      }
    ]



-- LONGER PITCH (used on the home page below the feature grid)


whyQuone : List String
whyQuone =
    [ "Quone is for R users who want compiler help without giving up the R ecosystem they already work in."
    , "v0.0.1 is early, but already useful for teams that want more confidence around pipelines, functions, and package-ready output."
    ]
