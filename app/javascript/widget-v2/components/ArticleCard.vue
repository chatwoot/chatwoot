<script setup>
defineProps({
  article: { type: Object, required: true },
});
</script>

<template>
  <button
    type="button"
    class="flex items-center w-full gap-3 row-pad text-left transition-colors bg-cw-solid hover:bg-cw-surface outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cw-primary"
  >
    <span class="flex-1 min-w-0">
      <span class="block text-sm font-520 text-cw-text truncate">
        {{ article.title }}
      </span>
      <span
        v-if="article.description"
        class="block mt-0.5 text-xs text-cw-text-muted truncate"
      >
        {{ article.description }}
      </span>
    </span>
    <span class="i-ph-caret-right shrink-0 text-cw-text-faint" />
  </button>
</template>
