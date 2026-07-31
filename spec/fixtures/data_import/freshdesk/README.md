# Freshdesk fixture provenance

These fixtures contain no production credentials, signed attachment URLs, or
personal data. Their field shapes were derived from the Freshdesk API v2
documentation, sanitized examples in these public repositories, and a
sanitized Freshdesk trial-account Web Chat response captured during live API
validation:

- [`Aaronontheweb/freshdesk-cli` ticket with conversations](https://github.com/Aaronontheweb/freshdesk-cli/blob/c87b74043a1662646378cd3385ec0db9af6fa28c/tests/TestData/FreshdeskResponses/ticket_with_conversations.json)
- [`airbytehq/airbyte` Freshdesk expected records](https://github.com/airbytehq/airbyte/blob/0673d69418fe3874a6970d6113eec891db4a296b/airbyte-integrations/connectors/source-freshdesk/integration_tests/expected_records.jsonl)
- [`pbrane/freshdesk-api-client` conversation fixture](https://github.com/pbrane/freshdesk-api-client/blob/c6685af0bf2da889b4a89ccb6cfeb53e65eb5575/src/main/resources/freshdesk/documents/tac-case-notes/tacCase99Conversations.json)
- [`freshworks-developers/fw-attach` conversation event fixture](https://github.com/freshworks-developers/fw-attach/blob/45b7ea1ad6b9008b9edb73ecca349ee9d3b28a6d/server/test_data/support_ticket/onConversationCreate.json)

The fixture intentionally covers an incoming ticket description, a public
agent reply, a private note with attachment metadata, and a later customer
reply.

`web_chat_ticket_with_conversations.json` covers Freshdesk's current Web Chat
ticket source (`15`), structured conversation bodies, the generated greeting,
the initial customer message repeated in the ticket description, subsequent
replies, and real attachment metadata keys. IDs, timestamps, addresses, names,
content, and attachment URLs were replaced or removed.
