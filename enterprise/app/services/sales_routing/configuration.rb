class SalesRouting::Configuration
  pattr_initialize [:inbox!]

  def enabled?
    settings.present? && settings.fetch('inbox_ids').include?(inbox.id)
  end

  def stores
    settings.fetch('stores')
  end

  def teams
    @teams ||= inbox.account.teams.where(id: stores.values.map { |store| store.fetch('team_id') }).includes(:members).index_by(&:id)
  end

  def store_for_team(team_id)
    stores.find { |_code, store| store.fetch('team_id') == team_id }&.first
  end

  def team_for(store)
    teams.fetch(stores.fetch(store).fetch('team_id'))
  end

  def member_ids
    memberships = stores.keys.flat_map { |store| team_for(store).members.map(&:id) }
    raise 'A seller belongs to more than one store team' if memberships.uniq != memberships

    memberships
  end

  private

  def settings
    @settings ||= inbox.account.internal_attributes['store_routing']
  end
end
