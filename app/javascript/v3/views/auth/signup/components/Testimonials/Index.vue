<template>
  <div
    v-if="testimonials.length"
    class="hidden bg-woot-400 dark:bg-woot-800 overflow-hidden relative xl:flex flex-1"
  >
    <img
      src="/assets/images/auth/top-left.svg"
      class="left-0 absolute h-40 w-40 top-0"
    />
    <img
      src="/assets/images/auth/bottom-right.svg"
      class="right-0 absolute h-40 w-40 bottom-0"
    />
    <img
      src="/assets/images/auth/auth--bg.svg"
      class="h-[96%] left-[6%] top-[8%] w-[96%] absolute"
    />
    <div class="flex items-center justify-center flex-col h-full w-full z-50">
      <div class="flex items-start justify-center p-6">
        <testimonial-card
          v-for="(testimonial, index) in testimonials"
          :key="testimonial.id"
          :review-content="testimonial.authorReview"
          :author-image="testimonial.authorImage"
          :author-name="testimonial.authorName"
          :author-designation="testimonial.authorCompany"
          :class="!index ? 'mt-[20%] -mr-4 z-50' : ''"
        />
      </div>
    </div>
  </div>
</template>

<script>
import TestimonialCard from './TestimonialCard.vue';
import { getTestimonialContent } from '../../../../../api/testimonials';
export default {
  components: { TestimonialCard },
  data() {
    return { testimonials: [] };
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
.center--img {
}
</style>
