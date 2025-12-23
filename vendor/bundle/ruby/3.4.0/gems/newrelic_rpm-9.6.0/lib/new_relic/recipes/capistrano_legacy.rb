# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

make_notify_task = proc do
  namespace(:newrelic) do
    # on all deployments, notify New Relic
    desc('Record a deployment in New Relic (newrelic.com)')
    task(:notice_deployment, :roles => :app, :except => {:no_release => true}) do
      rails_env = fetch(:newrelic_rails_env, fetch(:rails_env, 'production'))

      require 'new_relic/cli/command'

      begin
        # allow overrides to be defined for revision, description, changelog, appname, and user
        rev = fetch(:newrelic_revision) if exists?(:newrelic_revision)
        description = fetch(:newrelic_desc) if exists?(:newrelic_desc)
        changelog = fetch(:newrelic_changelog) if exists?(:newrelic_changelog)
        appname = fetch(:newrelic_appname) if exists?(:newrelic_appname)
        user = fetch(:newrelic_user) if exists?(:newrelic_user)
        license_key = fetch(:newrelic_license_key) if exists?(:newrelic_license_key)

        unless scm == :none
          changelog = lookup_changelog(changelog)
          rev = lookup_rev(rev)
        end

        new_revision = rev
        deploy_options = {
          :environment => rails_env,
          :revision => new_revision,
          :changelog => changelog,
          :description => description,
          :appname => appname,
          :user => user,
          :license_key => license_key
        }

        logger.debug('Uploading deployment to New Relic')
        deployment = NewRelic::Cli::Deployments.new(deploy_options)
        deployment.run
        logger.info('Uploaded deployment information to New Relic')
      rescue NewRelic::Cli::Command::CommandFailure => e
        logger.info(e.message)
      rescue Capistrano::CommandError
        logger.info('Unable to notify New Relic of the deployment... skipping')
      rescue => e
        logger.info("Error creating New Relic deployment (#{e})\n#{e.backtrace.join("\n")}")
      end
    end

    def lookup_changelog(changelog)
      if !changelog
        logger.debug('Getting log of changes for New Relic Deployment details')
        from_revision = source.next_revision(current_revision)

        if scm == :git
          log_command = "git --no-pager log --no-color --pretty=format:'  * %an: %s' " +
            "--abbrev-commit --no-merges #{previous_revision}..#{real_revision}"
        else
          log_command = "#{source.log(from_revision)}"
        end

        changelog = `#{log_command}`
      end
      changelog
    end

    def lookup_rev(rev)
      if rev.nil?
        rev = source.query_revision(source.head()) do |cmd|
          logger.debug("executing locally: '#{cmd}'")
          `#{cmd}`
        end

        rev = rev[0..6] if scm == :git
      end
      rev
    end
  end
end

require 'capistrano/version'

if defined?(Capistrano::Version::MAJOR) && Capistrano::Version::MAJOR < 2
  STDERR.puts "Unable to load #{__FILE__}\nNew Relic Capistrano hooks require at least version 2.0.0"
else
  instance = Capistrano::Configuration.instance

  if instance
    instance.load(&make_notify_task)
  else
    make_notify_task.call
  end
end
