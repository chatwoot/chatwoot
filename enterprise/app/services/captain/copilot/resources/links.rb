# Paths between resources, built from belongs_to associations in either direction whose foreign key Copilot may read,
# so a listed table linked to another is reachable from it without code. Polymorphic associations are left out,
# because their target is not one table.
module Captain::Copilot::Resources::Links
  # The records of model linked to the given records of other_model, or nil when the two are not linked. records is a
  # relation, so a chain of steps stays one database query.
  def self.path(model, other_model)
    if (link = belongs_to(model, other_model))
      ->(records) { model.where(link.foreign_key => records.select(:id)) }
    elsif (link = belongs_to(other_model, model))
      ->(records) { model.where(id: records.select(link.foreign_key)) }
    end
  end

  # For each resource that points at model, such as inbox_members at inboxes, a query for the IDs of model's records it
  # points at, among the records the user may see. Records that take labels add labels, through their taggings.
  def self.owners(model)
    owners = Captain::Copilot::Resources.all.each_with_object({}) do |other, queries|
      link = belongs_to(other::MODEL, model)
      next unless link

      queries[other::NAME] = lambda do |account, user|
        Captain::Copilot::Resources.build(other::NAME, account: account, user: user).scope.where.not(link.foreign_key => nil).select(link.foreign_key)
      end
    end
    return owners unless model.reflect_on_association(:label_taggings)

    owners.merge('labels' => lambda do |account, _user|
      ActsAsTaggableOn::Tagging.where(taggable_type: model.polymorphic_name, taggable_id: model.where(account_id: account.id).select(:id),
                                      context: 'labels').select(:taggable_id)
    end)
  end

  # A resource in empty keeps the records it points at none of, and in not_empty the records it points at at least once.
  def self.apply(relation, owners, filters, account:, user:)
    relation = (Array(filters['empty']) & owners.keys).reduce(relation) { |scope, name| scope.where.not(id: owners[name].call(account, user)) }
    (Array(filters['not_empty']) & owners.keys).reduce(relation) { |scope, name| scope.where(id: owners[name].call(account, user)) }
  end

  def self.belongs_to(from, to)
    readable = Captain::Copilot::Resources::Columns.names(from)
    from.reflect_on_all_associations(:belongs_to).find do |link|
      !link.polymorphic? && link.klass == to && readable.include?(link.foreign_key.to_s)
    end
  end
end
