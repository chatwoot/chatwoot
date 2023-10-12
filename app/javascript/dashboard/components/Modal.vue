<template>
  <transition name="modal-fade">
    <div
      v-if="show"
      :class="modalClassName"
      transition="modal"
      @mousedown="handleMouseDown"
    >
      <div
        :class="modalContainerClassName"
        @mouse.stop
        @mousedown="event => event.stopPropagation()"
      >
        <woot-button
          v-if="showCloseButton"
          color-scheme="secondary"
          icon="dismiss"
          variant="clear"
          class="absolute ltr:right-2 rtl:left-2 top-2 z-10"
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
    modalContainerClassName() {
      let className =
        'modal-container bg-white dark:bg-slate-800 skip-context-menu';
      if (this.fullWidth) {
        return `${className} modal-container--full-width`;
      }

      return `${className} ${this.size}`;
    },
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
        this.onClose();
      }
    },
  },
};
</script>

<style scoped lang="scss">
.modal-container--full-width {
  align-items: center;
  border-radius: 0;
  display: flex;
  height: 100%;
  justify-content: center;
  width: 100%;
}

.modal-mask.right-aligned {
  justify-content: flex-end;

  .modal-container {
    border-radius: 0;
    height: 100%;
    width: 30rem;
  }
}
.modal-big {
  width: 60%;
}
</style>
