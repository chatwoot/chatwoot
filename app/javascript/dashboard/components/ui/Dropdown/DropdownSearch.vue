<script setup>
import { defineEmits, defineModel } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  inputPlaceholder: {
    type: String,
    default: '',
  },
  showClearFilter: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['remove']);

const value = defineModel({
  type: String,
  default: '',
});
</script>

<template>
  <div
    class="flex items-center justify-between h-10 min-h-[40px] sticky top-0 bg-white z-10 dark:bg-slate-800 gap-2 px-3 border-b rounded-t-xl border-slate-50 dark:border-slate-700"
  >
    <div class="flex items-center w-full gap-2" @keyup.space.prevent>
      <fluent-icon
        icon="search"
        size="16"
        class="text-slate-400 dark:text-slate-400 flex-shrink-0"
      />
      <input
        v-model="value"
        :placeholder="inputPlaceholder"
        type="text"
        class="w-full mb-0 text-sm !outline-0 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-75 reset-base"
      />
    </div>
    <!-- Clear filter button -->
    <Button
      v-if="!modelValue && showClearFilter"
      faded
      xs
      class="flex-shrink-0"
      :label="$t('REPORT.FILTER_ACTIONS.CLEAR_FILTER')"
      @click="emit('remove')"
    />
  </div>
</template>
