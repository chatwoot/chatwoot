<script setup>
import Card from '../../bubbles/Template/Card.vue';

const message = {
  title: 'Two in one cake (1 pound)',
  content: 'Customize your order for special occasions',
  image_url:
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=300&fit=crop',
};
</script>

<template>
  <Story
    title="Components/Message Bubbles/Template/Card"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Card">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-4xl">
        <Card :message="message" />
      </div>
    </Variant>
  </Story>
</template>
