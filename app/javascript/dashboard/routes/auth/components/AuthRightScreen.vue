<template>
  <div class="image--wrap">
    <div class="image">
      <img src="./assets/top-left.svg" class="top-left absolute" />
      <img
        v-show="showTestimonials"
        src="./assets/testimonials.svg"
        class="union-center absolute"
      />
      <img
        v-show="!showTestimonials"
        src="./assets/reports.svg"
        class="union-center absolute"
      />
      <img src="./assets/bottom-right.svg" class="bottom-right absolute" />
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      showTestimonials: false,
      timer: null,
    };
  },
  mounted() {
    this.switchImage();
  },
  beforeDestroy() {
    this.clearTimer();
  },
  methods: {
    switchImage() {
      this.timer = setTimeout(() => {
        this.showTestimonials = !this.showTestimonials;
        this.switchImage();
      }, 5000);
    },
    clearTimer() {
      if (this.timer) {
        clearTimeout(this.timer);
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.image--wrap {
  display: flex;
  position: relative;
  flex: 1 1;
  background: #56b9fc;

  .absolute {
    position: absolute;
  }

  .image {
    .top-left {
      width: 24rem;
      height: 24rem;
      top: 0;
      left: 0;
    }
    .union-center {
      width: 100rem;
      height: 100vh;
      padding: 0 var(--space-larger);
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
    }
    .bottom-right {
      width: 32rem;
      height: 32rem;
      right: 0;
      bottom: 0;
    }
  }
}

@media screen and (max-width: 1200px) {
  .image--wrap {
    display: none;
  }
}
</style>
