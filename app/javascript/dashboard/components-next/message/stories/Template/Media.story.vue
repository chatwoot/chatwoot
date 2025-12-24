<script setup>
import Media from '../../bubbles/Template/Media.vue';

const message = {
  content:
    'Welcome to our Diwali sale! Get flat 50% off on select items. Hurry now!',
  image_url:
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=300&fit=crop',
};
</script>

<template>
  <Story
    title="Components/Message Bubbles/Template/Media"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Image Media">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-4xl">
        <Media :message="message" />
      </div>
    </Variant>
  </Story>
</template>
