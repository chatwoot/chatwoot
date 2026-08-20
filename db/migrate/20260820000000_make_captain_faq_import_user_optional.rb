class MakeCaptainFaqImportUserOptional < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :captain_faq_imports, :users
    change_column_null :captain_faq_imports, :user_id, true
    add_foreign_key :captain_faq_imports, :users, on_delete: :nullify
  end
end
