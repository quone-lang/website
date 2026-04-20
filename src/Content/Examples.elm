module Content.Examples exposing
    ( Example
    , Snippet
    , hero
    , script
    , dataframe
    , decoder
    , packageModule
    , normalizeSnippet
    , meanSnippet
    , rmseSnippet
    , topScoresSnippet
    , adslSummarySnippet
    , heroSnippets
    )

{-| The Quone code samples shown on the marketing site. Each example
includes a title, a one-line description, and a side-by-side Quone /
generated R pair so visitors can see exactly what they'd write and what
they'd ship.

The R column is what the v0.0.1 compiler is specified to produce per
LANGUAGE.md sections 13 and 14 - it is not a hand-stylised
approximation.

-}


type alias Example =
    { title : String
    , blurb : String
    , quone : String
    , r : String
    }


{-| A short Quone snippet shown in the hero "try it" tabs. Each one has a
realistic filename and a small Quone program plus the R the compiler
would emit when you call `quone::compile()` on it.
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



-- HERO: shortest possible "Quone in, R out" demonstration


hero : Example
hero =
    { title = "Quone, compiled to R"
    , blurb =
        "A typed function and the R it produces."
    , quone = """normalize : Double -> Double -> Double
normalize max_score raw <-
    raw / max_score"""
    , r = """normalize <- function(max_score, raw) {
  raw / max_score
}"""
    }



-- A SCRIPT: end-to-end main program


script : Example
script =
    { title = "A small script"
    , blurb =
        "No module header, no project file - just compile and run with R."
    , quone = """#' Demonstrate score normalisation.

normalize : Double -> Double -> Double
normalize max_score raw <-
    raw / max_score

scores : Vector Double
scores <-
    [ 92.0, 88.5, 71.0, 64.0 ]

main <-
    scores
        |> map (normalize 100.0)
        |> mean"""
    , r = """#' Demonstrate score normalisation.

normalize <- function(max_score, raw) {
  raw / max_score
}

scores <- c(92.0, 88.5, 71.0, 64.0)

main <- mean(purrr::map_dbl(scores, function(s) normalize(100.0, s)))"""
    }



-- A DATAFRAME PIPELINE: shows native verbs with column-name sugar


dataframe : Example
dataframe =
    { title = "Native dataframe verbs"
    , blurb =
        "Type-checked column references and idiomatic dplyr output."
    , quone = """type alias Students <-
    dataframe
        { name  : Vector Character
        , dept  : Vector Character
        , score : Vector Double
        }

top_by_dept : Students -> dataframe { dept : Vector Character, avg : Vector Double }
top_by_dept students <-
    students
        |> filter (score > 70.0)
        |> group_by { dept }
        |> summarize { avg = mean score }
        |> arrange { desc avg }"""
    , r = """top_by_dept <- function(students) {
  students |>
    dplyr::filter(score > 70.0) |>
    dplyr::group_by(dept) |>
    dplyr::summarize(avg = mean(score)) |>
    dplyr::arrange(dplyr::desc(avg))
}"""
    }



-- A CSV DECODER: shows fail-fast script style


decoder : Example
decoder =
    { title = "Typed CSV decoders"
    , blurb =
        "Decoders describe the schema; the compiler refuses to ship code that lies about its data."
    , quone = """import readr.read_csv : Character -> dataframe { name : Vector Character }

type alias Adsl <-
    dataframe
        { subject_id : Vector Character
        , treatment  : Vector Character
        , age        : Vector Integer
        }

adsl_decoder <-
    Csv.dataframe
        |> Csv.column "USUBJID" character
        |> Csv.column "TRTA" character
        |> Csv.optional_column "AGE" integer 0

main <-
    Csv.read_dataframe adsl_decoder "adsl.csv"
        |> Script.expect"""
    , r = """main <- (function() {
  result <- tryCatch(
    {
      raw <- readr::read_csv("adsl.csv", show_col_types = FALSE)
      list(
        subject_id = as.character(raw$USUBJID),
        treatment  = as.character(raw$TRTA),
        age        = ifelse(is.na(raw$AGE), 0L, as.integer(raw$AGE))
      )
    },
    error = function(e) stop(paste("Could not load adsl.csv:", conditionMessage(e)))
  )
  result
})()"""
    }



-- A PACKAGE MODULE: shows roxygen-driven exports


packageModule : Example
packageModule =
    { title = "Compile a project to an R package"
    , blurb =
        "Module headers and @export tags become a clean DESCRIPTION and NAMESPACE - generated by roxygen2 from the same doc blocks."
    , quone = """module Stats.Transform exporting (normalize, rmse)

#' Compute a normalised score in the range [0, 1].
#'
#' @param max_score The maximum possible score.
#' @param raw The raw value.
#' @export
normalize : Double -> Double -> Double
normalize max_score raw <-
    raw / max_score

#' Root-mean-squared error.
#' @export
rmse : Vector Double -> Vector Double -> Double
rmse predictions actuals <-
    predictions
        |> map2 (\\p a -> (p - a) ^ 2.0) actuals
        |> mean
        |> sqrt"""
    , r = """#' Compute a normalised score in the range [0, 1].
#'
#' @param max_score The maximum possible score.
#' @param raw The raw value.
#' @export
normalize <- function(max_score, raw) {
  raw / max_score
}

#' Root-mean-squared error.
#' @export
rmse <- function(predictions, actuals) {
  sqrt(
    mean(
      purrr::map2_dbl(predictions, actuals, function(p, a) (p - a) ^ 2.0)
    )
  )
}"""
    }
