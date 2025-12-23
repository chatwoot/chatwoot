# frozen_string_literal: true
module Slack
  module Web
    module Api
      module Mixins
        module Ids
          private

          def id_for(key:, name:, prefix:, enum_method:, list_method:, options: {})
            return { 'ok' => true, key.to_s => { 'id' => name } } unless name[0] == prefix

            public_send(enum_method, **options) do |list|
              list.public_send(list_method).each do |li|
                return Slack::Messages::Message.new('ok' => true, key.to_s => { 'id' => li.id }) if li.name == name[1..-1]
              end
            end

            raise Slack::Web::Api::Errors::SlackError, "#{key}_not_found"
          end
        end
      end
    end
  end
end
