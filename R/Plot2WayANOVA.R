#' Plot a 2 Way ANOVA using dplyr and ggplot2
#'
#' Takes a formula and a dataframe as input, conducts an analysis of variance
#' prints the results (AOV summary table, table of overall model information
#' and table of means) then uses ggplot2 to plot an interaction graph (line
#' or bar) .  Also uses Brown-Forsythe test for homogeneity of
#' variance.  Users can also choose to save the plot out as a png file.
#'
#' Details about how the function works in order of steps taken.
#' \enumerate{
#' \item Some basic error checking to ensure a valid formula and dataframe.
#'   Only accepts fully *crossed* formula to check for interaction term
#' \item Ensure the dependent (outcome) variable is numeric and that the two
#'   independent (predictor) variables are or can be coerced to factors -- user
#'   warned on the console
#' \item Remove missing cases -- user warned on the console
#' \item Calculate a summarized table of means, sds, standard errors of the
#'    means, confidence intervals, and group sizes.
#' \item Use \code{\link[stats]{aov}} function to execute an Analysis of
#'   Variance (ANOVA)
#' \item Use \code{sjstats::anova_stats} to calculate eta squared
#'   and omega squared values per factor. If the design is unbalanced warn
#'   the user and use Type II sums of squares
#' \item Produce a standard ANOVA table with additional columns
#' \item Use the \code{\link[DescTools]{PostHocTest}} for producing a table
#'   of post hoc comparisons for all effects that were significant
#' \item Testing Homogeneity
#'   of Variance assumption with Brown-Forsythe test
#' \item Use the \code{\link[DescTools]{PostHocTest}} for conducting
#'   post hoc tests for effects that were significant
#' \item Use the \code{\link[stats]{shapiro.test}} for testing normality
#'   assumption with Shapiro-Wilk
#' \item Use \code{ggplot2} to plot an interaction plot of the type the
#'   user specified.}
#' The defaults are deliberately constructed to emphasize the nature
#'   of the interaction rather than focusing on distributions. So
#'   while a violin plot of the first factor by level is displayed
#'   along with dots for individual data points shaded by the second
#'   factor, the emphasis is on the interaction lines.
#'
#' @usage Plot2WayANOVA(formula,
#'                dataframe = NULL,
#'                confidence=.95,
#'                plottype = "line",
#'                errorbar.display = "CI",
#'                xlab = NULL,
#'                ylab = NULL,
#'                title = NULL,
#'                subtitle = NULL,
#'                interact.line.size = 2,
#'                ci.line.size = 1,
#'                mean.label = FALSE,
#'                mean.ci = TRUE,
#'                mean.size = 4,
#'                mean.shape = 23,
#'                mean.color = "darkred",
#'                mean.label.size = 3,
#'                mean.label.color = "black",
#'                offset.style = "none",
#'                overlay.type = NULL,
#'                posthoc.method = "scheffe",
#'                show.dots = FALSE,
#'                PlotSave = FALSE,
#'                ggtheme = ggplot2::theme_bw(),
#'                package = "RColorBrewer",
#'                palette = "Dark2",
#'                ggplot.component = NULL)
#' @param formula a formula with a numeric dependent (outcome) variable,
#'   and two independent (predictor) variables e.g. \code{mpg ~ am * vs}.
#'   The independent variables are coerced to factors (with warning) if
#'   possible.
#' @param dataframe a dataframe or an object that can be coerced to a dataframe
#' @param confidence what confidence level for confidence intervals
#' @param plottype bar or line (quoted)
#' @param errorbar.display default "CI" (confidence interval), which type of
#'   errorbar should be displayed around the mean point? Other options
#'   include "SEM" (standard error of the mean) and "SD" (standard dev).
#'   "none" removes it entirely much like \code{\link[stats]{interaction.plot}}
#' @param PlotSave a logical indicating whether the user wants to save the plot
#'  as a png file
#' @param xlab,ylab Labels for `x` and `y` axis variables. If `NULL` (default),
#'   variable names for `x` and `y` will be used.
#' @param title The text for the plot title. A generic default is provided.
#' @param subtitle The text for the plot subtitle. If `NULL` (default), key
#'   model information is provided as a subtitle.
#' @param interact.line.size Line size for the line connecting the group means
#'   (Default: `2`).
#' @param ci.line.size Line size for the confidence interval bracketing
#'   the group means (Default: `1`).
#' @param mean.label Logical that decides whether the value of the group
#'   mean is to be displayed (Default: `FALSE`).
#' @param mean.ci Logical that decides whether the confidence interval for
#'   group means is to be displayed (Default: `TRUE`).
#' @param mean.color Color for the data point corresponding to mean (Default:
#'   `"darkred"`).
#' @param mean.label.size,mean.label.color Aesthetics for
#' the label displaying mean. Defaults: `3`, `"black"`, respectively.
#' @param mean.size Point size for the data point corresponding to mean
#'   (Default: `4`).
#' @param mean.shape Shape of the plot symbol for the mean
#'   (Default: `23` which is a diamond).
#' @param offset.style A character string (e.g., `"wide"` or `"narrow"`,
#'   or `"none"`) which controls whether items are offset from the
#'   centerline for clarity. Useful when you want to add individual
#'   datapoints or confdence interval lines overlap. (Default: `"none"`).
#' @param overlay.type A character string (e.g., `"box"` or `"violin"`),
#'   if you wish to overlay that information on factor1
#' @param posthoc.method A character string, one of "hsd", "bonf", "lsd",
#'   "scheffe", "newmankeuls", defining the method for the pairwise comparisons.
#'   (Default: `"scheffe"`).
#' @param show.dots Logical that decides whether the individual data points
#'   are displayed (Default: `FALSE`).
#' @param package Name of package from which the palette is desired as string
#'   or symbol.
#' @param palette Name of palette as string or symbol.
#' @param ggtheme A function, ggplot2 theme name. Default value is ggplot2::theme_bw().
#'   Any of the ggplot2 themes, or themes from extension packages are allowed (e.g.,
#'   hrbrthemes::theme_ipsum(), etc.).
#' @param ggplot.component A ggplot component to be added to the plot prepared.
#'   The default is NULL. The argument should be entered as a function.
#'   for example to change the size and color of the x axis text you use:
#'   `ggplot.component = theme(axis.text.x = element_text(size=13, color="darkred"))`
#'   depending on what theme is in use the ggplot component might not work as expected.
#' @return A list with 5 elements which is returned invisibly. These items
#'   are always sent to the console for display but for user convenience
#'   the function also returns a named list with the following items
#'   in case the user desires to save them or further process them -
#'   \code{$ANOVATable}, \code{$ModelSummary}, \code{$MeansTable},
#'   \code{$PosthocTable}, \code{$BFTest}, and \code{$SWTest}.
#'   The plot is always sent to the default plot device
#'
#' @references: ANOVA: Delacre, Leys, Mora, & Lakens, *PsyArXiv*, 2018
#'
#' @author Chuck Powell
#' @seealso \code{\link[stats]{aov}}, \code{\link{BrownForsytheTest}},
#' \code{sjstats::anova_stats}, \code{\link[stats]{replications}},
#' \code{\link[stats]{shapiro.test}}, \code{\link[stats]{interaction.plot}}
#' @examples
#'
#' Plot2WayANOVA(mpg ~ am * cyl, mtcars, plottype = "line")
#' Plot2WayANOVA(mpg ~ am * cyl,
#'   mtcars,
#'   plottype = "line",
#'   overlay.type = "box",
#'   mean.label = TRUE
#' )
#' 
#' library(ggplot2)
#' Plot2WayANOVA(mpg ~ am * vs, 
#'   mtcars, 
#'   confidence = .99,
#'   ggplot.component = theme(axis.text.x = element_text(size=13, color="darkred")))
#'   
#' @import ggplot2
#' @import rlang
#' @importFrom methods is
#' @importFrom stats anova aov lm pf qt replications sd symnum residuals shapiro.test AIC BIC
#' @importFrom dplyr as_tibble case_when group_by summarise %>% n select filter
#' @importFrom sjstats anova_stats
#' @importFrom DescTools PostHocTest
#' @importFrom BayesFactor anovaBF
#' @importFrom tidyr complete
#' @export
#'
Plot2WayANOVA <- function(formula,
                          dataframe = NULL,
                          confidence = .95,
                          plottype = "line",
                          errorbar.display = "CI",
                          xlab = NULL,
                          ylab = NULL,
                          title = NULL,
                          subtitle = NULL,
                          interact.line.size = 2,
                          ci.line.size = 1,
                          mean.label = FALSE,
                          mean.ci = TRUE,
                          mean.size = 4,
                          mean.shape = 23,
                          mean.color = "darkred",
                          mean.label.size = 3,
                          mean.label.color = "black",
                          offset.style = "none",
                          overlay.type = NULL,
                          posthoc.method = "scheffe",
                          show.dots = FALSE,
                          PlotSave = FALSE,
                          ggtheme = ggplot2::theme_bw(),
                          package = "RColorBrewer",
                          palette = "Dark2",
                          ggplot.component = NULL) {

  # -------- error checking ----------------
  # set default theme 
  ggplot2::theme_set(ggtheme)
  
  if (length(match.call()) - 1 <= 1) {
    stop("Not enough arguments passed...
         requires at least a formula with a DV and 2 IV plus a dataframe")
  }
  if (missing(formula)) {
    stop("\"formula\" argument is missing, with no default")
  }
  if (!is(formula, "formula")) {
    stop("\"formula\" argument must be a formula")
  }
  if (length(formula) != 3) {
    stop("invalid value for \"formula\" argument")
  }
  vars <- all.vars(formula)
  chkinter <- all.names(formula)
  if (length(vars) != 3) {
    stop("invalid value for \"formula\" argument")
  }
  if ("+" %in% chkinter) {
    stop("Sorry you need to use an asterisk not a plus sign in 
         the formula so the interaction can be plotted")
  }
  if ("~" == chkinter[2]) {
    stop("Sorry you can only have one dependent variable so only 
         one tilde is allowed ~ you have two or more")
  }

  # we can trust the basics grab the variable names from formula
  # these are now of ***class character***
  depvar <- vars[1]
  iv1 <- vars[2]
  iv2 <- vars[3]

  # create a filename in case they want to save png
  potentialfname <- paste0(depvar, "by", iv1, "and", iv2, ".png")

  if (missing(dataframe)) {
    stop("You didn't specify a data frame to use")
  }
  if (!exists(deparse(substitute(dataframe)))) {
    stop("That dataframe does not exist\n")
  }
  if (!is(dataframe, "data.frame")) {
    stop("The dataframe name you specified is not valid\n")
  }
  if (!(depvar %in% names(dataframe))) {
    stop(paste0(
      "'", depvar, "' is not the name of a variable in '",
      deparse(substitute(dataframe)), "'"
    ))
  }
  if (!(iv1 %in% names(dataframe))) {
    stop(paste0(
      "'", iv1, "' is not the name of a variable in '",
      deparse(substitute(dataframe)), "'"
    ))
  }
  if (!(iv2 %in% names(dataframe))) {
    stop(paste0(
      "'", iv2, "' is not the name of a variable in '",
      deparse(substitute(dataframe)), "'"
    ))
  }

  # force it to a data frame
  dataframe <- dataframe[, c(depvar, iv1, iv2)]

  # -------- x & y axis labels ----------------------------

  # if `xlab` is not provided, use the variable `x` name
  if (is.null(xlab)) {
    xlab <- iv1
  }

  # if `ylab` is not provided, use the variable `y` name
  if (is.null(ylab)) {
    ylab <- depvar
  }

  # -------- check variable types ----------------

  dataframe <- as.data.frame(dataframe)
  if (!is(dataframe[, depvar], "numeric")) {
    stop("dependent variable must be numeric")
  }
  if (!is(dataframe[, iv1], "factor")) {
    message(paste0("\nConverting ", iv1, " to a factor --- check your results"))
    dataframe[, iv1] <- as.factor(dataframe[, iv1])
  }
  if (!is(dataframe[, iv2], "factor")) {
    message(paste0("\nConverting ", iv2, " to a factor --- check your results"))
    dataframe[, iv2] <- as.factor(dataframe[, iv2])
  }

  # grab the names of the factor levels
  factor1.names <- levels(dataframe[, iv1])
  factor2.names <- levels(dataframe[, iv2])

  if (!is(confidence, "numeric") | length(confidence) != 1 |
    confidence < .5 | confidence > .9991) {
    stop("\"confidence\" must be a number between .5 and 1")
  }
  if (plottype != "bar") {
    plottype <- "line"
  }

  # -------- Remove missing cases notify user ----------------

  missing <- apply(is.na(dataframe), 1, any)
  if (any(missing)) {
    warning(paste(sum(missing)), " case(s) removed because of missing data")
  }
  dataframe <- dataframe[!missing, ]
  
  # -------- Check cell counts ----------------
  
  checkcells <- 
    dataframe %>%
    group_by(!!sym(iv1), !!sym(iv2)) %>%
    summarize(count = n()) %>%
    ungroup() %>%
    complete(!!sym(iv1), !!sym(iv2), fill = list(count = 0))
  
  if (any(checkcells$count == 0)) {
    print(checkcells)
    stop(paste0(
      "\n--- MAJOR Problem! ---\n",
      "You have one or more cells with ZERO observations.\n"
    ))
  } else if (any(checkcells$count <= 2)){
    message(paste0(
      "\n\t\t\t\t--- WARNING! ---\n",
      "\t\tYou have one or more cells with less than 3 observations.\n"
    ))
    print(checkcells)
  }
  
  # -------- Build summary dataframe ----------------

  newdata <- dataframe %>%
    group_by(!!sym(iv1), !!sym(iv2)) %>%
    summarise(
      TheMean = mean(!!sym(depvar), na.rm = TRUE),
      TheSD = sd(!!sym(depvar), na.rm = TRUE),
      TheSEM = sd(!!sym(depvar), na.rm = TRUE) / sqrt(n()),
      CIMuliplier = qt(confidence / 2 + .5, n() - 1),
      LowerBoundCI = TheMean - TheSEM * CIMuliplier,
      UpperBoundCI = TheMean + TheSEM * CIMuliplier,
      LowerBoundSEM = TheMean - TheSEM,
      UpperBoundSEM = TheMean + TheSEM,
      LowerBoundSD = TheMean - TheSD,
      UpperBoundSD = TheMean + TheSD,
      N = n()
    ) %>%
    mutate(
      LowerBound = case_when(
        errorbar.display == "SD" ~ LowerBoundSD,
        errorbar.display == "SEM" ~ LowerBoundSEM,
        errorbar.display == "CI" ~ LowerBoundCI,
        TRUE ~ LowerBoundCI),
      UpperBound = case_when(
        errorbar.display == "SD" ~ UpperBoundSD,
        errorbar.display == "SEM" ~ UpperBoundSEM,
        errorbar.display == "CI" ~ UpperBoundCI,
        TRUE ~ UpperBoundCI)
    )
  
  # -------- Run tests and procedures ----------------

  # run analysis of variance
  MyAOV <- aov(formula, dataframe)
  # force to Type 2 sums of squares
  MyAOVt2 <- aovtype2(MyAOV)
  # get more detailed information including effect sizes
  WithETA <- sjstats::anova_stats(MyAOVt2)
  # Run Brown-Forsythe
  BFTest <- BrownForsytheTest(formula, dataframe)
  # Grab the residuals and run Shapiro-Wilk
  MyAOV_residuals <- residuals(object = MyAOV)
  if (nrow(dataframe) < 5000){
    SWTest <- shapiro.test(x = MyAOV_residuals) # run Shapiro-Wilk test
  } else {
    SWTest <- NULL
  }

  # Grab the effects that were significant in omnibuds test
  sigfactors <- filter(WithETA, p.value <= 1 - confidence) %>% select(term)
  if (nrow(sigfactors) > 0) {
    posthocresults <- PostHocTest(MyAOV,
      method = posthoc.method,
      conf.level = confidence,
      which = as.character(sigfactors[, 1])
    )
  } else {
    posthocresults <- "No signfiicant effects"
  }
  
  bf_models <- BayesFactor::anovaBF(formula = formula, 
                                    data = dataframe, 
                                    progress = FALSE)
  bf_models <- 
    as_tibble(bf_models, rownames = "model") %>%
    select(model:error) %>% 
    arrange(desc(bf)) %>%
    mutate(support = bf_display(bf = bf, display_type = "support")) %>%
    mutate(margin_of_error = error) %>%
    select(-error)
  
  # return(bf_models)

  # -------- save the common plot items as a list to be used ---------

  # Make a default title
  cipercent <- round(confidence * 100, 2)
  # if `title` is not provided, use this generic
  if (is.null(title)) {
    title <- paste("Interaction plot ", deparse(formula, width.cutoff = 80), collapse="")
    if (errorbar.display == "CI") {
      title <- bquote(.(title) * " with" ~ .(cipercent) * "% conf ints")
    } else if (errorbar.display == "SEM") {
      title <- bquote(.(title) * " with standard error of the mean")
    } else if (errorbar.display == "SD") {
      title <- bquote(.(title) * " with standard deviations")
    } else {
      title <- title
    }
  }
  

  # make pretty labels
  AICnumber <- round(stats::AIC(MyAOV), 1)
  BICnumber <- round(stats::BIC(MyAOV), 1)
  eta2iv1 <- WithETA[1, 7]
  eta2iv2 <- WithETA[2, 7]
  eta2interaction <- WithETA[3, 7]
  

  # if `subtitle` is not provided, use this generic
  if (is.null(subtitle)) {
    subtitle <- bquote(
       eta^2 * " (" * .(iv1) *  ") =" ~ .(eta2iv1) * 
       ", " * eta^2 * " (" * .(iv2) *  ") =" ~ .(eta2iv2) * 
       ", " * eta^2 * " (interaction) =" ~ .(eta2interaction) * 
         ", AIC =" ~ .(AICnumber) * ", BIC =" ~ .(BICnumber)
#      "AIC =" ~ .(AICnumber) * ", BIC =" ~ .(BICnumber)
    )
  }

  # decide how much to offset things
  if (offset.style == "wide") {
    dot.dodge <- .4
    ci.dodge <- .15
    mean.dodge <- .15
  }
  if (offset.style == "narrow") {
    dot.dodge <- .1
    ci.dodge <- .05
    mean.dodge <- .05
  }
  if (offset.style != "narrow" && offset.style != "wide") {
    dot.dodge <- 0
    ci.dodge <- 0
    mean.dodge <- 0
  }


  commonstuff <- list(
    xlab(xlab),
    ylab(ylab),
    scale_colour_hue(l = 40),
    ggtitle(title, subtitle = subtitle),
    theme(panel.grid.major.x = element_blank())
  )

  # -------- start the plot ---------

  p <- newdata %>%
    ggplot(aes_string(
      x = iv1,
      y = "TheMean",
      colour = iv2,
      fill = iv2,
      group = iv2
    )) +
    commonstuff

  # -------- display individual dots ---------

  if (plottype == "line" && show.dots == TRUE) {
    p <- p +
      geom_point(
        data = dataframe,
        mapping = aes(
          x = !!sym(iv1),
          y = !!sym(depvar),
          shape = !!sym(iv2)
        ),
        alpha = .4,
        position = position_dodge(dot.dodge),
        show.legend = TRUE
      )
  }

  # -------- switch for bar versus line plot ---------

  if (errorbar.display != "none") {
    switch(plottype,
           bar =
             p <- p +
             geom_bar(
               stat = "identity",
               position = "dodge"
             ) +
             geom_errorbar(aes(ymin = LowerBound, ymax = UpperBound),
                           width = .5,
                           size = ci.line.size,
                           position = position_dodge(0.9),
                           show.legend = FALSE
             ),
           line =
             p <- p +
             geom_errorbar(aes(
               ymin = LowerBound,
               ymax = UpperBound
             ),
             width = .2,
             size = ci.line.size,
             position = position_dodge(ci.dodge)
             ) +
             geom_line(
               aes_string(linetype = iv2),
               size = interact.line.size,
               position = position_dodge(mean.dodge)
             ) +
             geom_point(aes(y = TheMean),
                        shape = mean.shape,
                        size = mean.size,
                        color = mean.color,
                        alpha = 1,
                        position = position_dodge(mean.dodge)
             )
    )
  } else {
    switch(plottype,
           bar =
             p <- p +
             geom_bar(
               stat = "identity",
               position = "dodge"
             ),
           line =
             p <- p +
             geom_line(
               aes_string(linetype = iv2),
               size = interact.line.size,
               position = position_dodge(mean.dodge)
             ) +
             geom_point(aes(y = TheMean),
                        shape = mean.shape,
                        size = mean.size,
                        color = mean.color,
                        alpha = 1,
                        position = position_dodge(mean.dodge)
             )
    )
  }
  
  # -------- Add box or violin if needed ---------

  if (!is.null(overlay.type)) {
    if (plottype == "line" && overlay.type == "box") {
      p <- p +
        geom_boxplot(
          data = dataframe,
          mapping = aes(
            x = !!sym(iv1),
            y = !!sym(depvar),
            group = !!sym(iv1)
          ),
          color = "gray",
          width = 0.4,
          alpha = 0.2,
          fill = "white",
          outlier.shape = NA,
          show.legend = FALSE
        )
    } else if (plottype == "line" && overlay.type == "violin") {
      p <- p +
        geom_violin(
          data = dataframe,
          mapping = aes(
            x = !!sym(iv1),
            y = !!sym(depvar),
            group = !!sym(iv1)
          ),
          color = "gray",
          width = 0.7,
          alpha = 0.2,
          fill = "white",
          show.legend = FALSE
        )
    }
  }

  # -------- Add mean labels if needed ---------

  if (isTRUE(mean.label && plottype == "line")) {
    p <- p +
      ggrepel::geom_label_repel(
        data = newdata,
        mapping = aes(
          x = !!sym(iv1),
          y = TheMean,
          label = as.character(round(TheMean, 2))
        ),
        size = mean.label.size,
        color = mean.label.color,
        fontface = "bold",
        alpha = .8,
        direction = "both",
        nudge_x = -.2,
        max.iter = 3e2,
        box.padding = 0.35,
        point.padding = 0.5,
        segment.color = "black",
        force = 2,
        inherit.aes = FALSE,
        seed = 123
      )
  }

  if (isTRUE(mean.label && plottype == "bar")) {
    p <- p +
      ggrepel::geom_label_repel(
        data = newdata,
        mapping = aes(
          x = !!sym(iv1),
          y = TheMean,
          label = as.character(round(TheMean, 2))
        ),
        size = mean.label.size,
        color = mean.label.color,
        fontface = "bold",
        alpha = .8,
        direction = "both",
        max.iter = 3e2,
        box.padding = 0.35,
        point.padding = 0.5,
        segment.color = "black",
        force = 2,
        position = position_dodge(0.9),
        inherit.aes = TRUE,
        show.legend = FALSE,
        seed = 123
      )
  }

  # -------- Warn user of unbalanced design ----------------
  
  if (!all(checkcells$count == checkcells$count[1])) {
    rsquaredx <- round(1 - (MyAOVt2$`Sum Sq`[4] / sum(MyAOVt2$`Sum Sq`[1:4])), 3)
    message(paste0(
      "\n\t\t\t\t--- WARNING! ---\n",
      "\t\tYou have an unbalanced design. Using Type II sum of 
            squares, to calculate factor effect sizes eta and omega.
            Your two factors account for ", rsquaredx, " of the type II sum of 
            squares.\n"
    ))
  }
  else {
    message("\nYou have a balanced design. \n")
  }
  
#  return(checkcells)
  print(WithETA)

  # -------- Print tests and tables ----------------

  # message("\nMeasures of overall model fit\n")
  # print(model_summary)
  message("\nTable of group means\n")
  print(newdata)
  message("\nPost hoc tests for all effects that were significant\n")
  print(posthocresults)
  message("\nTesting Homogeneity of Variance with Brown-Forsythe \n")
  if (BFTest$`Pr(>F)`[[1]] <= .05) {
    message("   *** Possible violation of the assumption ***")
  }
  print(BFTest)
  if(!is.null(SWTest)) {
    message("\nTesting Normality Assumption with Shapiro-Wilk \n")
    if (SWTest$p.value <= .05) {
      message("   *** Possible violation of the assumption.  You may 
            want to plot the residuals to see how they vary from normal ***")
    }
    print(SWTest)
  }
  message("\nBayesian analysis of models in order\n")
  print(bf_models)
  
  # -------- adding optional ggplot.component ----------
  p <- p + ggplot.component
  
  # -------- Print the plot itself ----------------
  
  message("\nInteraction graph plotted...")
  print(p)


  # -------- Return stuff to user ----------------

  whattoreturn <- list(
    ANOVATable = WithETA,
    # ModelSummary = model_summary,
    MeansTable = newdata,
    PosthocTable = posthocresults,
    BFTest = BFTest,
    SWTest = SWTest,
    Bayesian_models = bf_models
  )
  if (PlotSave) {
    ggsave(potentialfname, device = "png")
    whattoreturn[["plotfile"]] <- potentialfname
  }
  return(invisible(whattoreturn))
}
