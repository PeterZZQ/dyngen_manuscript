% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/theme_common.R
\name{theme_common}
\alias{theme_common}
\title{A common theme for results in this manuscript}
\usage{
theme_common(
  legend.position = "bottom",
  plot.title = element_text(hjust = 0.5),
  plot.subtitle = element_text(hjust = 0.5),
  ...
)
}
\arguments{
\item{legend.position}{the position of legends ("none", "left", "right",
"bottom", "top", or two-element numeric vector)}

\item{plot.title}{plot title (text appearance) (\code{\link[ggplot2:element_text]{element_text()}}; inherits
from \code{title}) left-aligned by default}

\item{plot.subtitle}{plot subtitle (text appearance) (\code{\link[ggplot2:element_text]{element_text()}};
inherits from \code{title}) left-aligned by default}

\item{...}{additional element specifications not part of base ggplot2. In general,
these should also be defined in the \verb{element tree} argument.}
}
\description{
A common theme for results in this manuscript
}
