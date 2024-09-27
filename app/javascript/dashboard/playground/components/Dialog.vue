<script setup>
import { ref } from 'vue';
import { onClickOutside } from '@vueuse/core';
import ButtonV4 from 'dashboard/playground/components/Button.vue';

defineProps({
  type: {
    type: String,
    default: 'edit',
    validator: value => ['alert', 'edit'].includes(value),
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  cancelButtonLabel: {
    type: String,
    default: 'Cancel',
  },
  confirmButtonLabel: {
    type: String,
    default: 'Confirm',
  },
});

const emit = defineEmits(['confirm']);

const dialogRef = ref(null);
const dialogContentRef = ref(null);

const open = () => {
  dialogRef.value?.showModal();
};

const close = () => {
  dialogRef.value?.close();
};

const confirm = () => {
  emit('confirm');
};

defineExpose({ open });

onClickOutside(dialogContentRef, event => {
  if (
    dialogRef.value &&
    dialogRef.value.open &&
    event.target === dialogRef.value
  ) {
    close();
  }
});
</script>

<template>
  <Teleport to="body">
    <dialog
      ref="dialogRef"
      class="w-full max-w-lg shadow-xl bg-modal-backdrop-light dark:bg-modal-backdrop-dark rounded-xl"
      @close="close"
    >
      <div
        ref="dialogContentRef"
        class="flex flex-col w-full h-auto gap-6 p-6 overflow-hidden text-left align-middle transition-all duration-300 ease-in-out transform bg-white shadow-xl dark:bg-slate-800 rounded-xl"
        @click.stop
      >
        <div class="flex flex-col gap-2">
          <h3
            class="text-base font-medium leading-6 text-gray-900 dark:text-white"
          >
            {{ title }}
          </h3>
          <p
            v-if="description"
            class="mb-0 text-sm text-slate-500 dark:text-slate-400"
          >
            {{ description }}
          </p>
        </div>
        <slot name="form">
          <!-- Form content will be injected here -->
        </slot>
        <div class="flex items-center justify-between w-full gap-3">
          <ButtonV4
            variant="secondary"
            :label="cancelButtonLabel"
            class="w-full"
            size="sm"
            @click="close"
          />
          <ButtonV4
            v-if="type !== 'alert'"
            :variant="type === 'edit' ? 'default' : 'destructive'"
            :label="confirmButtonLabel"
            class="w-full"
            size="sm"
            @click="confirm"
          />
        </div>
      </div>
    </dialog>
  </Teleport>
</template>

<!-- <style scoped>
dialog::backdrop {
  backdrop-filter: blur(1px);
}
</style> -->
