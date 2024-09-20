class FixFaultyContactInboxes < ActiveRecord::Migration[7.0]
  def change
    Digitaltolk::Tasks::FixFaultyContactInboxes.new.call
  end
end
