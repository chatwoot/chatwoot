json.partial! 'api/v1/models/account', formats: [:json], resource: @account
json.partial! 'enterprise/api/v1/accounts/partials/account', account: @account if ChatwootApp.enterprise?
