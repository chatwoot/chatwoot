require 'ostruct'
require 'fileutils'
require 'active_record'
require 'hair_trigger/base'
require 'hair_trigger/migrator'
require 'hair_trigger/adapter'
require 'hair_trigger/schema_dumper'
require 'hair_trigger/railtie' if defined?(Rails::Railtie)

module HairTrigger

  autoload :Builder, 'hair_trigger/builder'
  autoload :MigrationReader, 'hair_trigger/migration_reader'

  class << self
    attr_writer :model_path, :schema_rb_path, :migration_path

    def current_triggers
      # see what the models say there should be
      canonical_triggers = models.map(&:triggers).flatten.compact
      canonical_triggers.each(&:prepare!) # interpolates any vars so we match the migrations
    end

    def models
      if defined?(Rails)
        Rails.application.eager_load!
      else
        Dir[model_path + '/*rb'].each do |model|
          class_name = model.sub(/\A.*\/(.*?)\.rb\z/, '\1').camelize
          next unless File.read(model) =~ /^\s*trigger[\.\(]/
          begin
            require "./#{model}" unless Object.const_defined?(class_name)
          rescue StandardError, LoadError
            raise "unable to load #{class_name} and its trigger(s)"
          end
        end
      end
      ActiveRecord::Base.descendants
    end

    def migrator
      if ActiveRecord::VERSION::STRING >= "7.1."
        connection = ActiveRecord::Tasks::DatabaseTasks.migration_connection
        schema_migration = connection.schema_migration
        migrations = ActiveRecord::MigrationContext.new(migration_path, schema_migration).migrations
        ActiveRecord::Migrator.new(:up, migrations, schema_migration, ActiveRecord::InternalMetadata.new(connection))
      else
        migrations = ActiveRecord::MigrationContext.new(migration_path, ActiveRecord::SchemaMigration).migrations
        ActiveRecord::Migrator.new(:up, migrations, ActiveRecord::SchemaMigration)
      end
    end

    def current_migrations(options = {})
      if options[:in_rake_task]
        options[:include_manual_triggers] = true
        options[:schema_rb_first] = true
        options[:skip_pending_migrations] = true
      end

      # if we're in a db:schema:dump task (explicit or kicked off by db:migrate),
      # we evaluate the previous schema.rb (if it exists), and then all applied
      # migrations in order (even ones older than schema.rb). this ensures we
      # handle db:migrate:down scenarios correctly
      #
      # if we're not in such a rake task (i.e. we just want to know what
      # triggers are defined, whether or not they are applied in the db), we
      # evaluate all migrations along with schema.rb, ordered by version
      migrator = self.migrator
      migrated = migrator.migrated rescue []
      migrations = []
      migrator.migrations.each do |migration|
        next if options[:skip_pending_migrations] && !migrated.include?(migration.version)
        triggers = MigrationReader.get_triggers(migration, options)
        migrations << [migration, triggers] unless triggers.empty?
      end

      if previous_schema = (options.has_key?(:previous_schema) ? options[:previous_schema] : File.exist?(schema_rb_path) && File.read(schema_rb_path))
        base_triggers = MigrationReader.get_triggers(previous_schema, options)
        unless base_triggers.empty?
          version = (previous_schema =~ /ActiveRecord::Schema(\[\d\.\d\])?\.define\(version\: (.*)\)/) && $2.to_i
          migrations.unshift [OpenStruct.new({:version => version}), base_triggers]
        end
      end

      migrations = migrations.sort_by{|(migration, triggers)| migration.version} unless options[:schema_rb_first]

      all_builders = []
      migrations.each do |(migration, triggers)|
        triggers.each do |new_trigger|
          # if there is already a trigger with this name, delete it since we are
          # either dropping it or replacing it
          new_trigger.prepare!
          all_builders.delete_if{ |(n, t)| t.prepared_name == new_trigger.prepared_name }
          all_builders << [migration.name, new_trigger] unless new_trigger.options[:drop]
        end
      end

      all_builders
    end

    def migrations_current?
      current_migrations.map(&:last).sort.eql? current_triggers.sort
    end

    def generate_migration(silent = false)
      begin
        canonical_triggers = current_triggers
      rescue
        $stderr.puts $!
        exit 1
      end

      migrations = current_migrations
      migration_names = migrations.map(&:first)
      existing_triggers = migrations.map(&:last)

      up_drop_triggers = []
      up_create_triggers = []
      down_drop_triggers = []
      down_create_triggers = []

      # see which triggers need to be dropped
      existing_triggers.each do |existing|
        next if canonical_triggers.any?{ |t| t.prepared_name == existing.prepared_name }
        up_drop_triggers.concat existing.drop_triggers
        down_create_triggers << existing
      end

      # see which triggers need to be added/replaced
      (canonical_triggers - existing_triggers).each do |new_trigger|
        up_create_triggers << new_trigger
        down_drop_triggers.concat new_trigger.drop_triggers
        if existing = existing_triggers.detect{ |t| t.prepared_name == new_trigger.prepared_name }
          # it's not sufficient to rely on the new trigger to replace the old
          # one, since we could be dealing with trigger groups and the name
          # alone isn't sufficient to know which component triggers to remove
          up_drop_triggers.concat existing.drop_triggers
          down_create_triggers << existing
        end
      end

      return if up_drop_triggers.empty? && up_create_triggers.empty?

      migration_name = infer_migration_name(migration_names, up_create_triggers, up_drop_triggers)
      migration_version = infer_migration_version(migration_name)
      file_name = migration_path + '/' + migration_version + "_" + migration_name.underscore + ".rb"
      FileUtils.mkdir_p migration_path
      File.open(file_name, "w") { |f| f.write <<-RUBY }
# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class #{migration_name} < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]
  def up
    #{(up_drop_triggers + up_create_triggers).map{ |t| t.to_ruby('    ') }.join("\n\n").lstrip}
  end

  def down
    #{(down_drop_triggers + down_create_triggers).map{ |t| t.to_ruby('    ') }.join("\n\n").lstrip}
  end
end
      RUBY
      file_name
    end

    def infer_migration_name(migration_names, create_triggers, drop_triggers)
      if create_triggers.size > 0
        migration_base_name = "create trigger#{create_triggers.size > 1 ? 's' : ''} "
        name_parts = create_triggers.map { |t| [t.options[:table], t.options[:events].join(" ")].join(" ") }.uniq
        part_limit = 4
      else
        migration_base_name = "drop trigger#{drop_triggers.size > 1 ? 's' : ''} "
        name_parts = drop_triggers.map { |t| t.options[:table] }
        part_limit = 6
      end

      # don't let migration names get too ridiculous
      if name_parts.size > part_limit
        migration_base_name << " multiple tables"
      else
        migration_base_name << name_parts.join(" OR ")
      end

      migration_base_name = migration_base_name.
        downcase.
        gsub(/[^a-z0-9_]/, '_').
        gsub(/_+/, '_').
        camelize

      name_version = nil
      while migration_names.include?("#{migration_base_name}#{name_version}")
        name_version = name_version.to_i + 1
      end

      "#{migration_base_name}#{name_version}"
    end

    def timestamped_migrations
      if ActiveRecord::VERSION::STRING >= "7.0."
        ActiveRecord.timestamped_migrations
      else
        ActiveRecord::Base.timestamped_migrations
      end
    end

    def infer_migration_version(migration_name)
      timestamped_migrations ?
        Time.now.getutc.strftime("%Y%m%d%H%M%S") :
        Dir.glob(migration_path + '/*rb').
          map{ |f| f.gsub(/.*\/(\d+)_.*/, '\1').to_i}.
          inject(0){ |curr, i| i > curr ? i : curr } + 1
    end

    def model_path
      @model_path ||= 'app/models'
    end

    def schema_rb_path
      @schema_rb_path ||= 'db/schema.rb'
    end

    def migration_path
      @migration_path ||= 'db/migrate'
    end

    def adapter_name_for(adapter)
      adapter.adapter_name.downcase.sub(/\d$/, '').to_sym
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send :extend, HairTrigger::Base
  ActiveRecord::Migration.send :include, HairTrigger::Migrator
  ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval { include HairTrigger::Adapter }
  ActiveRecord::SchemaDumper.class_eval { include HairTrigger::SchemaDumper }
end
