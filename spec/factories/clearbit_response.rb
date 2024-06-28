# spec/factories/response_bodies.rb
FactoryBot.define do
  factory :clearbit_combined_response, class: Hash do
    skip_create

    initialize_with do
      {
        'person' => {
          'name' => {
            'fullName' => 'John Doe'
          },
          'avatar' => 'https://example.com/avatar.png'
        },
        'company' => {
          'name' => 'Doe Inc.',
          'timeZone' => 'Asia/Kolkata',
          'category' => {
            'sector' => 'Technology',
            'industryGroup' => 'Software',
            'industry' => 'Software'
          },
          'metrics' => {
            'employees' => '1-10'
          }
        }
      }.to_json
    end
  end
end
