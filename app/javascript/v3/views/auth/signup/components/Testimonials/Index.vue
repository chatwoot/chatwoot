<script setup>
import { ref, onBeforeMount } from 'vue';
import TestimonialCard from './TestimonialCard.vue';
import { getTestimonialContent } from '../../../../../api/testimonials';

const emit = defineEmits(['resizeContainers']);

const testimonial = ref(null);

const fetchTestimonials = async () => {
  try {
    const { data } = await getTestimonialContent();
    if (data.length) {
      testimonial.value = data[Math.floor(Math.random() * data.length)];
    }
  } catch {
    // Ignoring the error as the UI wouldn't break
  } finally {
    emit('resizeContainers', !!testimonial.value);
  }
};

onBeforeMount(() => {
  fetchTestimonials();
});
</script>

<template>
  <div
    class="relative flex-1 flex flex-col items-start justify-center bg-n-alpha-black2 dark:bg-n-solid-3 px-12 py-14 rounded-e-lg"
  >
    <TestimonialCard
      v-if="testimonial"
      :review-content="testimonial.authorReview"
      :author-image="testimonial.authorImage"
      :author-name="testimonial.authorName"
      :author-designation="testimonial.authorCompany"
    />
    <div class="absolute bottom-8 right-8 grid grid-cols-3 gap-1.5">
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
    </div>
  </div>
</template>
