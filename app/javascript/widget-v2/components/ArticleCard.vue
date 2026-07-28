<script setup>
defineProps({
  article: { type: Object, required: true },
  // Home lists articles straight on the background; the card views put them
  // on a solid surface.
  flat: { type: Boolean, default: false },
});
</script>

<template>
  <button
    type="button"
    class="flex items-center w-full gap-3 row-pad text-left transition-colors hover:bg-cw-surface outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cw-primary"
    :class="flat ? 'rounded-token-sm' : 'bg-cw-solid'"
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
