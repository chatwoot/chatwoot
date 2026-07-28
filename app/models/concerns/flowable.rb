module Flowable
  extend ActiveSupport::Concern

  included do
    has_many :flow_runs, dependent: :destroy
  end

  def in_flow?
    flow_runs.where(state: %i[running waiting]).exists?
  end

  def flow_already_entered?(flow_id)
    flow_runs.where(flow_id: flow_id).exists?
  end

  def active_flow_run
    flow_runs.where(state: %i[running waiting]).order(started_at: :desc).first
  end
end
