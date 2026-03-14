# Chatwit Mobile — Quick Reference

This file supplements SKILL.md with concrete paths, store mappings, and production constraints. Read this after SKILL.md when you need implementation details.

## Production constraints

- **No Firebase/FCM.** Push notifications use Web Push via VAPID protocol. Keys are auto-generated on first boot and stored in the `InstallationConfig` database table.
- **No Chatwoot Hub.** `ENABLE_PUSH_RELAY_SERVER=false`. The hub relay is blocked.
- **No native app.** `IOS_APP_ID` and `ANDROID_BUNDLE_ID` are removed. Chatwit is PWA-only.
- **Service worker:** `public/sw.js` handles push events and notification clicks.
- **Push helper:** `app/javascript/dashboard/helper/pushHelper.js` — `requestPushPermissions()`, `registerSubscription()`, `hasPushPermissions()`.
- **Backend push delivery:** `app/services/notification/push_notification_service.rb` routes to `send_browser_push` (VAPID) for web subscriptions.

## Store action map

Use this table to find the exact desktop action/getter for any mobile feature. Search the store module file if you need the implementation.

| Feature | Store module | Key actions | Key getters |
|---------|-------------|-------------|-------------|
| Conversation status | `store/modules/conversations/actions.js` | `toggleStatus`, `updateConversation` | `getConversationById` |
| Assignee | `store/modules/conversations/actions.js` | `assignAgent`, `setCurrentChatAssignee` | `getSelectedChat` |
| Team | `store/modules/conversations/actions.js` | `assignTeam`, `setCurrentChatTeam` | `getSelectedChat` |
| Priority | `store/modules/conversations/actions.js` | `assignPriority`, `setCurrentChatPriority` | `getSelectedChat` |
| Labels | `store/modules/conversationLabels/` | `conversationLabels/get`, `conversationLabels/update` | `conversationLabels/getConversationLabels` |
| Participants | `store/modules/conversationWatchers.js` | `conversationWatchers/show`, `conversationWatchers/update` | `conversationWatchers/getByConversationId` |
| Agents list | `store/modules/agents.js` | `agents/get` | `agents/getAgents` |
| Teams list | `store/modules/teams/` | `teams/get` | `teams/getTeams` |
| Contact details | `store/modules/contacts/` | `contacts/show` | `contacts/getContact` |
| Notifications | `store/modules/notifications/` | `notifications/index`, `notifications/read` | `notifications/getNotifications` |
| Push subscriptions | API client `api/notificationSubscription.js` | `NotificationSubscriptions.create()` | — |

## Existing mobile components

These already exist and can be extended or composed:

| Component | Purpose |
|-----------|---------|
| `MobileLayout.vue` | Root shell with bottom tabs + tab views |
| `MobileConversationList.vue` | Conversation list with swipe actions |
| `MobileChatView.vue` | Two-page pager: chat + conversation actions |
| `MobileConversationActionsView.vue` | Second page: status, assignee, team, priority, labels, participants, attributes |
| `MobileInboxView.vue` | Notification list with swipe actions |
| `MobileSettingsView.vue` | Profile, availability, push toggle, logout |
| `MobileBottomSheet.vue` | Reusable sheet modal |
| `MobileSwipeableRow.vue` | Reusable swipe-to-reveal wrapper |
| `MobilePullToRefresh.vue` | Pull-to-refresh gesture wrapper |

## Existing composables

| Composable | Purpose |
|------------|---------|
| `useHaptics.js` | Vibration API wrapper |
| `useSwipeBack.js` | Edge-swipe gesture for back navigation |
| `useKeyboardResize.js` | Virtual keyboard detection and layout adjustment |

## i18n structure

Mobile strings live in `app/javascript/dashboard/i18n/locale/*/mobile.json` under the `MOBILE` key.

Sections: `TABS`, `INBOX`, `CONVERSATIONS`, `CHAT`, `ACTIONS` (with subsections: `SECTIONS`, `STATUS`, `CTA`, `ASSIGNEE`, `TEAM`, `LABELS`, `PARTICIPANTS`, `ATTRIBUTES`, `PICKERS`, `SEARCH`, `EMPTY`), `SETTINGS`, `FILTER_SHEET`, `STATUS_SHEET`, `SWIPE`, `PUSH`.

Always add keys to all three locales: `en`, `pt`, `pt_BR`.
