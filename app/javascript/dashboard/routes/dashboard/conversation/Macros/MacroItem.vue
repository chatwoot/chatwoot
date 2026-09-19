<script setup>
import { ref } from 'vue';

import NextButton from 'dashboard/components-next/button/Button.vue';
import MacroPreview from './MacroPreview.vue';

defineProps({
  macro: {
    type: Object,
    required: true,
  },
  isExecuting: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['execute']);

const showPreview = ref(false);

const toggleMacroPreview = () => {
  showPreview.value = !showPreview.value;
};

const closeMacroPreview = () => {
  showPreview.value = false;
};
</script>

<template>
  <div
    class="relative flex items-center justify-between leading-4 rounded-md h-10 pl-3 pr-2"
    :class="showPreview ? 'cursor-default' : 'drag-handle cursor-grab'"
  >
    <span
      class="overflow-hidden whitespace-nowrap text-ellipsis font-medium text-n-slate-12"
    >
      {{ macro.name }}
    </span>
    <div class="flex items-center gap-1 justify-end">
      <NextButton
        v-tooltip.left-start="$t('MACROS.EXECUTE.PREVIEW')"
        icon="i-lucide-info"
        slate
        faded
        xs
        @click="toggleMacroPreview"
      />
      <NextButton
        v-tooltip.left-start="$t('MACROS.EXECUTE.BUTTON_TOOLTIP')"
        icon="i-lucide-play"
        slate
        faded
        xs
        :is-loading="isExecuting"
        :disabled="isExecuting"
        @click="$emit('execute')"
      />
    </div>
    <transition name="menu-slide">
      <MacroPreview
        v-if="showPreview"
        v-on-clickaway="closeMacroPreview"
        :macro="macro"
      />
    </transition>
  </div>
</template>
