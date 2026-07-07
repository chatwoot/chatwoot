<script setup>
import { computed } from 'vue';

const props = defineProps({
  reactions: { type: Array, default: () => [] },
});

const displayValue = reaction =>
  reaction.emoji || reaction.reactionType || reaction.reaction_type;

const activeReactions = computed(() => {
  return props.reactions
    .filter(reaction => reaction.status === 'active' && displayValue(reaction))
    .map((reaction, index) => ({
      id: reaction.id ?? `${displayValue(reaction)}-${index}`,
      value: displayValue(reaction),
    }));
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="activeReactions.length"
    class="flex flex-wrap gap-1"
    data-test-id="message-reactions"
  >
    <span
      v-for="reaction in activeReactions"
      :key="reaction.id"
      class="inline-flex h-6 min-w-6 items-center justify-center rounded-full border border-n-slate-4 bg-n-alpha-2 px-2 text-sm leading-none text-n-slate-12"
      data-test-id="message-reaction"
    >
      {{ reaction.value }}
    </span>
  </div>
</template>
