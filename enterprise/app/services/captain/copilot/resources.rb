# The record types Copilot can select with get_data. Each type owns its permission scope, filters, display columns
# and the queries that reach it from another saved set, so the model never writes a query or a join.
#
# Every class in this folder is a resource. The other tables in enterprise/config/copilot_tables.yml get a resource
# generated from their model (Captain::Copilot::Resources::Table).
module Captain::Copilot::Resources
  def self.all
    @all ||= begin
      # Development loads classes on first use, so the folder is loaded to find every class in it.
      Rails.autoloaders.main.eager_load_namespace(self)
      written = Captain::Copilot::Resources::BaseResource.subclasses.excluding(Captain::Copilot::Resources::Table).sort_by do |resource|
        resource::NAME
      end
      written + Captain::Copilot::Resources::Table.generated(written)
    end
  end

  # The resources this user may read, for get_data's description.
  def self.readable(account:, user:)
    all.select { |resource| resource.new(account: account, user: user).readable? }
  end

  def self.build(name, account:, user:)
    resource = all.find { |candidate| name == candidate::NAME }
    raise ArgumentError, "Unknown resource #{name}. Available resources: #{all.map { |candidate| candidate::NAME }.join(', ')}" unless resource

    resource.new(account: account, user: user)
  end

  # The records of a saved set, as a relation. A collection is rebuilt from its filters, so a step that starts from it
  # sees every matching record, not only the IDs it saved, and a chain of steps is one database query. Records created
  # after the collection was taken stay out, so a chain reads the data as it was then. A collection that picked
  # particular records, with newest or sample, and the matches of a review are lists of IDs.
  def self.records(set)
    resource = build(set.resource, account: set.account, user: set.user)
    model = resource.class::MODEL
    return model.where(id: set.record_ids) unless set.is_a?(CopilotRun::Collection) && set.query?

    relation = resource.matching(set.filters, as_of: set.as_of, source: set.source_run, excluded: set.excluded_run)
    relation.where(model.arel_table[:created_at].lteq(set.as_of))
  end
end
