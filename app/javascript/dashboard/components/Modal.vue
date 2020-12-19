<template>
  <transition name="modal-fade">
    <div
      v-if="show"
      class="modal-mask"
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
  },
  computed: {
    modalContainerClassName() {
      let className = 'modal-container';
      if (this.fullWidth) {
        return `${className} modal-container--full-width`;
      }
      return className;
    },
  },
  mounted() {
    document.addEventListener('keydown', e => {
      if (this.show && e.keyCode === 27) {
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

<style scoped>
.modal-container--full-width {
  align-items: center;
  border-radius: 0;
  display: flex;
  height: 100%;
  justify-content: center;
  width: 100%;
}
</style>
