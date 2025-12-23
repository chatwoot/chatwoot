module AuditedSpecHelpers
  def create_user(attrs = {})
    Models::ActiveRecord::User.create({name: "Brandon", username: "brandon", password: "password", favourite_device: "Android Phone"}.merge(attrs))
  end

  def build_user(attrs = {})
    Models::ActiveRecord::User.new({name: "darth", username: "darth", password: "noooooooo"}.merge(attrs))
  end

  def create_versions(n = 2, attrs = {})
    Models::ActiveRecord::User.create(name: "Foobar 1", **attrs).tap do |u|
      (n - 1).times do |i|
        u.update_attribute :name, "Foobar #{i + 2}"
      end
      u.reload
    end
  end

  def run_migrations(direction, migrations_paths, target_version = nil)
    if rails_below?("5.2.0.rc1")
      ActiveRecord::Migrator.send(direction, migrations_paths, target_version)
    elsif rails_below?("6.0.0.rc1")
      ActiveRecord::MigrationContext.new(migrations_paths).send(direction, target_version)
    else
      ActiveRecord::MigrationContext.new(migrations_paths, ActiveRecord::SchemaMigration).send(direction, target_version)
    end
  end

  def rails_below?(rails_version)
    Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new(rails_version)
  end
end
