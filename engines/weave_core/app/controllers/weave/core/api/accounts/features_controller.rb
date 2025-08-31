module Weave
  module Core
    module Api
      module Accounts
        class FeaturesController < BaseController
          before_action :current_account

          def show
            features = Weave::Core::Features.effective_for(Current.account)
            render json: {
              account_id: Current.account.id,
              plan: Weave::Core::Features.plan_for(Current.account),
              features: features
            }
          end

          def update
            unless Current.account_user&.administrator?
              return render json: { error: 'Forbidden' }, status: :forbidden
            end

            updates = params.require(:features).permit!
            updates.to_h.each do |key, value|
              next unless key.is_a?(String)
              ft = Weave::Core::FeatureToggle.find_or_initialize_by(account_id: Current.account.id, feature_key: key)
              ft.enabled = ActiveModel::Type::Boolean.new.cast(value)
              ft.save!
            end
            show
          end
        end
      end
    end
  end
end

