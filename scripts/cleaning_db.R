###############################################################################
# Cleaning database: from raw (ztree output) to clean
###############################################################################

library(tidyverse)

db.clean <- read_csv(here::here('data/DB_raw.csv'), col_names = T) %>%
  filter(trial == 0,   
         !(performance == 3),
         !(framing == 3)) %>% 
  mutate(group_id = interaction(union, group, framing, sep=''),
         id = interaction(id, union, framing, sep=''),
         round = ifelse(round <= 13, round - 3, round - 6),
         overext_observed = ifelse(observer == 1, overext_observed, NA),
         report= ifelse(observer == 1, report, NA),
         punished = ifelse(observer == 0, punished, NA),
         observer = ifelse(round < 11, NA, observer)) %>% 
  select(union, 
         performance, 
         framing, 
         id, 
         group_id,
         round,
         overextraction,
         observer,
         overext_observed,
         report,
         punished,
         round_profit)


write.csv(db.clean, (here::here('data/db.clean.csv')), row.names = F)
