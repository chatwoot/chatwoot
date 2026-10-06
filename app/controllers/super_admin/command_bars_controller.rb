class SuperAdmin::CommandBarsController < SuperAdmin::ApplicationController
  RESULTS_PER_RESOURCE = 5
  # The list pages match on every column, which scans large tables for seconds; these are the ones a row shows.
  SEARCH_COLUMNS = %w[name email title].freeze

  layout false

  def show
    render locals: { results: helpers.nav_resources.index_with { |resource| search(resource.classify.constantize) }.compact_blank }
  end

  def record
    resource = helpers.nav_resources.find { |name| name == params[:resource] }
    return head :unprocessable_entity unless resource

    render locals: { record: routable(resource.classify.constantize.find(params[:id])) }
  end

  private

  def search(model)
    query = params[:q].to_s.strip
    columns = SEARCH_COLUMNS & model.column_names
    matches = columns.map { |column| model.where(model.arel_table[column].matches("%#{query}%")) }.reduce(model.none, :or)
    exact = model.find_by(id: query.delete_prefix('#')) if query.match?(/\A#?\d+\z/)
    [exact, *matches.order(id: :desc).limit(RESULTS_PER_RESOURCE)].compact.uniq.first(RESULTS_PER_RESOURCE).map { |record| routable(record) }
  end

  # A SuperAdmin is a User without routes of its own.
  def routable(record)
    record.is_a?(User) ? record.becomes(User) : record
  end
end
