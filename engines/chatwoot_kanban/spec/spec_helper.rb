# The engine relies on the host application's rails_helper for full setup.
# Run the engine specs from the host root with:
#   bundle exec rspec engines/chatwoot_kanban/spec
#
# No standalone rails_helper here on purpose — we want the host's DB, factories
# (account, user, conversation) and devise_token_auth headers.
require 'rspec'
