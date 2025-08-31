Weave::Core::Engine.routes.draw do
  get "/healthz", to: "health#show"
  get "/metrics", to: "metrics#show"

  namespace :api, defaults: { format: :json } do
    # 2FA management for current user
    scope :profile do
      scope :two_factor, controller: 'two_factor' do
        get :setup, action: :setup
        post :enable, action: :enable
        post :disable, action: :disable
      end
    end
    namespace :accounts do
      get ":account_id/features", to: "features#show"
      patch ":account_id/features", to: "features#update"
    end
  end
end
