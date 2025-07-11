
library(connectapi)

# Connect to old and new servers

old_client <- connect("https://dap-prd2-connect.azure.defra.cloud/", api_key = "xdfXrE3yD2Ct0hVhQgkr8kHVdmuKfAO2")

new_client <- connect("http://10.178.101.5", api_key = "xdfXrE3yD2Ct0hVhQgkr8kHVdmuKfAO2")

# Create local bundle directory

bundle_dir <- tempfile("bundle_dir_")

dir.create(bundle_dir)

# Helper function to detect R apps

is_r_app <- function(app) {
  
  grepl("shiny|rmarkdown|quarto", tolower(app$app_mode)) || grepl("\\.Rmd|\\.R$", app$source)
  
}

# Get all content on old server

all_content <- get_content(old_client)

# Filter to only R-based apps

r_apps <- Filter(is_r_app, all_content)

for (app in r_apps) {
  
  cat("Migrating:", app$name, "(", app$guid, ")\n")
  
  # Get all historical bundles for this app
  
  bundles <- get_bundle(app)
  
  if (length(bundles) == 0) {
    
    cat("No bundles found. Skipping.\n")
    
    next
    
  }
  
  # Create app on new server (once)
  
  new_app <- create_empty_content(
    
    client = new_client,
    
    name = app$name,
    
    title = app$title,
    
    access_type = app$access_type
    
  )
  
  # Upload and deploy each historical bundle
  
  for (i in seq_along(bundles)) {
    
    bundle <- bundles[[i]]
    
    bundle_path <- file.path(bundle_dir, paste0(app$guid, "_v", i, ".tar.gz"))
    
    download_bundle(bundle, bundle_path)
    
    cat("Uploading version", i, "...\n")
    
    uploaded <- upload_bundle(new_app, bundle_path)
    
    deploy(new_app, uploaded)
    
  }
  
  cat("Done migrating", app$name, "\n\n")
  
}

cat("Migration complete for all R apps!\n")
