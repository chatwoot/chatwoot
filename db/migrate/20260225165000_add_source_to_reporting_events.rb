class AddSourceToReportingEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :reporting_events, :source, :string
  end
end
