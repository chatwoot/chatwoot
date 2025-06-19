<script setup>
// [TODO] Use Teleport to move the modal to the end of the body
import { ref, computed, defineEmits, onMounted } from 'vue';
import { useEventListener } from '@vueuse/core';
import Button from 'dashboard/components-next/button/Button.vue';

const { modalType, closeOnBackdropClick, onClose } = defineProps({
  closeOnBackdropClick: { type: Boolean, default: true },
  showCloseButton: { type: Boolean, default: true },
  onClose: { type: Function, required: true },
  fullWidth: { type: Boolean, default: false },
  modalType: { type: String, default: 'centered' },
  size: { type: String, default: '' },
});

const emit = defineEmits(['close']);
const show = defineModel('show', { type: Boolean, default: false });

const modalClassName = computed(() => {
  const modalClassNameMap = {
    centered: '',
    'right-aligned': 'right-aligned',
  };

  return `modal-mask skip-context-menu ${modalClassNameMap[modalType] || ''}`;
});

// [TODO] Revisit this logic to use outside click directive
const mousedDownOnBackdrop = ref(false);

const handleMouseDown = () => {
  mousedDownOnBackdrop.value = true;
};

const close = () => {
  show.value = false;
  emit('close');
  onClose();
};

const onMouseUp = () => {
  if (mousedDownOnBackdrop.value) {
    mousedDownOnBackdrop.value = false;
    if (closeOnBackdropClick) {
      close();
    }
  }
};

const onKeydown = e => {
  if (show.value && e.code === 'Escape') {
    close();
    e.stopPropagation();
  }
};

useEventListener(document.body, 'mouseup', onMouseUp);
useEventListener(document, 'keydown', onKeydown);

onMounted(() => {
  if (onClose && typeof onClose === 'function') {
    // eslint-disable-next-line no-console
    console.warn(
      "[DEPRECATED] The 'onClose' prop is deprecated. Please use the 'close' event instead."
    );
  }
});
</script>

<template>
  <transition name="modal-fade">
    <div
      v-if="show"
      :class="modalClassName"
      transition="modal"
      @mousedown="handleMouseDown"
    >
      <div
        @mouse.stop
        @mousedown="event => event.stopPropagation()"
        class="flex flex-col gap-2">
          <div class="bg-n-alpha-3 px-3 py-2 self-start rounded-lg flex flex-row text-sm gap-2 items-center cursor-pointer"
            @click="() => close()" >
            <img src="dashboard/assets/images/ic_close.svg" height="32">
            <span class="text-[#DF605B] font-bold">{{ $t('BILLING.INVOICE.CLOSE') }}</span>
          </div>
        <slot />
      </div>
    </div>
  </transition>
</template>

<style lang="scss">
.modal-mask {
  @apply flex items-center justify-center bg-n-alpha-black2 backdrop-blur-[4px] z-[9990] h-full left-0 fixed top-0 w-full;

  .modal-container {
    &.medium {
      @apply max-w-[80%] w-[56.25rem];
    }

    // .content-box {
    //   @apply h-auto p-0;
    // }
    .content {
      @apply p-8;
    }

    form,
    .modal-content {
      @apply pt-4 pb-8 px-8 self-center;

      a {
        @apply p-4;
      }
    }
  }
}

.modal-big {
  @apply w-full;
}

.modal-mask.right-aligned {
  @apply justify-end;

  .modal-container {
    @apply rounded-none h-full w-[30rem];
  }
}

.modal-enter,
.modal-leave {
  @apply opacity-0;
}

.modal-enter .modal-container,
.modal-leave .modal-container {
  transform: scale(1.1);
}
</style>
