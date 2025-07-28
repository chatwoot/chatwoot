json.data do
  json.array! @scenarios do |scenario|
    json.partial! 'api/v1/models/captain/scenario', scenario: scenario
  end
end
