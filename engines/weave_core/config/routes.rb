Weave::Core::Engine.routes.draw do
  get "/healthz", to: "health#show"
end

