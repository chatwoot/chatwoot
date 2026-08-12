class Captain::Routines::Operations::Queries::ContactSearch < Captain::Routines::Operations::Query
  returns :collection

  configure(
    name: 'contacts.search', effect: 'read', approval: 'never',
    description: 'Find contacts using deterministic identity, label, or activity filters.',
    arguments: {
      query: 'name, email, phone number, or identifier', labels: 'array of label names',
      last_activity: 'relative date or range'
    }
  )
end
