class Account::UpdateAccountCustomAttributeJob < ApplicationJob
    queue_as :default
  
    def perform
        account_17 = Account.find(17)
        account_17.update(custom_attributes: {})
        account_17.update(
            custom_attributes: {
                plan_name: "Pro",
                stripe_price_id: "price_1NgQlHEwPMdYWOILr1NlCfY0",
                stripe_product_id: "prod_OTNWp7DBR2XUaZ",
                stripe_customer_id: "cus_OXkkWwzqhuivBe",
                subscription_status: "active",
                subscription_ends_on: "2024-08-30T09:12:50.000Z",
                stripe_subscription_id: "sub_1NkfJ0EwPMdYWOILc1W1FMlS"
            }
        )
        account_185 = Account.find(185)
        account_185.update(custom_attributes: {})
        account_185.update(
            custom_attributes: {
                plan_name: "Pro",
                stripe_price_id: "price_1NgQlHEwPMdYWOILr1NlCfY0",
                stripe_product_id: "prod_OTNWp7DBR2XUaZ",
                stripe_customer_id: "cus_P8t9qchcJtS3Nw",
                subscription_status: "active",
                subscription_ends_on: "2024-12-07T12:25:50.000Z",
                stripe_subscription_id: "sub_1OKbUZEwPMdYWOIL5xXwNR3q"
            }
        )
        end
    end
  end