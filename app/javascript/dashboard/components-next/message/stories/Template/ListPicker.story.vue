<script setup>
import ListPicker from '../../bubbles/Template/ListPicker.vue';

const message = {
  content: `Hey there! Thanks for reaching out to us. Could you let us know
what you need to help us better assist you? `,
};
</script>

<template>
  <Story
    title="Components/Message Bubbles/Template/ListPicker"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="ListPicker">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-4xl">
        <ListPicker :message="message" />
      </div>
    </Variant>
  </Story>
</template>
