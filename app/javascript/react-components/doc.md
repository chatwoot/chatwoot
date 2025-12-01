# Chatwoot React Components - Architecture Documentation

This document provides comprehensive context for the embeddable chat UI components built with React by wrapping Vue components as Web Components.

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Build System](#build-system)
4. [Component Hierarchy](#component-hierarchy)
5. [Key Patterns](#key-patterns)
6. [Runtime Theme Customization](#runtime-theme-customization)
7. [Real-time Communication](#real-time-communication)
8. [File Structure](#file-structure)
9. [Extension Guide](#extension-guide)
10. [Known Limitations](#known-limitations)

---

## Overview

The system enables embedding Chatwoot's conversation UI into any React application. It achieves this through a **three-layer architecture**:

1. **React Layer** - Provider pattern for configuration and React-friendly API
2. **Web Component Layer** - Vue components converted to Custom Elements via `defineCustomElement`
3. **Vue Layer** - Existing Chatwoot Vue components reused without modification

### Why This Approach?

- **Code Reuse**: Leverage existing battle-tested Vue components (`components-next/message/*`)
- **Framework Agnostic**: Web Components work in any framework (React, Angular, vanilla JS)
- **Isolated Styles**: Shadow DOM encapsulation prevents CSS conflicts
- **Shared State**: Single Vuex store instance across all components

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     React Application                            │
├─────────────────────────────────────────────────────────────────┤
│  <ChatwootProvider>                                              │
│    ├── Sets up globals (window.__WOOT_*)                        │
│    ├── Initializes Vuex store                                   │
│    ├── Registers Web Components                                 │
│    └── Initializes ActionCable (WebSocket)                      │
│                                                                  │
│    <ChatwootConversation>                                        │
│      └── <ChatwootMessageListWrapper>                           │
│            └── <chatwoot-message-list> (Web Component)          │
│                  └── [Shadow DOM]                               │
│                        └── MessageList.vue                      │
│                              ├── Message.vue (components-next)  │
│                              ├── TypingIndicator.vue            │
│                              └── LiteReplyBox.vue               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Build System

### Build Modes (vite.config.ts)

The Vite configuration supports multiple build modes via `BUILD_MODE` environment variable:

| Mode | Command | Output | Purpose |
|------|---------|--------|---------|
| `library` | `pnpm build:sdk` | `public/packs/js/sdk.js` | Widget SDK (IIFE) |
| `ui` | `pnpm build:ui` | `public/packs/js/ui.js` | Standalone UI (IIFE) |
| `react-components` | `pnpm build:react` | `public/packs/react-components.{es,cjs}.js` | NPM package (ES + CJS) |
| (default) | `bin/vite build` | Standard Vite output | Main app build |

### React Components Build Pipeline

```bash
# Full build and package
pnpm package:react

# Build only (no packaging)
pnpm build:react

# Copy mode (skip build, just package)
node scripts/package-react-components.js --copyMode
```

**Build Output** (`dist/react-components/`):
- `index.js` - ES module entry
- `index.cjs` - CommonJS entry
- `style.css` - Bundled styles
- `package.json` - Generated with timestamp versioning

### Plugin Configuration

```javascript
// react-components mode plugins
plugins = [
  vue({ ...vueOptions, customElement: true }),  // Enable CE mode
  react()                                        // React JSX transform
];

// Rollup externals - React is peer dependency
rollupOptions = {
  external: ['react', 'react-dom'],
};
```

---

## Component Hierarchy

### React Components (`src/components/`)

#### ChatwootProvider.jsx
**Purpose**: Root provider that initializes the entire Chatwoot environment.

**Key Responsibilities**:
1. Validates required props (`baseURL`, `userToken`)
2. Registers Vue Web Components via `registerVueWebComponents()`
3. Sets up global window variables for Vue components
4. Initializes axios with authentication
5. Dispatches `setUser` to hydrate auth state
6. Initializes ActionCable for real-time updates

**Props**:
```typescript
interface ChatwootProviderProps {
  baseURL: string;        // Required: Chatwoot API URL
  userToken: string;      // Required: Agent access token
  accountId: number;      // Account ID
  conversationId: number; // Conversation to display
  websocketURL?: string;  // WebSocket server URL
  pubsubToken?: string;   // PubSub authentication token
  disableUpload?: boolean; // Disable file attachments
  disableEditor?: boolean; // Disable reply editor
}
```

**Global Variables Set**:
```javascript
window.__WOOT_API_HOST__      // API base URL
window.__WOOT_ACCOUNT_ID__    // Account ID
window.__WOOT_ACCESS_TOKEN__  // Auth token (used by axios)
window.__WEBSOCKET_URL__      // WebSocket URL
window.__PUBSUB_TOKEN__       // Real-time auth token
window.__WOOT_CONVERSATION_ID__ // Active conversation
window.__EDITOR_DISABLE_UPLOAD__ // Upload flag
window.__DISABLE_EDITOR__     // Editor flag
window.__WOOT_ISOLATED_SHELL__ // Disables audio notifications
window.__CHATWOOT_STORE__     // Vuex store reference
window.WootConstants          // Global constants
window.axios                  // Configured axios instance
```

#### ChatwootConversation.jsx
**Purpose**: High-level wrapper providing styled container.

**Pattern**: Uses `useChatwoot()` hook to enforce Provider context.

#### ChatwootMessageListWrapper.jsx
**Purpose**: Bridge between React and Web Component.

**Key Pattern - Imperative Handle Updates**:
```jsx
// React props → Web Component properties
useEffect(() => {
  element.conversationId = conversationId;
}, [conversationId]);
```

**Event Forwarding**:
```jsx
element.addEventListener('chatwoot:loaded', handleLoad);
element.addEventListener('chatwoot:error', handleError);
```

### Web Component Layer (`src/vue-components/`)

#### registerWebComponents.js
**Purpose**: Converts Vue SFCs to Web Components and registers them.

**Key Pattern - Style Injection**:
```javascript
const ceOptions = {
  configureApp(app) {
    app.use(store);
    app.use(VueDOMPurifyHTML, domPurifyConfig);
    app.use(i18n);
    app.provide(I18nInjectionKey, i18n);
    vueActionCable.init(store, window.__PUBSUB_TOKEN__);
  },
  // Styles bundled into Shadow DOM
  styles: [chatwootStyles, multiselectStyles, floatingVueStyles, uploadStyles],
};

const ChatwootMessageListElement = defineCustomElement(
  ChatwootMessageListWebComponent,
  ceOptions
);
```

**Important**: Styles are imported with `?inline` query to get CSS as string:
```javascript
import chatwootStyles from '../../../dashboard/assets/scss/app.scss?inline';
```

#### ChatwootMessageListWebComponent.vue
**Purpose**: Thin wrapper that renders the actual MessageList.

**Pattern - Additional Styles for Third-Party Components**:
```vue
<style>
/* vue-upload-component requires these styles */
.file-uploads { /* ... */ }
</style>
```

### Vue Layer (`/app/javascript/ui/`)

#### MessageList.vue
**Purpose**: Core conversation view with infinite scroll.

**Key Features**:
1. **Infinite Scroll**: Uses `@vueuse/core`'s `useInfiniteScroll`
2. **Typing Indicators**: Real-time via `conversationTypingStatus` store module
3. **Message Rendering**: Uses `components-next/message/Message.vue`
4. **Reply Box**: Integrated `LiteReplyBox.vue`

**Data Flow**:
```javascript
// Gets conversation ID from global
const conversationId = computed(() => window.__WOOT_CONVERSATION_ID__);

// Fetches conversation data on mount
onMounted(async () => {
  await store.dispatch('inboxes/get');
  await Promise.all([
    store.dispatch('getConversation', conversationId.value),
    store.dispatch('fetchAllAttachments', conversationId.value),
  ]);
});
```

**Key Pattern - Store Access Without Vue Instance**:
```javascript
// From composables/store.js
export const useStore = () => {
  if (window.__CHATWOOT_STORE__) {
    return window.__CHATWOOT_STORE__;
  }
  // Fallback to Vue instance
  const vm = getCurrentInstance();
  return vm.proxy.$store;
};
```

#### LiteReplyBox.vue
**Purpose**: Message composition editor.

**Key Features**:
- Rich text editing via ProseMirror (`WootMessageEditor`)
- File attachments with preview
- Typing indicators (on/off status)
- Keyboard shortcuts (Cmd/Ctrl+Enter to send)
- Private notes support

**Conditional Features via Globals**:
```javascript
isEditorDisabled() {
  return window.__DISABLE_EDITOR__;
},
allowFileUpload() {
  return window.__EDITOR_DISABLE_UPLOAD__ !== true;
},
```

#### axios.js (UI-specific axios factory)
**Purpose**: Creates axios instance configured for external use.

**Pattern - Token from Global**:
```javascript
export default axios => {
  const apiHost = window.__WOOT_API_HOST__;
  const accessToken = window.__WOOT_ACCESS_TOKEN__;

  const wootApi = axios.create({ baseURL: `${apiHost}/` });

  Object.assign(wootApi.defaults.headers.common, {
    api_access_token: accessToken,
  });

  return wootApi;
};
```

---

## Key Patterns

### 1. Global Variable Bridge

Vue components expect certain globals. The React provider sets these before rendering:

```javascript
// Set by ChatwootProvider
window.__WOOT_API_HOST__ = config.baseURL;
window.__WOOT_ACCOUNT_ID__ = config.accountId;
// ...etc

// Consumed by Vue components
const accountIdFromRoute = window.__WOOT_ACCOUNT_ID__;
```

### 2. Vuex Store as Global Singleton

The store is created once and shared via `window.__CHATWOOT_STORE__`:

```javascript
// In ChatwootProvider
import store from '../../../dashboard/store';
window.__CHATWOOT_STORE__ = store;

// In Vue composables
export const useStore = () => {
  if (window.__CHATWOOT_STORE__) {
    return window.__CHATWOOT_STORE__;
  }
  // ...
};
```

### 3. I18n in Web Components

Vue I18n requires special injection for Web Components:

```javascript
// Must provide I18nInjectionKey for useI18n() to work in CE mode
app.use(i18n);
app.provide(I18nInjectionKey, i18n);
```

Reference: https://vue-i18n.intlify.dev/guide/advanced/wc

### 4. Isolated Shell Mode

The `__WOOT_ISOLATED_SHELL__` flag disables features not needed in embedded mode:

```javascript
// In actionCable.js
if (!window.__WOOT_ISOLATED_SHELL__) {
  DashboardAudioNotificationHelper.onNewMessage(data);
}
```

### 5. CamelCase Transformation

API returns snake_case, Vue components expect camelCase:

```javascript
import { useCamelCase } from '../dashboard/composables/useTransformKeys';

const allMessages = computed(() => {
  return useCamelCase(conversation.value.messages, { deep: true }).reverse();
});
```

### 6. Web Component Event Communication

Web Components emit custom events that React can listen to:

```javascript
// In Web Component
this.$emit('chatwoot:loaded');
this.$emit('chatwoot:error', { message: 'Error details' });

// In React wrapper
element.addEventListener('chatwoot:loaded', handleLoad);
element.addEventListener('chatwoot:error', handleError);
```

### 7. CSS Variable Theming for Bubbles

Message bubble styles use CSS custom properties that can be overridden from outside the Shadow DOM:

```javascript
// In Base.vue - uses CSS variables for colors
const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]: 'bg-[rgb(var(--bubble-agent-bg))] text-[rgb(var(--bubble-agent-text))]',
  [MESSAGE_VARIANTS.USER]: 'bg-[rgb(var(--bubble-user-bg))] text-[rgb(var(--bubble-user-text))]',
  // ...
};

// Border radius also uses variables
const orientationMap = {
  [ORIENTATION.LEFT]: 'rounded-[var(--bubble-radius)] ltr:rounded-bl-[var(--bubble-radius-sm)]...',
  // ...
};
```

Variables are defined in `_next-colors.scss` and can be overridden via `bubble-overrides.css`.

---

## Runtime Theme Customization

The Web Component supports runtime theming via CSS custom properties. These variables **inherit through the Shadow DOM boundary**, allowing consumers to customize bubble appearance without modifying the source.

### Available CSS Variables

#### Colors (RGB values without commas)

| Variable | Description | Default |
|----------|-------------|---------|
| `--chatwoot-bubble-agent-bg` | Agent message background | `--solid-blue` |
| `--chatwoot-bubble-agent-text` | Agent message text | `--slate-12` |
| `--chatwoot-bubble-user-bg` | User/customer message background | `--slate-4` |
| `--chatwoot-bubble-user-text` | User message text | `--slate-12` |
| `--chatwoot-bubble-private-bg` | Private note background | `--solid-amber` |
| `--chatwoot-bubble-private-text` | Private note text | `--amber-12` |
| `--chatwoot-bubble-bot-bg` | Bot/template message background | `--solid-iris` |
| `--chatwoot-bubble-bot-text` | Bot message text | `--slate-12` |

#### Meta (timestamp) - Per Variant

| Variable | Description | Default |
|----------|-------------|---------|
| `--chatwoot-bubble-agent-meta` | Meta text for agent messages | `--slate-11` |
| `--chatwoot-bubble-user-meta` | Meta text for user messages | `--slate-11` |
| `--chatwoot-bubble-private-meta` | Meta text for private notes (50% opacity applied) | `--amber-12` |
| `--chatwoot-bubble-bot-meta` | Meta text for bot messages | `--slate-11` |

#### Message Status Icons - Per Variant

| Variable | Description | Default |
|----------|-------------|---------|
| `--chatwoot-bubble-agent-status` | Agent: sent/delivered/progress color | `--slate-10` |
| `--chatwoot-bubble-agent-status-read` | Agent: read receipt color | `126 182 255` |
| `--chatwoot-bubble-user-status` | User: sent/delivered/progress color | `--slate-10` |
| `--chatwoot-bubble-user-status-read` | User: read receipt color | `126 182 255` |
| `--chatwoot-bubble-private-status` | Private: sent/delivered/progress color | `--amber-11` |
| `--chatwoot-bubble-private-status-read` | Private: read receipt color | `126 182 255` |
| `--chatwoot-bubble-bot-status` | Bot: sent/delivered/progress color | `--slate-10` |
| `--chatwoot-bubble-bot-status-read` | Bot: read receipt color | `126 182 255` |

#### Spacing

| Variable | Description | Default |
|----------|-------------|---------|
| `--chatwoot-bubble-spacing-ratio` | Scale factor for border radius | `1` |

### Usage Examples

#### Option 1: Global CSS

```css
/* In your app's CSS file */
:root {
  --chatwoot-bubble-agent-bg: 59 130 246;    /* Blue */
  --chatwoot-bubble-user-bg: 243 244 246;    /* Light gray */
  --chatwoot-bubble-spacing-ratio: 1.5;      /* 50% more rounded */
}
```

#### Option 2: Wrapper with Inline Styles

```jsx
function App() {
  return (
    <div
      style={{
        '--chatwoot-bubble-agent-bg': '59 130 246',
        '--chatwoot-bubble-user-bg': '243 244 246',
        '--chatwoot-bubble-spacing-ratio': '1.5',
      }}
    >
      <ChatwootProvider {...props}>
        <ChatwootConversation />
      </ChatwootProvider>
    </div>
  );
}
```

#### Option 3: Dynamic Theming

```jsx
function App() {
  const [theme, setTheme] = useState({
    '--chatwoot-bubble-agent-bg': '59 130 246',
  });

  return (
    <div style={theme}>
      <button onClick={() => setTheme({
        '--chatwoot-bubble-agent-bg': '34 197 94',  // Switch to green
      })}>
        Change Theme
      </button>
      <ChatwootProvider {...props}>
        <ChatwootConversation />
      </ChatwootProvider>
    </div>
  );
}
```

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│  Consumer's CSS                                                  │
│  :root { --chatwoot-bubble-agent-bg: 59 130 246; }             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (CSS inheritance)
┌─────────────────────────────────────────────────────────────────┐
│  Shadow DOM (:host)                                              │
│  bubble-overrides.css:                                          │
│    --bubble-agent-bg: var(--chatwoot-bubble-agent-bg,           │
│                           var(--solid-blue));                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (used by components)
┌─────────────────────────────────────────────────────────────────┐
│  Base.vue                                                        │
│  class="bg-[rgb(var(--bubble-agent-bg))]"                       │
└─────────────────────────────────────────────────────────────────┘
```

### Key Files

| File | Purpose |
|------|---------|
| `src/styles/bubble-overrides.css` | Defines `:host` overrides that bridge external variables |
| `dashboard/assets/scss/_next-colors.scss` | Default theme values |
| `dashboard/components-next/message/bubbles/Base.vue` | Consumes CSS variables |

---

## Real-time Communication

### ActionCable Setup

```javascript
// BaseActionCableConnector.js
const websocketURL = websocketHost ? `${websocketHost}/cable` : undefined;
this.consumer = createConsumer(websocketURL);
this.subscription = this.consumer.subscriptions.create({
  channel: 'RoomChannel',
  pubsub_token: pubsubToken,
  account_id: app.$store.getters.getCurrentAccountId,
  user_id: app.$store.getters.getCurrentUserID,
});
```

### Events Handled

| Event | Action |
|-------|--------|
| `message.created` | Add message to conversation |
| `message.updated` | Update existing message |
| `conversation.typing_on` | Show typing indicator |
| `conversation.typing_off` | Hide typing indicator |
| `presence.update` | Update online status |
| `conversation.updated` | Refresh conversation data |

### Presence Updates

Heartbeat every 20 seconds:

```javascript
const PRESENCE_INTERVAL = 20000;
this.triggerPresenceInterval = () => {
  setTimeout(() => {
    this.subscription.updatePresence();
    this.triggerPresenceInterval();
  }, PRESENCE_INTERVAL);
};
```

---

## File Structure

```
app/javascript/
├── react-components/
│   ├── src/
│   │   ├── index.jsx                     # Package exports
│   │   ├── components/
│   │   │   ├── ChatwootProvider.jsx      # Root provider
│   │   │   ├── ChatwootConversation.jsx  # Container component
│   │   │   └── ChatwootMessageListWrapper.jsx  # WC bridge
│   │   ├── vue-components/
│   │   │   ├── registerWebComponents.js  # WC registration
│   │   │   └── ChatwootMessageListWebComponent.vue
│   │   └── styles/
│   │       ├── upload.css                # File upload styles
│   │       └── bubble-overrides.css      # Runtime theme customization
│   └── doc.md                            # This file
│
├── ui/
│   ├── MessageList.vue                   # Core message list
│   ├── LiteReplyBox.vue                  # Reply editor
│   ├── axios.js                          # Axios factory
│   └── usage.md                          # Usage docs
│
├── dashboard/
│   ├── store/                            # Vuex store
│   │   ├── index.js
│   │   └── modules/
│   │       ├── conversations/            # Conversation state
│   │       ├── auth.js                   # Auth state
│   │       └── conversationTypingStatus.js
│   ├── components-next/
│   │   └── message/                      # Message components
│   │       ├── Message.vue
│   │       ├── TypingIndicator.vue
│   │       └── bubbles/
│   ├── composables/
│   │   ├── store.js                      # Store helpers
│   │   └── useTransformKeys.js           # Case conversion
│   ├── helper/
│   │   ├── actionCable.js                # WebSocket connector
│   │   └── commons.js                    # Utility functions
│   └── api/
│       ├── ApiClient.js                  # Base API client
│       └── auth.js                       # Auth API
│
└── shared/
    └── helpers/
        └── BaseActionCableConnector.js   # WebSocket base class

scripts/
└── package-react-components.js           # NPM packaging script

vite.config.ts                            # Multi-mode build config
```

---

## Extension Guide

### Adding a New Web Component

1. **Create Vue Component** (`vue-components/NewComponent.vue`):
```vue
<script setup>
import { useStore, useMapGetter } from 'dashboard/composables/store';
// Use composables that check window.__CHATWOOT_STORE__
</script>
```

2. **Register Web Component** (`registerWebComponents.js`):
```javascript
import NewComponent from './NewComponent.vue';

const NewElement = defineCustomElement(NewComponent, ceOptions);

export const registerVueWebComponents = () => {
  // ...existing registrations
  if (!customElements.get('chatwoot-new-component')) {
    customElements.define('chatwoot-new-component', NewElement);
  }
};
```

3. **Create React Wrapper** (`components/NewComponentWrapper.jsx`):
```jsx
export const NewComponentWrapper = (props) => {
  const elementRef = useRef();

  useEffect(() => {
    // Sync React props to WC properties
  }, [props]);

  return <chatwoot-new-component ref={elementRef} />;
};
```

4. **Export from index.jsx**:
```javascript
export { NewComponentWrapper } from './components/NewComponentWrapper';
```

### Adding New Global Configuration

1. Add prop to `ChatwootProvider.jsx`
2. Set corresponding `window.__WOOT_*` variable
3. Access in Vue components via `window.__WOOT_*`

### Adding Store Modules

If the new component needs additional Vuex state:

1. Ensure module is already in `dashboard/store/index.js`
2. Access via `useStore().dispatch('module/action')` or `useMapGetter('module/getter')`

---

## Known Limitations

### 1. Single Conversation Per Page
Currently, only one conversation can be displayed at a time due to global state (`__WOOT_CONVERSATION_ID__`).

**Workaround**: For multiple conversations, instantiate separate iframes.

### 2. Style Isolation
Shadow DOM prevents parent CSS from affecting components, but also means:
- Global CSS resets don't apply
- Most parent styles don't cascade

**Solution**: Message bubble colors and border radius can be customized via CSS custom properties (see [Runtime Theme Customization](#runtime-theme-customization)). CSS custom properties DO inherit through Shadow DOM boundaries.

### 3. React DevTools
Web Components don't appear in React DevTools component tree. Use browser's native Custom Elements inspector.

### 4. Hot Module Replacement
Vue components inside Web Components don't support HMR well. Full page reload often needed during development.

### 5. Bundle Size
The react-components bundle includes:
- Full Vuex store
- All SCSS styles
- I18n messages

**Future optimization**: Tree-shake unused store modules.

### 6. Single Language (English Only)
Currently hardcoded to English locale:
```javascript
const i18n = createI18n({
  locale: 'en',
  messages: { en },
});
```

---

## Debugging Tips

### Inspect Vuex Store
```javascript
// In browser console
window.__CHATWOOT_STORE__.state
window.__CHATWOOT_STORE__.getters.getConversationById(123)
```

### Check WebSocket Connection
```javascript
// ActionCable consumer status
window.__CHATWOOT_STORE__._modules.root._rawModule // Check if actions dispatch
```

### Verify Web Component Registration
```javascript
customElements.get('chatwoot-message-list') // Should return constructor
```

### Force Re-render
```javascript
// Dispatch any action to trigger reactivity
window.__CHATWOOT_STORE__.dispatch('setActiveChat', { data: { id: conversationId } });
```

---

## Related Files

- `CLAUDE.md` - General Chatwoot development guidelines
- `app/javascript/ui/usage.md` - UI components usage guide
- `vite.config.ts` - Build configuration documentation (inline comments)
