require "sidekiq/cron/web_extension"
require "sidekiq/cron/job"

if defined?(Sidekiq::Web)
  Sidekiq::Web.register Sidekiq::Cron::WebExtension
  Sidekiq::Web.tabs["Cron"] = "cron"
end
