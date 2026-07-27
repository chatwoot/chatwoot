<script setup>
defineProps({
  article: { type: Object, required: true },
});
</script>

<template>
  <button
    type="button"
    class="flex items-center w-full gap-3 px-4 py-3 text-left transition-colors bg-cw-background hover:bg-cw-surface outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cw-primary"
  >
    <span class="flex-1 min-w-0">
      <span class="block text-sm font-medium text-cw-text truncate">
        {{ article.title }}
      </span>
      <span
        v-if="article.description"
        class="block mt-0.5 text-xs text-cw-text-muted truncate"
      >
        {{ article.description }}
      </span>
    </span>
    <span class="i-lucide-chevron-right shrink-0 text-cw-text-faint" />
  </button>
</template>
