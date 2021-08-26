<template>
  <transition name="modal-fade">
    <div
      v-if="show"
      :class="modalClassName"
      transition="modal"
      @click="onBackDropClick"
    >
      <div :class="modalContainerClassName" @click.stop>
        <i class="ion-android-close modal--close" @click="close"></i>
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
  },
  computed: {
    modalContainerClassName() {
      let className = 'modal-container';
      if (this.fullWidth) {
        return `${className} modal-container--full-width`;
      }
      return className;
    },
    modalClassName() {
      const modalClassNameMap = {
        centered: '',
        'right-aligned': 'right-aligned',
      };

      return `modal-mask ${modalClassNameMap[this.modalType] || ''}`;
    },
  },
  mounted() {
    document.addEventListener('keydown', e => {
      if (this.show && e.code === 'Escape') {
        this.onClose();
      }
    });
  },
  methods: {
    close() {
      this.onClose();
    },
    onBackDropClick() {
      if (this.closeOnBackdropClick) {
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
    width: 48rem;
  }
}
</style>
