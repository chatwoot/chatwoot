<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import { useEventListener } from '@vueuse/core';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  // Accessible name for the dialog; the visible layout is fully slot-driven.
  title: { type: String, default: '' },
  width: {
    type: String,
    default: 'xl',
    validator: value => ['md', 'lg', 'xl', '2xl', '3xl'].includes(value),
  },
});

// `afterLeave` fires once the slide-out transition finishes, so consumers
// mounted with v-if can wait for it before unmounting the drawer.
const emit = defineEmits(['close', 'afterLeave']);

const drawerRef = ref(null);

let previousActiveElement = null;

const maxWidthClass = computed(() => {
  const classesMap = {
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl',
    '2xl': 'max-w-2xl',
    '3xl': 'max-w-3xl',
  };

  return classesMap[props.width] ?? 'max-w-xl';
});

const closeDrawer = () => emit('close');

const restoreFocus = () => {
  if (previousActiveElement?.isConnected) {
    previousActiveElement.focus();
  }
  previousActiveElement = null;
};

const rememberActiveElement = () => {
  if (previousActiveElement) return;

  previousActiveElement =
    document.activeElement instanceof HTMLElement
      ? document.activeElement
      : null;
};

const onKeydown = event => {
  if (!props.open) return;

  if (event.key === 'Escape') {
    event.preventDefault();
    event.stopPropagation();
    closeDrawer();
  }
};

useEventListener(document, 'keydown', onKeydown);

watch(
  () => props.open,
  isOpen => {
    if (!isOpen) {
      restoreFocus();
      return;
    }

    rememberActiveElement();
    nextTick(() => drawerRef.value?.focus());
  },
  { immediate: true }
);

onBeforeUnmount(() => {
  restoreFocus();
});
</script>

<template>
  <TeleportWithDirection to="body">
    <Transition
      appear
      enter-active-class="transition-opacity duration-300 ease-out"
      enter-from-class="opacity-0"
      leave-active-class="transition-opacity duration-200 ease-in"
      leave-to-class="opacity-0"
    >
      <div
        v-if="open"
        class="fixed inset-0 z-50 bg-black/30"
        role="presentation"
        @click="closeDrawer"
      />
    </Transition>
    <Transition
      appear
      enter-active-class="transition-transform duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"
      enter-from-class="translate-x-[calc(100%+12px)] rtl:translate-x-[calc(-100%-12px)]"
      leave-active-class="transition-transform duration-200 ease-[cubic-bezier(0.32,0.72,0,1)]"
      leave-to-class="translate-x-[calc(100%+12px)] rtl:translate-x-[calc(-100%-12px)]"
      @after-leave="emit('afterLeave')"
    >
      <aside
        v-if="open"
        ref="drawerRef"
        class="fixed inset-y-3 end-3 z-50 flex w-[calc(100%-1.5rem)] flex-col overflow-hidden rounded-xl bg-n-solid-1 shadow-lg outline outline-1 outline-n-container"
        :class="maxWidthClass"
        role="dialog"
        aria-modal="true"
        :aria-label="title"
        tabindex="-1"
      >
        <slot :close="closeDrawer" />
      </aside>
    </Transition>
  </TeleportWithDirection>
</template>
