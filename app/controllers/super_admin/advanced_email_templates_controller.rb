class SuperAdmin::AdvancedEmailTemplatesController < SuperAdmin::ApplicationController
  def show
    @advanced_email_template = AdvancedEmailTemplate.find(params[:id])
  end

  def new
    @advanced_email_template = AdvancedEmailTemplate.new
    @accounts = Account.all.order(:name)
  end

  def edit
    @advanced_email_template = AdvancedEmailTemplate.find(params[:id])
    @accounts = Account.all.order(:name)
  end

  def create
    @advanced_email_template = AdvancedEmailTemplate.new(advanced_email_template_params)
    if @advanced_email_template.save
      redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.advanced.created')
    else
      @accounts = Account.all.order(:name)
      render :new
    end
  end

  def update
    @advanced_email_template = AdvancedEmailTemplate.find(params[:id])
    if @advanced_email_template.update(advanced_email_template_params)
      redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.advanced.updated')
    else
      @accounts = Account.all.order(:name)
      render :edit
    end
  end

  def destroy
    @advanced_email_template = AdvancedEmailTemplate.find(params[:id])
    @advanced_email_template.destroy
    redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.advanced.deleted')
  end

  private

  def advanced_email_template_params
    params.require(:advanced_email_template).permit(:name, :friendly_name, :description, :template_type, :html, :account_id)
  end
end
