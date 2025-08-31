Rails.application.config.to_prepare do
  next unless ActiveModel::Type::Boolean.new.cast(ENV.fetch('WSC_2FA_ENFORCE', false))

  mod = Module.new do
    def enforce_wsc_two_factor
      # Allow 2FA endpoints themselves
      return if request.path.start_with?('/wsc/api/profile/two_factor')
      return unless current_user

      account_id = extract_account_id_from_path_for_2fa(request)
      return unless account_id

      account_user = ::AccountUser.find_by(account_id: account_id, user_id: current_user.id)
      return unless account_user&.administrator?

      unless current_user.two_factor_enabled
        render json: { error: 'Two-factor authentication required for administrators' }, status: :forbidden
      end
    end

    private

    def extract_account_id_from_path_for_2fa(req)
      if (m = %r{^/api/(v1|v2)/accounts/(?<id>\d+)}.match(req.path))
        m[:id].to_i
      else
        nil
      end
    end
  end

  ::Api::BaseController.class_eval do
    before_action :enforce_wsc_two_factor
    include mod
  end
end

