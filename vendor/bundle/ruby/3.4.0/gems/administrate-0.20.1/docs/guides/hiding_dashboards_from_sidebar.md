---
title: Hiding Dashboards from the Sidebar
---

Resources can be removed from the sidebar by removing their `index` action
from the routes. For example:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :admin do
    resources :line_items, except: :index
    resources :orders
    resources :products
    root to: "customers#index"
  end
end
```

In this case, only Orders and Products will appear in the sidebar, while
Line Items can still appear as an association.
