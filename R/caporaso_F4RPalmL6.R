#' @title Caporaso Right Palm Sequencing Data for Subject F4 on level 6
#'
#' @description Mostly genus-level counts (L6) from right palm skin samples of subject F4 over time.
#' @details Subject F4 was followed over 6 months. V4 16S region was sequenced. A counter was attached to genera appearing more than once in the count table.
#' @return TaxonxSample matrix of size 1295 x 133
#' @docType data
#' @usage data(caporaso_F4RPalmL6)
#' @keywords data, datasets
#' @references
#' Caporaso et al. (2011) Moving pictures of the human microbiome Genome Biology vol. 12:R50
#' \href{https://genomebiology.biomedcentral.com/articles/10.1186/gb-2011-12-5-r50}{Genome Biology}
#' @examples
#' data(caporaso_F4RPalmL6)
#' # sort taxa by abundance and print top 10 most abundant taxa
#' sorted <- sort(apply(caporaso_F4RPalmL6,1,sum),decreasing = TRUE, index.return = TRUE)
#' rownames(caporaso_F4RPalmL6)[sorted$ix[1:10]]
"caporaso_F4RPalmL6"
