bibtex_2academic <- function(bibfile,
                             outfold,
                             abstract = FALSE,
                             overwrite = FALSE,
                             workinprogress = FALSE) {

  require(RefManageR)
  require(dplyr)
  require(stringr)
  require(anytime)
  require(lubridate)

  # Import the bibtex file and convert to data.frame
  mypubs   <- ReadBib(bibfile, check = "warn") %>%
    as.data.frame()

  # assign "categories" to the different types of publications
  mypubs   <- mypubs %>%
    dplyr::mutate(
      pubtype = dplyr::case_when(bibtype == "Article" ~ "2",
                                 bibtype == "Article in Press" ~ "2",
                                 bibtype == "InProceedings" ~ "1",
                                 bibtype == "Proceedings" ~ "1",
                                 bibtype == "Conference" ~ "1",
                                 bibtype == "Conference Paper" ~ "1",
                                 bibtype == "MastersThesis" ~ "3",
                                 bibtype == "PhdThesis" ~ "3",
                                 bibtype == "Manual" ~ "4",
                                 bibtype == "TechReport" ~ "4",
                                 bibtype == "Book" ~ "5",
                                 bibtype == "InCollection" ~ "6",
                                 bibtype == "InBook" ~ "6",
                                 bibtype == "Misc" ~ "0",
                                 TRUE ~ "0"),
      month = dplyr::case_when(month == "jan" ~ "01",
                               month == "feb" ~ "02",
                               month == "mar" ~ "03",
                               month == "apr" ~ "04",
                               month == "may" ~ "05",
                               month == "jun" ~ "06",
                               month == "jul" ~ "07",
                               month == "aug" ~ "08",
                               month == "sep" ~ "09",
                               month == "oct" ~ "10",
                               month == "nov" ~ "11",
                               month == "dec" ~ "12",
                               is.na(month) ~ "01"))
  if(!workinprogress) mypubs <- mypubs %>% dplyr::filter(pubtype != 1)

  # create a function which populates the md template based on the info
  # about a publication
  create_md <- function(x) {

    # define a date and create filename by appending date and start of title
    if (!is.na(x[["year"]])) {
      x[["date"]] <- paste0(x[["year"]],"-", x[["month"]], "-01")
    } else {
      x[["date"]] <- "2999-01-01"
    }

    x[["title"]] <- x[["title"]] %>% str_remove_all(fixed("{")) %>%
      str_remove_all(fixed("}")) %>%
      str_replace_all(fixed("\\textendash"), "-") %>%
    str_replace_all(fixed("\\textquoteright"), "\'")

    filename <- paste(x[["date"]], x[["title"]] %>%
                        str_replace_all(fixed(" "), "_") %>%
                        str_remove_all(fixed(":")) %>%
                        str_sub(1, 20) %>%
                        paste0(".md"), sep = "_")
    # start writing
    if (!file.exists(file.path(outfold, filename)) | overwrite) {
      fileConn <- file.path(outfold, filename)
      write("---", fileConn)

      # Title and date
      write(paste0("title: \"", x[["title"]], "\""), fileConn, append = T)
      write(paste0("date: \"", anydate(x[["date"]]), "\""), fileConn, append = T)

      # # Authors. Comma separated list, e.g. `["Bob Smith", "David Jones"]`.
      auth_hugo <- str_replace_all(x["author"], " and ", "\", \"")
      auth_hugo <- stringi::stri_trans_general(auth_hugo, "latin-ascii")
      write(paste0("authors: [\"", auth_hugo,"\"]"), fileConn, append = T)

      # Publication type. Legend:
      # 0 = Uncategorized, 1 = Conference paper, 2 = Journal article
      # 3 = Manuscript, 4 = Report, 5 = Book,  6 = Book section
      write(paste0("publication_types: [\"", x[["pubtype"]],"\"]"),
            fileConn, append = T)

      # # Publication details: journal, volume, issue, page numbers and doi link
      publication <- coalesce(x[["journal"]],
                              paste0("_", x[["booktitle"]], "_. ", x[["address"]], ": ", x[["publisher"]]))
      if (!is.na(x[["volume"]])) publication <- paste0(publication,
                                                       ", (", x[["volume"]], ")")
      if (!is.na(x[["number"]])) publication <- paste0(publication,
                                                       ", ", x[["number"]])
      if (!is.na(x[["pages"]])) publication <- paste0(publication,
                                                      ", _pp. ", x[["pages"]], "_")
      if (!is.na(x[["doi"]])) publication <- paste0(publication,
                                                    ", ", paste0("https://doi.org/",
                                                                 x[["doi"]]))

      write(paste0("publication: \"", publication,"\""), fileConn, append = T)
      write(paste0("publication_short: \"", publication,"\""),fileConn, append = T)

      # # Abstract and optional shortened version.
      # if (abstract) {
      #   write(paste0("abstract = \"", x[["abstract"]],"\""), fileConn, append = T)
      # } else {
      #   write("abstract: \"\"", fileConn, append = T)
      # }
      # write(paste0("abstract_short: \"","\""), fileConn, append = T)

      # other possible fields are kept empty. They can be customized later by
      # editing the created md

      # write("image_preview: \"\"", fileConn, append = T)
      # write("selected: false", fileConn, append = T)
      # write("projects: []", fileConn, append = T)
      write(paste0("tags: [",x[["keywords"]],"]"), fileConn, append = T)
      # #links
      # write("url_pdf: \"\"", fileConn, append = T)
      # write("url_preprint: \"\"", fileConn, append = T)
      # write("url_code: \"\"", fileConn, append = T)
      # write("url_dataset: \"\"", fileConn, append = T)
      # write("url_project: \"\"", fileConn, append = T)
      # write("url_slides: \"\"", fileConn, append = T)
      # write("url_video: \"\"", fileConn, append = T)
      # write("url_poster: \"\"", fileConn, append = T)
      # write("url_source: \"\"", fileConn, append = T)
      # #other stuff
      # write("math: true", fileConn, append = T)
      # write("highlight: true", fileConn, append = T)
      # # Featured image
      # write("[header]", fileConn, append = T)
      # write("image: \"\"", fileConn, append = T)
      # write("caption: \"\"", fileConn, append = T)

      write("---", fileConn, append = T)
    }
  }
  # apply the "create_md" function over the publications list to generate
  # the different "md" files.

  apply(mypubs, FUN = function(x) create_md(x), MARGIN = 1)
}

bibtex_2academic(bibfile  = "~/Dropbox/mine.bib",
                 outfold   = "content/publication",
                 abstract  = FALSE,
                 overwrite = TRUE)
