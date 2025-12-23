# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/datastores/nosql_obfuscator'
require 'new_relic/agent/datastores/metric_helper'

module NewRelic
  module Agent
    module Datastores
      module Mongo
        module MetricTranslator
          def self.operation_and_collection_for(name, payload)
            payload ||= {}

            if collection_in_selector?(payload)
              command_key = command_key_from_selector(payload)
              name = get_name_from_selector(command_key, payload)
              collection = get_collection_from_selector(command_key, payload)
            else
              collection = payload[:collection]
            end

            # The 1.10.0 version of the mongo driver renamed 'remove' to
            # 'delete', but for metric consistency with previous versions we
            # want to keep it as 'remove'.
            name = 'remove' if name.to_s == 'delete'

            if self.find_one?(name, payload)
              name = 'findOne'
            elsif self.find_and_remove?(name, payload)
              name = 'findAndRemove'
            elsif self.find_and_modify?(name, payload)
              name = 'findAndModify'
            elsif self.create_indexes?(name, payload)
              name = 'createIndexes'
            elsif self.create_index?(name, payload)
              name = 'createIndex'
              collection = self.collection_name_from_index(payload)
            elsif self.drop_indexes?(name, payload)
              name = 'dropIndexes'
            elsif self.drop_index?(name, payload)
              name = 'dropIndex'
            elsif self.re_index?(name, payload)
              name = 'reIndex'
            elsif self.group?(name, payload)
              name = 'group'
              collection = collection_name_from_group_selector(payload)
            elsif self.rename_collection?(name, payload)
              name = 'renameCollection'
              collection = collection_name_from_rename_selector(payload)
            end

            [name.to_s, collection]
          rescue => e
            NewRelic::Agent.logger.debug('Failure during Mongo metric generation', e)
            nil
          end

          def self.collection_in_selector?(payload)
            payload[:collection] == '$cmd' && payload[:selector]
          end

          NAMES_IN_SELECTOR = [
            :findandmodify,

            'aggregate',
            'count',
            'group',
            'mapreduce',

            :distinct,

            :createIndexes,
            :deleteIndexes,
            :reIndex,

            :collstats,
            :renameCollection,
            :drop
          ]

          def self.command_key_from_selector(payload)
            selector = payload[:selector]
            NAMES_IN_SELECTOR.find do |check_name|
              selector.key?(check_name)
            end
          end

          def self.get_name_from_selector(command_key, payload)
            if command_key
              command_key.to_sym
            else
              NewRelic::Agent.increment_metric('Supportability/Mongo/UnknownCollection')
              payload[:selector].first.first unless command_key
            end
          end

          CMD_COLLECTION = '$cmd'.freeze

          def self.get_collection_from_selector(command_key, payload)
            if command_key
              payload[:selector][command_key]
            else
              NewRelic::Agent.increment_metric('Supportability/Mongo/UnknownCollection')
              CMD_COLLECTION
            end
          end

          def self.find_one?(name, payload)
            name == :find && payload[:limit] == -1
          end

          def self.find_and_modify?(name, payload)
            name == :findandmodify
          end

          def self.find_and_remove?(name, payload)
            name == :findandmodify && payload[:selector] && payload[:selector][:remove]
          end

          def self.create_indexes?(name, _payload)
            name == :createIndexes
          end

          def self.create_index?(name, payload)
            name == :insert && payload[:collection] == 'system.indexes'
          end

          def self.drop_indexes?(name, payload)
            name == :deleteIndexes && payload[:selector] && payload[:selector][:index] == '*'
          end

          def self.drop_index?(name, payload)
            name == :deleteIndexes
          end

          def self.re_index?(name, payload)
            name == :reIndex && payload[:selector] && payload[:selector][:reIndex]
          end

          def self.group?(name, payload)
            name == :group
          end

          def self.rename_collection?(name, payload)
            name == :renameCollection
          end

          def self.collection_name_from_index(payload)
            if payload[:documents]
              if payload[:documents].is_a?(Array)
                # mongo gem versions pre 1.10.0
                document = payload[:documents].first
              else
                # mongo gem versions 1.10.0 and later
                document = payload[:documents]
              end

              if document && document[:ns]
                return document[:ns].split('.').last
              end
            end

            'system.indexes'
          end

          def self.collection_name_from_group_selector(payload)
            payload[:selector]['group']['ns']
          end

          def self.collection_name_from_rename_selector(payload)
            parts = payload[:selector][:renameCollection].split('.')
            parts.shift
            parts.join('.')
          end
        end
      end
    end
  end
end
