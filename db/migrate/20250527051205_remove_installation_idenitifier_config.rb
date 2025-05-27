class RemoveInstallationIdenitifierConfig < ActiveRecord::Migration[7.0]
  def up
    config = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')
    config&.destroy
  end
end
