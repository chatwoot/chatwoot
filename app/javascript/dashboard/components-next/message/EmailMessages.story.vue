<script setup>
import Message from './Message.vue';

import simpleEmail from './fixtures/simpleEmail.js';

const messages = simpleEmail;
</script>

<template>
  <Story title="Components/Messages/Email" :layout="{ type: 'single' }">
    <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
      <template v-for="message in messages" :key="message.id">
        <Message :current-user-id="1" is-email-inbox v-bind="message" />
      </template>
    </div>
  </Story>
</template>
