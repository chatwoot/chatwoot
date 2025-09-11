# frozen_string_literal: true

class Enterprise::Railtie < Rails::Railtie
  rake_tasks do
    Dir[File.expand_path('../tasks/**/*.rake', __dir__)].each { |f| load f }
  end
end
