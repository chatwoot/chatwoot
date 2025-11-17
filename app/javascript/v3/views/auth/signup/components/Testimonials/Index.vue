<script setup>
import { ref, onBeforeMount } from 'vue';
import TestimonialCard from './TestimonialCard.vue';
import { getTestimonialContent } from '../../../../../api/testimonials';

const emit = defineEmits(['resizeContainers']);

const testimonials = ref([]);

const fetchTestimonials = async () => {
  try {
    const { data } = await getTestimonialContent();
    testimonials.value = data;
  } catch (error) {
    // Ignoring the error as the UI wouldn't break
  } finally {
    emit('resizeContainers', !!testimonials.value.length);
  }
};

onBeforeMount(() => {
  fetchTestimonials();
});
</script>

<template>
  <div
    v-show="testimonials.length"
    class="relative self-stretch hidden overflow-hidden bg-n-blue-8 dark:bg-n-blue-5 xl:flex"
  >
    <img
      src="assets/images/auth/top-left.svg"
      class="absolute top-0 left-0 w-40 h-40"
    />
    <img
      src="assets/images/auth/bottom-right.svg"
      class="absolute bottom-0 right-0 w-40 h-40"
    />
    <img
      src="assets/images/auth/auth--bg.svg"
      class="h-[96%] left-[6%] top-[8%] w-[96%] absolute"
    />
    <div class="z-50 flex flex-col items-center justify-center w-full h-full">
      <div class="flex items-start justify-center p-6">
        <TestimonialCard
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

<style lang="scss" scoped>
.center--img {
}
</style>
