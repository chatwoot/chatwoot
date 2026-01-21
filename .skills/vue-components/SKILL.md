---
name: vue-components
description: Create and modify Vue.js components in Chatwoot following project conventions. Use this skill when building UI components, working with the dashboard frontend, or implementing Vue features with Composition API and Tailwind CSS.
metadata:
  author: chatwoot
  version: "1.0"
---

# Vue Components Development

## Component Structure

Always use Composition API with `<script setup>` at the top:

```vue
<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  isActive: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'close']);

const { t } = useI18n();
const isOpen = ref(false);

const displayTitle = computed(() => props.title.toUpperCase());

const handleClick = () => {
  emit('update', { isOpen: isOpen.value });
};
</script>

<template>
  <div class="flex items-center gap-2 p-4">
    <h2 class="text-slate-900 dark:text-slate-100 text-lg font-medium">
      {{ displayTitle }}
    </h2>
    <button
      class="rounded-md bg-woot-500 px-4 py-2 text-white hover:bg-woot-600"
      @click="handleClick"
    >
      {{ t('COMMON.SAVE') }}
    </button>
  </div>
</template>
```

## Naming Conventions

- **Components**: PascalCase (`ConversationCard.vue`, `MessageBubble.vue`)
- **Events**: camelCase (`@updateStatus`, `@closeModal`)
- **Props**: camelCase (`isActive`, `messageCount`)

## Component Locations

| Location | Purpose |
|----------|---------|
| `app/javascript/dashboard/components-next/` | **Preferred** - New components |
| `app/javascript/dashboard/components/` | Legacy components (being deprecated) |
| `app/javascript/widget/components/` | Chat widget components |
| `app/javascript/shared/` | Shared components across apps |

## Styling Rules

**CRITICAL: Use Tailwind CSS exclusively**

✅ **DO**:
```vue
<template>
  <div class="flex items-center justify-between p-4 bg-white dark:bg-slate-800 rounded-lg shadow-sm">
    <span class="text-sm font-medium text-slate-700 dark:text-slate-200">
      {{ label }}
    </span>
  </div>
</template>
```

❌ **DON'T**:
```vue
<!-- No custom CSS -->
<style scoped>
.container { padding: 16px; }
</style>

<!-- No inline styles -->
<div style="padding: 16px;">

<!-- No CSS classes outside Tailwind -->
<div class="my-custom-class">
```

## Internationalization (i18n)

Never use bare strings in templates:

```vue
<script setup>
import { useI18n } from 'vue-i18n';
const { t } = useI18n();
</script>

<template>
  <!-- ✅ Correct -->
  <span>{{ t('CONVERSATION.HEADER.TITLE') }}</span>
  
  <!-- ❌ Wrong -->
  <span>Conversations</span>
</template>
```

Frontend translations are in `config/locales/en.json`.

## Props Validation

Always define prop types:

```vue
<script setup>
const props = defineProps({
  // Required prop
  conversationId: {
    type: Number,
    required: true,
  },
  // Optional with default
  status: {
    type: String,
    default: 'open',
    validator: (value) => ['open', 'resolved', 'pending'].includes(value),
  },
  // Array/Object props
  messages: {
    type: Array,
    default: () => [],
  },
});
</script>
```

## Composables

Use composables for reusable logic:

```javascript
// composables/useConversation.js
import { ref, computed } from 'vue';
import { useStore } from 'vuex';

export function useConversation(conversationId) {
  const store = useStore();
  
  const conversation = computed(() => 
    store.getters['conversations/getConversationById'](conversationId)
  );
  
  const isResolved = computed(() => 
    conversation.value?.status === 'resolved'
  );
  
  return {
    conversation,
    isResolved,
  };
}
```

## Dark Mode Support

Always include dark mode variants:

```vue
<template>
  <div class="bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100">
    <p class="text-slate-600 dark:text-slate-400">
      Secondary text
    </p>
  </div>
</template>
```

## Common Tailwind Classes in Chatwoot

| Purpose | Classes |
|---------|---------|
| Primary button | `bg-woot-500 hover:bg-woot-600 text-white` |
| Card | `bg-white dark:bg-slate-800 rounded-lg shadow-sm` |
| Input | `border border-slate-200 dark:border-slate-700 rounded-md` |
| Text primary | `text-slate-900 dark:text-slate-100` |
| Text secondary | `text-slate-600 dark:text-slate-400` |

## Testing Components

```bash
pnpm test           # Run all tests
pnpm test:watch     # Watch mode
```

Use Vitest for component testing. Test files go alongside components with `.spec.js` extension.
