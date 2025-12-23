---
title: Adding Controllers without a related Model
---

Sometimes you may want to add a custom controller that has no resource
related to it (for example for a statistics page).

To do that, you must define an `index` route, as only controllers with index
routes are displayed in the sidebar and then add a custom dashboard:

```erb
# app/views/admin/stats/index.html.erb 

<div style="padding: 20px">
  <h1>Stats</h1>
  <br>
  <p><b>Total Customers:</b> <%= @stats[:customer_count] %></p>
  <br>
  <p><b>Total Orders:</b> <%= @stats[:order_count] %></p>
</div>
```

```ruby
# app/dashboards/stat_dashboard.rb
require "administrate/custom_dashboard"

class StatDashboard < Administrate::CustomDashboard
  resource "Stats" # used by administrate in the views
end
```

```ruby
# app/controllers/admin/stats_controller.rb
module Admin
  class StatsController < Admin::ApplicationController
    def index
      @stats = {
        customer_count: Customer.count,
        order_count: Order.count,
      }
    end
  end
end
```

```ruby
# config/routes.rb
namespace :admin do
  # ...
  resources :stats, only: [:index]
end
```
