<script setup>
import { computed } from 'vue';
import BaseNode from './BaseNode.vue';

const props = defineProps({
  id: { type: String, required: true },
  data: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
});

const rulesSummary = computed(() => {
  const rules = props.data.rules || [];
  if (rules.length === 0) return 'No rules';
  const first = rules[0];
  if (rules.length === 1)
    return `${first.field || '?'} ${first.operator} ${first.value}`;
  return `${rules.length} rules (${props.data.logic || 'and'})`;
});
</script>

<template>
  <BaseNode :id="id" type="condition" :data="data" :selected="selected">
    <template #body>
      <div class="text-xs text-n-slate-11">
        {{ rulesSummary }}
      </div>
    </template>
  </BaseNode>
</template>
