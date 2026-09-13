class Api::V1::Accounts::Captain::WootqlController < Api::V1::Accounts::BaseController
  before_action :ensure_development_access

  rescue_from Captain::Apropos::Error, ActionController::ParameterMissing do |error|
    render json: { error: error.message }, status: :unprocessable_entity
  end

  rescue_from ActiveRecord::QueryCanceled do
    render json: { error: 'WootQL query exceeded its execution timeout' }, status: :unprocessable_entity
  end

  def show
    resources = Captain::Apropos::Catalog::ENTITIES.transform_values do |definition|
      { fields: definition.fetch(:fields) + definition.fetch(:query_fields, {}).keys, relations: definition.fetch(:relations) }
    end
    render json: { resources: resources }
  end

  def create
    source = params.require(:source)
    unless source.is_a?(String) && source.bytesize <= Captain::Apropos::WootqlParser::MAX_BYTES
      raise Captain::Apropos::Error, 'WootQL source must be a string of at most 32 KB'
    end

    offset = params.fetch(:offset, 0)
    unless offset.is_a?(Integer) && offset.between?(0, Captain::Apropos::Query::MAX_OFFSET)
      raise Captain::Apropos::Error, 'WootQL offset must be a nonnegative integer no larger than 100000'
    end

    data = Captain::Apropos::DataAccess.new(account: Current.account, user: Current.user)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = Captain::Apropos::Query.new(data: data, budget: { queries: 0 }).run(source, {}, offset, debug: true)
    result['duration_ms'] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
    render json: result
  end

  private

  def ensure_development_access
    return head :not_found unless Rails.env.development?

    Captain::Apropos::Access.check!(Current.account, Current.user)
  rescue Captain::Apropos::Error => e
    render json: { error: e.message }, status: :forbidden
  end
end
