<template>
  <div class="testimonial--section">
    <img src="/assets/images/auth/top-left.svg" class="top-left--img" />
    <img src="/assets/images/auth/bottom-right.svg" class="bottom-right--img" />
    <img src="/assets/images/auth/auth--bg.svg" class="center--img" />
    <div class="testimonial--content">
      <div v-show="!showTestimonials" class="image-bottom--text">
        <h3 class="heading">{{ 'Get Realtime Reports ' }}</h3>
        <span class="sub-block-title sub-heading">{{
          'Stay on top of SLAs, agents, inboxes, multiple channels'
        }}</span>
      </div>
      <div v-show="showTestimonials" class="testimonial--content-card">
        <testimonial-card
          :review-content="LEFT_CARD.AUTHOR_REVIEW"
          :author-image="LEFT_CARD.AUTHOR_IMAGE"
          :author-name="LEFT_CARD.AUTHOR_NAME"
          :author-designation="LEFT_CARD.AUTHOR_COMAPNY"
          class="testimonial-left--card"
        />

        <testimonial-card
          :review-content="RIGHT_CARD.AUTHOR_REVIEW"
          :author-image="RIGHT_CARD.AUTHOR_IMAGE"
          :author-name="RIGHT_CARD.AUTHOR_NAME"
          :author-designation="RIGHT_CARD.AUTHOR_COMAPNY"
          class="testimonial-right--card"
        />
      </div>
      <testimonial-footer
        title="Loved by small and big teams, alike"
        sub-title="We put your needs first. That is what keeps us going."
      />

      <div v-show="!showTestimonials">
        <img
          src="/assets/images/auth/reports-left-card.svg"
          class="reports-card absolute reports-left-card"
        />
        <img
          src="/assets/images/auth/reports-right-card.svg"
          class="reports-card absolute reports-right-card"
        />
      </div>
    </div>
  </div>
</template>

<script>
import TestimonialCard from './TestimonialCard.vue';
import TestimonialFooter from './TestimonialFooter.vue';

import content from './content';
export default {
  components: {
    TestimonialCard,
    TestimonialFooter,
  },
  data() {
    return {
      showTestimonials: true,
      timer: null,
      LEFT_CARD: content.LEFT_CARD,
      RIGHT_CARD: content.RIGHT_CARD,
    };
  },
  computed: {},
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
      }, 50000000);
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
@import '~dashboard/assets/scss/woot';

.top-left--img {
  left: 0;
  height: 16rem;
  position: absolute;
  top: 0;
  width: 16rem;
}

.bottom-right--img {
  bottom: 0;
  height: 16rem;
  position: absolute;
  right: 0;
  width: 16rem;
}

.center--img {
  left: 5%;
  max-height: 86%;
  max-width: 90%;
  position: absolute;
  top: 2%;
}

.center-container {
  padding: var(--space-medium) 0;
}

.testimonial--section {
  background: var(--w-300);
  display: flex;
  flex: 1 1;
  position: relative;
}

.testimonial--content {
  align-content: center;
  display: flex;
  flex-direction: column;
  height: 100%;
  justify-content: center;
  width: 100%;
  z-index: 1000;
  padding-top: var(--space-larger);
}

.testimonial--content-card {
  display: flex;
  align-items: flex-start;
  justify-content: center;
  margin-bottom: var(--space-larger);
}

.testimonial-left--card {
  --signup-testimonial-top: 20rem;
  margin-top: var(--signup-testimonial-top);
  margin-right: var(--space-minus-mega);
  z-index: 10000;
}

@media screen and (max-width: 1200px) {
  .testimonial--section {
    display: none;
  }
}
</style>
