<script setup>
import ChatCard from 'shared/components/ChatCard.vue';
import { computed } from 'vue';
import BaseBubble from './Base.vue';

const props = defineProps({
  contentAttributes: {
    type: Object,
    default: () => ({}),
  },
  content: {
    type: String,
    default: '',
  },
});

const items = computed(() => props.contentAttributes.items || []);
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="card">
    <div class="gap-3 flex flex-col">
      <div v-if="content">
        <div
          v-dompurify-html="content"
          class="message-content text-n-slate-12"
        />
      </div>
      <div v-if="!items.length" class="text-red-500">[Debug] No items in card message</div>
      <div v-for="item in items" :key="item.title">
        <ChatCard
          :image-src="item.mediaUrl"
          :title="item.title"
          :description="item.description"
          :actions="item.actions"
        />
      </div>
    </div>
  </BaseBubble>
</template>

<style scoped>
.dashboard-card-bubble {
  padding: 0.5rem 0;
}
</style> 