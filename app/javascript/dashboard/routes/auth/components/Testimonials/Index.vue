<template>
  <div v-if="testimonials.length" class="testimonial--section">
    <div class="testimonial">
      <img src="/assets/images/auth/top-left.svg" class="top-left--img" />
      <img
        src="/assets/images/auth/bottom-right.svg"
        class="bottom-right--img"
      />
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
    <testimonial-footer
      title="All it takes is one step to move forward."
      sub-title="You're one step away from engaging your customers, retaining them and finding new ones."
    />
  </div>
</template>

<script>
import TestimonialCard from './TestimonialCard.vue';
import TestimonialFooter from './TestimonialFooter.vue';
import { getTestimonialContent } from 'dashboard/api/testimonials';
export default {
  components: {
    TestimonialCard,
    TestimonialFooter,
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
        this.$emit('resize-containers', !!this.testimonials.length);
      } catch (error) {
        // Ignoring the error as the UI wouldn't break
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
  height: 84%;
  left: 5%;
  position: absolute;
  top: 2%;
  width: 90%;
}

.center-container {
  padding: var(--space-medium) 0;
}

.testimonial--section {
  background: var(--w-300);
  display: flex;
  flex: 1 1;
  flex-direction: column;
  justify-content: center;
  position: relative;

  .testimonial {
    display: flex;
  }
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
