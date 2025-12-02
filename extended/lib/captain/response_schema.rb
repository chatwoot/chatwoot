class Captain::ResponseSchema
  def self.schema
    {
      type: 'object',
      properties: {
        response: { type: 'string', description: 'The message to send to the user' },
        reasoning: { type: 'string', description: "Agent's thought process" }
      },
      required: %w[response reasoning]
    }
  end
end
