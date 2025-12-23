require 'rails_helper'

<% module_namespacing do -%>
RSpec.describe '<%= class_name %>Controller', <%= type_metatag(:routing) %> do
  describe 'routing' do
<% for action in actions -%>
    it 'routes to #<%= action %>' do
      expect(get: "/<%= class_name.underscore %>/<%= action %>").to route_to("<%= class_name.underscore %>#<%= action  %>")
    end
<% end -%>
  end
end
<% end -%>
