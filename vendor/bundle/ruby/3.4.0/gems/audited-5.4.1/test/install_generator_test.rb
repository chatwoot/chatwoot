require "test_helper"

require "generators/audited/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  destination File.expand_path("../../tmp", __FILE__)
  setup :prepare_destination
  tests Audited::Generators::InstallGenerator

  test "generate migration with 'text' type for audited_changes column" do
    run_generator

    assert_migration "db/migrate/install_audited.rb" do |content|
      assert_includes(content, "class InstallAudited")
      assert_includes(content, "t.column :audited_changes, :text")
    end
  end

  test "generate migration with 'jsonb' type for audited_changes column" do
    run_generator %w[--audited-changes-column-type jsonb]

    assert_migration "db/migrate/install_audited.rb" do |content|
      assert_includes(content, "class InstallAudited")
      assert_includes(content, "t.column :audited_changes, :jsonb")
    end
  end

  test "generate migration with 'json' type for audited_changes column" do
    run_generator %w[--audited-changes-column-type json]

    assert_migration "db/migrate/install_audited.rb" do |content|
      assert_includes(content, "class InstallAudited")
      assert_includes(content, "t.column :audited_changes, :json")
    end
  end

  test "generate migration with 'string' type for user_id column" do
    run_generator %w[--audited-user-id-column-type string]

    assert_migration "db/migrate/install_audited.rb" do |content|
      assert_includes(content, "class InstallAudited")
      assert_includes(content, "t.column :user_id, :string")
    end
  end

  test "generate migration with 'uuid' type for user_id column" do
    run_generator %w[--audited-user-id-column-type uuid]

    assert_migration "db/migrate/install_audited.rb" do |content|
      assert_includes(content, "class InstallAudited")
      assert_includes(content, "t.column :user_id, :uuid")
    end
  end

  test "generate migration with correct AR migration parent" do
    run_generator

    assert_migration "db/migrate/install_audited.rb" do |content|
      assert_includes(content, "class InstallAudited < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]\n")
    end
  end
end
