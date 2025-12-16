install.packages(c("ggplot2","tidyverse", "dplyr"))
library("ggplot2", "tidyverse", "dplyr")
setwd("Documents/UNI AND SCHOOL DOCS/MED7")
data1 <- read.csv("synthetic_evaluation_data_with_categories.csv", header = TRUE)

###### DATA CLEANING
# Folder where  15 txt files are
folder <- "/Users/julia/Documents/UNI AND SCHOOL DOCS/MED7/Data"
dir.exists(folder)
# List all txt files
files <- list.files(folder, pattern = "\\.txt$", full.names = TRUE)


process_file <- function(file_path) {
  lines <- readLines(file_path)
  
  # Extract participant from first line
  participant <- strsplit(lines[1], " - ")[[1]][1]
  
  # Find lines with choices
  choice_lines <- grep("Defensive|Honest", lines)
  
  # Prepare storage
  df <- data.frame(
    Participant = character(0),
    Choice = character(0),
    Stress = numeric(0),
    Relax = numeric(0),
    Baseline = numeric(0)
  )
  
  for (i in choice_lines) {
    choice <- strsplit(lines[i], " ")[[1]][1]  # first word
    metrics_line <- lines[i + 1]
    
    # Extract numeric values
    stress <- as.numeric(sub(".*Stress: ([0-9]+).*", "\\1", metrics_line))
    relax  <- as.numeric(sub(".*Relax: ([0-9]+).*", "\\1", metrics_line))
    baseline  <- as.numeric(sub(".*Baseline: ([0-9]+).*", "\\1", metrics_line))
    
    # Append
    df <- rbind(df, data.frame(
      Participant = participant,
      Choice = choice,
      Stress = stress,
      Relax = relax,
      Baseline = baseline
    ))
  }
  
  return(df)
}

all_data <- do.call(rbind, lapply(files, process_file))



participants <- unique(all_data$Participant)
most_choice_list <- list()

for (p in participants) {
  sub_df <- all_data[all_data$Participant == p, ]
  choice_counts <- table(sub_df$Choice)
  
  max_count <- max(choice_counts)
  top_choices <- names(choice_counts[choice_counts == max_count])
  
  if (length(top_choices) > 1) {
    most_choice_list[[p]] <- "Mixed"
  } else {
    most_choice_list[[p]] <- top_choices
  }
}

# Create a data frame
most_choice_df <- data.frame(
  Participant = names(most_choice_list),
  MostChoice = unlist(most_choice_list),
  stringsAsFactors = FALSE
)
all_data$MostChoice <- most_choice_df$MostChoice[match(all_data$Participant, most_choice_df$Participant)]

# Create new column based on Stress vs Relax
all_data$State <- ifelse(
  all_data$Stress > all_data$Relax, "Stressed",
  ifelse(all_data$Stress == 0 & all_data$Relax == 0, "Relaxed", "Relaxed")
)

participants <- unique(all_data$Participant)
majority_state_list <- list()

for (p in participants) {
  sub_df <- all_data[all_data$Participant == p, ]
  
  # Count how many Stressed and Relaxed
  counts <- table(sub_df$State)
  
  if (length(counts) == 1) {
    # All the same
    majority_state_list[[p]] <- names(counts)
  } else if (counts["Stressed"] == counts["Relaxed"]) {
    # Tie 2/2
    majority_state_list[[p]] <- "Mixed"
  } else if (counts["Stressed"] > counts["Relaxed"]) {
    majority_state_list[[p]] <- "Stressed"
  } else {
    majority_state_list[[p]] <- "Relaxed"
  }
}

# Build dataframe
majority_state_df <- data.frame(
  Participant = names(majority_state_list),
  MajorityState = unlist(majority_state_list),
  stringsAsFactors = FALSE
)

# Merge back into all_data
all_data$MajorityState <- majority_state_df$MajorityState[match(all_data$Participant, majority_state_df$Participant)]

all_data$profile <- paste0(all_data$MostChoice, all_data$MajorityState)

# Create empty columns for percentages
all_data$StressPerc <- NA
all_data$RelaxPerc <- NA

# Get unique participants
participants <- unique(all_data$Participant)

for (p in participants) {
  # Subset rows for this participant
  sub_idx <- which(all_data$Participant == p)
  sub_df <- all_data[sub_idx, ]
  
  # Sum Stress and Relax across all 4 rows
  total_stress <- sum(sub_df$Stress, na.rm = TRUE)
  total_relax  <- sum(sub_df$Relax, na.rm = TRUE)
  total_sum    <- total_stress + total_relax
  
  # Avoid division by zero
  if (total_sum == 0) {
    all_data$StressPerc[sub_idx] <- 0
    all_data$RelaxPerc[sub_idx]  <- 0
  } else {
    # Compute percentages per row
    all_data$StressPerc[sub_idx] <- sub_df$Stress / total_sum * 100
    all_data$RelaxPerc[sub_idx]  <- sub_df$Relax / total_sum * 100
  }
}

# Create a new dataframe for participant-level totals
participant_perc <- data.frame(
  Participant = unique(all_data$Participant),
  TotalStressPerc = NA,
  TotalRelaxPerc = NA,
  stringsAsFactors = FALSE
)

# Loop over participants
for (i in seq_along(participant_perc$Participant)) {
  p <- participant_perc$Participant[i]
  sub_df <- all_data[all_data$Participant == p, ]
  
  # Sum percentages across the 4 rows
  participant_perc$TotalStressPerc[i] <- sum(sub_df$StressPerc, na.rm = TRUE)
  participant_perc$TotalRelaxPerc[i]  <- sum(sub_df$RelaxPerc, na.rm = TRUE)
}

# View result
# Create new columns in all_data
all_data$TotalStressPerc <- NA
all_data$TotalRelaxPerc <- NA

# Fill each row for each participant with their totals
for (p in unique(all_data$Participant)) {
  sub_idx <- which(all_data$Participant == p)
  
  total_stress <- participant_perc$TotalStressPerc[participant_perc$Participant == p]
  total_relax  <- participant_perc$TotalRelaxPerc[participant_perc$Participant == p]
  
  all_data$TotalStressPerc[sub_idx] <- total_stress
  all_data$TotalRelaxPerc[sub_idx]  <- total_relax
}

###### TOTAL PINGS ######

# Sum Stress and Relax per participant
participant_totals <- aggregate(cbind(Stress, Relax, Baseline) ~ Participant, data = all_data, FUN = sum)

# Rename columns for clarity
names(participant_totals) <- c("Participant", "TotalStress", "TotalRelax", "Baseline")

# View result
pings <- participant_totals
pings$TotalStress <- as.numeric(pings$TotalStress)
pings$TotalRelax <- as.numeric(pings$TotalRelax)
pings$Baseline <- as.numeric(pings$Baseline)
pings$total <- rowSums( pings[,2:4] )

#########################################################
##################### A N A L Y S I S ###################
#########################################################

summary_table <- table(all_data$MostChoice, all_data$MajorityState)
summary_table
summary_table2 <- table(participant_df$MostChoice)
summary_table2

profile_counts <- as.data.frame(table(all_data$Profile))  # replace participant_df$Profile with your column name

names(profile_counts) <- c("Profile", "Count")
profile_counts




###### T-TEST ON STRESS ACROSS CHOICE GROUPS

# Take the first row per participant (all rows have same totals now)
participant_df <- all_data[!duplicated(all_data$Participant), ]

# Keep only relevant columns
participant_df <- participant_df[, c("Participant", "MostChoice", "TotalStressPerc", "TotalRelaxPerc")]

# Filter to just the two groups you want
subset_df <- participant_df[participant_df$MostChoice %in% c("Defensive", "Honest"), ]

t.test(TotalStressPerc ~ MostChoice, data = subset_df)



plot1 <-  ggplot(all_data) +                                      
  geom_bar(aes(x = MostChoice, fill=MajorityState))
plot2 <-  ggplot(all_data) +                                      
  geom_point(aes(x = TotalRelaxPerc, y = TotalStressPerc, color=MostChoice))

plot2 + theme_minimal()

# Boxplot Stress% by MostChoice
ggplot(all_data, aes(x = MostChoice, y = StressPerc)) +
  geom_boxplot(fill = "lightblue") +
  labs(title = "Stress % by MostChoice", y = "Stress %", x = "MostChoice")

# Violin plot Relax% by MajorityState
ggplot(all_data, aes(x = MajorityState, y = RelaxPerc)) +
  geom_violin(fill = "lightgreen") +
  labs(title = "Relax % by MajorityState", y = "Relax %", x = "MajorityState")

# Stress %
hist(all_data$StressPerc, breaks = 10, col = "lightblue", main = "Distribution of Stress %", xlab = "Stress %")

# Relax %
hist(all_data$RelaxPerc, breaks = 10, col = "lightgreen", main = "Distribution of Relax %", xlab = "Relax %")

# Using aggregate for MostChoice
aggregate(cbind(StressPerc, RelaxPerc) ~ MostChoice, data = all_data, FUN = function(x) c(mean = mean(x), median = median(x), sd = sd(x)))

# Using aggregate for MajorityState
aggregate(cbind(StressPerc, RelaxPerc) ~ MajorityState, data = all_data, FUN = function(x) c(mean = mean(x), median = median(x), sd = sd(x)))

# Add trial number per participant
all_data$Trial <- ave(seq_along(all_data$Participant), all_data$Participant, FUN = function(x) (seq_along(x) - 1) %% 4 + 1)


# Boxplot Stress% by Trial and Choice
ggplot(all_data, aes(x = factor(Trial), y = StressPerc, fill = MostChoice)) +
  geom_boxplot() +
  labs(title = "Stress % by Trial and MostChoice", x = "Trial", y = "Stress %") +
  scale_fill_brewer(palette = "Set1")

ggplot(all_data, aes(x = factor(Trial), y = RelaxPerc, fill = MostChoice)) +
  geom_boxplot() +
  labs(title = "Relax % by Trial and MostChoice", x = "Trial", y = "Relax %") +
  scale_fill_brewer(palette = "Set1")


####################################
######### STRESS PER TRiAL #########
###################################


# Mean Stress % per Trial and MostChoice
stress_summary <- aggregate(StressPerc ~ Trial + MostChoice, data = all_data, FUN = mean)

# Mean Relax % per Trial and MostChoice
relax_summary <- aggregate(RelaxPerc ~ Trial + MostChoice, data = all_data, FUN = mean)

trial_summary <- merge(stress_summary, relax_summary, by = c("Trial", "MostChoice"))
trial_summary

# Make sure Trial is a factor
all_data$Trial <- factor(all_data$Trial)

# Each participant measured 4 times: StressPerc ~ Trial + Error(Participant/Trial)
anova_result <- aov(StressPerc ~ Trial + Error(Participant/Trial), data = all_data)
summary(anova_result)

# Pairwise t-tests with Bonferroni correction
pairwise.t.test(all_data$StressPerc, all_data$Trial, paired = TRUE, p.adjust.method = "bonferroni")


# Summarize mean and standard error per trial
stressMeanPerTrial <- aggregate(StressPerc ~ Trial, data = all_data, FUN = function(x) c(mean = mean(x), se = sd(x)/sqrt(length(x))))
stressMeanPerTrial <- do.call(data.frame, stressMeanPerTrial)  # convert list columns to separate columns
names(stressMeanPerTrial) <- c("Trial", "MeanStress", "SE")
relaxMeanPerTrial <- aggregate(RelaxPerc ~ Trial, data = all_data, FUN = function(x) c(mean = mean(x), se = sd(x)/sqrt(length(x))))
relaxMeanPerTrial <- do.call(data.frame, relaxMeanPerTrial)  # convert list columns to separate columns
names(relaxMeanPerTrial) <- c("Trial", "MeanRelax", "SE")


# STRESS + RELAX MEAN W ERROR BARS PER TRIAL 
ggplot(stressMeanPerTrial, aes(x = Trial, y = MeanStress)) +
  geom_line(group = 1, color = "blue") +
  geom_point(size = 3, color = "blue") +
  geom_errorbar(aes(ymin = MeanStress - SE, ymax = MeanStress + SE), width = 0.2, color = "blue") +
  labs(title = "Mean Stress % per Trial", x = "Trial", y = "Mean Stress %") +
  theme_minimal()

ggplot(relaxMeanPerTrial, aes(x = Trial, y = MeanRelax)) +
  geom_line(group = 1, color = "blue") +
  geom_point(size = 3, color = "blue") +
  geom_errorbar(aes(ymin = MeanRelax - SE, ymax = MeanRelax + SE), width = 0.2, color = "blue") +
  labs(title = "Mean Relax % per Trial", x = "Trial", y = "Mean Relax %") +
  theme_minimal()



ggplot(all_data, aes(x = Trial, y = StressPerc, color = MostChoice, group = MostChoice)) +
  stat_summary(fun = mean, geom = "line") +
  stat_summary(fun = mean, geom = "point") +
  labs(title = "Stress % per Round by Choice", y = "Mean Stress %", x = "Trial")


# Create a matrix: rows = participants, columns = trials
stress_matrix <- reshape(all_data[, c("Participant","Trial","StressPerc")],
                         timevar = "Trial", idvar = "Participant", direction = "wide")

# Set row names
rownames(stress_matrix) <- stress_matrix$Participant

# Remove Participant column for the matrix
stress_matrix <- stress_matrix[, -1]

# Base R heatmap
heatmap(as.matrix(stress_matrix), Rowv = NA, Colv = NA,
        col = colorRampPalette(c("white", "red"))(20),
        main = "Stress % Heatmap", xlab = "Trial", ylab = "Participant")

