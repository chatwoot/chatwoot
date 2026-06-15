"""Channel connectors for non-native platforms (personal Telegram/Viber via E-Chat, etc.).

Connector pattern (see docs/knowledge/channels.md): receive a platform event → map the user to
a Chatwoot contact → POST it into a Chatwoot **API-channel** inbox → relay Chatwoot's outgoing
webhook back out to the platform. The Chatwoot side is fully wired here; the platform-specific
adapter (parse inbound / send outbound) is the boundary you complete with your account's API.
"""
