# rubocop:disable Style/ClassAndModuleChildren
module Enterprise
  module Billing
    module V2
      class ProrationCalculator
        # Calculate prorated amounts for subscription changes
        #
        # @param old_plan_price [Float] Price per unit of the old plan
        # @param new_plan_price [Float] Price per unit of the new plan
        # @param old_quantity [Integer] Old quantity/seats
        # @param new_quantity [Integer] New quantity/seats
        # @param next_billing_date [String/Time] Next billing date (ISO 8601)
        # @return [Hash] { credit_amount:, charge_amount:, net_amount:, days_remaining:, total_days: }
        #
        def self.calculate(old_plan_price:, new_plan_price:, old_quantity:, new_quantity:, next_billing_date:)
          new(
            old_plan_price: old_plan_price,
            new_plan_price: new_plan_price,
            old_quantity: old_quantity,
            new_quantity: new_quantity,
            next_billing_date: next_billing_date
          ).calculate
        end

        def initialize(old_plan_price:, new_plan_price:, old_quantity:, new_quantity:, next_billing_date:)
          @old_plan_price = old_plan_price.to_f
          @new_plan_price = new_plan_price.to_f
          @old_quantity = old_quantity.to_i
          @new_quantity = new_quantity.to_i
          @next_billing_date = parse_date(next_billing_date)
          @current_date = Time.zone.now
        end

        def calculate
          {
            credit_amount: credit_amount,
            charge_amount: charge_amount,
            net_amount: net_amount,
            days_remaining: days_remaining,
            total_days: total_days,
            proration_factor: proration_factor
          }
        end

        private

        def parse_date(date)
          return date if date.is_a?(Time) || date.is_a?(DateTime)

          Time.zone.parse(date.to_s)
        rescue StandardError
          raise ArgumentError, "Invalid next_billing_date format: #{date}"
        end

        # Credit from unused time on old plan
        def credit_amount
          @credit_amount ||= (@old_plan_price * @old_quantity * proration_factor).round(2)
        end

        # Charge for new plan for remaining time
        def charge_amount
          @charge_amount ||= (@new_plan_price * @new_quantity * proration_factor).round(2)
        end

        # Net amount to charge (positive) or credit (negative)
        def net_amount
          @net_amount ||= (charge_amount - credit_amount).round(2)
        end

        # Number of days remaining in current billing period
        def days_remaining
          @days_remaining ||= (@next_billing_date.to_date - @current_date.to_date).to_i
        end

        # Total days in the actual billing period (calculate from current cycle)
        # This ensures proration factor never exceeds 1.0
        def total_days
          @total_days ||= begin
            # Calculate the total days in this billing cycle
            # Assume billing started one month ago from next_billing_date
            billing_start = @next_billing_date - 1.month
            ((@next_billing_date.to_date - billing_start.to_date).to_i)
          end
        end

        # Fraction of billing period remaining
        # This value should always be between 0.0 and 1.0
        def proration_factor
          @proration_factor ||= begin
            factor = days_remaining.to_f / total_days
            # Ensure factor never exceeds 1.0
            [factor, 1.0].min.round(4)
          end
        end
      end
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
