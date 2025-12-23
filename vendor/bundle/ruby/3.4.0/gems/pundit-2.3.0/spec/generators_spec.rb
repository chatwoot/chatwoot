# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

require "rails/generators"
require "generators/pundit/install/install_generator"
require "generators/pundit/policy/policy_generator"

RSpec.describe "generators" do
  before(:all) do
    @tmpdir = Dir.mktmpdir

    Dir.chdir(@tmpdir) do
      Pundit::Generators::InstallGenerator.new([], { quiet: true }).invoke_all
      Pundit::Generators::PolicyGenerator.new(%w[Widget], { quiet: true }).invoke_all

      require "./app/policies/application_policy"
      require "./app/policies/widget_policy"
    end
  end

  after(:all) do
    FileUtils.remove_entry(@tmpdir)
  end

  describe "WidgetPolicy", type: :policy do
    permissions :index?, :show?, :create?, :new?, :update?, :edit?, :destroy? do
      it "has safe defaults" do
        expect(WidgetPolicy).not_to permit(double("User"), double("Widget"))
      end
    end

    describe "WidgetPolicy::Scope" do
      describe "#resolve" do
        it "raises a descriptive error" do
          scope = WidgetPolicy::Scope.new(double("User"), double("User.all"))
          expect { scope.resolve }.to raise_error(NotImplementedError, /WidgetPolicy::Scope/)
        end
      end
    end
  end
end
