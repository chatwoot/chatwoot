<% module_namespacing do -%>
# Preview all emails at http://localhost:3000/rails/mailers/<%= file_path %>_mailer
class <%= class_name %><%= 'Mailer' unless class_name.end_with?('Mailer') %>Preview < ActionMailer::Preview
<% actions.each do |action| -%>

  # Preview this email at http://localhost:3000/rails/mailers/<%= file_path %>_mailer/<%= action %>
  def <%= action %>
    <%= class_name.sub(/(Mailer)?$/, 'Mailer') %>.<%= action %>
  end
<% end -%>

end
<% end -%>
