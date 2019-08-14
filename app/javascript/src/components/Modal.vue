<template>
  <transition name="modal-fade">
    <div class="modal-mask" @click="close" v-if="show" transition="modal">
      <div class="modal-container" :class="className" @click.stop>
        <i class="ion-android-close modal--close" @click="close"></i>
        <slot></slot>
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
  methods: {
    close() {
      this.onClose();
    },
  },
  mounted() {
    document.addEventListener('keydown', (e) => {
      if (this.show && e.keyCode === 27) {
        this.onClose();
      }
    });
  },
};
</script>
