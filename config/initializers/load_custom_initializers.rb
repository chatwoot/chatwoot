# frozen_string_literal: true

# Load CommMate custom initializers from custom/config/initializers/
# This allows keeping CommMate initializers separate while still loading them
custom_initializers_path = Rails.root.join('custom/config/initializers')

if Dir.exist?(custom_initializers_path)
  Dir[custom_initializers_path.join('*.rb')].sort.each do |initializer|
    Rails.logger.info "Loading CommMate initializer: #{File.basename(initializer)}" if Rails.logger
    load initializer
  end
end
