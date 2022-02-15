class AddDirectUploadsToInstallationConfig < ActiveRecord::Migration[6.1]
  def change
    ConfigLoader.new.process
  end
end
