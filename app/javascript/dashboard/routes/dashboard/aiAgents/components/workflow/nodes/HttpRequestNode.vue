<script setup>
import { computed } from 'vue';
import BaseNode from './BaseNode.vue';

const props = defineProps({
  id: { type: String, required: true },
  data: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
});

const urlPreview = computed(() => {
  const url = props.data.url_template || '';
  return url.length > 40 ? `${url.slice(0, 40)}...` : url;
});
</script>

<template>
  <BaseNode :id="id" type="http_request" :data="data" :selected="selected">
    <template #body>
      <div class="space-y-1">
        <div class="flex items-center gap-1.5">
          <span
            class="rounded px-1.5 py-0.5 text-[10px] font-bold"
            :class="{
              'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300':
                data.method === 'GET',
              'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300':
                data.method === 'POST',
              'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300':
                ['PUT', 'PATCH'].includes(data.method),
              'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300':
                data.method === 'DELETE',
            }"
          >
            {{ data.method || 'GET' }}
          </span>
          <span class="truncate text-xs text-n-slate-10">
            {{ urlPreview || 'No URL' }}
          </span>
        </div>
      </div>
    </template>
  </BaseNode>
</template>
