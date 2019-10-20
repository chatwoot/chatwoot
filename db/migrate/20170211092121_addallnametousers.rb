class Addallnametousers < ActiveRecord::Migration[5.0]
  def change
    User.all.each do |u|
      u.name = 'Subash'
      u.save!
    end
  end
end
