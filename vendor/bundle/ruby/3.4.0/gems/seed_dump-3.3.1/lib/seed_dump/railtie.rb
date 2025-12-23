class SeedDump
  class Railtie < Rails::Railtie

    rake_tasks do
      load "tasks/seed_dump.rake"
    end

  end
end
