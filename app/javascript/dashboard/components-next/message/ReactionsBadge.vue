<script setup>
import { computed } from 'vue';
import { useMessageContext } from './provider.js';

const { contentAttributes } = useMessageContext();

const reactions = computed(() => {
  const raw =
    contentAttributes.value?.external_reactions ??
    contentAttributes.value?.externalReactions;
  if (!raw || typeof raw !== 'object') return [];

  return Object.values(raw)
    .filter(r => r?.emoji)
    .map(r => r.emoji);
});

const uniqueEmojis = computed(() => [...new Set(reactions.value)]);

const totalCount = computed(() => reactions.value.length);
</script>

<template>
  <div
    v-if="uniqueEmojis.length"
    class="inline-flex items-center gap-0.5 mt-1 px-1.5 py-0.5 rounded-full bg-s-subtle border border-s-border text-xs leading-none select-none"
  >
    <span v-for="emoji in uniqueEmojis" :key="emoji" class="text-sm">
      {{ emoji }}
    </span>
    <span v-if="totalCount > 1" class="text-s-muted ml-0.5 tabular-nums">
      {{ totalCount }}
    </span>
  </div>
</template>
