<script setup>
import CallToAction from '../../bubbles/Template/CallToAction.vue';

const message = {
  content:
    'We have super cool products going live! Pre-order and customize products. Contact us for more details',
};
</script>

<template>
  <Story
    title="Components/Message Bubbles/Template/CallToAction"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Call To Action">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-4xl">
        <CallToAction :message="message" />
      </div>
    </Variant>
  </Story>
</template>
