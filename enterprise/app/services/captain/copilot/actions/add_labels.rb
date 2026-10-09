class Captain::Copilot::Actions::AddLabels < Captain::Copilot::Actions::BaseAction
  NAME = 'add_labels'.freeze
  DESCRIPTION = 'Add existing account labels to each conversation. Arguments: labels, an array of label titles.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[labels],
    properties: { labels: { type: 'array', minItems: 1, maxItems: 10, uniqueItems: true, items: { type: 'string', minLength: 1 } } }
  }.deep_stringify_keys.freeze

  def perform(conversation)
    return 'skipped' if (labels - conversation.label_list).empty?

    conversation.add_labels(labels)
    'applied'
  end

  private

  def labels
    @arguments['labels']
  end

  def validate!
    unknown = labels - @account.labels.where(title: labels).pluck(:title)
    return if unknown.empty?

    raise ArgumentError,
          "Unknown labels: #{unknown.join(', ')}. Available labels: #{@account.labels.order(:title).limit(100).pluck(:title).join(', ')}"
  end
end
