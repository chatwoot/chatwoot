<template>
  <transition name="modal-fade">
    <div
      v-if="show"
      :class="modalClassName"
      transition="modal"
      @mousedown="handleMouseDown"
    >
      <div
        :class="{
          'modal-container rtl:text-right shadow-md max-h-full overflow-auto relative bg-white dark:bg-slate-800 skip-context-menu': true,
          'rounded-xl w-[37.5rem]': !fullWidth,
          'items-center rounded-none flex h-full justify-center w-full':
            fullWidth,
          [size]: true,
        }"
        @mouse.stop
        @mousedown="event => event.stopPropagation()"
      >
        <woot-button
          v-if="showCloseButton"
          color-scheme="secondary"
          icon="dismiss"
          variant="clear"
          class="absolute z-10 ltr:right-2 rtl:left-2 top-2"
          @click="close"
        />
        <slot />
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  props: {
    closeOnBackdropClick: {
      type: Boolean,
      default: true,
    },
    show: Boolean,
    showCloseButton: {
      type: Boolean,
      default: true,
    },
    onClose: {
      type: Function,
      required: true,
    },
    fullWidth: {
      type: Boolean,
      default: false,
    },
    modalType: {
      type: String,
      default: 'centered',
    },
    size: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      mousedDownOnBackdrop: false,
    };
  },
  computed: {
    modalClassName() {
      const modalClassNameMap = {
        centered: '',
        'right-aligned': 'right-aligned',
      };

      return `modal-mask skip-context-menu ${
        modalClassNameMap[this.modalType] || ''
      }`;
    },
  },
  mounted() {
    document.addEventListener('keydown', e => {
      if (this.show && e.code === 'Escape') {
        this.onClose();
      }
    });

    document.body.addEventListener('mouseup', this.onMouseUp);
  },
  beforeDestroy() {
    document.body.removeEventListener('mouseup', this.onMouseUp);
  },
  methods: {
    handleMouseDown() {
      this.mousedDownOnBackdrop = true;
    },
    close() {
      this.onClose();
    },
    onMouseUp() {
      if (this.mousedDownOnBackdrop) {
        this.mousedDownOnBackdrop = false;
        if (this.closeOnBackdropClick) {
          this.onClose();
        }
      }
    },
  },
};
</script>

<style lang="scss">
.modal-mask {
  @apply flex items-center justify-center bg-modal-backdrop-light dark:bg-modal-backdrop-dark z-[9990] h-full left-0 fixed top-0 w-full;
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
