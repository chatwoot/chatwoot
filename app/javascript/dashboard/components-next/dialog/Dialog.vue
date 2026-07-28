<script setup>
import { ref, computed, provide } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

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
  // Title + footer stay put; only the default slot scrolls (ComboBox should teleport).
  bodyScroll: {
    type: Boolean,
    default: false,
  },
  width: {
    type: String,
    default: 'lg',
    validator: value => ['3xl', '2xl', 'xl', 'lg', 'md', 'sm'].includes(value),
  },
  position: {
    type: String,
    default: 'center',
    validator: value => ['center', 'top'].includes(value),
  },
});

const emit = defineEmits(['confirm', 'close']);

const { t } = useI18n();

const dialogRef = ref(null);
const dialogContentRef = ref(null);
const isOpen = ref(false);

// ComboBox menus teleport here so they stay in the dialog top-layer
// and are not clipped by the scrollable body.
provide('dialogPortalTarget', dialogRef);

// Explicit width: native <dialog> otherwise shrinks to content.
const widthClass = computed(() => {
  const classesMap = {
    '3xl': 'w-[min(100vw-2rem,48rem)]',
    '2xl': 'w-[min(100vw-2rem,42rem)]',
    xl: 'w-[min(100vw-2rem,36rem)]',
    lg: 'w-[min(100vw-2rem,32rem)]',
    md: 'w-[min(100vw-2rem,28rem)]',
    sm: 'w-[min(100vw-2rem,24rem)]',
  };

  return classesMap[props.width] ?? classesMap.lg;
});

const positionClass = computed(() =>
  props.position === 'top' ? 'dialog-position-top' : ''
);

const dialogOverflowClass = computed(() => {
  // Keep overflow visible so teleported ComboBox menus aren't clipped by <dialog>.
  if (props.bodyScroll) return 'max-h-[90vh] overflow-visible';
  if (props.overflowYAuto) return 'max-h-[90vh] overflow-y-auto';
  return 'overflow-visible';
});

const formClass = computed(() => {
  // Avoid `transform` with bodyScroll so fixed teleported menus aren't trapped.
  if (props.bodyScroll) {
    return 'flex flex-col w-full max-h-[90vh] gap-4 p-6 overflow-hidden text-start align-middle transition-all duration-300 ease-in-out bg-n-alpha-3 backdrop-blur-[100px] shadow-xl rounded-xl';
  }
  return 'flex flex-col w-full h-auto gap-6 p-6 overflow-visible text-start align-middle transition-all duration-300 ease-in-out transform bg-n-alpha-3 backdrop-blur-[100px] shadow-xl rounded-xl';
});

const open = () => {
  isOpen.value = true;
  dialogRef.value?.showModal();
};

const close = () => {
  emit('close');
  dialogRef.value?.close();
  isOpen.value = false;
};

// Only close if the close event originated from this dialog,
// not from a child dialog (e.g. ProseMirror prompt) bubbling up.
const handleDialogClose = e => e.target === dialogRef.value && close();

// Only close on click-outside if this dialog is the topmost one.
// Ignore teleported ComboBox menus (sibling of the form, still in <dialog>).
const handleClickOutside = event => {
  if (event?.target?.closest?.('[data-combobox-dropdown]')) return;
  const dialogs = document.querySelectorAll('dialog[open]');
  if (dialogs[dialogs.length - 1] === dialogRef.value) close();
};

const confirm = () => {
  emit('confirm');
};

defineExpose({ open, close });
</script>

<template>
  <TeleportWithDirection to="body">
    <dialog
      ref="dialogRef"
      class="transition-all duration-300 ease-in-out shadow-xl rounded-xl"
      :class="[widthClass, positionClass, dialogOverflowClass]"
      @close.prevent="handleDialogClose"
    >
      <OnClickOutside @trigger="handleClickOutside">
        <form
          ref="dialogContentRef"
          :class="formClass"
          @submit.prevent="confirm"
          @click.stop
        >
          <div v-if="title || description" class="flex flex-col gap-2 shrink-0">
            <h3 class="text-base font-medium leading-6 text-n-slate-12">
              {{ title }}
            </h3>
            <slot name="description">
              <p v-if="description" class="mb-0 text-sm text-n-slate-11">
                {{ description }}
              </p>
            </slot>
          </div>
          <!-- Explicit max-height so the scrollbar appears when fields overflow -->
          <div
            v-if="isOpen && bodyScroll"
            class="overflow-y-auto overscroll-contain -mx-1 px-1 max-h-[calc(90vh-11rem)]"
          >
            <slot />
          </div>
          <slot v-else-if="isOpen" />
          <div
            class="shrink-0"
            :class="{ 'pt-4 border-t border-n-weak': bodyScroll }"
          >
            <slot name="footer">
              <div
                v-if="showCancelButton || showConfirmButton"
                class="flex items-center justify-between w-full gap-3"
              >
                <Button
                  v-if="showCancelButton"
                  variant="faded"
                  color="slate"
                  :label="cancelButtonLabel || t('DIALOG.BUTTONS.CANCEL')"
                  class="w-full"
                  type="button"
                  @click="close"
                />
                <Button
                  v-if="showConfirmButton"
                  :color="type === 'edit' ? 'blue' : 'ruby'"
                  :label="confirmButtonLabel || t('DIALOG.BUTTONS.CONFIRM')"
                  class="w-full"
                  :is-loading="isLoading"
                  :disabled="disableConfirmButton || isLoading"
                  type="submit"
                />
              </div>
            </slot>
          </div>
        </form>
      </OnClickOutside>
    </dialog>
  </TeleportWithDirection>
</template>

<style scoped>
dialog::backdrop {
  @apply bg-n-alpha-black1 backdrop-blur-[4px];
}

.dialog-position-top {
  margin-top: clamp(2rem, 5vh, 5rem);
  margin-bottom: auto;
}
</style>
