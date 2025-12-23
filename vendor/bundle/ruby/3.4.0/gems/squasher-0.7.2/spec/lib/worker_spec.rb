require 'spec_helper'
require 'tempfile'

describe Squasher::Worker do
  context 'failed on #check!' do
    let(:worker) { described_class.new(Time.new(2012, 6, 20)) }

    specify 'command was run not in application root' do
      allow_any_instance_of(Squasher::Config).to receive(:migrations_folder?).and_return(false)

      expect_exit_with(:migration_folder_missing)
    end

    specify 'db configuration is invalid' do
      allow_any_instance_of(Squasher::Config).to receive(:dbconfig?).and_return(false)

      expect_exit_with(:dbconfig_invalid)
    end

    specify 'matched migrations was not found' do
      expect_exit_with(:no_migrations, :date => "2012/06/20")
    end

    def expect_exit_with(*args)
      expect(Squasher).to receive(:error).with(*args).and_call_original
      expect { worker.process }.to raise_error(SystemExit)
    end
  end

  it 'creates a new squashed migration & remove selected migrations' do
    worker = described_class.new(Time.new(2014))
    allow(worker).to receive(:under_squash_env).and_yield.and_return(true)
    new_migration_path = File.join(Dir.tmpdir, 'init_schema.rb')
    allow_any_instance_of(Squasher::Config).to receive(:migration_file).with('20131213090719', :init_schema).and_return(new_migration_path)

    expect(FileUtils).to receive(:rm).with(File.join(fake_root, 'db', 'migrate', '20131205160936_first_migration.rb'))
    expect(FileUtils).to receive(:rm).with(File.join(fake_root, 'db', 'migrate', '20131213090719_second_migration.rb'))
    expect(Squasher).to receive(:ask).with(:keep_database).and_return(false)
    expect(Squasher).to receive(:rake).with("db:drop")
    expect(Squasher).to receive(:ask).with(:apply_clean).and_return(true)
    expect(Squasher).to receive(:clean)

    worker.process

    expect(File.exist?(new_migration_path)).to be_truthy
    File.open(new_migration_path) do |stream|
      content = stream.read
      expect(content).to include("InitSchema")
      expect(content).to include('create_table "managers" do |t|')
    end
  end

  context 'with flags' do
    before do
      Squasher.instance_variable_set(:@config, Squasher::Config.new)
    end

    specify 'the sql mode' do
      Squasher.config.set(:sql, true)
      worker = described_class.new(Time.new(2014))
      allow(worker).to receive(:under_squash_env).and_yield.and_return(true)
      new_migration_path = File.join(Dir.tmpdir, 'init_schema.rb')
      allow_any_instance_of(Squasher::Config).to receive(:migration_file).with('20131213090719', :init_schema).and_return(new_migration_path)
      expect(FileUtils).to receive(:rm).with(File.join(fake_root, 'db', 'migrate', '20131205160936_first_migration.rb'))
      expect(FileUtils).to receive(:rm).with(File.join(fake_root, 'db', 'migrate', '20131213090719_second_migration.rb'))

      expect(Squasher).to receive(:ask).with(:keep_database).and_return(false)
      expect(Squasher).to receive(:rake).with("db:drop")
      expect(Squasher).to receive(:ask).with(:apply_clean).and_return(false)
      worker.process

      expect(File.exist?(new_migration_path)).to be_truthy
      File.open(new_migration_path) do |stream|
        content = stream.read
        expect(content.strip).to eq(%q{
class InitSchema < ActiveRecord::Migration
  def up
    execute %q{
    CREATE TABLE cities (
      id integer NOT NULL,
      name character varying,
      created_at timestamp without time zone NOT NULL,
      updated_at timestamp without time zone NOT NULL,
    );
    CREATE TABLE managers (
      id integer NOT NULL,
      email character varying,
      password_digest character varying,
      created_at timestamp without time zone NOT NULL,
      updated_at timestamp without time zone NOT NULL,
      CONSTRAINT email_format CHECK (email ~* '^.+@.+\..+')
    );
    CREATE TABLE offices (
      id integer NOT NULL,
      name character varying,
      address character varying,
      phone character varying,
      description text,
      capacity integer,
      manager_id integer,
      city_id integer,
      created_at timestamp without time zone NOT NULL,
      updated_at timestamp without time zone NOT NULL
    );
    }
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end
        }.strip
      )
      end
    end

    specify 'the dry mode' do
      Squasher.config.set(:dry, nil)
      worker = described_class.new(Time.new(2014))
      allow(worker).to receive(:under_squash_env).and_yield.and_return(true)
      expect(Squasher).to receive(:tell).with(:dry_mode_finished).and_call_original
      expect(Squasher).to receive(:ask).with(:keep_database).and_return(false)
      expect(Squasher).to receive(:rake).with("db:drop")
      expect(Squasher).to receive(:ask).with(:apply_clean).and_return(false)
      worker.process
    end

    specify 'reuse of an existing database' do
      Squasher.config.set(:reuse, nil)
      worker = described_class.new(Time.new(2014))
      expect(Squasher).to receive(:tell).with(:db_reuse).and_call_original
      expect(Squasher).not_to receive(:rake).with("db:drop db:create", :db_create)
      allow(Squasher).to receive(:rake).with("db:migrate VERSION=20131213090719", :db_migrate).and_return(false)
      worker.process
    end
  end
end
