class Account::MoveLtdAccountsJob < ApplicationJob
    queue_as :default
  
    def perform
        # Find accounts with coupon_code_used >= 1
        accounts_to_move = Account.where("coupon_code_used >= 1")
    
        # Your logic for moving the accounts goes here
        accounts_to_move.each do |account|
            if account.coupon_code_used == 1
                account.update(ltd_attributes: { ltd_plan_name: 'Tier 1', ltd_quantity: 3 },limits: { agents: 3 , inboxes: 100000})
            elsif account.coupon_code_used == 2
                account.update(ltd_attributes: { ltd_plan_name: 'Tier 2', ltd_quantity: 5 },limits: { agents: 5 , inboxes: 100000})
            elsif account.coupon_code_used == 3
                account.update(ltd_attributes: { ltd_plan_name: 'Tier 3', ltd_quantity: 15 },limits: { agents: 15 , inboxes: 100000})
            elsif account.coupon_code_used == 5
                account.update(ltd_attributes: { ltd_plan_name: 'Tier 4', ltd_quantity: 100000 },limits: { agents: 100000 , inboxes: 100000})
            end
        end
      end
  end
  