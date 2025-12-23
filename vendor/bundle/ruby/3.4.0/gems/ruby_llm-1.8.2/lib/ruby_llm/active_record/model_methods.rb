# frozen_string_literal: true

module RubyLLM
  module ActiveRecord
    # Methods mixed into model registry models.
    module ModelMethods
      extend ActiveSupport::Concern

      class_methods do # rubocop:disable Metrics/BlockLength
        def refresh!
          RubyLLM.models.refresh!

          transaction do
            RubyLLM.models.all.each do |model_info|
              model = find_or_initialize_by(
                model_id: model_info.id,
                provider: model_info.provider
              )
              model.update!(from_llm_attributes(model_info))
            end
          end
        end

        def save_to_database
          transaction do
            RubyLLM.models.all.each do |model_info|
              model = find_or_initialize_by(
                model_id: model_info.id,
                provider: model_info.provider
              )
              model.update!(from_llm_attributes(model_info))
            end
          end
        end

        def from_llm(model_info)
          new(from_llm_attributes(model_info))
        end

        private

        def from_llm_attributes(model_info)
          {
            model_id: model_info.id,
            name: model_info.name,
            provider: model_info.provider,
            family: model_info.family,
            model_created_at: model_info.created_at,
            context_window: model_info.context_window,
            max_output_tokens: model_info.max_output_tokens,
            knowledge_cutoff: model_info.knowledge_cutoff,
            modalities: model_info.modalities.to_h,
            capabilities: model_info.capabilities,
            pricing: model_info.pricing.to_h,
            metadata: model_info.metadata
          }
        end
      end

      def to_llm
        RubyLLM::Model::Info.new(
          id: model_id,
          name: name,
          provider: provider,
          family: family,
          created_at: model_created_at,
          context_window: context_window,
          max_output_tokens: max_output_tokens,
          knowledge_cutoff: knowledge_cutoff,
          modalities: modalities&.deep_symbolize_keys || {},
          capabilities: capabilities,
          pricing: pricing&.deep_symbolize_keys || {},
          metadata: metadata&.deep_symbolize_keys || {}
        )
      end

      delegate :supports?, :supports_vision?, :supports_functions?, :type,
               :input_price_per_million, :output_price_per_million,
               :function_calling?, :structured_output?, :batch?,
               :reasoning?, :citations?, :streaming?,
               to: :to_llm
    end
  end
end
