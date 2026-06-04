<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useBreakpoints, breakpointsTailwind } from '@vueuse/core';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  align: {
    type: String,
    default: 'end',
    validator: v => ['start', 'end'].includes(v),
  },
  disableMobileView: {
    type: Boolean,
    default: false,
  },
  showContentBorder: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['show', 'hide']);

const isActive = ref(false);
const triggerRef = ref(null);
const popoverRef = ref(null);
const mobileContentRef = ref(null);

const breakpoints = useBreakpoints(breakpointsTailwind);
const belowMd = breakpoints.smaller('md');
const isMobile = computed(() => !props.disableMobileView && belowMd.value);
const showPopover = computed(() => isActive.value && !isMobile.value);

const { fixedPosition, updatePosition } = useDropdownPosition(
  triggerRef,
  popoverRef,
  showPopover,
  { align: props.align }
);

const show = async () => {
  isActive.value = true;
  if (!isMobile.value) {
    await nextTick();
    updatePosition();
  }
  emit('show');
};

const hide = () => {
  if (!isActive.value) return;
  isActive.value = false;
  emit('hide');
};

const toggle = async () => {
  if (isActive.value) hide();
  else await show();
};

// Recalculate position when switching from mobile to desktop while open
watch(isMobile, async mobile => {
  if (!isActive.value || mobile) return;
  await nextTick();
  updatePosition();
});

const handleClickOutside = event => {
  if (triggerRef.value?.contains(event.target)) return;
  hide();
};

// Selectors for teleported elements that should not trigger close
const clickOutsideIgnore = [
  'dialog.ProseMirror-prompt-backdrop',
  '[data-popover-content]',
];

useKeyboardEvents({
  Escape: {
    action: () => isActive.value && hide(),
    allowOnFocusedInput: true,
  },
});

defineExpose({ show, hide, toggle });
</script>

<template>
  <span ref="triggerRef" class="inline-flex" @click="toggle">
    <slot :is-open="isActive" />
  </span>

  <TeleportWithDirection to="body">
    <!-- Mobile: centered modal with backdrop -->
    <div
      v-if="isActive && isMobile"
      data-popover-backdrop
      class="fixed inset-0 z-[9999] flex items-start pt-[clamp(3rem,15vh,12rem)] justify-center bg-n-alpha-black1"
    >
      <div
        ref="mobileContentRef"
        v-on-click-outside="[
          handleClickOutside,
          { ignore: clickOutsideIgnore },
        ]"
        data-popover-content
        class="relative flex flex-col w-full max-w-lg max-h-[calc(100vh-4rem)] mx-4 bg-n-alpha-3 backdrop-blur-[100px] shadow-xl rounded-xl"
      >
        <div
          class="flex-1 min-h-0 overflow-y-auto overscroll-contain rounded-xl"
        >
          <slot name="content" :hide="hide" />
        </div>
      </div>
    </div>

    <!-- Desktop: fixed popover -->
    <div
      v-else-if="showPopover"
      ref="popoverRef"
      v-on-click-outside="[handleClickOutside, { ignore: clickOutsideIgnore }]"
      data-popover-content
      :class="fixedPosition.class"
      :style="fixedPosition.style"
      class="flex flex-col bg-n-alpha-3 backdrop-blur-[100px] shadow-xl rounded-xl"
    >
      <div
        class="flex-1 min-h-0 overflow-y-auto overscroll-contain rounded-xl"
        :class="{ 'border border-n-strong': showContentBorder }"
      >
        <slot name="content" :hide="hide" />
      </div>
    </div>
  </TeleportWithDirection>
</template>
