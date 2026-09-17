<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import { formatDate, formatStatus, statusDotClass } from './importStatus';

defineProps({ exports: { type: Array, default: () => [] } });
defineEmits(['open', 'create']);
</script>

<template>
  <div
    v-if="!exports.length"
    class="flex min-h-80 flex-col items-center justify-center gap-4 rounded-xl border border-n-weak p-6 text-center"
  >
    <h3 class="text-heading-2 text-n-slate-12">
      {{ $t('DATA_EXPORTS.EMPTY') }}
    </h3>
    <p class="max-w-md text-body-main text-n-slate-11">
      {{ $t('DATA_EXPORTS.DESCRIPTION') }}
    </p>
    <Button :label="$t('DATA_EXPORTS.NEW')" @click="$emit('create')" />
  </div>
  <div v-else class="divide-y divide-n-weak border-t border-n-weak">
    <button
      v-for="item in exports"
      :key="item.id"
      type="button"
      class="flex w-full items-center justify-between gap-4 py-4 text-start"
      @click="$emit('open', item.id)"
    >
      <div class="flex min-w-0 flex-col gap-1">
        <span class="truncate text-heading-3 text-n-slate-12">{{
          item.name
        }}</span>
        <span class="text-body-main text-n-slate-11">{{
          item.export_options.scope_name ||
          item.export_options.label ||
          $t('DATA_EXPORTS.ALL_CONTACTS')
        }}</span>
        <span class="text-body-main text-n-slate-11">{{
          formatDate(item.created_at)
        }}</span>
        <span class="text-body-main text-n-slate-11">{{
          $t('DATA_EXPORTS.PROCESSED', { count: item.processed_records })
        }}</span>
      </div>
      <span class="flex items-center gap-2 text-body-main text-n-slate-11">
        <span
          class="size-2 rounded-full"
          :class="statusDotClass(item.status)"
        />
        {{ formatStatus(item.status) }}
      </span>
    </button>
  </div>
</template>
