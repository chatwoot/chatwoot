<script setup>
import { computed } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['show']);

const formatNumber = value => {
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000)
    return `${(value / 1_000).toFixed(value >= 10_000 ? 0 : 1)}k`;
  return String(value);
};

const formattedFollowers = computed(() => {
  const val = props.contact.customAttributes?.followers;
  if (!val) return null;
  return formatNumber(Number(val));
});

const formattedEngagementRate = computed(() => {
  const val = props.contact.customAttributes?.engagementRate;
  if (val == null) return null;
  return `${Number(val).toFixed(2)}%`;
});
</script>

<template>
  <div
    class="flex items-center gap-3 p-3 bg-n-solid-2 rounded-xl border border-n-weak cursor-grab hover:border-n-slate-7 transition-colors"
    @click="emit('show', contact.id)"
  >
    <Avatar
      :name="contact.name"
      :src="contact.thumbnail"
      :size="32"
      rounded-full
    />
    <div class="flex flex-col flex-1 min-w-0">
      <span class="text-sm font-medium truncate text-n-slate-12">
        {{ contact.name || contact.email || 'Unnamed' }}
      </span>
      <span v-if="contact.email" class="text-xs truncate text-n-slate-10">
        {{ contact.email }}
      </span>
      <div
        v-if="formattedFollowers || formattedEngagementRate"
        class="flex items-center gap-2"
      >
        <span
          v-if="formattedFollowers"
          class="inline-flex items-center gap-0.5 text-xs text-n-slate-10"
        >
          <span class="i-lucide-users size-3" />
          {{ formattedFollowers }}
        </span>
        <span
          v-if="formattedEngagementRate"
          class="inline-flex items-center gap-0.5 text-xs text-n-slate-10"
        >
          <span class="i-lucide-percent size-3" />
          {{ formattedEngagementRate }}
        </span>
      </div>
    </div>
  </div>
</template>
