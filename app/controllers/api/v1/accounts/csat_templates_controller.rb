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
    # rubocop:enable Rails/SkipsModelValidations

    inboxes = Current.account.inboxes.where(id: inbox_id_params)
    return unless inboxes.present?

    inboxes.each do |inbox|
      inbox.update(csat_template_id: @template.id)
    end
  end

  def destroy
    @template.destroy
    render json: { success: @template.destroyed? }
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
    params.require(:csat_template).permit(:name, csat_template_questions_attributes: [:id, :content, :_destroy])
  end

  def inbox_id_params
    params[:csat_template][:inbox_ids]
  end
end
