Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :admin do
    resources :posts do
      delete :other_image, on: :member, action: :destroy_other_image
    end

    root to: "posts#index"
  end
end
