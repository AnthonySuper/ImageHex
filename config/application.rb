require File.expand_path('../boot', __FILE__)


# Instead of 'rails/all', require these:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

##
# Add the Markdown Handler in '../lib/handlers/'.
# For use on the About and FAQ pages.
require_relative '../lib/handlers/markdown_handler.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ImageHex
  class Application < Rails::Application
    config.react.addons = true
    config.active_record.raise_in_transactional_callbacks = true

    config.autoload_paths << Rails.root.join("lib")
    config.eager_load_paths << Rails.root.join("lib")
    routes.default_url_options[:host] = "localhost"

    # Default host URL for links in emails.
    config.action_mailer.default_url_options = { host: 'https://www.imagehex.com' }

    # Use vanilla JavaScript for the JavaScript engine in generators.
    config.generators.javascript_engine :js

    # Add the fonts folder to the paths used by the Asset Pipeline.
    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "UTC"

    # Custom i18n routes.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
  end
end
