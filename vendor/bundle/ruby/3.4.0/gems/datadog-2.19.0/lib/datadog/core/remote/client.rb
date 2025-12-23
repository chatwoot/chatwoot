# frozen_string_literal: true

require 'securerandom'

require_relative 'configuration'
require_relative 'dispatcher'

module Datadog
  module Core
    module Remote
      # Client communicates with the agent and sync remote configuration
      class Client
        class TransportError < StandardError; end

        class SyncError < StandardError; end

        attr_reader :transport, :repository, :id, :dispatcher, :logger

        def initialize(transport, capabilities, logger: Datadog.logger, repository: Configuration::Repository.new)
          @transport = transport
          @logger = logger

          @repository = repository
          @id = SecureRandom.uuid
          @capabilities = capabilities
          @dispatcher = Dispatcher.new(@capabilities.receivers)
        end

        def sync
          # TODO: Skip sync if no capabilities are registered
          response = transport.send_config(payload)

          if response.ok?
            process_response(response)
          elsif response.internal_error?
            raise TransportError, response.to_s
          end
        end

        private

        def process_response(response)
          # when response is completely empty, do nothing as in: leave as is
          if response.empty?
            logger.debug { 'remote: empty response => NOOP' }

            return
          end

          begin
            paths = response.client_configs.map do |path|
              Configuration::Path.parse(path)
            end

            targets = Configuration::TargetMap.parse(response.targets)

            contents = Configuration::ContentList.parse(response.target_files)
          rescue Remote::Configuration::Path::ParseError => e
            raise SyncError, e.message
          end

          # To make sure steep does not complain
          return unless paths && targets && contents

          # TODO: sometimes it can strangely be so that paths.empty?
          # TODO: sometimes it can strangely be so that targets.empty?

          apply_config(paths, targets, contents)
        end

        def apply_config(paths, targets, contents)
          changes = repository.transaction do |current, transaction|
            # paths to be removed: previously applied paths minus ingress paths
            (current.paths - paths).each { |p| transaction.delete(p) }

            # go through each ingress path
            paths.each do |path|
              # match target with path
              target = targets[path]

              # abort entirely if matching target not found
              raise SyncError, "no target for path '#{path}'" if target.nil?

              # new paths are not in previously applied paths
              new = !current.paths.include?(path)

              # updated paths are in previously applied paths
              # but the content hash changed
              changed = current.paths.include?(path) && !current.contents.find_content(path, target)

              # skip if unchanged
              same = !new && !changed

              next if same

              # match content with path and target
              content = contents.find_content(path, target)

              # abort entirely if matching content not found
              raise SyncError, "no valid content for target at path '#{path}'" if content.nil?

              # to be added or updated << config
              # TODO: metadata (hash, version, etc...)
              transaction.insert(path, target, content) if new
              transaction.update(path, target, content) if changed
            end

            # save backend opaque backend state
            transaction.set(opaque_backend_state: targets.opaque_backend_state)
            transaction.set(targets_version: targets.version)

            # upon transaction end, new list of applied config + metadata (add, change, remove) will be saved
            # TODO: also remove stale config (matching removed) from cache (client configs is exhaustive list of paths)
          end

          if changes.empty?
            logger.debug { 'remote: no changes' }
          else
            dispatcher.dispatch(changes, repository)
          end
        end

        def payload # standard:disable Metrics/MethodLength
          state = repository.state

          client_tracer_tags = [
            "platform:#{native_platform}", # native platform
            # "asm.config.rules:#{}", # TODO: defined|undefined
            # "asm.config.enabled:#{}", # TODO: true|false|undefined
            # TODO: Inaccurate if tracing is extracted and version diverges from the datadog gem.
            #       Update this if this ever occurs.
            "ruby.tracer.version:#{Core::Environment::Identity.gem_datadog_version}",
            "ruby.runtime.platform:#{RUBY_PLATFORM}",
            "ruby.runtime.version:#{RUBY_VERSION}",
            "ruby.runtime.engine.name:#{RUBY_ENGINE}",
            "ruby.runtime.engine.version:#{ruby_engine_version}",
            "ruby.rubygems.platform.local:#{Gem::Platform.local}",
            "ruby.gem.libddwaf.version:#{gem_spec("libddwaf").version}",
            "ruby.gem.libddwaf.platform:#{gem_spec("libddwaf").platform}",
            "ruby.gem.libdatadog.version:#{gem_spec("libdatadog").version}",
            "ruby.gem.libdatadog.platform:#{gem_spec("libdatadog").platform}",
          ]

          if (git_repository_url = Core::Environment::Git.git_repository_url)
            client_tracer_tags << "git.repository_url:#{git_repository_url}"
          end
          if (git_commit_sha = Core::Environment::Git.git_commit_sha)
            client_tracer_tags << "git.commit.sha:#{git_commit_sha}"
          end

          client_tracer = {
            runtime_id: Core::Environment::Identity.id,
            language: Core::Environment::Identity.lang,
            tracer_version: tracer_version,
            service: service_name,
            env: Datadog.configuration.env,
            tags: client_tracer_tags,
          }

          app_version = Datadog.configuration.version

          client_tracer[:app_version] = app_version if app_version

          {
            client: {
              state: {
                root_version: state.root_version,
                targets_version: state.targets_version,
                config_states: state.config_states,
                has_error: state.has_error,
                error: state.error,
                backend_client_state: state.opaque_backend_state,
              },
              id: id,
              products: @capabilities.products,
              is_tracer: true,
              is_agent: false,
              client_tracer: client_tracer,
              # base64 is needed otherwise the Go agent fails with an unmarshal error
              capabilities: @capabilities.base64_capabilities
            },
            cached_target_files: state.cached_target_files,
          }
        end

        def service_name
          Datadog.configuration.remote.service || Datadog.configuration.service
        end

        def tracer_version
          @tracer_version ||= Core::Environment::Identity.gem_datadog_version_semver2
        end

        def ruby_engine_version
          @ruby_engine_version ||= defined?(RUBY_ENGINE_VERSION) ? RUBY_ENGINE_VERSION : RUBY_VERSION
        end

        def gem_spec(name)
          (@gem_specs ||= {})[name] ||= ::Gem.loaded_specs[name] || GemSpecificationFallback.new(nil, nil)
        end

        def native_platform
          return @native_platform unless @native_platform.nil?

          os = if RUBY_ENGINE == 'jruby'
            os_name = java.lang.System.get_property('os.name')

            case os_name
            when /linux/i then 'linux'
            when /mac/i then 'darwin'
            else os_name
            end
          else
            Gem::Platform.local.os
          end

          version = if os != 'linux'
            nil
          elsif RUBY_PLATFORM =~ /linux-(.+)$/
            # Old rubygems don't handle non-gnu linux correctly
            Regexp.last_match(1)
          else
            'gnu'
          end

          cpu = if RUBY_ENGINE == 'jruby'
            os_arch = java.lang.System.get_property('os.arch')

            case os_arch
            when 'amd64' then 'x86_64'
            when 'aarch64' then (os == 'darwin') ? 'arm64' : 'aarch64'
            else os_arch
            end
          else
            Gem::Platform.local.cpu
          end

          @native_platform = [cpu, os, version].compact.join('-')
        end

        GemSpecificationFallback = _ = Struct.new(:version, :platform) # rubocop:disable Naming/ConstantName
      end
    end
  end
end
