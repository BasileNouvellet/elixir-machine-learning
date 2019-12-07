import Config

config :crawly,
  # Close spider if it extracts less than 10 items per minute
  closespider_timeout: 10,
  # Start 16 concurrent workers per domain
  concurrent_requests_per_domain: 16,
  follow_redirects: true,
  # Define item structure (required fields)
  item: [
    :id,
    :title,
    :brand,
    :images
    # :category,
    # :description
  ],
  # Define item identifyer (used to filter out duplicated items)
  item_id: :id,
  # Define item pipelines
  pipelines: [
    Crawly.Pipelines.Validate,
    Crawly.Pipelines.DuplicatesFilter,
    Crawly.Pipelines.JSONEncoder
  ],
  base_store_path: "tmp/"

import_config "#{Mix.env()}.exs"
