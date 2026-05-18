FactoryBot.define do
  factory :glpi_connection, class: 'ChatwootGlpiIntegration::Connection' do
    association :account
    base_url            { 'https://glpi.example.com' }
    api_path            { '/apirest.php' }
    client_id           { 'client_xyz' }
    client_secret       { 'sssh_secret' }
    scope               { 'api' }
    default_entity_id   { 0 }
    default_request_type_id { 1 }
    webhook_secret      { 'wh_secret' }
    active              { true }
  end

  factory :glpi_ticket_link, class: 'ChatwootGlpiIntegration::TicketLink' do
    association :account
    sequence(:glpi_ticket_id) { |n| 1000 + n }
    sync_direction { 'both' }
  end
end
