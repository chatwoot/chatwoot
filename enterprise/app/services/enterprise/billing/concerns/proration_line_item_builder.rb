module Enterprise::Billing::Concerns::ProrationLineItemBuilder
  extend ActiveSupport::Concern
  include Enterprise::Billing::Concerns::PlanDataHelper

  private

  def build_proration_line_items(context, proration_data)
    return build_seat_change_line_items(context, proration_data) if seat_only_change?(context)

    build_plan_change_line_items(context, proration_data)
  end

  def seat_only_change?(context)
    !context[:plan_changed] && context[:seats_changed]
  end

  def build_seat_change_line_items(context, proration_data)
    [{
      amount: (proration_data[:net_amount] * 100).to_i,
      description: build_seat_change_description(context),
      metadata: build_seat_change_metadata(context, proration_data)
    }]
  end

  def build_plan_change_line_items(context, proration_data)
    line_items = []
    old_plan_name = plan_display_name(context[:old_plan_id])
    new_plan_name = plan_display_name(context[:target_plan_id])

    line_items << build_credit_line_item(context, proration_data, old_plan_name) if proration_data[:credit_amount].positive?
    line_items << build_charge_line_item(context, proration_data, new_plan_name) if proration_data[:charge_amount].positive?

    line_items
  end

  def build_credit_line_item(context, proration_data, old_plan_name)
    {
      amount: -(proration_data[:credit_amount] * 100).to_i,
      description: credit_description(old_plan_name, context[:old_quantity]),
      metadata: credit_metadata(old_plan_name, context[:old_quantity], proration_data[:days_remaining])
    }
  end

  def build_charge_line_item(context, proration_data, new_plan_name)
    {
      amount: (proration_data[:charge_amount] * 100).to_i,
      description: charge_description(new_plan_name, context[:target_quantity]),
      metadata: charge_metadata(new_plan_name, context[:target_quantity], proration_data[:days_remaining])
    }
  end

  def credit_description(plan_name, quantity)
    "Credit for unused time on #{plan_name} (#{quantity} seat#{quantity > 1 ? 's' : ''})"
  end

  def charge_description(plan_name, quantity)
    "Prorated charge for #{plan_name} (#{quantity} seat#{quantity > 1 ? 's' : ''})"
  end

  def build_seat_change_description(context)
    plan_name = plan_display_name(context[:target_plan_id])
    change_type = context[:target_quantity] > context[:old_quantity] ? 'increase' : 'decrease'
    quantity_diff = (context[:target_quantity] - context[:old_quantity]).abs

    "Seat #{change_type} for #{plan_name}: #{context[:old_quantity]} → #{context[:target_quantity]} " \
      "seats (#{quantity_diff} seat#{quantity_diff > 1 ? 's' : ''})"
  end

  def base_metadata(type, days_remaining, **additional_fields)
    {
      type: type,
      days_remaining: days_remaining,
      billing_version: 'v2'
    }.merge(additional_fields)
  end

  def credit_metadata(plan_name, quantity, days_remaining)
    base_metadata('proration_credit', days_remaining, old_plan: plan_name, old_quantity: quantity)
  end

  def charge_metadata(plan_name, quantity, days_remaining)
    base_metadata('proration_charge', days_remaining, new_plan: plan_name, new_quantity: quantity)
  end

  def build_seat_change_metadata(context, proration_data)
    base_metadata('seat_change', proration_data[:days_remaining],
                  plan_name: plan_display_name(context[:target_plan_id]),
                  old_quantity: context[:old_quantity],
                  new_quantity: context[:target_quantity],
                  quantity_change: context[:target_quantity] - context[:old_quantity])
  end
end
