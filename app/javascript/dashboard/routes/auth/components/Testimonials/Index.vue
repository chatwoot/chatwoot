<template>
  <div v-if="testimonials.length" class="testimonial--section">
    <img src="/assets/images/auth/top-left.svg" class="top-left--img" />
    <img src="/assets/images/auth/bottom-right.svg" class="bottom-right--img" />
    <img src="/assets/images/auth/auth--bg.svg" class="center--img" />
    <div class="testimonial--content">
      <div class="testimonial--content-card">
        <testimonial-card
          v-for="(testimonial, index) in testimonials"
          :key="testimonial.id"
          :review-content="testimonial.authorReview"
          :author-image="testimonial.authorImage"
          :author-name="testimonial.authorName"
          :author-designation="testimonial.authorCompany"
          :class="`testimonial-${index ? 'right' : 'left'}--card`"
        />
      </div>
    </div>
  </div>
</template>

<script>
import TestimonialCard from './TestimonialCard.vue';
import { getTestimonialContent } from 'dashboard/api/testimonials';
export default {
  components: {
    TestimonialCard,
  },
  data() {
    return {
      testimonials: [],
    };
  },
  beforeMount() {
    this.fetchTestimonials();
  },
  methods: {
    async fetchTestimonials() {
      try {
        const { data } = await getTestimonialContent();
        this.testimonials = data;
      } catch (error) {
        // Ignoring the error as the UI wouldn't break
      } finally {
        this.$emit('resize-containers', !!this.testimonials.length);
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
  background: var(--w-400);
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
}

.testimonial--content-card {
  align-items: flex-start;
  display: flex;
  justify-content: center;
  padding: var(--space-larger);
}

.testimonial-left--card {
  --signup-testimonial-top: 20%;
  margin-top: var(--signup-testimonial-top);
  margin-right: var(--space-minus-normal);
  z-index: 10000;
}

@media screen and (max-width: 1200px) {
  .testimonial--section {
    display: none;
  }
}
</style>
