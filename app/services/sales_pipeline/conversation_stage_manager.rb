module SalesPipeline
  class ConversationStageManager
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :conversation, :conversation
    attribute :stage, :sales_pipeline_stage
    attribute :account, :account

    validates :conversation, presence: true
    validates :account, presence: true

    def initialize(conversation:, stage: nil, account: nil)
      @conversation = conversation
      @stage = stage
      @account = account || conversation.account
    end

    def current_stage
      return nil unless account.present?

      stage_labels = account.sales_pipeline_stages.joins(:label).pluck(:labels__title)
      conversation_labels = conversation.labels.pluck(:name)

      stage_title = stage_labels.find { |label| conversation_labels.include?(label) }
      return nil unless stage_title

      SalesPipelineStage.joins(:label).find_by(
        labels: { title: stage_title },
        account: account
      )
    end

    def update_stage!(new_stage)
      ActiveRecord::Base.transaction do
        remove_current_stage_label!
        add_stage_label!(new_stage)
        update_custom_attribute!(new_stage)
      end
    end

    def remove_stage!
      ActiveRecord::Base.transaction do
        remove_current_stage_label!
        clear_custom_attribute!
      end
    end

    private

    def remove_current_stage_label!
      return unless account.present?

      stage_labels = account.sales_pipeline_stages.joins(:label).pluck(:labels__title)
      current_labels = conversation.labels.pluck(:name)

      stage_labels_to_remove = stage_labels & current_labels
      return if stage_labels_to_remove.empty?

      remaining_labels = current_labels - stage_labels_to_remove
      conversation.update!(label_list: remaining_labels)
    end

    def add_stage_label!(stage)
      return unless stage.present?

      current_labels = conversation.labels.pluck(:name)
      return if current_labels.include?(stage.label.title)

      updated_labels = current_labels + [stage.label.title]
      conversation.update!(label_list: updated_labels)
    end

    def update_custom_attribute!(stage)
      return unless stage.present?

      custom_attrs = conversation.custom_attributes || {}
      custom_attrs['sales_stage_id'] = stage.id
      custom_attrs['sales_stage_name'] = stage.name

      conversation.update!(custom_attributes: custom_attrs)
    end

    def clear_custom_attribute!
      custom_attrs = conversation.custom_attributes || {}
      custom_attrs.delete('sales_stage_id')
      custom_attrs.delete('sales_stage_name')

      conversation.update!(custom_attributes: custom_attrs)
    end
  end
end