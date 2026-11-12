# Who a calling inbox rings and what happens outside business hours, for Twilio and WhatsApp alike
json.ring_strategy channel.sequential_ringing? ? 'sequential' : 'simultaneous'
json.ring_step_seconds channel.ring_step_seconds
json.assignee_rings_first channel.assignee_rings_first?
json.call_cooldown_seconds channel.call_cooldown_seconds
json.business_hours_calls_enabled channel.business_hours_calls_enabled?
