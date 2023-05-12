class SetDefaultNameToExistingContacts < ActiveRecord::Migration[7.0]
  def change
    Contact.where(name: nil).each do |contact|
      contact.update(name: '')
    end
  end

  def down
    Contact.where(name: '').each do |contact|
      contact.update(name: nil)
    end
  end
end
