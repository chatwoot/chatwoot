# Renders fields that sit outside the <form> they belong to: each check box names that form
# through the HTML `form` attribute, and so does the hidden "0" Rails writes next to it, so the
# browser submits them with it. Used for the account fields Enterprise's own account form does
# not render (super_admin/accounts/_agent_restrictions.html.erb).
class SuperAdmin::LinkedFormBuilder < ActionView::Helpers::FormBuilder
  def check_box(method, options = {}, checked_value = '1', unchecked_value = '0')
    super(method, options.merge(form: @options.fetch(:linked_form)), checked_value, unchecked_value)
  end
end
