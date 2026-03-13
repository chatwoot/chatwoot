# Chatwit Mobile Redesign

> **Status:** MVP Implementation
> **Date:** 2026-03-13
> **Base:** Chatwoot 4.10.1

## Overview

Complete mobile-first redesign of the Chatwit web frontend. When accessed from a smartphone (screen width < 768px), the app now renders a dedicated mobile layout that replicates the Chatwoot mobile app (React Native) experience with 3 bottom tabs: **Inbox**, **Conversations**, and **Settings**.

The desktop experience is completely unchanged — all mobile components are conditionally rendered only on small screens.

## Architecture

### Design Principle

- **Conditional rendering** in `Dashboard.vue`: `<MobileLayout v-if="isSmallScreen" />`
- Desktop sidebar, command bar, and copilot are hidden on mobile
- Mobile layout provides its own navigation via bottom tab bar
- All new code lives in `components-next/mobile/` (per CLAUDE.md: prefer new files over modifying existing ones)
- Reuses existing Vuex stores, composables, and API layers

### Detection

Uses the existing `SMALL_SCREEN_BREAKPOINT: 768` from `constants/globals.js` combined with `useWindowSize()` from `@vueuse/core`. The `isSmallScreen` computed property in `Dashboard.vue` controls which layout renders.

### Navigation

```
Dashboard.vue
├── [Desktop: width >= 768px] → NextSidebar + router-view (unchanged)
└── [Mobile: width < 768px] → MobileLayout.vue
    ├── MobileBottomTabBar (fixed bottom)
    └── Active Tab View:
        ├── Tab 0: MobileInboxView (notifications)
        │   └── (tap) → MobileChatView
        ├── Tab 1: MobileConversationList (conversations)
        │   └── (tap) → MobileChatView
        └── Tab 2: MobileSettingsView (profile/settings)
```

URL-based navigation: Vue Router updates the URL when entering a chat, so browser back button works and links are shareable.

## Components Created

All under `app/javascript/dashboard/components-next/mobile/`:

### Core
| Component | Description |
|-----------|-------------|
| `MobileLayout.vue` | Root wrapper: bottom tab bar + active tab view + chat overlay |
| `MobileBottomTabBar.vue` | Fixed bottom nav with 3 tabs + unread badge on Inbox |
| `MobileBackButton.vue` | Reusable back navigation button |

### Conversations Tab
| Component | Description |
|-----------|-------------|
| `MobileConversationList.vue` | Full-screen conversation list with virtual scrolling, assignee tabs, infinite scroll |
| `MobileConversationHeader.vue` | Header with title + filter button |
| `MobileChatView.vue` | Full-screen chat view wrapping existing `MessagesView` + `ReplyBox` |
| `MobileChatHeader.vue` | Chat header with back button + contact avatar + name |

### Inbox Tab
| Component | Description |
|-----------|-------------|
| `MobileInboxView.vue` | Full-screen notification list using existing `InboxCard` |
| `MobileInboxHeader.vue` | Header with title + "Mark all read" button |
| `MobilePullToRefresh.vue` | Touch-based pull-to-refresh wrapper |

### Settings Tab
| Component | Description |
|-----------|-------------|
| `MobileSettingsView.vue` | Profile section + availability toggle + settings list + logout |
| `MobileSettingsHeader.vue` | Header with title |
| `MobileAvailabilityToggle.vue` | Online/Busy/Offline status toggle |

### Shared
| Component | Description |
|-----------|-------------|
| `MobileBottomSheet.vue` | Reusable bottom sheet modal (teleported to body) |
| `MobileFilterSheet.vue` | Conversation filter sheet (status, assignee, sort) |

## Files Modified

| File | Change |
|------|--------|
| `routes/dashboard/Dashboard.vue` | Added `MobileLayout` import + conditional render in template |
| `tailwind.config.js` | Added `slide-up` keyframe + animation for bottom sheets |
| `public/manifest.json` | Enhanced for PWA: name, display, orientation, theme_color |
| `app/views/layouts/vueapp.html.erb` | Added PWA meta tags (apple-mobile-web-app-capable, viewport-fit=cover) |
| `i18n/locale/en/index.js` | Added mobile.json import |
| `i18n/locale/en/mobile.json` | New file with all mobile UI strings |

## Existing Code Reused

| Component/Utility | From |
|-------------------|------|
| `ConversationCard.vue` | `components/widgets/conversation/ConversationCard.vue` |
| `InboxCard.vue` | `components-next/Inbox/InboxCard.vue` |
| `MessagesView.vue` | `components/widgets/conversation/MessagesView.vue` |
| `ChatTypeTabs.vue` | `components/widgets/ChatTypeTabs.vue` |
| `Avatar.vue` | `components-next/avatar/Avatar.vue` |
| `Spinner.vue` | `components-next/spinner/Spinner.vue` |
| `IntersectionObserver.vue` | `components/IntersectionObserver.vue` |
| `useWindowSize()` | `@vueuse/core` |
| `useUISettings()` | `composables/useUISettings` |
| `useAccount()` | `composables/useAccount` |
| `useMapGetter()` | `composables/store` |
| Vuex stores | conversations, notifications, auth |

## PWA Support

- `manifest.json` enhanced with `display: standalone`, `orientation: portrait`
- Meta tags added: `apple-mobile-web-app-capable`, `mobile-web-app-capable`, `viewport-fit=cover`
- Users can "Add to Home Screen" on iOS/Android for app-like experience
- No service worker in MVP (planned for future offline support)

## Styling

- **Tailwind only** (no custom CSS, no scoped CSS)
- Safe area handling: `pb-[env(safe-area-inset-bottom)]` for notched devices
- Dark mode: all components use `dark:` Tailwind variants
- RTL support: uses `ltr:` / `rtl:` classes where applicable
- Bottom tab bar: fixed position, z-50, border-top separator
- Bottom sheet: slide-up animation via Tailwind keyframes

## Testing Checklist

1. Open browser DevTools → iPhone/Android viewport → bottom tab bar appears, sidebar hidden
2. Tab switching works between Inbox, Conversations, Settings
3. Tap conversation → full-screen chat → back button returns to list
4. Notifications load → tap → opens conversation → mark as read
5. Settings: profile displays, availability toggle works, logout works
6. Desktop (>= 768px): normal layout with sidebar, no mobile components
7. Dark mode renders correctly
8. PWA: "Add to Home Screen" prompts correctly on mobile browsers

---

## Roadmap: Future Improvements

### Phase 2: Enhanced Mobile UX
- [x] Swipe actions on conversation/notification rows (swipe to resolve, delete)
- [x] Gesture-based navigation (swipe right to go back)
- [x] Haptic feedback on interactions
- [x] Improved keyboard handling (auto-scroll on input focus)

### Phase 3: Rich Features
- [ ] Voice message recording in mobile chat
- [ ] Contact detail modal in mobile
- [ ] Conversation assignment/transfer from mobile
- [ ] Mobile-optimized search with recent searches
- [ ] Inline image/file previews optimized for mobile

### Phase 4: PWA Advanced
- [ ] Service worker for offline support
- [ ] Push notifications via Web Push API
- [ ] Background sync for messages
- [ ] PWA install prompt UI
- [ ] App shortcuts in manifest

### Phase 5: Performance
- [ ] Route-based code splitting for mobile components
- [ ] Image lazy loading and progressive rendering
- [ ] Skeleton loading states for all views
- [ ] Virtualized list for large conversation/notification lists

### Phase 6: Platform Parity
- [ ] All settings pages accessible from mobile
- [ ] Contact/company views on mobile
- [ ] Reports summary view on mobile
- [ ] Campaign management on mobile
- [ ] Help center access on mobile

---

## Changelog

### 2026-03-13 — Phase 2: Enhanced Mobile UX

#### New Components
| Component | Path | Description |
|-----------|------|-------------|
| `MobileSwipeableRow.vue` | `components-next/mobile/MobileSwipeableRow.vue` | Reusable swipe-to-reveal actions wrapper for list rows. Supports configurable action buttons, threshold-based activation, horizontal/vertical conflict resolution, and auto-close via provide/inject. |

#### New Composables
| Composable | Path | Description |
|------------|------|-------------|
| `useHaptics.js` | `composables/useHaptics.js` | Vibration API wrapper with `light()`, `medium()`, `heavy()`, `success()` methods. Graceful no-op when API unavailable. |
| `useSwipeBack.js` | `composables/useSwipeBack.js` | Edge-swipe gesture detection composable. Activates on touch within 20px of left edge (right edge in RTL). Returns reactive `swipeOffset` for visual feedback. Threshold: 100px to trigger navigation. |
| `useKeyboardResize.js` | `composables/useKeyboardResize.js` | Virtual keyboard detection via `visualViewport` API. Returns `keyboardHeight` and `isKeyboardOpen` reactive refs. Auto-scrolls focused input into view. |

#### Modified Components
| Component | Path | Changes |
|-----------|------|---------|
| `MobileConversationList.vue` | `components-next/mobile/MobileConversationList.vue` | Wrapped `ConversationCard` in `MobileSwipeableRow` with Resolve/Reopen and Delete swipe actions. Added provide/inject for single-open-row management. Haptic feedback on swipe threshold. |
| `MobileInboxView.vue` | `components-next/mobile/MobileInboxView.vue` | Wrapped `InboxCard` in `MobileSwipeableRow` with Mark Read and Delete swipe actions. Added provide/inject for single-open-row management. Haptic feedback on actions. |
| `MobileChatView.vue` | `components-next/mobile/MobileChatView.vue` | Integrated `useSwipeBack` for edge-swipe-right back navigation with visual slide effect. Integrated `useKeyboardResize` to adjust padding when virtual keyboard opens, keeping reply box visible. |
| `MobileBottomTabBar.vue` | `components-next/mobile/MobileBottomTabBar.vue` | Added haptic feedback (`light()`) on tab switches via `useHaptics`. |
| `MobilePullToRefresh.vue` | `components-next/mobile/MobilePullToRefresh.vue` | Added haptic feedback (`medium()`) when pull distance crosses the refresh threshold. Fires once per gesture via flag. |

#### i18n
| File | Changes |
|------|---------|
| `i18n/locale/en/mobile.json` | Added `MOBILE.SWIPE` keys: `RESOLVE`, `REOPEN`, `DELETE`, `MARK_READ`, `CONFIRM_DELETE` |

#### Functionalities Added
- **Swipe actions**: Swipe left on conversation rows to reveal Resolve/Reopen and Delete buttons; swipe left on notification rows to reveal Mark Read and Delete buttons
- **Haptic feedback**: Vibration API triggers on tab switch, swipe action threshold, pull-to-refresh threshold, and back gesture completion
- **Gesture navigation**: Swipe right from the left screen edge in chat view to navigate back to the list (with RTL support)
- **Keyboard handling**: Chat view auto-adjusts layout when the virtual keyboard opens, preventing the reply box from being hidden behind the keyboard
