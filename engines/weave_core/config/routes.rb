Weave::Core::Engine.routes.draw do
  get "/healthz", to: "health#show"
  get "/metrics", to: "metrics#show"

  namespace :api, defaults: { format: :json } do
    namespace :accounts do
      get ":account_id/features", to: "features#show"
      patch ":account_id/features", to: "features#update"
    end
  end
end
