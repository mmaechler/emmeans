##############################################################################
#    Copyright (c) 2012-2017 Russell V. Lenth                                #
#                                                                            #
#    This file is part of the emmeans package for R (*emmeans*)              #
#                                                                            #
#    *emmeans* is free software: you can redistribute it and/or modify       #
#    it under the terms of the GNU General Public License as published by    #
#    the Free Software Foundation, either version 2 of the License, or       #
#    (at your option) any later version.                                     #
#                                                                            #
#    *emmeans* is distributed in the hope that it will be useful,            #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of          #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
#    GNU General Public License for more details.                            #
#                                                                            #
#    You should have received a copy of the GNU General Public License       #
#    along with R and *emmeans*.  If not, see                                #
#    <https://www.r-project.org/Licenses/> and/or                            #
#    <http://www.gnu.org/licenses/>.                                         #
##############################################################################


### =========== Various methods for emmGrid class =============================
# (note: some major ones have their own file)



### S4 show method
## use S3 for this setMethod("summary", "emmGrid", summary.emmGrid)
setMethod("show", "emmGrid", function(object) {
    isnewrg = object@misc$is.new.rg
    if (is.null(isnewrg)) 
        isnewrg = FALSE
    
    if (isnewrg)
        str.emmGrid(object)
    else
        print(summary.emmGrid(object))
})


### Others are all S3 methods

#' @rdname emmGrid-methods
#' @method str emmGrid
#' @export
str.emmGrid <- function(object, ...) {
    showlevs = function(x) { # internal convenience function
        if (is.null(x)) cat("(predicted by other variables)")
        else cat(paste(format(x, digits = 5, justify = "none"), collapse=", "))
    }
    showtran = function(tran, label) { # internal convenience fcn
        if (is.list(tran)) 
            tran = ifelse(is.null(tran$name), "custom", tran$name)
        if (!is.null(mul <- object@misc$tran.mult))
            tran = paste0(mul, "*", tran)
        cat(paste(label, dQuote(tran), "\n"))
        
    }
    levs = object@levels
    cat(paste("'", class(object)[1], "' object with variables:\n", sep=""))
    for (nm in union(object@roles$predictors, union(object@roles$multresp, object@roles$responses))) {
        cat(paste("    ", nm, " = ", sep = ""))
        if (hasName(object@matlevs, nm)) {
            if (nm %in% object@roles$responses)
                cat("multivariate response with means: ")
            else
                cat("matrix with column means: ")
            cat("\n        ")
            showlevs(object@matlevs[[nm]])
        }
        else if (nm %in% object@roles$multresp) {
            cat("multivariate response levels: ")
            showlevs(levs[[nm]])
        }
        else if (nm %in% object@roles$responses) {
            cat("response variable with mean ")
            showlevs(levs[[nm]])
        }
        else
            showlevs(levs[[nm]])
        cat("\n")
    }
    if(!is.null(object@model.info$nesting)) {
        cat("Nesting structure:  ")
        cat(.fmt.nest(object@model.info$nesting))
        cat("\n")
    }
    if(!is.null(tran <- object@misc$tran)) {
        showtran(tran, "Transformation:")
        if (!is.null(tran2 <- object@misc$tran2))
            showtran(tran2, "Additional response transformation:")
    }
}


#' @rdname emmGrid-methods
#' @method print emmGrid
#' @param x An \code{emmGrid} object
#' @export
print.emmGrid = function(x,...)
    print(summary.emmGrid(x, ...))


# vcov method
#' Miscellaneous methods for \code{emmGrid} objects
#' @rdname emmGrid-methods
#' 
#' @param object An \code{emmGrid} object
#' @param ... (required but not used)
#' 
#' @return The \code{vcov} method returns a ymmetric matrix of variances and
#'   covariances for \code{predict.emmGrid(object, type = "lp")}
#'
#' @method vcov emmGrid
#' @export
vcov.emmGrid = function(object, ...) {
    tol = get_emm_option("estble.tol")
    if (!is.null(hook <- object@misc$vcovHook)) {
        if (is.character(hook)) 
            hook = get(hook)
        hook(object, tol = tol, ...)
    }
    else {
        X = object@linfct
        estble = estimability::is.estble(X, object@nbasis, tol) 
        X[!estble, ] = NA
        X = X[, !is.na(object@bhat), drop = FALSE]
        X %*% tcrossprod(object@V, X)
    }
}


# Method to alter contents of misc slot

#' Set or retrieve options for objects and summaries
#' 
#' Objects of class \code{emmGrid} contain several settings that affect primarily 
#' the defaults used by \code{\link{summary.emmGrid}}. This \code{update} method allows
#' them to be changed more safely than by modifying this slot directly.
#' In addition, the user may set or retrieve defaults for these settings.
#'
#' @param object An \code{emmGrid} object
#' @param ... Options to be set. These must match a list of known options (see
#'   Details)
#' @param silent Logical value. If \code{FALSE} (the default), a message is
#'   displayed if any options are not matched. If \code{TRUE}, no messages are
#'   shown.
#'
#' @return \code{update.emmGrid} returns an updated \code{emmGrid} object.
#' @method update emmGrid
#' @export
#' 
#' @section Details for \code{update.emmGrid}:
#' In \code{update}, the names in \code{\dots} are partially matched against those that are valid, and if a match is found, it adds or replaces the current setting. The valid names are
#' 
#' \describe{
#' \item{\code{tran}, \code{tran2}}{(\code{list} or \code{character}) specifies
#' the transformation which, when inverted, determines the results displayed by
#' \code{\link{summary.emmGrid}}, \code{\link{predict.emmGrid}}, or \code{\link{emmip}} when
#' \code{type="response"}. The value may be the name of a standard
#' transformation from \code{\link{make.link}} or additional ones supported by
#' name, such as \code{"log2"}; or, for a custom transformation, a \code{list}
#' containing at least the functions \code{linkinv} (the inverse of the
#' transformation) and \code{mu.eta} (the derivative thereof). The
#' \code{\link{make.tran}} function returns such lists for a number of popular
#' transformations. See the help page of \code{\link{make.tran}} for details as
#' well as information on the additional named transformations that are
#' supported. \code{tran2} is just like \code{tran} except it is a second
#' transformation (i.e., a response transformation in a generalized linear
#' model).}
#' 
#' \item{\code{tran.mult}}{Multiple for \code{tran}. For example, for the
#' response transformation \samp{2*sqrt(y)} (or \samp{sqrt(y) + sqrt(y + 1)},
#' for that matter), we should have \code{tran = "sqrt"} and \code{tran.mult =
#' 2}. If absent, a multiple of 1 is assumed.}
#' 
#' \item{\code{estName}}{(\code{character}) is the column label used for
#' displaying predictions or EMMs.}
#' 
#' \item{\code{inv.lbl}}{(\code{character)}) is the column label to use for
#' predictions or EMMs when \code{type="response"}.}
#' 
#' \item{\code{by.vars}}{(\code{character)} vector or \code{NULL}) the variables
#' used for grouping in the summary, and also for defining subfamilies in a call
#' to \code{\link{contrast}}.}
#' 
#' \item{\code{pri.vars}}{(\code{character} vector) are the names of the grid
#' variables that are not in \code{by.vars}. Thus, the combinations of their
#' levels are used as columns in each table produced by \code{\link{summary.emmGrid}}.}
#' 
#' \item{\code{alpha}}{(numeric) is the default significance level for tests, in
#' \code{\link{summary.emmGrid}} as well as \code{\link{cld.emmGrid}} and \code{\link{plot.emmGrid}}
#' when \samp{intervals = TRUE}}
#' 
#' \item{\code{adjust}}{(\code{character)}) is the default for the \code{adjust}
#' argument in \code{\link{summary.emmGrid}}.}
#' 
#' \item{\code{estType}}{(\code{character}) is the type of the estimate. It
#' should match one of \samp{c("prediction", "contrast", "pairs")}. This is used
#' along with \code{"adjust"} to determine appropriate adjustments to P values
#' and confidence intervals.}
#' 
#' \item{\code{famSize}}{(integer) is the \code{nmeans} parameter for
#' \code{\link{ptukey}} when \code{adjust="tukey"}. }
#' 
#' \item{\code{infer}}{(\code{logical} vector of length 2) is the default value
#' of \code{infer} in \code{\link{summary.emmGrid}}.}
#' 
#' \item{\code{level}}{(numeric) is the default confidence level, \code{level},
#' in \code{\link{summary.emmGrid}}}
#' 
#' \item{\code{df}}{(numeric) overrides the default degrees of freedom with a
#' specified single value.}
#' 
#' \item{\code{null}}{(numeric) null hypothesis for \code{summary} or
#' \code{test} (taken to be zero if missing).}
#' 
#' \item{\code{side}}{(numeric or character) \code{side} specification for for
#' \code{summary} or \code{test} (taken to be zero if missing).}
#' 
#' \item{\code{delta}}{(numeric) \code{delta} specification for \code{summary}
#' or \code{test} (taken to be zero if missing).}
#' 
#' \item{\code{predict.type} or \code{type}}{(character) sets the default method
#' of displaying predictions in \code{\link{summary.emmGrid}},
#' \code{\link{predict.emmGrid}}, and \code{\link{emmip}}. Valid values are
#' \code{"link"} (with synonyms \code{"lp"} and \code{"linear"}), or
#' \code{"response"}.}
#' 
#' \item{\code{avgd.over}}{(\code{character)} vector) are the names of the 
#' variables whose levels are averaged over in obtaining marginal averages of 
#' predictions, i.e., estimated marginal means. Changing this might produce a 
#' misleading printout, but setting it to \code{character(0)} will suppress the 
#' \dQuote{averaged over} message in the summary.}
#' 
#' \item{\code{initMesg}}{(\code{character}) is a string that is added to the
#' beginning of any annotations that appear below the \code{\link{summary.emmGrid}}
#' display.}
#' 
#' \item{\code{methDesc}}{(\code{character}) is a string that may be used for
#' creating names for a list of \code{emmGrid} objects. }
#' 
#' \item{\code{nesting}}{(Character or named \code{list}) specifies the nesting
#' structure. See \dQuote{Recovering or overriding model information} in the
#' documentation for \code{\link{ref_grid}}. The current nesting structure is
#' displayed by \code{\link{str.emmGrid}}.}
#' 
#' \item{(any slot name)}{If the name matches an element of
#' \code{slotNames(object)}, that slot is replaced by the supplied value, if it
#' is of the required class (otherwise an error occurs). Note that other options
#' above are saved in the \code{misc} slot; hence, you probably
#' don't want to replace that slot. The user must be very careful in
#' replacing slots because they are interrelated; for example, the \code{levels}
#' and \code{grid} slots must involve the same variable names, and the lengths
#' and dimensions of \code{grid}, \code{linfct}, \code{bhat}, and \code{V} must
#' conform.}
#' } %%%%%%% end \describe 
#'
#' @examples
#' # Using an already-transformed response:
#' mypigs <- transform(pigs, logconc = log(pigs$conc))
#' mypigs.lm <- lm(logconc ~ source + factor(percent), data = mypigs)
#' 
#' # Reference grid that knows about the transformation:
#' mypigs.rg <- update(ref_grid(mypigs.lm), tran = "log", 
#'                     predict.type = "response")
#' emmeans(mypigs.rg, "source")
update.emmGrid = function(object, ..., silent = FALSE) {
    args = list(...)
    valid.misc = c("adjust","alpha","avgd.over","by.vars","delta","df",
                   "initMesg","estName","estType","famSize","infer","inv.lbl",
                   "level","methDesc","nesting","null","predict.type","pri.vars"
                   ,"side","tran","tran.mult","tran2","type","is.new.rg")
    valid.slots = slotNames(object)
    valid.choices = union(valid.misc, valid.slots)
    misc = object@misc
    for (nm in names(args)) {
        fullname = try(match.arg(nm, valid.choices), silent=TRUE)
        if(inherits(fullname, "try-error")) {
            if (!silent)
                message("Argument ", sQuote(nm), " was ignored. Valid choices are:\n",
                        paste(valid.choices, collapse=", "))
        }
        else {
            if (fullname == "type") fullname = "predict.type"
            if (fullname %in% valid.slots)
                slot(object, fullname) = args[[nm]]
            else {
                if (fullname == "by.vars") {
                    allvars = union(misc$pri.vars, misc$by.vars)
                    misc$pri.vars = setdiff(allvars, args[[nm]])
                }
                if (fullname == "pri.vars") {
                    allvars = union(misc$pri.vars, misc$by.vars)
                    misc$by.vars = setdiff(allvars, args[[nm]])
                }
                if (fullname == "nesting") # special case - I keep nesting in model.info
                    object@model.info$nesting = args[[nm]]
                else
                    misc[[fullname]] = args[[nm]]
            }
        }
    }
    object@misc = misc
    object
}

### set or change emmeans options
#' @rdname update.emmGrid
#' @section Using \code{emm_options}:
#' In \code{emm_options}, we may set or change the \emph{default} values for the
#' above options. These defaults are set separately for different contexts in
#' which \code{emmGrid} objects are created, in a named list of option lists.
#' Currently, the following main list entries are supported:
#' \describe{
#' \item{\code{ref_grid}}{A named \code{list} of defaults for objects created by
#' \code{\link{ref_grid}}. This could affect other objects as well. For example,
#' if \code{emmeans} is called with a fitted model object, it calls
#' \code{ref_grid} and this option will affect the resulting \code{emmGrid}
#' object.}
#' \item{\code{emmeans}}{A named \code{list} of defaults for objects created by
#'   \code{\link{emmeans}} or \code{\link{emtrends}}.}
#' \item{\code{contrast}}{A named \code{list} of defaults for objects created by
#'   \code{\link{contrast.emmGrid}} or \code{\link{pairs.emmGrid}}.}
#' \item{\code{summary}}{A named \code{list} of defaults used by the methods
#'   \code{\link{summary.emmGrid}}, \code{\link{predict.emmGrid}}, \code{\link{test.emmGrid}},
#'   \code{\link{confint.emmGrid}}, and \code{\link{emmip}}. The only option that can
#'   affect the latter four is \code{"predict.method"}.}
#' \item{\code{graphics.engine}}{A character value matching 
#'   \code{c("ggplot", "lattice")}, setting the default engine to use in
#'   \code{\link{emmip}} and \code{\link{plot.emmGrid}}.  Defaults to \code{"ggplot"}.}
#'% \item{\code{msg.data.call}}{Logical value controlling whether or not
#'%   a warning is displayed when a model's \code{data} or \code{subset}
#'%   component contains a call. This can be hazardous; for example, if a model
#'%   call contains something like \code{subset = sample(...)}, then that same
#'%   call to \code{sample} will be run again when the reference grid is
#'%   constructed -- but it will be a different subset! This will definitely
#'%   affect the covariate settings, and may even affect the factor levels.
#'%   Defaults to \code{TRUE}.} 
#' \item{\code{msg.interaction}}{A logical value controlling whether or not
#'   a message is displayed when \code{emmeans} averages over a factor involved
#'   in an interaction. It is probably not appropriate to do this, unless
#'   the interaction is weak. Defaults to \code{TRUE}.}
#' \item{\code{msg.nesting}}{A logical value controlling whether or not to
#'   display a message when a nesting structure is auto-detected. The existence
#'   of such a structure affects computations of EMMs. Sometimes, a nesting
#'   structure is falsely detected -- namely when a user has omitted some
#'   main effects but included them in interactions. This does not change the
#'   model fit, but it produces a different parameterization that is picked
#'   up when the reference grid is constructed. Defaults to \code{TRUE}.}
#' }%%% end describe{}
#' Some other options have more specific purposes:
#' \describe{
#' \item{\code{estble.tol}}{Tolerance for determining estimability in
#' rank-deficient cases. If absent, the value in \code{emm_defaults$estble.tol)}
#' is used.}
#' \item{code{save.ref_grid}}{Logical value of \code{TRUE} if you wish the 
#' latest reference grid created to be saved in \code{.Last.ref_grid}}
#' \item{Options for \code{lme4::lmerMod} models}{Options \code{lmer.df},
#' \code{disable.pbkrtest}, \code{pbkrtest.limit}, \code{disable.lmerTest},
#' and \code{lmerTest.limit}
#' options affect how degrees of freedom are computed for \code{lmerMod} objects
#' produced by the \pkg{lme4} package). See that section of the "models" vignette
#' for details.}
#' } %%%%%% end \describe

#' @return \code{emm_options} returns the current options (same as the result 
#'   of \samp{getOption("emmeans")}) -- invisibly, unless called with no arguments.
#' @export
#' @examples
#' \dontrun{
#' emm_options(ref_grid = list(level = .90),
#'             contrast = list(infer = c(TRUE,FALSE)),
#'             estble.tol = 1e-6)
#' # Sets default confidence level to .90 for objects created by ref.grid
#' # AS WELL AS emmeans called with a model object (since it creates a 
#' # reference grid). In addition, when we call 'contrast', 'pairs', etc.,
#' # confidence intervals rather than tests are displayed by default.
#' }
#' 
#' \dontrun{
#' emm_options(disable.pbkrtest = TRUE)
#' # This forces use of asymptotic methods for lmerMod objects.
#' # Set to FALSE or NULL to re-enable using pbkrtest.
#' }
#' 
#' # See tolerance being used for determining estimability
#' get_emm_option("estble.tol")
#'
emm_options = function(...) {
    opts = getOption("emmeans", list())
    #    if (is.null(opts)) opts = list()
    newopts = list(...)
    for (nm in names(newopts))
        opts[[nm]] = newopts[[nm]]
    options(emmeans = opts)
    if (length(newopts) > 0)
        invisible(opts)
    else
        opts
}

# equivalent of getOption()
#' @rdname update.emmGrid
#' @param x Character value - the name of an option to be queried
#' @param default Value to return if \code{x} is not found
#' @return \code{get_emm_option} returns the currently stored option for \code{x}, 
#'   or its default value if not found.
#' @export
get_emm_option = function(x, default = emm_defaults[[x]]) {
    opts = getOption("emmeans", list())
    if(is.null(default) || hasName(opts, x))
        opts[[x]]
    else 
        default
}

### Exported defaults for certain options
#' @rdname update.emmGrid
#' @export
emm_defaults = list (
    ref_grid = list(is.new.rg = TRUE, infer = c(FALSE, FALSE)),
    emmeans = list(infer = c(TRUE, FALSE)),
    contrast = list(infer = c(FALSE, TRUE)),
    save.ref_grid = TRUE,     # save new ref_grid in .Last.ref_grid
    graphics.engine = "ggplot",  # default for emmip and plot.emmGrid
###    msg.data.call = TRUE,     # message when there's a call in data or subset
    msg.interaction = TRUE,   # message about averaging w/ interactions
    msg.nesting = TRUE,       # message when nesting is detected
    estble.tol = 1e-8,        # tolerance for estimability checks
    lmer.df = "kenward-roger",  # Use Kenward-Roger for df
    disable.pbkrtest = FALSE, # whether to bypass pbkrtest routines for lmerMod
    pbkrtest.limit = 3000,    # limit on N for enabling K-R
    disable.lmerTest = FALSE, # whether to bypass lmerTest routines for lmerMod
    lmerTest.limit = 3000     # limit on N for enabling Satterthwaite
)


### Utility to change the internal structure of an emmGrid object
### Returned emmGrid object has linfct = I and bhat = estimates
### Primary reason to do this is with transform = TRUE, then can 
### work with linear functions of the transformed predictions

#' Reconstruct a reference grid with a new transformation
#' 
#' The typical use of this function is to cause EMMs to be computed on
#' a different scale, e.g., the back-transformed scale rather than the 
#' linear-predictor scale. In other words, if you want back-transformed 
#' results, do you want to average and then back-transform, or 
#' back-transform and then average?
#' 
#' The \code{regrid} function reparameterizes an existing \code{ref.grid} so
#' that its \code{linfct} slot is the identity matrix and its \code{bhat} slot
#' consists of the estimates at the grid points. If \code{transform} is
#' \code{TRUE}, the inverse transform is applied to the estimates. Outwardly,
#' when \code{transform = "response"}, the result of \code{\link{summary.emmGrid}}
#' after applying \code{regrid} is identical to the summary of the original
#' object using \samp{type="response"}. But subsequent EMMs or
#' contrasts will be conducted on the new scale -- which is
#' the reason this function exists. 
#' 
#' In cases where the
#' degrees of freedom depended on the linear function being estimated, the d.f.
#' from the reference grid are saved, and a kind of \dQuote{containment} method
#' is substituted in the returned object whereby the calculated d.f. for a new
#' linear function will be the minimum d.f. among those having nonzero
#' coefficients. This is kind of an \emph{ad hoc} method, and it can
#' over-estimate the degrees of freedom in some cases.
#'
#' @param object An object of class \code{emmGrid}
#' @param transform Character or logical value. If \code{"response"} or
#'   \code{"mu"}, the inverse transformation is applied to the estimates in the
#'   grid (but if there is both a link function and a response transformation,
#'   \code{"mu"} back-transforms only the link part); if \code{"log"}, the
#'   results are formulated as if the response had been \code{log}-transformed;
#'   if \code{"none"}, predictions thereof are on the same scale as in 
#'   \code{object}, and any internal transformation information is preserved. 
#'   For compatibility with past versions, \code{transform} may also be logical;
#'   \code{TRUE} is taken as \code{"response"}, and \code{FALSE} as 
#'   \code{"none"}.
#' @param inv.log.lbl Character value. This applies only when \code{transform =
#'   "log"}, and is used to label the predictions if subsequently summarized
#'   with \code{type = "response"}.
#' @param predict.type Character value. If provided, the returned object is
#'   updated with the given type, e.g., \code{"response"}. 
#'   See \code{\link{update.emmGrid}}.
#'   
#' @note Another way to use \code{regrid} is to supply a \code{transform} 
#'   argument to \code{\link{ref_grid}} (either directly of indirectly via
#'   \code{\link{emmeans}}). This is often a simpler approach if the reference
#'   grid has not already been constructed.
#'
#' @return An \code{emmGrid} object with the requested changes
#' @export
#'
#' @examples
#' pigs.lm <- lm(log(conc) ~ source + factor(percent), data = pigs)
#' 
#' # This will yield EMMs as GEOMETRIC means of concentrations:
#' emmeans(pigs.lm, "source", type = "response")
#' # NOTE: pairs() of the above will be RATIOS of these results
#' 
#' # This will yield EMMs as ARITHMETIC means of concentrations:
#' emmeans(regrid(ref_grid(pigs.lm, transform = "response")), "source")
#' # Same thing, made simpler:
#' emmeans(pigs.lm, "source", transform = "response")
#' # NOTE: pairs() of the above will be DIFFERENCES of these results
regrid = function(object, transform = c("response", "mu", "unlink", "log", "none"), 
                  inv.log.lbl = "response", predict.type) 
{
    if (is.logical(transform))   # for backward-compatibility
        transform = ifelse(transform, "response", "none")
    else
        transform = match.arg(transform)
    
    # if we have two transformations to undo, do the first one recursively
    if ((transform == "response") && (!is.null(object@misc$tran2)))
        object = regrid(object, transform = "mu")
    
    # Save post.beta stuff
    PB = object@post.beta
    NC = attr(PB, "n.chains")
    
    if (!is.na(PB[1])) # fix up post.beta BEFORE we overwrite parameters
        PB = PB %*% t(object@linfct)
    
    est = .est.se.df(object, do.se = TRUE) ###FALSE)
    estble = !is.na(est[[1]])
    object@V = vcov(object, complete=FALSE)[estble, estble, drop=FALSE]
    object@bhat = est[[1]]
    object@linfct = diag(1, length(estble))
    if(all(estble))
        object@nbasis = estimability::all.estble
    else
        object@nbasis = object@linfct[, !estble, drop = FALSE]
    
    # override the df function
    df = est$df
    test.df = diff(range(df))
    if (is.na(test.df) || test.df < .001) {
        object@dfargs = list(df = mean(df))
        object@dffun = function(k, dfargs) dfargs$df
    }
    else { # use containment df
        object@dfargs = list(df = df)
        object@dffun = function(k, dfargs) {
            idx = which(zapsmall(k) != 0)
            ifelse(length(idx) == 0, NA, min(dfargs$df[idx]))
        }
    }
    
    if(transform %in% c("response", "mu", "unlink", "log") && !is.null(object@misc$tran)) {
        link = attr(est, "link")
        D = .diag(link$mu.eta(object@bhat[estble]))
        object@bhat = link$linkinv(object@bhat)
        object@V = D %*% tcrossprod(object@V, D)
        if (!is.na(PB[1]))
            PB = matrix(link$linkinv(PB), ncol = ncol(PB))
        inm = object@misc$inv.lbl
        if (!is.null(inm))
            object@misc$estName = inm
        if((transform %in% c("mu", "unlink")) && !is.null(object@misc$tran2)) {
            object@misc$tran = object@misc$tran2
            object@misc$tran2 = object@misc$tran.mult = object@misc$inv.lbl = NULL
        }
        else
            object@misc$tran = object@misc$tran.mult = object@misc$inv.lbl = NULL
    }
    if (transform == "log") { # from prev block, we now have stuff on response scale
        incl = which(object@bhat > 0)
        if (length(incl) < length(object@bhat)) {
            message("Non-positive response predictions are flagged as non-estimable")
            tmp = seq_along(object@bhat)
            excl = tmp[-incl]
            object@bhat[excl] = NA
            object@nbasis = sapply(excl, function(ii) 0 + (tmp == ii))
        }
        D = .diag(1/object@bhat[incl])
        object@V = D %*% tcrossprod(object@V[incl, incl, drop = FALSE], D)
        object@bhat = log(object@bhat)
        if (!is.na(PB[1])) {
            PB[PB <= 0] = NA
            PB = log(PB)
            PB[1] = ifelse(is.na(PB[1]), 0, PB[1]) # make sure 1st elt isn't NA
        }
        object@misc$tran = "log"
        object@misc$inv.lbl = inv.log.lbl
    }
    
    if(!is.na(PB[1])) {
        attr(PB, "n.chains") = NC
        object@post.beta = PB
    }
    
    # Nix out things that are no longer needed or valid
    object@grid$.offset. = object@misc$offset.mult =
        object@misc$estHook = object@misc$vcovHook = NULL
    if(!missing(predict.type))
        object = update(object, predict.type = predict.type)
    object
}

