class AddLabelsToDigitalTolk < ActiveRecord::Migration[7.0]
  def change
    account = Account.find(1)
    Digitaltolk::ChangeContactKindService::KIND_LABELS.each do |_key, value|
      label = account.labels.find_or_create_by({ title: value })

      label.update({
                     description: value,
                     color: Faker::Color.hex_color,
                     show_on_sidebar: true
                   })
    end
  end
end
