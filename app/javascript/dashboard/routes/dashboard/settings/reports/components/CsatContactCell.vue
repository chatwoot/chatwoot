<script setup>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

defineProps({
  contact: {
    type: Object,
    default: null,
  },
  conversationId: {
    type: Number,
    required: true,
  },
  createdAgo: {
    type: String,
    default: '',
  },
  createdAt: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="flex items-center gap-2">
    <Avatar
      :src="contact?.thumbnail || ''"
      :name="contact?.name || ''"
      :size="32"
      rounded-full
    />
    <div class="flex flex-col gap-0.5">
      <span class="text-sm text-n-slate-12 font-medium capitalize">
        {{ contact?.name || '—' }}
      </span>
      <div
        class="flex items-center gap-1 text-xs text-n-slate-10 whitespace-nowrap"
      >
        <a
          :href="`/app/accounts/${$route.params.accountId}/conversations/${conversationId}`"
          class="flex items-center text-xs gap-0.5 hover:text-n-brand hover:underline"
          target="_blank"
          rel="noopener noreferrer nofollow"
        >
          <span>#{{ conversationId }}</span>
        </a>
        <span>·</span>
        <span :title="createdAt">{{ createdAgo }}</span>
      </div>
    </div>
  </div>
</template>
