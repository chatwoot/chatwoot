namespace :db do
  desc "Creates a database migration for any newly created/modified/deleted triggers in the models"
  task :generate_trigger_migration => :environment do
    if file_name = HairTrigger.generate_migration
      puts "Generated #{file_name}"
    else
      puts "Nothing to do"
    end
  end

  namespace :schema do
    desc "Create a db/schema.rb file that can be portably used against any DB supported by AR"
    task :dump => :environment do
      require 'active_record/schema_dumper'
      filename = ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb"
      ActiveRecord::SchemaDumper.previous_schema = File.exist?(filename) ? File.read(filename) : nil
      File.open(filename, "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
      Rake::Task["db:schema:dump"].reenable
    end
  end
end
