json.extract! marketing_campaign, :id, :title, :description, :active, :source_id
json.start_date marketing_campaign.start_date&.to_i
json.end_date marketing_campaign.end_date&.to_i
