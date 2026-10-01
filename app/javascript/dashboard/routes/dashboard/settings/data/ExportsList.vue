<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DataOperationList from './components/DataOperationList.vue';

defineProps({ exports: { type: Array, default: () => [] } });
defineEmits(['open', 'create']);
</script>

<template>
  <div
    v-if="!exports.length"
    class="flex min-h-80 flex-col items-center justify-center gap-4 rounded-xl border border-n-weak bg-n-solid-1 px-6 py-16 text-center"
  >
    <span
      class="grid size-12 place-items-center rounded-xl border border-n-weak bg-n-alpha-1"
    >
      <Icon icon="i-lucide-file-output" class="size-5 text-n-slate-11" />
    </span>
    <div class="flex flex-col gap-1">
      <h3 class="text-heading-2 text-n-slate-12">
        {{ $t('DATA_EXPORTS.EMPTY') }}
      </h3>
      <p class="max-w-sm text-body-main text-n-slate-11">
        {{ $t('DATA_EXPORTS.EMPTY_DESCRIPTION') }}
      </p>
    </div>
    <Button
      size="sm"
      icon="i-lucide-plus"
      :label="$t('DATA_EXPORTS.NEW')"
      @click="$emit('create')"
    />
  </div>
  <DataOperationList
    v-else
    :items="exports"
    type="export"
    @open="$emit('open', $event)"
  />
</template>
