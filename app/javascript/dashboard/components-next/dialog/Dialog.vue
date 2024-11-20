<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'edit',
    validator: value => ['alert', 'edit'].includes(value),
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  cancelButtonLabel: {
    type: String,
    default: '',
  },
  confirmButtonLabel: {
    type: String,
    default: '',
  },
  disableConfirmButton: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  showCancelButton: {
    type: Boolean,
    default: true,
  },
  showConfirmButton: {
    type: Boolean,
    default: true,
  },
  overflowYAuto: {
    type: Boolean,
    default: false,
  },
  width: {
    type: String,
    default: 'lg',
    validator: value => ['3xl', '2xl', 'xl', 'lg', 'md', 'sm'].includes(value),
  },
});

const emit = defineEmits(['confirm', 'close']);

const { t } = useI18n();

const isRTL = useMapGetter('accounts/isRTL');

const dialogRef = ref(null);
const dialogContentRef = ref(null);

const maxWidthClass = computed(() => {
  const classesMap = {
    '3xl': 'max-w-3xl',
    '2xl': 'max-w-2xl',
    xl: 'max-w-xl',
    lg: 'max-w-lg',
    md: 'max-w-md',
    sm: 'max-w-sm',
  };

  return classesMap[props.width] ?? 'max-w-md';
});

const open = () => {
  dialogRef.value?.showModal();
};
const close = () => {
  emit('close');
  dialogRef.value?.close();
};
const confirm = () => {
  emit('confirm');
};

defineExpose({ open, close });
</script>

<template>
  <Teleport to="body">
    <dialog
      ref="dialogRef"
      class="w-full transition-all duration-300 ease-in-out shadow-xl rounded-xl"
      :class="[
        maxWidthClass,
        overflowYAuto ? 'overflow-y-auto' : 'overflow-visible',
      ]"
      :dir="isRTL ? 'rtl' : 'ltr'"
      @close="close"
    >
      <OnClickOutside @trigger="close">
        <div
          ref="dialogContentRef"
          class="flex flex-col w-full h-auto gap-6 p-6 overflow-visible text-left align-middle transition-all duration-300 ease-in-out transform bg-n-alpha-3 backdrop-blur-[100px] shadow-xl rounded-xl"
          @click.stop
        >
          <div v-if="title || description" class="flex flex-col gap-2">
            <h3 class="text-base font-medium leading-6 text-n-slate-12">
              {{ title }}
            </h3>
            <slot name="description">
              <p v-if="description" class="mb-0 text-sm text-n-slate-11">
                {{ description }}
              </p>
            </slot>
          </div>
          <slot />
          <!-- Dialog content will be injected here -->
          <slot name="footer">
            <div class="flex items-center justify-between w-full gap-3">
              <Button
                v-if="showCancelButton"
                variant="faded"
                color="slate"
                :label="cancelButtonLabel || t('DIALOG.BUTTONS.CANCEL')"
                class="w-full"
                @click="close"
              />
              <Button
                v-if="showConfirmButton"
                :color="type === 'edit' ? 'blue' : 'ruby'"
                :label="confirmButtonLabel || t('DIALOG.BUTTONS.CONFIRM')"
                class="w-full"
                :is-loading="isLoading"
                :disabled="disableConfirmButton || isLoading"
                @click="confirm"
              />
            </div>
          </slot>
        </div>
      </OnClickOutside>
    </dialog>
  </Teleport>
</template>

<style scoped>
dialog::backdrop {
  @apply dark:bg-n-alpha-white bg-n-alpha-black2;
}
</style>
