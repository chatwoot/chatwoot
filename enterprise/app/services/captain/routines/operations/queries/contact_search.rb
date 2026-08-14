class Captain::Routines::Operations::Queries::ContactSearch < Captain::Routines::Operations::Query
  returns :collection, of: :contact

  configure(
    name: 'contacts.search', effect: 'read',
    description: 'Find contacts using deterministic identity, label, or activity filters.',
    arguments: {
      query: 'name, email, phone number, or identifier', labels: 'array of label names',
      last_activity: 'relative date or range'
    }
  )

  def execute(query: nil, labels: nil, last_activity: nil)
    scope = account.contacts.includes(:labels)
    scope = apply_query(scope, query) if query.present?
    scope = scope.tagged_with(Array(labels)) if labels.present?
    scope = scope.where(last_activity_at: time_range!(last_activity)) if last_activity.present?
    scope.reorder(last_activity_at: :desc, id: :asc).map { |contact| contact_data(contact) }
  end

  private

  def apply_query(scope, query)
    escaped = ActiveRecord::Base.sanitize_sql_like(query.to_s)
    scope.where(
      'name ILIKE :query OR email ILIKE :query OR phone_number ILIKE :query OR identifier ILIKE :query',
      query: "%#{escaped}%"
    )
  end
end
