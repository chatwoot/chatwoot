require 'hair_trigger'
require 'rails'
module HairTrigger
  class Railtie < Rails::Railtie
    railtie_name :hair_trigger

    rake_tasks do
      load "tasks/hair_trigger.rake"
    end
  end
end
