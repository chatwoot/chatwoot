# ActionView escapes the output of `<%= %>` in every ERB template whose type is not on
# this list, and CSV was never on it. An apostrophe in an agent's name reached the file as
# `&#39;`, and so did the quote CSVSafe prefixes onto a field that would otherwise read as
# a formula, which left the guard visible in the cell.
#
# HTML escaping buys a CSV nothing, because the file is not markup. What a CSV needs is
# quoting, which the CSV library does, and a defused leading `=`, which CSVSafe does. Both
# happen before the value reaches this buffer.
ActiveSupport.on_load(:action_view) do
  csv_type = Mime[:csv].to_s
  ignore_list = ActionView::Template::Handlers::ERB.escape_ignore_list
  ignore_list << csv_type unless ignore_list.include?(csv_type)
end
