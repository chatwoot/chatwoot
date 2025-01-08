curl --location --request GET 'http://localhost:3000/api/v2/accounts/1/reports/agents?since=1603823400&until=1604341800' \
--header 'api_access_token: R5sCYvpAYqdpQc7iR2FnVF4q' \
--header 'Content-Type: text/plain' \
--header 'Cookie: __profilin=p%3Dt' \
--data-raw '{
  "since" =>  "1603823400",
  "until"=> "1604341800"

}'
