class Api::V1::Accounts::QueuesController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :set_queue, except: [:index, :create]

  def index
    @queues = Current.account.queues.active.includes(:department, :sla_policy, :agents)
    @queues = @queues.where(department_id: params[:department_id]) if params[:department_id].present?
  end

  def show; end

  def create
    @queue = Current.account.queues.build(queue_params)
    
    if @queue.save
      render json: { success: true, queue: queue_data(@queue) }
    else
      render json: { success: false, errors: @queue.errors }
    end
  end

  def update
    if @queue.update(queue_params)
      render json: { success: true, queue: queue_data(@queue) }
    else
      render json: { success: false, errors: @queue.errors }
    end
  end

  def destroy
    if @queue.conversations.open.any?
      render json: { success: false, error: 'Cannot delete queue with active conversations' }
    else
      @queue.destroy
      render json: { success: true }
    end
  end

  def assign_agents
    agent_ids = params[:agent_ids] || []
    current_agent_ids = @queue.agents.pluck(:id)
    
    # Remove agents not in the new list
    agents_to_remove = current_agent_ids - agent_ids
    @queue.agents.where(id: agents_to_remove).each do |agent|
      @queue.agents.delete(agent)
    end
    
    # Add new agents
    agents_to_add = agent_ids - current_agent_ids
    agents_to_add.each do |agent_id|
      agent = Current.account.users.find_by(id: agent_id)
      @queue.agents << agent if agent
    end
    
    render json: { success: true, queue: queue_data(@queue) }
  end

  private

  def set_queue
    @queue = Current.account.queues.find(params[:id])
  end

  def queue_params
    params.require(:queue).permit(:name, :description, :department_id, :sla_policy_id, 
                                  :priority, :active, :max_capacity, 
                                  routing_rules: {}, working_hours: {})
  end

  def queue_data(queue)
    {
      id: queue.id,
      name: queue.name,
      description: queue.description,
      department_id: queue.department_id,
      department_name: queue.department&.name,
      sla_policy_id: queue.sla_policy_id,
      sla_policy_name: queue.sla_policy&.name,
      priority: queue.priority,
      active: queue.active,
      max_capacity: queue.max_capacity,
      current_load: queue.current_load,
      capacity_percentage: queue.capacity_percentage,
      is_available: queue.is_available?,
      within_working_hours: queue.within_working_hours?,
      routing_rules: queue.routing_rules,
      working_hours: queue.working_hours,
      agents_count: queue.agents.count,
      average_wait_time: queue.average_wait_time,
      sla_compliance_rate: queue.sla_compliance_rate,
      agents: queue.agents.map { |agent| { id: agent.id, name: agent.name, email: agent.email } },
      created_at: queue.created_at,
      updated_at: queue.updated_at
    }
  end
end