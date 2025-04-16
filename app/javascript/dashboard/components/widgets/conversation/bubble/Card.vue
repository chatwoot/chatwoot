<template>
  <div class="card-container">
    <div v-for="(item, index) in items" :key="index" class="card">
      <div v-if="item.media_url" class="card-media">
        <img :src="item.media_url" :alt="item.title" class="card-image" />
      </div>
      <div class="card-content">
        <h3 v-if="item.title" class="card-title">{{ item.title }}</h3>
        <p v-if="item.description" class="card-description" v-html="renderMarkdown(item.description)"></p>
        <div v-if="item.actions && item.actions.length" class="card-actions">
          <button
            v-for="(action, actionIndex) in item.actions"
            :key="actionIndex"
            class="card-action-button"
            :class="{ 'is-link': action.type === 'link', 'is-postback': action.type === 'postback' }"
            @click="handleAction(action)"
          >
            {{ action.text }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { renderMarkdown } from 'shared/helpers/markdown';

export default {
  name: 'BubbleCard',
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
  methods: {
    handleAction(action) {
      if (action.type === 'link') {
        window.open(action.uri, '_blank', 'noopener,noreferrer');
      } else if (action.type === 'postback') {
        emitter.emit(BUS_EVENTS.CARD_ACTION, action.payload);
      }
    },
    renderMarkdown(text) {
      return renderMarkdown(text);
    },
  },
};
</script>

<style lang="scss" scoped>
.card-container {
  @apply flex flex-col gap-4;
}

.card {
  @apply bg-white dark:bg-slate-800 rounded-lg overflow-hidden shadow-sm max-w-[20rem];
}

.card-media {
  @apply relative;
}

.card-image {
  @apply w-full h-48 object-cover;
}

.card-content {
  @apply p-4;
}

.card-title {
  @apply text-base font-semibold text-slate-900 dark:text-slate-100 mb-2;
}

.card-description {
  @apply text-sm text-slate-600 dark:text-slate-300 mb-4;
}

.card-description :deep(p) {
  @apply mb-2;
}

.card-description :deep(strong) {
  @apply font-semibold;
}

.card-description :deep(em) {
  @apply italic;
}

.card-description :deep(ul), .card-description :deep(ol) {
  @apply pl-4 mb-2;
}

.card-description :deep(li) {
  @apply mb-1;
}

.card-actions {
  @apply flex flex-wrap gap-2;
}

.card-action-button {
  @apply px-3 py-1.5 text-sm rounded-md transition-colors duration-200;
  @apply bg-slate-100 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600;
  @apply text-slate-700 dark:text-slate-200;

  &.is-link {
    @apply bg-blue-100 hover:bg-blue-200 dark:bg-blue-900 dark:hover:bg-blue-800;
    @apply text-blue-700 dark:text-blue-200;
  }

  &.is-postback {
    @apply bg-green-100 hover:bg-green-200 dark:bg-green-900 dark:hover:bg-green-800;
    @apply text-green-700 dark:text-green-200;
  }
}
</style> 