TestApp.routes.draw do
  resource :pokemon, :beer
  get 'exit' => proc { exit! }
  get 'pry' => proc { binding.pry; [200, {}, ['']] }
end
