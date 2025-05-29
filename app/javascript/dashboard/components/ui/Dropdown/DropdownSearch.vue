<script setup>
import { defineEmits, defineModel } from 'vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

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
    class="flex items-center justify-between h-10 min-h-[40px] sticky top-0 bg-n-solid-2 dark:bg-n-solid-2 z-10 gap-2 px-3 border-b rounded-t-xl border-n-weak"
  >
    <div class="flex items-center w-full gap-2" @keyup.space.prevent>
      <fluent-icon
        icon="search"
        size="16"
        class="text-n-slate-11 flex-shrink-0"
      />
      <input
        v-model="value"
        :placeholder="inputPlaceholder"
        type="text"
        class="w-full mb-0 text-sm !outline-0 bg-transparent text-n-slate-12 placeholder:text-n-slate-10 reset-base"
      />
    </div>
    <!-- Clear filter button -->
    <NextButton
      v-if="!modelValue && showClearFilter"
      faded
      xs
      class="flex-shrink-0"
      :label="$t('REPORT.FILTER_ACTIONS.CLEAR_FILTER')"
      @click="emit('remove')"
    />
  </div>
</template>
