class AutomationRules::TemplatePlaceholderService
  include EmailHelper

  # Resolves `{{ namespace.attribute }}` placeholders inside WhatsApp template
  # parameter values at rule-execution time, using the Liquid drops Chatwoot
  # already exposes for message rendering. The drops give us a single
  # extensible surface (contact / conversation / inbox / account / agent) so
  # rule authors can use the same tokens they already see in canned responses
  # and campaign templates.
  #
  # Tokens that don't resolve produce an empty string rather than the literal
  # placeholder, so the WhatsApp API never receives a `{{1}}`-style sentinel
  # when contact data is missing.
  def initialize(trigger_conversation)
    @conversation = trigger_conversation
    @drops = build_drops
  end

  def substitute(value)
    return value unless value.is_a?(String)
    return value unless value.include?('{{')

    Liquid::Template.parse(value).render(@drops)
  rescue Liquid::Error
    value
  end

  def substitute_processed_params(processed_params)
    return {} if processed_params.blank?

    processed_params.transform_values { |v| substitute(v) }
  end

  private

  def build_drops
    drops = message_drops(@conversation)
    drops['agent'] = UserDrop.new(@conversation.assignee) if @conversation.assignee.present?
    drops
  end
end
