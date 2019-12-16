<template>
  <transition name="modal-fade">
    <div v-if="show" class="modal-mask" transition="modal" @click="close">
      <i class="ion-android-close modal--close" @click="close"></i>
      <div class="modal-container" :class="className" @click.stop>
        <slot />
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  props: {
    show: Boolean,
    onClose: Function,
    className: String,
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
  },
};
</script>
