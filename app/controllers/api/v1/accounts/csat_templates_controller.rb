class Api::V1::Accounts::CsatTemplatesController < Api::V1::Accounts::BaseController
  before_action :load_template, only: [:show, :update, :destroy]
  def index
    @templates = csat_templates
    @templates_count = @templates.count
  end

  def show; end

  def create
    @template = csat_templates.create(csat_template_params)
    # rubocop:disable Rails/SkipsModelValidations
    Current.account.inboxes.where(id: inbox_id_params).update_all(csat_template_id: @template.id)
    # rubocop:enable Rails/SkipsModelValidations
    render json: @template
  end

  def update
    @template.update(csat_template_params)
    # rubocop:disable Rails/SkipsModelValidations
    Current.account.inboxes.where(csat_template_id: params[:id]).update_all(csat_template_id: nil)
    Current.account.inboxes.where(id: inbox_id_params).update_all(csat_template_id: @template.id)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def update_csat_trigger
    render json: { status: Current.account.update(csat_trigger: params[:csat_trigger]) }
  end

  def csat_trigger
    render json: { csat_trigger: Current.account.csat_trigger }
  end

  def destroy
    @template.destroy
    render json: { success: @template.destroyed? }
  end

  def setting_status
    render json: { status: Current.account.csat_template_enabled }
  end

  def toggle_setting
    Current.account.update(csat_template_enabled: params[:status])
    render json: { success: true }
  end

  def inboxes
    render json: { inboxes: Current.account.inboxes.map { |inbox| { id: inbox.id, name: inbox.name } } }
  end

  private

  def load_template
    @template = csat_templates.find_by(id: params[:id])
  end

  def csat_templates
    Current.account.csat_templates
  end

  def csat_questions
    @template.csat_template_questions
  end

  def csat_template_params
    params.require(:csat_template).permit(csat_template_questions_attributes: [:id, :content, :_destroy])
  end

  def inbox_id_params
    params[:csat_template][:inbox_ids]
  end
end
