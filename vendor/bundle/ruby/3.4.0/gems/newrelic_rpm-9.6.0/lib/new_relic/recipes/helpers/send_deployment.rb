# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module SendDeployment
  def send_deployment_notification_to_newrelic
    require 'new_relic/cli/command'
    debug('Uploading deployment to New Relic')
    NewRelic::Cli::Deployments.new(deploy_options).run
    info('Uploaded deployment information to New Relic')
  rescue NewRelic::Cli::Command::CommandFailure => e
    info(e.message)
  rescue => e
    info("Error creating New Relic deployment (#{e})\n#{e.backtrace.join("\n")}")
  end

  private

  def deploy_options
    {
      :environment => fetch_environment,
      :revision => fetch_rev,
      :changelog => fetch_changelog,
      :description => fetch(:newrelic_desc),
      :appname => fetch(:newrelic_appname),
      :user => fetch(:newrelic_user),
      :license_key => fetch(:newrelic_license_key)
    }
  end

  def fetch_changelog
    newrelic_changelog = fetch(:newrelic_changelog)
    has_scm? && !newrelic_changelog ? lookup_changelog : newrelic_changelog
  end

  def fetch_environment
    fetch(:newrelic_rails_env, fetch(:rack_env, fetch(:rails_env, fetch(:stage, 'production'))))
  end

  def fetch_rev
    newrelic_rev = fetch(:newrelic_revision)
    has_scm? && !newrelic_rev ? fetch(:current_revision) : newrelic_rev
  end

  def has_scm?
    has_scm_from_plugin? || has_scm_from_config?
  end

  def has_scm_from_config?
    defined?(scm) && !scm.nil? && scm != :none
  end

  def has_scm_from_plugin?
    respond_to?(:scm_plugin_installed?) && scm_plugin_installed?
  end

  def lookup_changelog
    previous_revision = fetch(:previous_revision)
    current_revision = fetch(:current_revision)
    return unless current_revision && previous_revision

    debug('Retrieving changelog for New Relic Deployment details')

    if Rake::Task.task_defined?('git:check')
      log_command = "git --no-pager log --no-color --pretty=format:'  * %an: %s' " +
        "--abbrev-commit --no-merges #{previous_revision}..#{current_revision}"
      `#{log_command}`
    end
  end
end
