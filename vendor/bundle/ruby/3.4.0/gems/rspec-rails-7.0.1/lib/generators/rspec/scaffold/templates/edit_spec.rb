require 'rails_helper'

<% output_attributes = attributes.reject{|attribute| [:datetime, :timestamp, :time, :date].index(attribute.type) } -%>
RSpec.describe "<%= ns_table_name %>/edit", <%= type_metatag(:view) %> do
  let(:<%= singular_table_name %>) {
    <%= class_name %>.create!(<%= ')' if output_attributes.empty? %>
<% output_attributes.each_with_index do |attribute, attribute_index| -%>
      <%= attribute.name %>: <%= attribute.default.inspect %><%= attribute_index == output_attributes.length - 1 ? '' : ','%>
<% end -%>
<%= "    )\n" unless output_attributes.empty? -%>
  }

  before(:each) do
    assign(:<%= singular_table_name %>, <%= singular_table_name %>)
  end

  it "renders the edit <%= ns_file_name %> form" do
    render

    assert_select "form[action=?][method=?]", <%= ns_file_name %>_path(<%= singular_table_name %>), "post" do
<% for attribute in output_attributes -%>
      <%- name = attribute.respond_to?(:column_name) ? attribute.column_name : attribute.name %>
      assert_select "<%= attribute.input_type -%>[name=?]", "<%= ns_file_name %>[<%= name %>]"
<% end -%>
    end
  end
end
