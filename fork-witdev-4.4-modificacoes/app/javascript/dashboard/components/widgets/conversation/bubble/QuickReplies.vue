<script>
export default {
  name: 'QuickReplies',
  props: {
    items: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['fallbackToText'],
  mounted() {
    // Track component render for metrics
    if (window.analytics) {
      window.analytics.track('cw_quick_replies_render_total', {
        error: 'false',
        type: 'render_success',
        options_count: this.items.length,
      });
    }
  },
  errorCaptured(err) {
    if (import.meta.env.MODE !== 'production') {
      // eslint-disable-next-line no-console
      console.error('QuickReplies error:', err);
    }

    // Track error for metrics
    if (window.analytics) {
      window.analytics.track('cw_quick_replies_render_total', {
        error: 'true',
        type: 'component_error',
      });
    }

    // Emit fallback event to parent
    this.$emit('fallbackToText');
    return false;
  },
};
</script>

<template>
  <div class="quick-replies-wrapper">
    <div class="quick-replies-list">
      <div
        v-for="(item, index) in items"
        :key="index"
        class="quick-reply-option"
        role="button"
        tabindex="0"
        :aria-label="`Quick reply option: ${item.title}`"
      >
        <div class="quick-reply-content">
          <span class="quick-reply-title">{{ item.title }}</span>
          <span
            v-if="item.value && item.value !== item.title"
            class="quick-reply-value"
          >
            {{ item.value }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.quick-replies-wrapper {
  @apply max-w-full;
}

.quick-replies-list {
  @apply flex flex-col gap-2;
}

.quick-reply-option {
  @apply border border-slate-200 dark:border-slate-600 rounded-lg p-3 bg-slate-50 dark:bg-slate-700 cursor-pointer transition-colors duration-200;

  &:hover {
    @apply bg-slate-100 dark:bg-slate-600 border-slate-300 dark:border-slate-500;
  }

  &:focus {
    @apply outline-none ring-2 ring-woot-500 dark:ring-woot-400 ring-opacity-50;
  }
}

.quick-reply-content {
  @apply flex flex-col gap-1;
}

.quick-reply-title {
  @apply font-medium text-slate-900 dark:text-slate-100 text-sm;
}

.quick-reply-value {
  @apply text-xs text-slate-500 dark:text-slate-400 font-mono bg-slate-100 dark:bg-slate-600 px-2 py-1 rounded;
}

/* Right-aligned (outgoing) message styling */
.right .quick-replies-wrapper {
  .quick-reply-option {
    @apply bg-woot-50 dark:bg-woot-800 border-woot-200 dark:border-woot-600;

    &:hover {
      @apply bg-woot-100 dark:bg-woot-700 border-woot-300 dark:border-woot-500;
    }
  }

  .quick-reply-title {
    @apply text-woot-900 dark:text-woot-100;
  }

  .quick-reply-value {
    @apply text-woot-600 dark:text-woot-300 bg-woot-100 dark:bg-woot-700;
  }
}

/* Left-aligned (incoming) message styling */
.left .quick-replies-wrapper {
  .quick-reply-option {
    @apply bg-slate-50 dark:bg-slate-700 border-slate-200 dark:border-slate-600;
  }
}
</style>
