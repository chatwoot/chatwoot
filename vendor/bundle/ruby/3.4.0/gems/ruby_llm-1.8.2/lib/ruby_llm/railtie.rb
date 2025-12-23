# frozen_string_literal: true

module RubyLLM
  # Rails integration for RubyLLM
  class Railtie < Rails::Railtie
    initializer 'ruby_llm.inflections' do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym 'RubyLLM'
      end
    end

    initializer 'ruby_llm.active_record' do
      ActiveSupport.on_load :active_record do
        if RubyLLM.config.use_new_acts_as
          require 'ruby_llm/active_record/acts_as'
          ::ActiveRecord::Base.include RubyLLM::ActiveRecord::ActsAs
        else
          require 'ruby_llm/active_record/acts_as_legacy'
          ::ActiveRecord::Base.include RubyLLM::ActiveRecord::ActsAsLegacy

          Rails.logger.warn(
            "\n!!! RubyLLM's legacy acts_as API is deprecated and will be removed in RubyLLM 2.0.0. " \
            "Please consult the migration guide at https://rubyllm.com/upgrading-to-1-7/\n"
          )
        end
      end
    end

    rake_tasks do
      load 'tasks/ruby_llm.rake'
    end
  end
end
