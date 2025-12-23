# frozen_string_literal: true

require_relative 'content'

module Datadog
  module Core
    module Remote
      class Configuration
        # Repository
        class Repository
          attr_reader \
            :contents,
            :opaque_backend_state,
            :root_version,
            :targets_version

          UNVERIFIED_ROOT_VERSION = 1

          INITIAL_TARGETS_VERSION = 0

          def initialize
            @contents = ContentList.new
            @opaque_backend_state = nil
            @root_version = UNVERIFIED_ROOT_VERSION
            @targets_version = INITIAL_TARGETS_VERSION
          end

          def paths
            @contents.paths
          end

          def [](path)
            @contents[path]
          end

          def transaction
            transaction = Transaction.new

            yield(self, transaction)

            commit(transaction)
          end

          def commit(transaction)
            previous = contents.dup

            touched = transaction.operations.each_with_object([]) do |op, acc|
              acc << op.apply(self)
            end

            changes = ChangeSet.new

            touched.uniq.each do |path|
              next if path.nil?

              changes.add(path, previous[path], @contents[path])
            end

            changes.freeze
          end

          def state
            State.new(self)
          end

          # State store the repository state
          class State
            attr_reader \
              :root_version,
              :targets_version,
              :config_states,
              :has_error,
              :error,
              :opaque_backend_state,
              :cached_target_files

            def initialize(repository)
              @repository = repository
              @root_version = repository.root_version
              @targets_version = repository.targets_version
              @config_states = contents_to_config_states(repository.contents)
              @has_error = false
              @error = ''
              @opaque_backend_state = repository.opaque_backend_state
              @cached_target_files = contents_to_cached_target_files(repository.contents)
            end

            private

            def contents_to_config_states(contents)
              return [] if contents.empty?

              contents.map do |content|
                {
                  id: content.path.config_id,
                  version: content.version,
                  product: content.path.product,
                  apply_state: content.apply_state,
                  apply_error: content.apply_error,
                }
              end
            end

            def contents_to_cached_target_files(contents)
              return [] if contents.empty?

              contents.map do |content|
                {
                  path: content.path.to_s,
                  length: content.length,
                  hashes: content.hashes.map do |algorithm, hexdigest|
                    {
                      algorithm: algorithm,
                      hash: hexdigest
                    }
                  end
                }
              end
            end
          end

          # Encapsulates transaction operations
          class Transaction
            attr_reader :operations

            def initialize
              @operations = []
            end

            def delete(path)
              @operations << Operation::Delete.new(path)
            end

            def insert(path, target, content)
              @operations << Operation::Insert.new(path, target, content)
            end

            def update(path, target, content)
              @operations << Operation::Update.new(path, target, content)
            end

            def set(**options)
              @operations << Operation::Set.new(**options)
            end
          end

          # Operation
          module Operation
            # Delete contents base on path
            class Delete
              attr_reader :path

              def initialize(path)
                super()
                @path = path
              end

              def apply(repository)
                return if repository[@path].nil?

                repository.contents.delete(@path)

                @path
              end
            end

            # Insert content into the repository contents
            class Insert
              attr_reader :path, :target, :content

              def initialize(path, target, content)
                super()
                @path = path
                @target = target
                @content = content
              end

              def apply(repository)
                return unless repository[@path].nil?

                @content.version = @target.version
                repository.contents << @content

                @path
              end
            end

            # Update existimng repository's contents
            class Update
              attr_reader :path, :target, :content

              def initialize(path, target, content)
                super()
                @path = path
                @target = target
                @content = content
              end

              def apply(repository)
                return if repository[@path].nil?

                @content.version = @target.version
                repository.contents[@path] = @content

                @path
              end
            end

            # Set repository metadata
            class Set
              attr_reader :opaque_backend_state, :targets_version

              def initialize(**options)
                super()
                @opaque_backend_state = options[:opaque_backend_state]
                @targets_version = options[:targets_version]
              end

              def apply(repository)
                repository.instance_variable_set(:@opaque_backend_state, @opaque_backend_state) if @opaque_backend_state

                repository.instance_variable_set(:@targets_version, @targets_version) if @targets_version

                nil
              end
            end
          end

          private_constant :Operation

          module Change
            # Delete change
            class Deleted
              attr_reader :path, :previous

              def initialize(path, previous)
                @path = path
                @previous = previous
              end

              def type
                :delete
              end
            end

            # Insert change
            class Inserted
              attr_reader :path, :content

              def initialize(path, content)
                @path = path
                @content = content
              end

              def type
                :insert
              end
            end

            # Update change
            class Updated
              attr_reader :path, :content, :previous

              def initialize(path, content, previous)
                @path = path
                @content = content
                @previous = previous
              end

              def type
                :update
              end
            end
          end

          # Store list of Changes
          class ChangeSet < Array
            def paths
              map(&:path)
            end

            def add(path, previous, content)
              return if previous.nil? && content.nil?

              return deleted(path, previous) if previous && content.nil?
              return inserted(path, content) if content && previous.nil?

              updated(path, content, previous) if content && previous
            end

            def deleted(path, previous)
              self << Change::Deleted.new(path, previous).freeze
            end

            def inserted(path, content)
              self << Change::Inserted.new(path, content).freeze
            end

            def updated(path, content, previous)
              self << Change::Updated.new(path, content, previous).freeze
            end
          end
        end
      end
    end
  end
end
