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

# Reference grid code


# Change to cov.reduce specification: can be...
#     a function: is applied to all covariates
#     named list of functions: applied to those covariates (else mean is used)
#     TRUE - same as mean
#     FALSE - same as function(x) sort(unique(x))

#' Create a reference grid from a fitted model
#' 
#' Using a fitted model object, determine a reference grid for which estimated
#' marginal means are defined. The resulting \code{ref_grid} object encapsulates
#' all the information needed to calculate EMMs and make inferences on them.
#' 
#' The reference grid consists of combinations of independent variables over
#' which predictions are made. Estimated marginal means are defined as these
#' predictions, or marginal averages thereof. The grid is determined by first
#' reconstructing the data used in fitting the model (see
#' \code{\link{recover_data}}), or by using the \code{data.frame} provided in
#' \code{data}. The default reference grid is determined by the observed
#' levels of any factors, the ordered unique values of character-valued
#' predictors, and the results of \code{cov.reduce} for numeric predictors.
#' These may be overridden using \code{at}. See also the section below on
#' recovering/overriding model information.
#' 
#'
#' @param object An object produced by a supported model-fitting function, such
#'   as \code{lm}. Many models are supported. 
#'   See \href{../doc/models.html}{\code{vignette("models", "emmeans")}}.
#' @param at Optional named list of levels for the corresponding variables
#' @param cov.reduce A function, logical value, or formula; or a named list of
#'   these. Each covariate \emph{not} specified in \code{at} is reduced
#'   according to these specifications. See the section below on 
#'   \dQuote{Using \code{cov.reduce}}.
#' @param mult.name Character value: the name to give to the pseudo-factor
#'   whose levels delineate the elements of a multivariate response. If this is
#'   provided, it overrides the default name, e.g., \code{"rep.meas"} for an
#'   \code{\link[=lm]{mlm}} object or \code{"cut"} for a
#'   \code{\link[MASS]{polr}} object.
#' @param mult.levs A named list of levels for the dimensions of a multivariate
#'   response. If there is more than one element, the combinations of levels are
#'   used, in \code{\link{expand.grid}} order. The (total) number of levels must
#'   match the number of dimensions. If \code{mult.name} is specified, this
#'   argument is ignored.
#' @param options If non-\code{NULL}, a named \code{list} of arguments to pass
#'   to \code{\link{update.emmGrid}}, just after the object is constructed.
#' @param data A \code{data.frame} to use to obtain information about the
#'   predictors (e.g. factor levels). If missing, then
#'   \code{\link{recover_data}} is used to attempt to reconstruct the data.
#' @param df Numeric value. This is equivalent to specifying
#'   \code{options(df = df)}. See \code{\link{update.emmGrid}}.
#' @param type Character value. If provided, this is saved as the
#'   \code{"predict.type"} setting. See \code{\link{update.emmGrid}} and the section
#'   below on prediction types and transformations.
#' @param transform Character value. If other than \code{"none"}, the reference 
#'   grid is reconstructed via \code{\link{regrid}} with the given 
#'   \code{transform} argument. See the section below on prediction types and
#'   transformations.
#' @param nesting If the model has nested fixed effects, this may be specified
#'   here via a character vector or named \code{list} specifying the nesting
#'   structure. Specifying \code{nesting} overrides any nesting structure that
#'   is automatically detected. See Details.
#' @param ... Optional arguments passed to \code{\link{emm_basis}}, such as
#'   \code{vcov.} (see Details below) or options for certain models (see
#'   \href{../doc/models.html}{vignette("models", "emmeans")}).
#' 
#' @section Using \code{cov.reduce}:
#' \code{cov.reduce} may be a function, logical value, formula, or a named list of
#'   these.
#'   
#' If a single function, it is applied to each covariate. 
#' 
#' If logical and \code{TRUE}, \code{mean} is used. If logical and \code{FALSE},
#' it is equivalent to specifying \samp{function(x) sort(unique(x))}, and these
#' values are considered part of the reference grid; thus, it is a handy
#' alternative to specifying these same values in \code{at}.
#' 
#' If a formula (which must be two-sided), then a model is fitted to that
#' formula using \code{\link{lm}}; then in the reference grid, its response
#' variable is set to the results of \code{\link{predict}} for that model, with
#' the reference grid as \code{newdata}. (This is done \emph{after} the
#' reference grid is determined.) A formula is appropriate here when you think
#' experimental conditions affect the covariate as well as the response.
#' 
#' If \code{cov.reduce} is a named list, then the above criteria are used to
#' determine what to do with covariates named in the list. (However, formula
#' elements do not need to be named, as those names are determined from the
#' formulas' left-hand sides.) Any unresolved covariates are reduced using
#' \code{"mean"}.
#' 
#' Any \code{cov.reduce} specification for a covariate also named in \code{at}
#' is ignored.
#' 
#' @section Recovering or overriding model information:
#' Ability to support a particular class of \code{object} depends on the
#' existence of \code{recover_data} and \code{emm_basis} methods -- see
#' \link{extending-emmeans} for details. The call \code{methods("recover_data")}
#' will help identify these. 
#' 
#' \bold{Data.} In certain models, (e.g., results of \code{\link[lme4]{glmer.nb}}), it is not
#' possible to identify the original dataset. In such cases, we can work around
#' this by setting \code{data} equal to the dataset used in fitting the model,
#' or a suitable subset. Only the complete cases in \code{data} are used, so it
#' may be necessary to exclude some unused variables. Using \code{data} can also
#' help save computing, especially when the dataset is large. In any case,
#' \code{data} must represent all factor levels used in fitting the model. It
#' \emph{cannot} be used as an alternative to \code{at}. (Note: If there is a
#' pattern of \code{NAs} that caused one or more factor levels to be excluded
#' when fitting the model, then \code{data} should also exclude those levels.)
#' 
#' \bold{Covariance matrix.} By default, the variance-covariance matrix for the 
#' fixed effects is obtained from \code{object}, usually via its
#' \code{\link{vcov}} method. However, the user may override this via a
#' \code{vcov.} argument, specifying a matrix or a function. If a matrix, it
#' must be square and of the same dimension and parameter order of the fixed
#' effects. If a function, must return a suitable matrix when it is called with
#' \code{object} as its only argument.
#' 
#' \bold{Nested factors.} Having a nesting structure affects marginal averaging 
#' in \code{emmeans} in that it is done separately for each level (or 
#' combination thereof) of the grouping factors. \code{ref_grid} tries to 
#' discern which factors are nested in other factors, but it is not always 
#' obvious, and if it misses some, the user must specify this structure via 
#' \code{nesting}; or later using \code{\link{update.emmGrid}}. The \code{nesting}
#' argument may be a character vector or a named \code{list}. If a \code{list},
#' each name should be the name of a single factor in the grid, and its entry a
#' character vector of the name(s) of its grouping factor(s). \code{nested} may
#' also be a character value of the form \code{"factor1 \%in\%
#' (factor2*factor3)"}. If there is more than one such specification, they may
#' be appended separated by commas, or as separate elements of a character
#' vector. For example, these specifications are equivalent: \code{nesting =
#' list(state = "country", city = c("state", "country")}, \code{nesting = "state
#' \%in\% country, city \%in\% (state*country)"}, and \code{nesting = c("state
#' \%in\% country)", "city \%in\% (state*country)")}.
#'
#' @section Prediction types and transformations:
#' There is a subtle difference between specifying \samp{type = "response"} and 
#' \samp{transform = "response"}. While the summary statistics for the grid 
#' itself are the same, subsequent use in \code{\link{emmeans}} will yield 
#' different results if there is a response transformation or link function. 
#' With \samp{type = "response"}, EMMs are computed by averaging together
#' predictions on the \emph{linear-predictor} scale and then back-transforming
#' to the response scale; while with \samp{transform = "response"}, the
#' predictions are already on the response scale so that the EMMs will be
#' the arithmetic means of those response-scale predictions. To add further to
#' the possibilities, \emph{geometric} means of the response-scale predictions
#' are obtainable via \samp{transform = "log", type = "response"}.
#' 
#' @section Side effect:
#' The most recent result of \code{ref_grid}, whether called directly or
#' indirectly via \code{\link{emmeans}}, \code{\link{emtrends}}, or some other
#' function that calls one of these, is saved in the user's environment as
#' \code{.Last.ref_grid}. This facilitates checking what reference grid was
#' used, or reusing the same reference grid for further calculations. This
#' automatic saving is enabled by default, but may be disabled via
#' \samp{emm_options(save.ref_grid = FALSE)}, and re-enabled by specifying
#' \code{TRUE}.
#' 
#' @return An object of the S4 class \code{"emmGrid"} (see 
#'   \code{\link{emmGrid-class}}). These objects encapsulate everything needed 
#'   to do calculations and inferences for estimated marginal means, and contain
#'   nothing that depends on the model-fitting procedure.
#'   
#' @seealso Reference grids are of class \code{\link{emmGrid-class}} and several
#'   methods exist for them -- for example \code{\link{summary.emmGrid}}. Reference
#'   grids are fundamental to \code{\link{emmeans}}. Supported models are
#'   detailed in \href{../doc/models.html}{\code{vignette("models", "emmeans")}}.
#'   
#' @export
#'
#' @examples
#' fiber.lm <- lm(strength ~ machine*diameter, data = fiber)
#' ref_grid(fiber.lm)
#' summary(.Last.ref_grid)
#' 
#' ref_grid(fiber.lm, at = list(diameter = c(15, 25)))
#' 
#' \dontrun{
#' # We could substitute the sandwich estimator vcovHAC(fiber.lm)
#' # as follows:
#' summary(ref_grid(fiber.lm, vcov. = sandwich::vcovHAC))
#' }
#' 
#' # If we thought that the machines affect the diameters
#' # (admittedly not plausible in this example), then we should use:
#' ref_grid(fiber.lm, cov.reduce = diameter ~ machine)
#' 
#' # Multivariate example
#' MOats.lm = lm(yield ~ Block + Variety, data = MOats)
#' ref_grid(MOats.lm, mult.name = "nitro")
#' # Silly illustration of how to use 'mult.levs' to make comb's of two factors
#' ref_grid(MOats.lm, mult.levs = list(T=LETTERS[1:2], U=letters[1:2]))
#' 
ref_grid <- function(object, at, cov.reduce = mean, mult.name, mult.levs, 
                     options = get_emm_option("ref_grid"), data, df, type, 
                     transform = c("none", "response", "mu", "unlink", "log"), 
                     nesting, ...) 
{
    transform = match.arg(transform)
    if (!missing(df)) {
        if(is.null(options)) options = list()
        options$df = df
    }
    
    # recover the data
    if (missing(data)) {
        data = try(.chk_recover_data (object, data = NULL, ...))
        if (inherits(data, "try-error"))
            stop("Perhaps a 'data' or 'params' argument is needed")
    }
    else # attach needed attributes to given data
        data = .chk_recover_data(object, data = data, ...)
    
    if(is.character(data)) # 'data' is in fact an error message
        stop(data)
        
    
    trms = attr(data, "terms")
    
    # find out if any variables are coerced to factors or vice versa
    coerced = .find.coerced(trms, data) # now list with members 'factors' and 'covariates'
    
    # convenience function
    sort.unique = function(x) sort(unique(x))
    
    # Ensure cov.reduce is a function or list thereof
    dep.x = list() # list of formulas to fit later
    fix.cr = function(cvr) {
        # cvr is TRUE or FALSE
        if(is.logical(cvr)) 
            if(cvr[1]) cvr = mean
        else              cvr = sort.unique
        else if (inherits(cvr, "formula")) {
            if (length(cvr) < 3)
                stop("Formulas in 'cov.reduce' must be two-sided")
            lhs = .all.vars(cvr)[1]
            dep.x[[lhs]] <<- cvr
            cvr = mean 
        }
        else if (!inherits(cvr, c("function","list")))
            stop("Invalid 'cov.reduce' argument")
        cvr
    }
    
    # IMPORTANT: following stmts may also affect x.dep
    if (is.list(cov.reduce))
        cov.reduce = lapply(cov.reduce, fix.cr)
    else
        cov.reduce = fix.cr(cov.reduce)
    
    # zap any formulas that are also in 'at'
    if (!missing(at))
        for (xnm in names(at)) dep.x[[xnm]] = NULL
    
    
    # local cov.reduce function that works with function or named list
    cr = function(x, nm) {
        if (is.function(cov.reduce))
            cov.reduce(x)
        else if (hasName(cov.reduce, nm))
            cov.reduce[[nm]](x)
        else
            mean(x)
    }
    
    # initialize empty lists
    ref.levels = matlevs = xlev = list()
    
    for (nm in attr(data, "responses")) {
        y = data[[nm]]
        if (is.matrix(y))
            matlevs[[nm]] = apply(y, 2, mean)
        else
            ref.levels[[nm]] = mean(y)
    }
    
    for (nm in attr(data, "predictors")) {
        x = data[[nm]]
        
        # Save the original levels of factors, no matter what
        if (is.factor(x) && !(nm %in% coerced$covariates))
            xlev[[nm]] = levels(factor(x))
            # (applying factor drops any unused levels)
    
        # Now go thru and find reference levels...
        # mentioned in 'at' list but not coerced factor
        if (!(nm %in% coerced$factors) && !missing(at) && (hasName(at, nm)))
            ref.levels[[nm]] = at[[nm]]
        # factors not in 'at'
        else if (is.factor(x) && !(nm %in% coerced$covariates))
            ref.levels[[nm]] = levels(factor(x))
        else if (is.character(x))
            ref.levels[[nm]] = sort.unique(x)
        # matrices
        else if (is.matrix(x)) {
            # Matrices -- reduce columns thereof, but don't add to baselevs
            matlevs[[nm]] = apply(x, 2, cr, nm)
            # if cov.reduce returns a vector, average its columns
            if (is.matrix(matlevs[[nm]]))
                matlevs[[nm]] = apply(matlevs[[nm]], 2, mean)
        }
        # covariate coerced, or not mentioned in 'at'
        else {
            # single numeric pred but coerced to a factor - use unique values
            # even if in 'at' list. We'll fix this up later
            if (nm %in% coerced$factors)            
                ref.levels[[nm]] = sort.unique(x)
            
            # Ordinary covariates - summarize
            else 
                ref.levels[[nm]] = cr(as.numeric(x), nm)
        }
    }
    
    # Now create the reference grid
    grid = do.call(expand.grid, ref.levels)
    
    # add any matrices
    for (nm in names(matlevs))
        grid[[nm]] = matrix(rep(matlevs[[nm]], each=nrow(grid)), nrow=nrow(grid))

    # resolve any covariate formulas
    for (xnm in names(dep.x)) {
        if (!all(.all.vars(dep.x[[xnm]]) %in% names(grid)))
            stop("Formulas in 'cov.reduce' must predict covariates actually in the model")
        xmod = lm(dep.x[[xnm]], data = data)
        grid[[xnm]] = predict(xmod, newdata = grid)
        ref.levels[[xnm]] = NULL
    }
    
    basis = .chk_emm_basis(object, trms, xlev, grid, ...)
    
    misc = basis$misc
    
    ### Figure out if there is a response transformation...
    # next stmt assumes that model formula is 1st argument (2nd element) in call.
    # if not, we probably get an error or something that isn't a formula
    # and it is silently ignored
    lhs = try(eval(attr(data, "call")[[2]][-3]), silent = TRUE)
    if (inherits(lhs, "formula")) { # response may be transformed
        tran = setdiff(.all.vars(lhs, functions = TRUE), c(.all.vars(lhs), "~", "cbind", "+", "-", "*", "/", "^", "%%", "%/%"))
        if(length(tran) > 0) {
            tran = paste(tran, collapse = ".")  
            # length > 1: Almost certainly unsupported, but facilitates a more informative error message
            
            # Look for a multiplier, e.g. 2*sqrt(y)
            tst = strsplit(strsplit(as.character(lhs[2]), "\\(")[[1]][1], "\\*")[[1]]
            if(length(tst) > 1) {
                mul = suppressWarnings(as.numeric(tst[1]))
                if(!is.na(mul))
                    misc$tran.mult = mul
                tran = gsub("\\*\\.", "", tran)
            }
            if (tran == "linkfun")
                tran = as.list(environment(trms))
            if(is.null(misc$tran))
                misc$tran = tran
            else
                misc$tran2 = tran
            misc$inv.lbl = "response"
        }
    }
    
    # Take care of multivariate response
    multresp = character(0) ### ??? was list()
    ylevs = misc$ylevs
    if(!is.null(ylevs)) { # have a multivariate situation
       if (missing(mult.levs)) {
            if (missing(mult.name))
                mult.name = names(ylevs)[1]
            ref.levels[[mult.name]] = ylevs[[1]]
            multresp = mult.name
            MF = data.frame(ylevs)
            names(MF) = mult.name
        }
        else {
            k = prod(sapply(mult.levs, length))
            if (k != length(ylevs[[1]])) 
                stop("supplied 'mult.levs' is of different length than that of multivariate response")
            for (nm in names(mult.levs))
                ref.levels[[nm]] = mult.levs[[nm]]
            multresp = names(mult.levs)
            MF = do.call("expand.grid", mult.levs)
        }
        ###grid = do.call("expand.grid", ref.levels)
        grid = merge(grid, MF)
        # add any matrices
        for (nm in names(matlevs))
            grid[[nm]] = matrix(rep(matlevs[[nm]], each=nrow(grid)), nrow=nrow(grid))
    }

# Here's a complication. If a numeric predictor was coerced to a factor, we had to
# include all its levels in the reference grid, even if altered in 'at'
# Moreover, whatever levels are in 'at' must be a subset of the unique values
# So we now need to subset the rows of the grid and linfct based on 'at'

    problems = if (!missing(at)) 
        intersect(c(multresp, coerced$factors), names(at)) 
    else character(0)
    if (length(problems) > 0) {
        incl.flags = rep(TRUE, nrow(grid))
        for (nm in problems) {
            if (is.numeric(ref.levels[[nm]])) {
                at[[nm]] = round(at[[nm]], 3)
                ref.levels[[nm]] = round(ref.levels[[nm]], 3)
            }
            # get only "legal" levels
            at[[nm]] = at[[nm]][at[[nm]] %in% ref.levels[[nm]]]
            # Now which of those are left out?
            excl = setdiff(ref.levels[[nm]], at[[nm]])
            for (x in excl)
                incl.flags[grid[[nm]] == x] = FALSE
            ref.levels[[nm]] = at[[nm]]
        }
        if (!any(incl.flags))
            stop("Reference grid is empty due to mismatched levels in 'at'")
        grid = grid[incl.flags, , drop=FALSE]
        basis$X = basis$X[incl.flags, , drop=FALSE]
    }

    # Any offsets??? (misc$offset.mult might specify removing or reversing the offset)
    if(!is.null(attr(trms,"offset"))) {
        om = 1
        if (!is.null(misc$offset.mult))
            om = misc$offset.mult
        if (any(om != 0))
            grid[[".offset."]] = om * .get.offset(trms, grid)
    }

    ### --- Determine weights for each grid point --- (added ver.2.11), updated ver.2.14 to include weights
    if (!hasName(data, "(weights)"))
        data[["(weights)"]] = 1
    nms = union(names(xlev), coerced$factors) # only factors, no covariates or mult.resp
    if (length(nms) == 0)
        wgt = rep(1, nrow(grid))  # all covariates; give each weight 1
    else {
        id = plyr::id(data[, nms, drop = FALSE], drop = TRUE)
        uid = !duplicated(id)
        key = do.call(paste, data[uid, nms, drop = FALSE])
        key = key[order(id[uid])]
        tgt = do.call(paste, grid[, nms, drop = FALSE])
        wgt = rep(0, nrow(grid))
        for (i in seq_along(key))
            wgt[tgt == key[i]] = sum(data[["(weights)"]][id==i])
    }
    grid[[".wgt."]] = wgt
    
    model.info = list(call = attr(data,"call"), terms = trms, xlev = xlev)
    # Detect any nesting structures
    nst = .find_nests(grid, trms, coerced$orig, ref.levels)
    if (length(nst) > 0)
        model.info$nesting = nst

    misc$is.new.rg = TRUE
    misc$ylevs = NULL # No longer needed
    misc$estName = "prediction"
    misc$estType = "prediction"
    misc$infer = c(FALSE,FALSE)
    misc$level = .95
    misc$adjust = "none"
    misc$famSize = nrow(grid)
    misc$avgd.over = character(0)

    post.beta = basis$post.beta
    if (is.null(post.beta))
        post.beta = matrix(NA)
    
    result = new("emmGrid",
         model.info = model.info,
         roles = list(predictors = attr(data, "predictors"), 
                      responses = attr(data, "responses"), 
                      multresp = multresp),
         grid = grid, levels = ref.levels, matlevs = matlevs,
         linfct = basis$X, bhat = basis$bhat, nbasis = basis$nbasis, V = basis$V,
         dffun = basis$dffun, dfargs = basis$dfargs, 
         misc = misc, post.beta = post.beta)
        
    if (!missing(type)) {
        if (is.null(options)) options = list()
        options$predict.type = type
    }
    
    if (!missing(nesting))
        result@model.info$nesting = .parse_nest(nesting)
    else if (!is.null(nst <- result@model.info$nesting))
        if (get_emm_option("msg.nesting"))
            message("NOTE: A nesting structure was detected in the ",
                    "fitted model:\n    ", .fmt.nest(nst), 
                "\nIf this is incorrect, re-run or update with `nesting` specified")

    if(!is.null(options)) {
        options$object = result
        result = do.call("update.emmGrid", options)
    }

    if(!is.null(hook <- misc$postGridHook)) {
        if (is.character(hook))
            hook = get(hook)
        result@misc$postGridHook = NULL
        result = hook(result)
    }
    if(transform != "none")
        result = regrid(result, transform = transform)
    
    .save.ref_grid(result)
    result
}


#### End of ref_grid ------------------------------------------

# local utility to save each newly constructed ref_grid, if enabled
# Goes into global environment unless .Last.ref_grid is found further up
.save.ref_grid = function(object) {
    if (is.logical(isnewrg <- object@misc$is.new.rg))
        if(isnewrg && get_emm_option("save.ref_grid"))
            assign(".Last.ref_grid", object, inherits = TRUE)
}



# This function figures out which covariates in a model 
# have been coerced to factors. And also which factors have been coerced
# to be covariates
.find.coerced = function(trms, data) {
    if (ncol(data) == 0) 
        return(list(factors = integer(0), covariates = integer(0)))
    isfac = sapply(data, function(x) inherits(x, "factor"))
    
    # Character vectors of factors and covariates in the data...
    facs.d = names(data)[isfac]
    covs.d = names(data)[!isfac]
    
    lbls = attr(trms, "term.labels")
    M = model.frame(trms, utils::head(data, 2)) #### just need a couple rows
    isfac = sapply(M, function(x) inherits(x, "factor"))
    
    # Character vector of terms in the model frame that are factors ...
    facs.m = names(M)[as.logical(isfac)]
    covs.m = setdiff(names(M), facs.m)
    
    # Exclude the terms that are already factors
    # What's left will be things like "factor(dose)", "interact(dose,treat)", etc
    # we're saving these in orig
    orig = cfac = setdiff(facs.m, facs.d)
    if(length(cfac) != 0) {
        cvars = lapply(cfac, function(x) .all.vars(stats::reformulate(x))) # Strip off the function calls
        cfac = intersect(unique(unlist(cvars)), covs.d) # Exclude any variables that are already factors
    }
    
    # Do same with covariates
    ccov = setdiff(covs.m, covs.d)
    orig = c(orig, ccov)
    if(length(ccov) > 0) {
        cvars = lapply(ccov, function(x) .all.vars(stats::reformulate(x)))
        ccov = intersect(unique(unlist(cvars)), facs.d)
    }
    
    list(factors = cfac, covariates = ccov, orig = orig)
}



