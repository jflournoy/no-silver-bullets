# Function to check if we're running in a GitHub Action
is_github_action <- function() {
  Sys.getenv("GITHUB_ACTIONS") == "true"
}

# Set custom library path if running locally
if (!is_github_action()) {
  .libPaths("/home/rstudio/R/aarch64-unknown-linux-gnu-library/4.3")
}

library(posterior)
library(brms)
library(kableExtra)
library(memoise)

cm <- cachem::cache_mem(max_size = 5 * 1024^3)

load_model <- memoise(function(model_file) {
  readRDS(file.path('~/code/Developer-Insights-Lab/productivity-project/prod-proj-2/', model_file))
}, cache = cm)

brms_to_draws <- function(x, variables){
  x <- x$fit@sim$samples
  x_subsamples <- lapply(x, \(x) x[, variables])
  x_draws <- posterior::as_draws(x_subsamples)
  return(x_draws)
}

filename_do <- function(filename, do_this){
  if(!file.exists(filename)){
    result <- do_this
    saveRDS(result, filename)
  } else {
    result <- readRDS(filename)
  }
  return(result)
}

make_ct_model_obs_info <- function(model_file){
  filename <- paste0(gsub('\\.\\w+$', '', model_file), '_obs-info.rds')
  ct_model_obs_info <- filename_do(filename, {
    ct_model <- load_model(model_file)
    list(nobs = nobs(ct_model), 
         norgs = ngrps(ct_model)$org_id_fac,
         nusers = ngrps(ct_model)$`org_id_fac:user_id_fac`)
  })
  return(ct_model_obs_info)
}

make_ct_model_draws <- function(model_file, variable_indices, id = '1'){
  filename <- sprintf('%s_draws_id-%s.rds', gsub('\\.\\w+$', '', model_file), id)
  ct_model_obs_info <- filename_do(filename, {
    ct_model <- load_model(model_file)
    brms_to_draws(ct_model, variables(ct_model)[variable_indices])
  })
  
  return(ct_model_obs_info)
}

get_model_varnames <- function(model_file){
  filename <- sprintf('%s_varnames.rds', gsub('\\.\\w+$', '', model_file))
  filename_do(filename, {variables(load_model(model_file))})
}

ct_model_varnames <- get_model_varnames('cycle_time_full_intx_lin_remonth.rds')
ct_model_varnames[37:length(ct_model_varnames)]
ct_model_draws_fe <- make_ct_model_draws('cycle_time_full_intx_lin_remonth.rds', variable_indices = 1:19, id='fe')
ct_model_draws_bs <- make_ct_model_draws('cycle_time_full_intx_lin_remonth.rds', variable_indices = 20:25, id='bs')
ct_model_draws_re <- make_ct_model_draws('cycle_time_full_intx_lin_remonth.rds', variable_indices = 26:32, id='re')
ct_model_draws_sds <- make_ct_model_draws('cycle_time_full_intx_lin_remonth.rds', variable_indices = 33:36, id='sds')
ct_model_draws_allre <- make_ct_model_draws('cycle_time_full_intx_lin_remonth.rds', variable_indices = 37:length(ct_model_varnames), id='allre')
ct_model_obs_info <- make_ct_model_obs_info('cycle_time_full_intx_lin_remonth.rds')

library(ggplot2)
library(showtext)
library(data.table)
font_name <- "Roboto"
font_add_google(font_name)

theme_clean <- theme_minimal() + 
  theme(
    text = element_text(family = font_name),
    strip.text.x = element_blank(),  # Adjust text size for readability
    axis.text.x = element_blank(),            # Remove axis text for clarity
    axis.ticks.x = element_blank(),
    panel.grid.major.x = element_blank(),            # Remove grid lines for simplicity
    panel.grid.minor.x = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(), 
    panel.spacing = unit(0, 'lines')
  )

amod <- load_model('cycle_time_full_intx_lin_remonth.rds')

#Plot a histogram of organization sizes
dat <- as.data.table(amod$data)
org_size <- dat[, .(org_size = nrow(.SD)), by = org_id_fac]

ggplot(org_size, aes(x = org_size)) +
  geom_histogram(binwidth = 20, fill = 'red') +
  labs(x = 'Organization Size',
       y = 'Number of\norganizations') +
  scale_x_continuous(breaks = c(100, 1000, 2000)) + 
  theme_clean + 
  theme(axis.text.x = element_text())
ggsave('plots/org_size_hist.png', width = 3, height = 2, dpi = 300)
