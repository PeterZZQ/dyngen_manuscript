library(tidyverse)
library(googledrive)
library(rmarkdown)
library(textreadr)

# copy zotero library if on rcannood's computer
if (Sys.info()[["user"]] == "rcannood") {
  file.copy("~/Workspace/library.bib", "library.bib", overwrite = TRUE)
}

# download as docx instead of txt, because otherwise comments get pushed into the document
httr::set_config(httr::config(http_version = 0)) # avoid http2 framing layer bug
drive <- drive_download(as_id("1BOltsUJBQ8NhF5s9kU_Q470U0U00QblbG8HBgQwEzRE"), type="docx", overwrite=TRUE, path = tempfile())

# read docx
textreadr::read_docx(drive$local_path, remove.empty = FALSE, trim = FALSE) %>%
  str_replace_all("([^ ])(\\[@[^\\]]*\\])", "\\1 \\2") %>% # add spaces before citations
  str_replace_all("^#", "\n#") %>%
  write_lines("manuscript.Rmd")

# render the manuscript
render("manuscript.Rmd")

