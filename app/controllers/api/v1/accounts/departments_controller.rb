class Api::V1::Accounts::DepartmentsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :set_department, except: [:index, :create]

  def index
    @departments = Current.account.departments.active.includes(:queues)
  end

  def show; end

  def create
    @department = Current.account.departments.build(department_params)
    
    if @department.save
      render json: { success: true, department: department_data(@department) }
    else
      render json: { success: false, errors: @department.errors }
    end
  end

  def update
    if @department.update(department_params)
      render json: { success: true, department: department_data(@department) }
    else
      render json: { success: false, errors: @department.errors }
    end
  end

  def destroy
    if @department.queues.any?
      render json: { success: false, error: 'Cannot delete department with active queues' }
    else
      @department.destroy
      render json: { success: true }
    end
  end

  private

  def set_department
    @department = Current.account.departments.find(params[:id])
  end

  def department_params
    params.require(:department).permit(:name, :description, :department_type, :active)
  end

  def department_data(department)
    {
      id: department.id,
      name: department.name,
      description: department.description,
      department_type: department.department_type,
      active: department.active,
      queues_count: department.queues.count,
      active_conversations_count: department.active_conversations_count,
      sla_breach_rate: department.sla_breach_rate,
      created_at: department.created_at,
      updated_at: department.updated_at
    }
  end
end