<script setup>
import { useI18n } from 'vue-i18n';
import { Handle, Position } from '@vue-flow/core';

defineProps({
  data: { type: Object, default: () => ({}) },
});

const { t } = useI18n();
</script>

<template>
  <div
    class="flex w-52 rounded-xl bg-n-solid-2 outline outline-1 -outline-offset-1 outline-n-container shadow-sm overflow-hidden"
  >
    <Handle type="target" :position="Position.Top" class="!bg-n-amber-9" />
    <div class="w-1 shrink-0 bg-n-amber-9" />
    <div class="flex flex-col gap-1 px-3 py-2.5 min-w-0">
      <div class="flex items-center gap-2">
        <span class="i-lucide-git-branch text-n-amber-11 size-3.5 shrink-0" />
        <span class="text-xs font-medium text-n-slate-12 truncate">
          {{ data.label || 'Condition' }}
        </span>
      </div>
      <div class="flex items-center justify-between mt-1">
        <span class="text-[11px] font-medium text-n-teal-11">
          {{ t('CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.CONDITION_TRUE') }}
        </span>
        <span class="text-[11px] font-medium text-n-ruby-11">
          {{ t('CAPTAIN.ASSISTANTS.WORKFLOWS.CONFIG.CONDITION_FALSE') }}
        </span>
      </div>
    </div>
    <Handle
      id="true"
      type="source"
      :position="Position.Bottom"
      class="!left-[25%] !bg-n-teal-9"
    />
    <Handle
      id="false"
      type="source"
      :position="Position.Bottom"
      class="!left-[75%] !bg-n-ruby-9"
    />
  </div>
</template>
