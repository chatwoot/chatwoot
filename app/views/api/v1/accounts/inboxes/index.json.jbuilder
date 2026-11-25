# The key for exactly this response. A rolling deploy can answer /cache_keys from one build
# and this request from another, and the browser would then file an old payload under the
# new build's key, where it stays valid for good. Sending the key with the body it describes
# is what makes the two impossible to mismatch.
json.cache_key Current.account.cache_keys[:inbox]

json.payload do
  json.array! @inboxes do |inbox|
    json.partial! 'api/v1/models/inbox', formats: [:json], resource: inbox
  end
end
