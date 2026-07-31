<script setup>
import { computed, onBeforeUnmount, ref } from 'vue';
import { onKeyStroke, useScrollLock } from '@vueuse/core';
import Button from 'dashboard/components-next/button/Button.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  width: {
    type: String,
    default: 'lg',
    validator: value => ['sm', 'md', 'lg', 'xl'].includes(value),
  },
  closeOnClickOutside: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['close']);

const MAX_WIDTH_CLASSES = {
  sm: 'max-w-md',
  md: 'max-w-xl',
  lg: 'max-w-3xl',
  xl: 'max-w-5xl',
};

const isOpen = ref(false);
const panelRef = ref(null);
const isScrollLocked = useScrollLock(document.body);

let previousActiveElement = null;

const maxWidthClass = computed(() => MAX_WIDTH_CLASSES[props.width]);

const open = () => {
  if (isOpen.value) return;
  previousActiveElement =
    document.activeElement instanceof HTMLElement
      ? document.activeElement
      : null;
  isOpen.value = true;
};

// Locking the page and moving focus both force layout. Doing that in the frame the panel mounts
// in delays the slide by a frame, so it waits until the panel has arrived.
const onAfterEnter = () => {
  isScrollLocked.value = true;
  panelRef.value?.focus();
};

const close = () => {
  if (!isOpen.value) return;
  isOpen.value = false;
  isScrollLocked.value = false;
  if (previousActiveElement?.isConnected) previousActiveElement.focus();
  previousActiveElement = null;
  emit('close');
};

const onOverlayClick = () => {
  if (props.closeOnClickOutside) close();
};

onKeyStroke('Escape', event => {
  if (!isOpen.value) return;
  // A dialog opened on top of the panel (e.g. the editor's link prompt) handles Escape itself.
  if (document.querySelector('dialog[open]')) return;

  event.preventDefault();
  close();
});

onBeforeUnmount(() => {
  isScrollLocked.value = false;
});

defineExpose({ open, close });
</script>

<template>
  <TeleportWithDirection to="body">
    <Transition
      enter-active-class="transition-opacity duration-300 ease-[cubic-bezier(0.4,0,0.2,1)]"
      enter-from-class="opacity-0"
      leave-active-class="transition-opacity duration-200 ease-in"
      leave-to-class="opacity-0"
    >
      <div
        v-if="isOpen"
        class="fixed inset-0 z-50 bg-n-alpha-black1"
        role="presentation"
        @click="onOverlayClick"
      />
    </Transition>
    <Transition
      enter-active-class="transition-transform duration-300 ease-[cubic-bezier(0.4,0,0.2,1)]"
      enter-from-class="translate-x-full rtl:-translate-x-full"
      leave-active-class="transition-transform duration-200 ease-in"
      leave-to-class="translate-x-full rtl:-translate-x-full"
      @after-enter="onAfterEnter"
    >
      <aside
        v-if="isOpen"
        ref="panelRef"
        role="dialog"
        aria-modal="true"
        :aria-label="title"
        tabindex="-1"
        class="fixed z-50 flex flex-col w-full shadow-xl outline-none inset-y-0 end-0 bg-n-solid-1 will-change-transform"
        :class="maxWidthClass"
      >
        <header
          class="flex items-center justify-between flex-shrink-0 gap-4 px-6 py-5 border-b border-n-weak"
        >
          <div class="min-w-0">
            <h3 class="text-base font-medium truncate text-n-slate-12">
              {{ title }}
            </h3>
            <p v-if="description" class="mt-1 mb-0 text-sm text-n-slate-11">
              {{ description }}
            </p>
          </div>
          <Button
            ghost
            slate
            sm
            icon="i-lucide-x"
            class="-me-2"
            :aria-label="$t('GENERAL.CLOSE')"
            @click="close"
          />
        </header>
        <div class="flex-1 min-h-0 px-6 py-5 overflow-y-auto">
          <slot />
        </div>
        <footer
          v-if="$slots.footer"
          class="flex-shrink-0 px-6 py-4 border-t border-n-weak"
        >
          <slot name="footer" />
        </footer>
      </aside>
    </Transition>
  </TeleportWithDirection>
</template>
