ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Load environment variables from .env in development/test if dotenv is available
begin
  require "dotenv/load"
rescue LoadError
  # dotenv not available (e.g., production); ignore
end
