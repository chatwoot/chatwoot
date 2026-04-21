<script setup>
import Text from '../../bubbles/Template/Text.vue';

const message = {
  content: 'Hello John, how may we assist you?',
};
</script>

<template>
  <Story
    title="Components/Message Bubbles/Template/Text"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Default Text">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-4xl">
        <Text :message="message" />
      </div>
    </Variant>
  </Story>
</template>
