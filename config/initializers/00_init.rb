PLAN_CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'plans.yml'))
$chargebee = ChargeBee.configure(site: ENV['CHARGEBEE_SITE'], api_key: ENV['CHARGEBEE_API_KEY'])
