# ## Index
#
# This view is the template for the index page.
#
# ## Local variables:
#
# - `page`:
#   An instance of [Administrate::Page::Collection][1].
#   Contains helper methods to help display a table,
#   and knows which attributes should be displayed in the resource's table.
# - `resources`:
#   An instance of `ActiveRecord::Relation` containing the resources
#   that match the user's search criteria.
#   By default, these resources are passed to the table partial to be displayed.
# - `search_term`:
#   A string containing the term the user has searched for, if any.
#
# [1]: http://www.rubydoc.info/gems/administrate/Administrate/Page/Collection

json.resources resources do |resource|
  json.id resource.id
  json.dashboard_display_name @dashboard.display_resource(resource)
end
