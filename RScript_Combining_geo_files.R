# ============================================================================
# MEDICARE PART D GEOGRAPHIC FILE COMBINER
# Combines multiple yearly CMS Medicare Part D CSV files into one dataset
# ============================================================================
install.packages("dplyr")
install.packages("readr")

# Load libraries (install first if needed with: install.packages(c("dplyr", "readr")))
library(dplyr)
library(readr)

# USER SETTINGS – MODIFY THESE PATHS

input_dir <- "B:/UNCC Sem III/Capstone/Medicare Part D Prescribers - by Geography and Drug/Geo files"
output_file <- "B:/UNCC Sem III/Capstone/Medicare Part D Prescribers - by Geography and Drug/Combined_Medicare_2017_2023.csv"
# Get all CSV files
files <- list.files(input_dir, pattern = "MUP_DPR_.*\\.csv$", full.names = TRUE)
cat("Found", length(files), "files\n\n")

# Read and combine
combined_data <- lapply(seq_along(files), function(i) {
  
  # Extract year from filename (DY17 -> 2017, DY18 -> 2018, etc.)
  year <- as.integer(paste0("20", sub(".*DY(\\d{2}).*", "\\1", basename(files[i]))))
  
  cat(sprintf("[%d/%d] Reading %s (Year: %d)\n", i, length(files), basename(files[i]), year))
  
  # Read file and add year column
  df <- read_csv(files[i], col_types = cols(.default = "c"), show_col_types = FALSE)
  df$Data_Year <- year
  
  return(df)
  
}) %>% bind_rows()

# Save the combined file
cat("\nSaving combined file...\n")
write_csv(combined_data, output_file)

# Summary
cat("\n✓ DONE!\n")
cat(sprintf("Total rows: %s\n", format(nrow(combined_data), big.mark = ",")))
cat(sprintf("Years: %s\n", paste(sort(unique(combined_data$Data_Year)), collapse = ", ")))
cat(sprintf("Output: %s\n", output_file))

# Preview- Validation Check

cat("\nFirst few rows:\n")
print(head(combined_data, 5))

# Count rows in original files
original_files <- list.files(input_dir, pattern = "MUP_DPR_.*\\.csv$", full.names = TRUE)

cat("\n=== COMPARING ORIGINAL vs COMBINED ===\n\n")

# Count rows in each original file
original_counts <- sapply(original_files, function(f) {
  year <- as.integer(paste0("20", sub(".*DY(\\d{2}).*", "\\1", basename(f))))
  row_count <- nrow(read_csv(f, col_types = cols(.default = "c"), show_col_types = FALSE))
  return(c(Year = year, Rows = row_count))
})

original_df <- data.frame(t(original_counts))
names(original_df) <- c("Year", "Original_Rows")
original_df$Year <- as.integer(original_df$Year)

# Count rows in combined file by year
combined_counts <- combined_data %>%
  group_by(Data_Year) %>%
  summarise(Combined_Rows = n(), .groups = "drop")

# Merge and compare
comparison <- merge(original_df, combined_counts, 
                    by.x = "Year", by.y = "Data_Year", all = TRUE)
comparison$Match <- comparison$Original_Rows == comparison$Combined_Rows

print(comparison)

cat("\nAll years match:", all(comparison$Match, na.rm = TRUE), "\n")