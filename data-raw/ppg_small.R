## code to prepare `ppg_small` dataset goes here

# Goal is to construct smaller test dataset that includes all taxonomic ranks
# as in the full dataset and passes validation under the same conditions.
# So we don't need to download the full dataset every time for developing
# the app.

library(dplyr)
library(assertr)

# download full dataset
full_data <- load_data(data_source = "download")

# get list of taxonomic ranks
ranks <- full_data |>
  distinct(taxonRank) |>
  pull(taxonRank)

# filter data to only genus and above
data_genus_above <- full_data |>
  filter(taxonRank %in% c("genus", "tribe", "subfamily", "family", "order"))

# filter to accepted infraspecific
data_subspecies <- full_data |>
  filter(taxonRank %in% c("subspecies", "variety", "form")) |>
  filter(taxonomicStatus == "accepted")

# get parents of accepted infraspecific
data_species <- data_subspecies |>
  select(taxonID = parentNameUsageID) |>
  unique() |>
  left_join(full_data, relationship = "one-to-one", by = join_by(taxonID))

# combine into test dataset
ppg_small <-
  bind_rows(data_subspecies, data_species, data_genus_above) |>
  # TODO remove this once `modifiedBy` and `modifiedByID` are in original PPG
  dplyr::mutate(
    modified = as.character(modified),
    modifiedBy = NA_character_,
    modifiedByID = NA_character_
  ) |>
  # should pass using the same checks as the full dataset
  dwctaxon::dct_validate(
    valid_tax_status = "variant, accepted, synonym, ambiguous synonym",
    check_sci_name = FALSE
  ) |>
  assertr::assert(in_set(ranks), taxonRank)

usethis::use_data(ppg_small, overwrite = TRUE)
