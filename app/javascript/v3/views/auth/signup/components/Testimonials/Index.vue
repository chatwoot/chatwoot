<template>
  <div
    v-if="testimonials.length"
    class="hidden bg-woot-400 dark:bg-woot-800 overflow-hidden relative md:flex h-full"
  >
    <div
      class="absolute inset-0 h-full w-full bg-white dark:bg-slate-900 bg-[radial-gradient(var(--w-100)_1px,transparent_1px)] dark:bg-[radial-gradient(var(--w-800)_1px,transparent_1px)] [background-size:16px_16px] z-0"
    />
    <div
      class="absolute h-full w-full bg-signup-gradient dark:bg-signup-gradient-dark top-0 left-0 blur-[3px]"
    />

    <img
      src="/assets/images/auth/speech-bubble-heart.svg"
      class="left-10 absolute h-40 w-32 top-8 block dark:hidden"
    />
    <img
      src="/assets/images/auth/dark-speech-bubble-heart.svg"
      class="left-10 absolute h-40 w-32 top-8 hidden dark:block"
    />
    <div class="right-10 absolute bottom-[40%]">
      <img
        src="/assets/images/auth/speech-bubble-heart.svg"
        class="w-28 block dark:hidden"
      />
      <img
        src="/assets/images/auth/dark-speech-bubble-heart.svg"
        class="w-28 hidden dark:block"
      />
      <img
        src="/assets/images/auth/speech-bubble-checkmark.svg"
        class="w-20 mt-8 block dark:hidden"
      />
      <img
        src="/assets/images/auth/dark-speech-bubble-checkmark.svg"
        class="w-20 mt-8 hidden dark:block"
      />
    </div>
    <img
      src="/assets/images/auth/star-icon.svg"
      class="left-10 bottom-8 w-24 absolute block dark:hidden"
    />
    <img
      src="/assets/images/auth/dark-star-icon.svg"
      class="left-10 bottom-8 w-24 absolute hidden dark:block"
    />
    <div class="flex items-center justify-center flex-col h-full w-full z-50">
      <div class="flex flex-col items-start justify-center p-6 gap-12">
        <testimonial-card
          v-for="(testimonial, index) in testimonials"
          :key="testimonial.id"
          :review-content="testimonial.authorReview"
          :author-image="testimonial.authorImage"
          :author-name="testimonial.authorName"
          :author-designation="testimonial.authorCompany"
          :is-left-aligned="index % 2 === 0"
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
