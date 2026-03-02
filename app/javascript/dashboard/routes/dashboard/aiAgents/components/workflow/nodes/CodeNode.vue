<script setup>
import { computed } from 'vue';
import BaseNode from './BaseNode.vue';

const props = defineProps({
  id: { type: String, required: true },
  data: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
});

const codePreview = computed(() => {
  const code = props.data.code || '';
  return code.length > 50 ? `${code.slice(0, 50)}...` : code;
});
</script>

<template>
  <BaseNode :id="id" type="code" :data="data" :selected="selected">
    <template #body>
      <div class="space-y-1">
        <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
          <span class="i-lucide-code text-amber-500" />
          {{ data.language || 'liquid' }}
        </div>
        <pre
          v-if="codePreview"
          class="line-clamp-2 rounded bg-n-alpha-2 p-1 font-mono text-[10px] text-n-slate-10"
          >{{ codePreview }}</pre
        >
      </div>
    </template>
  </BaseNode>
</template>
