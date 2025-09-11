# frozen_string_literal: true

module Enterprise
  class Railtie < Rails::Railtie
    rake_tasks do
      Dir[File.expand_path('../tasks/**/*.rake', __dir__)].each { |f| load f }
    end
  end
end
