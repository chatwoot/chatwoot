<script setup>
defineProps({
  reactions: {
    type: Array,
    default: () => [],
  },
});

/**
 * Groups reactions by emoji and returns an array of { emoji, count }.
 */
function groupReactions(reactions) {
  const counts = {};
  reactions.forEach(({ emoji }) => {
    if (emoji) {
      counts[emoji] = (counts[emoji] || 0) + 1;
    }
  });
  return Object.entries(counts).map(([emoji, count]) => ({ emoji, count }));
}
</script>

<template>
  <div v-if="reactions.length" class="flex flex-wrap gap-1 mt-0.5">
    <!-- eslint-disable-line vue/no-root-v-if -->
    <span
      v-for="{ emoji, count } in groupReactions(reactions)"
      :key="emoji"
      class="inline-flex items-center gap-0.5 px-1.5 py-0.5 text-xs rounded-full bg-n-alpha-2 dark:bg-n-alpha-2 border border-n-weak select-none"
    >
      <span>{{ emoji }}</span>
      <span v-if="count > 1" class="text-n-slate-11">{{ count }}</span>
    </span>
  </div>
</template>
