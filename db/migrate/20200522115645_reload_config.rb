class ReloadConfig < ActiveRecord::Migration[6.0]
  def change
    ConfigLoader.new.process
  end
end
