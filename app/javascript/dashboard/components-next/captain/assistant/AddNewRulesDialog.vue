<script setup>
import { useToggle } from '@vueuse/core';

import Button from 'dashboard/components-next/button/Button.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

defineProps({
  placeholder: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
  confirmLabel: {
    type: String,
    default: '',
  },
  cancelLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['add']);

const [showPopover, togglePopover] = useToggle();

const onClickAdd = () => {
  emit('add');
};

const onClickCancel = () => {
  togglePopover(false);
};
</script>

<template>
  <div class="inline-flex relative">
    <Button
      :label="label"
      sm
      slate
      class="flex-shrink-0"
      @click="togglePopover(!showPopover)"
    />
    <div
      v-if="showPopover"
      class="absolute w-[26.5rem] top-9 z-50 ltr:left-0 rtl:right-0 flex flex-col gap-5 bg-n-alpha-3 backdrop-blur-[100px] p-4 rounded-xl border border-n-weak shadow-md"
    >
      <InlineInput :placeholder="placeholder" />
      <div class="flex gap-2 justify-between">
        <Button
          :label="cancelLabel"
          sm
          link
          slate
          class="h-10 hover:!no-underline"
          @click="onClickCancel"
        />
        <Button :label="confirmLabel" sm @click="onClickAdd" />
      </div>
    </div>
  </div>
</template>
