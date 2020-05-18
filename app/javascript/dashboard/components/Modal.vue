<template>
  <transition name="modal-fade">
    <div
      v-if="show"
      class="modal-mask"
      transition="modal"
      @click="onBackDropClick"
    >
      <div class="modal-container" :class="className" @click.stop>
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
    className: {
      type: String,
      default: '',
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
