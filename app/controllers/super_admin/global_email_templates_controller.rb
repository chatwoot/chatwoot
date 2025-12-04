class SuperAdmin::GlobalEmailTemplatesController < SuperAdmin::ApplicationController
  def show
    @global_email_template = GlobalEmailTemplate.find(params[:id])
  end

  def new
    @global_email_template = GlobalEmailTemplate.new
  end

  def edit
    @global_email_template = GlobalEmailTemplate.find(params[:id])
  end

  def create
    @global_email_template = GlobalEmailTemplate.new(global_email_template_params)
    if @global_email_template.save
      redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.global.created')
    else
      render :new
    end
  end

  def update
    @global_email_template = GlobalEmailTemplate.find(params[:id])
    if @global_email_template.update(global_email_template_params)
      redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.global.updated')
    else
      render :edit
    end
  end

  def destroy
    @global_email_template = GlobalEmailTemplate.find(params[:id])
    @global_email_template.destroy
    redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.global.deleted')
  end

  private

  def global_email_template_params
    params.require(:global_email_template).permit(:name, :friendly_name, :description, :template_type, :html)
  end
end
