% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datasets.R
\docType{data}
\name{nutrition}
\alias{nutrition}
\title{Nutrition data}
\format{A data frame with 107 observations and 4 variables:
\describe{
  \item{\code{age}}{a factor with levels \code{1}, \code{2}, \code{3},
    \code{4}. Mother's age group.}
  \item{\code{group}}{a factor with levels \code{FoodStamps}, \code{NoAid}.
    Whether or not the family receives food stamp assistance.}
  \item{\code{race}}{a factor with levels \code{Black}, \code{Hispanic},
    \code{White}. Mother's race.}
  \item{\code{gain}}{a numeric vector (the response variable). Gain score
    (posttest minus pretest) on knowledge of nutrition.}
}}
\source{
Milliken, G. A. and Johnson, D. E. (1984)
\emph{Analysis of Messy Data -- Volume I: Designed Experiments}. 
Van Nostrand, ISBN 0-534-02713-7.
}
\usage{
nutrition
}
\description{
This observational dataset involves three factors, but where several factor 
combinations are missing. It is used as a case study in Milliken and Johnson,
Chapter 17, p.202. (You may also find it in the second edition, p.278.)
}
\details{
A survey was conducted by home economists ``to study how much
lower-socioeconomic-level mothers knew about nutrition and to judge the
effect of a training program designed to increase their knowledge of
nutrition.'' This is a messy dataset with several empty cells.
}
\examples{
nutr.aov <- aov(gain ~ (group + age + race)^2, data = nutrition)

# Summarize predictions for age group 3
nutr.emmGrid <- emmeans(nutr.aov, ~ race * group, at = list(age="3"))
                   
emmip(nutr.emmGrid, race ~ group)

# Hispanics seem exceptional; but this doesn't test out due to very sparse data
cld(nutr.emmGrid, by = "group")
cld(nutr.emmGrid, by = "race")
}
\keyword{datasets}
