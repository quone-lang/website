module Content.Examples exposing
    ( Snippet
    , normalizeSnippet
    , heroSnippets
    )

{-| The Quone code samples shown on the marketing site.

Each snippet has a realistic filename and a small Quone program plus
the R the compiler would emit when you call `quone::compile()` on it.
The R column is what the v0.0.1 compiler is specified to produce per
LANGUAGE.md sections 13 and 14 - it is not a hand-stylised
approximation.

-}


{-| A short Quone snippet shown in the hero "try it" tabs.
-}
type alias Snippet =
    { filename : String
    , blurb : String
    , quone : String
    , r : String
    }


{-| The full set of snippets featured in the hero tab strip, in display
order. The first one is shown by default. Snippets are ordered by size:
the smallest, easiest-to-read example sits on the left and they grow
in length and richness as you move right.
-}
heroSnippets : List Snippet
heroSnippets =
    [ normalizeSnippet
    , meanSnippet
    , rmseSnippet
    , topScoresSnippet
    , adslSummarySnippet
    ]


normalizeSnippet : Snippet
normalizeSnippet =
    { filename = "normalize.Q"
    , blurb = ""
    , quone = """normalize : Double -> Double -> Double
normalize max_score raw <-
    raw / max_score"""
    , r = """normalize <- function(max_score, raw) {
  raw / max_score
}"""
    }


meanSnippet : Snippet
meanSnippet =
    { filename = "mean.Q"
    , blurb = ""
    , quone = """average : Vector Double -> Double
average xs <-
    sum xs / length xs"""
    , r = """average <- function(xs) {
  sum(xs) / length(xs)
}"""
    }


rmseSnippet : Snippet
rmseSnippet =
    { filename = "rmse.Q"
    , blurb = ""
    , quone = """rmse : Vector Double -> Vector Double -> Double
rmse predictions actuals <-
    predictions
        |> map2 (\\p a -> (p - a) ^ 2.0) actuals
        |> mean
        |> sqrt"""
    , r = """rmse <- function(predictions, actuals) {
  sqrt(
    mean(
      purrr::map2_dbl(predictions, actuals, function(p, a) (p - a) ^ 2.0)
    )
  )
}"""
    }


topScoresSnippet : Snippet
topScoresSnippet =
    { filename = "top_scores.Q"
    , blurb = ""
    , quone = """type alias Students <-
    dataframe
        { name  : Vector Character
        , score : Vector Double
        }

top_scores : Students -> Students
top_scores students <-
    students
        |> filter (score >= 70.0)
        |> arrange { desc score }"""
    , r = """top_scores <- function(students) {
  students |>
    dplyr::filter(score >= 70.0) |>
    dplyr::arrange(dplyr::desc(score))
}"""
    }


adslSummarySnippet : Snippet
adslSummarySnippet =
    { filename = "adsl_summary.Q"
    , blurb = ""
    , quone = """type alias Adsl <-
    dataframe
        { subject_id : Vector Character
        , arm        : Vector Character
        , age        : Vector Integer
        , sex        : Vector Character
        }

adsl_summary :
    Adsl
    -> dataframe
        { arm        : Vector Character
        , n_subjects : Vector Integer
        , mean_age   : Vector Double
        , pct_female : Vector Double
        }

adsl_summary adsl <-
    adsl
        |> group_by { arm }
        |> summarize
            { n_subjects = n
            , mean_age   = mean age
            , pct_female = mean (if sex == "F" then 1.0 else 0.0)
            }
        |> arrange { arm }"""
    , r = """adsl_summary <- function(adsl) {
  adsl |>
    dplyr::group_by(arm) |>
    dplyr::summarize(
      n_subjects = dplyr::n(),
      mean_age   = mean(age),
      pct_female = mean(ifelse(sex == "F", 1.0, 0.0))
    ) |>
    dplyr::arrange(arm)
}"""
    }
