class AddFrontendUrlToCustomApis < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_apis, :frontend_url, :string
  end
end
