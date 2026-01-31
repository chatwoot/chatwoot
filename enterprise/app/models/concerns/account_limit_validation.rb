module Concerns::AccountLimitValidation
  extend ActiveSupport::Concern

  LIMIT_SCHEMA = {
    'type' => 'object',
    'properties' => {
      'inboxes' => { 'type': 'number' },
      'agents' => { 'type': 'number' },
      'captain_responses' => { 'type': 'number' },
      'captain_documents' => { 'type': 'number' }
    },
    'required' => [],
    'additionalProperties' => false
  }.freeze

  def validate_limit_keys
    errors.add(:limits, ': Invalid data') unless self[:limits].is_a? Hash
    self[:limits] = {} if self[:limits].blank?

    errors.add(:limits, ': Invalid data') unless JSONSchemer.schema(LIMIT_SCHEMA).valid?(self[:limits])
  end
end
