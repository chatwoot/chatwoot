class SuperAdmin::AccountEmailTemplatesController < SuperAdmin::ApplicationController
  def show
    @account_email_template = AccountEmailTemplate.find(params[:id])
  end

  def new
    @account_email_template = AccountEmailTemplate.new
    @accounts = Account.all.order(:name)
  end

  def edit
    @account_email_template = AccountEmailTemplate.find(params[:id])
    @accounts = Account.all.order(:name)
  end

  def create
    @account_email_template = AccountEmailTemplate.new(account_email_template_params)
    if @account_email_template.save
      redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.account.created')
    else
      @accounts = Account.all.order(:name)
      render :new
    end
  end

  def update
    @account_email_template = AccountEmailTemplate.find(params[:id])
    if @account_email_template.update(account_email_template_params)
      redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.account.updated')
    else
      @accounts = Account.all.order(:name)
      render :edit
    end
  end

  def destroy
    @account_email_template = AccountEmailTemplate.find(params[:id])
    @account_email_template.destroy
    redirect_to super_admin_email_templates_path, notice: t('super_admin.email_templates.account.deleted')
  end

  private

  def account_email_template_params
    params.require(:account_email_template).permit(:name, :friendly_name, :description, :template_type, :html, :account_id)
  end
end
