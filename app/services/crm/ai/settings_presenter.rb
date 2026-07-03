module Crm
  module Ai
    class SettingsPresenter
      def initialize(pipeline:)
        @pipeline = pipeline
      end

      def perform
        {
          enabled: pipeline_settings[:enabled] != false,
          auto_move_enabled: pipeline_settings[:auto_move_enabled] == true,
          attribute_extraction_enabled: pipeline_settings[:attribute_extraction_enabled] == true,
          callback_enabled: pipeline_settings[:callback_enabled] != false,
          callback_mode: Config.pipeline_callback_mode(@pipeline),
          stale_hours: pipeline_settings[:stale_hours].presence || Config::DEFAULT_STALE_HOURS,
          auto_followup: Config.auto_followup_settings(@pipeline),
          handoff: Config.handoff_settings(nil, @pipeline),
          stages: @pipeline.stages.order(:position, :id).map do |stage|
            {
              id: stage.id,
              name: stage.name,
              ai_criteria: Config.stage_ai_criteria(stage),
              handoff: Config.handoff_settings(stage, @pipeline),
              handoff_custom: (stage.metadata || {}).key?('ai_handoff')
            }
          end
        }
      end

      private

      def pipeline_settings
        Config.pipeline_ai_settings(@pipeline)
      end
    end
  end
end
