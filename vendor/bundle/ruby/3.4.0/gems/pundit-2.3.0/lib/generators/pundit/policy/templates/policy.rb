<% module_namespacing do -%>
class <%= class_name %>Policy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
end
<% end -%>
