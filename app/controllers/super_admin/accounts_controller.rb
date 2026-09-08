class SuperAdmin::AccountsController < SuperAdmin::ApplicationController
  before_action :validate_suspension_metadata, only: :update

  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   super
  #   send_foo_updated_email(requested_resource)
  # end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #
  def resource_params
    permitted_params = super
    permitted_params.extract!(:suspension_category, :suspension_reason)
    permitted_params[:limits] = permitted_params[:limits].to_h.compact if permitted_params.key?(:limits)
    permitted_params[:captain_models] = permitted_params[:captain_models].to_h.compact_blank.presence if permitted_params.key?(:captain_models)
    permitted_params[:selected_feature_flags] = params[:enabled_features].keys.map(&:to_sym) if params[:enabled_features].present?
    permitted_params
  end

  def update
    apply_suspension_metadata
    super
  end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  def seed
    Internal::SeedAccountJob.perform_later(requested_resource)
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account seeding triggered')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def reset_cache
    requested_resource.reset_cache_keys
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Cache keys cleared')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def destroy
    account = Account.find(params[:id])

    DeleteObjectJob.perform_later(account) if account.present?
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account deletion is in progress.')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  private

  def validate_suspension_metadata
    return unless suspension_metadata_required?

    validate_suspension_category
    validate_suspension_reason
    return if requested_resource.errors.empty?

    requested_resource.assign_attributes(resource_params.except(:manually_managed_features))
    render :edit,
           locals: { page: Administrate::Page::Form.new(dashboard, requested_resource) },
           status: :unprocessable_entity
  end

  def validate_suspension_category
    if suspension_details[:category].blank?
      requested_resource.errors.add(:suspension_category, :blank)
    elsif Account::SUSPENSION_CATEGORIES.exclude?(suspension_details[:category])
      requested_resource.errors.add(:suspension_category, :inclusion)
    end
  end

  def validate_suspension_reason
    if suspension_details[:reason].blank?
      requested_resource.errors.add(:suspension_reason, :blank)
    elsif suspension_details[:reason].length > 256
      requested_resource.errors.add(:suspension_reason, :too_long, count: 256)
    end
  end

  def suspension_metadata_required?
    return false unless target_status == 'suspended'

    requested_resource.active? ||
      requested_resource.suspension_history.present? ||
      suspension_details.values.any?(&:present?)
  end

  def apply_suspension_metadata
    return unless target_status == 'suspended'

    history = suspension_history_with_changes
    return if history.blank?

    requested_resource.internal_attributes = requested_resource.internal_attributes.merge('suspensions' => history)
  end

  def suspension_history_with_changes
    history = requested_resource.suspension_history.map(&:dup)
    return history << new_suspension_event if requested_resource.active?
    return append_legacy_suspension(history) if history.empty?
    return unless suspension_metadata_changed?(history.last)

    history.tap { |events| events[-1] = events.last.merge(suspension_details.stringify_keys) }
  end

  def append_legacy_suspension(history)
    return if suspension_details.values.none?(&:present?)

    history << new_suspension_event
  end

  def new_suspension_event
    suspension_details.stringify_keys.merge('suspended_at' => Time.current.iso8601)
  end

  def suspension_metadata_changed?(latest_suspension)
    latest_suspension.values_at('category', 'reason') != suspension_details.values_at(:category, :reason)
  end

  def suspension_details
    @suspension_details ||= {
      category: params.dig(:account, :suspension_category).to_s,
      reason: params.dig(:account, :suspension_reason).to_s.strip
    }
  end

  def target_status
    params.dig(:account, :status).to_s
  end
end

SuperAdmin::AccountsController.prepend_mod_with('SuperAdmin::AccountsController')
