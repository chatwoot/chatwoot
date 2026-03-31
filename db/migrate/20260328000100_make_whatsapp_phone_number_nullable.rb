class MakeWhatsappPhoneNumberNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :channel_whatsapp, :phone_number, true
  end
end
