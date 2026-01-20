<script setup>
import QuickReply from '../../bubbles/Template/QuickReply.vue';

const message = {
  content: `Hey there! Thanks for reaching out to us. Could you let us know
what you need to help us better assist you?`,
};
</script>

<template>
  <Story
    title="Components/Message Bubbles/Template/QuickReply"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Quick Replies">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-4xl">
        <QuickReply :message="message" />
      </div>
    </Variant>
  </Story>
</template>
