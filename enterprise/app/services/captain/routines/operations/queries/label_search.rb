class Captain::Routines::Operations::Queries::LabelSearch < Captain::Routines::Operations::Query
  returns :one, of: :label

  configure(
    name: 'labels.search', effect: 'read',
    description: 'Resolve an account label by name or ID.',
    arguments: { query: 'label name or ID' }, required: %w[query]
  )

  def execute(query:)
    label_data(label!(query))
  end
end
