class Account::ContactsExportJob < ApplicationJob
  queue_as :low

  def perform(account, column_names)
    headers = column_names

    file = "#{Rails.root}/public/#{account.name}_#{account.id}_contacts.csv"

    CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
      products.each do |product|
        writer << [product.id, product.name, product.price, product.description]
      end
    end
  end
end
