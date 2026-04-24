module Content.Examples exposing
    ( Snippet
    , heroSnippets
    , normalizeSnippet
    )

import Content.ExampleText exposing (codeBlock)


type alias Snippet =
    { filename : String
    , blurb : String
    , quone : String
    , r : String
    }


heroSnippets : List Snippet
heroSnippets =
    [ meanSnippet
    , rmseSnippet
    , topScoresSnippet
    , scoreBandsSnippet
    , adslSummarySnippet
    , siteRollupSnippet
    ]


normalizeSnippet : Snippet
normalizeSnippet =
    case heroSnippets of
        first :: _ ->
            first

        [] ->
            meanSnippet


meanSnippet : Snippet
meanSnippet =
    { filename = "mean.Q"
    , blurb = "A small function with explicit numeric conversion."
    , quone =
        codeBlock
            """
            mean_score : Vector Double -> Double
            mean_score xs <-
                sum xs / to_double (length xs)
            """
    , r =
        codeBlock
            """
            mean_score <- function(xs) {
              sum(xs) / as.double(length(xs))
            }
            """
    }


rmseSnippet : Snippet
rmseSnippet =
    { filename = "rmse.Q"
    , blurb = "Elementwise functions lift naturally over vectors."
    , quone =
        codeBlock
            """
            rmse : Vector Double -> Vector Double -> Double
            rmse actuals predictions <-
                (predictions - actuals) ^ 2
                    |> mean
                    |> sqrt

            actuals : Vector Double
            actuals <- [2.1, 3.4, 4.0]

            predictions : Vector Double
            predictions <- [2.0, 3.7, 3.8]

            error <- rmse actuals predictions
            """
    , r =
        codeBlock
            """
            rmse <- function(actuals, predictions) {
              (predictions - actuals) ^ 2 |>
                mean() |>
                sqrt()
            }

            actuals <- c(2.1, 3.4, 4)
            predictions <- c(2, 3.7, 3.8)
            error <- rmse(actuals, predictions)
            """
    }


topScoresSnippet : Snippet
topScoresSnippet =
    { filename = "top_scores.Q"
    , blurb = "A dplyr-shaped pipeline with checked column names."
    , quone =
        codeBlock
            """
            type alias Students <-
                dataframe
                    { name  : Vector Character
                    , score : Vector Double
                    }

            top_scores : Students -> Students
            top_scores students <-
                students
                    |> filter (score >= 70)
                    |> arrange { desc score }
                    |> select { name, score }
            """
    , r =
        codeBlock
            """
            top_scores <- function(students) {
              students |>
                dplyr::filter(score >= 70) |>
                dplyr::arrange(dplyr::desc(score)) |>
                dplyr::select(name, score)
            }
            """
    }


scoreBandsSnippet : Snippet
scoreBandsSnippet =
    { filename = "score_bands.Q"
    , blurb = "Vectorized if keeps dataframe transforms readable."
    , quone =
        codeBlock
            """
            risk_band : Double -> Character
            risk_band probability <-
                if probability >= 0.8 then "high"
                else if probability >= 0.5 then "medium"
                else "low"

            type alias Scores <-
                dataframe
                    { subject_id  : Vector Character
                    , probability : Vector Double
                    }

            score_bands : Scores -> Scores
            score_bands scores <-
                scores
                    |> mutate { band = risk_band probability }
                    |> arrange { desc probability }
            """
    , r =
        codeBlock
            """
            risk_band <- function(probability) {
              dplyr::case_when(
                probability >= 0.8 ~ "high",
                probability >= 0.5 ~ "medium",
                .default = "low"
              )
            }

            score_bands <- function(scores) {
              scores |>
                dplyr::mutate(band = risk_band(probability)) |>
                dplyr::arrange(dplyr::desc(probability))
            }
            """
    }


adslSummarySnippet : Snippet
adslSummarySnippet =
    { filename = "adsl_summary.Q"
    , blurb = "Grouped clinical summaries with reducers and vectorized conditions."
    , quone =
        codeBlock
            """
            type alias Adsl <-
                dataframe
                    { subject_id : Vector Character
                    , arm        : Vector Character
                    , age        : Vector Integer
                    , sex        : Vector Character
                    }

            adsl_summary adsl <-
                adsl
                    |> group_by { arm }
                    |> summarize
                        { n_subjects = count subject_id
                        , mean_age   = mean (to_double age)
                        , pct_female = mean (if sex == "F" then 1 else 0)
                        }
                    |> arrange { arm }
            """
    , r =
        codeBlock
            """
            adsl_summary <- function(adsl) {
              adsl |>
                dplyr::group_by(arm) |>
                dplyr::summarize(
                  n_subjects = length(subject_id),
                  mean_age = mean(as.double(age)),
                  pct_female = mean(dplyr::if_else(sex == "F", 1, 0)),
                  .groups = "drop"
                ) |>
                dplyr::arrange(arm)
            }
            """
    }


siteRollupSnippet : Snippet
siteRollupSnippet =
    { filename = "site_rollup.Q"
    , blurb = "A larger pipeline with a typed join, mutation, grouping, and ordered output."
    , quone =
        codeBlock
            """
            discontinued_flag : Character -> Double
            discontinued_flag status <-
                if status == "DISCONTINUED" then 1 else 0

            type alias Subjects <-
                dataframe
                    { subject_id : Vector Character
                    , site_id    : Vector Character
                    , arm        : Vector Character
                    , status     : Vector Character
                    , response   : Vector Double
                    }

            type alias Sites <-
                dataframe
                    { id     : Vector Character
                    , region : Vector Character
                    }

            site_rollup subjects sites <-
                subjects
                    |> left_join sites { site_id = id }
                    |> mutate { discontinued = discontinued_flag status }
                    |> group_by { region, arm }
                    |> summarize
                        { n_subjects       = count subject_id
                        , mean_response    = mean response
                        , pct_discontinued = mean discontinued
                        }
                    |> arrange { region, arm }
            """
    , r =
        codeBlock
            """
            discontinued_flag <- function(status) {
              dplyr::if_else(status == "DISCONTINUED", 1, 0)
            }

            site_rollup <- function(subjects, sites) {
              subjects |>
                dplyr::left_join(sites, by = c("site_id" = "id")) |>
                dplyr::mutate(discontinued = discontinued_flag(status)) |>
                dplyr::group_by(region, arm) |>
                dplyr::summarize(
                  n_subjects = length(subject_id),
                  mean_response = mean(response),
                  pct_discontinued = mean(discontinued),
                  .groups = "drop"
                ) |>
                dplyr::arrange(region, arm)
            }
            """
    }

