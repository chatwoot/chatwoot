<script setup>
import Message from './Message.vue';

import simpleEmail from './fixtures/simpleEmail.js';
import newsletterEmail from './fixtures/newsletterEmail.js';
</script>

<template>
  <Story
    title="Components/Messages/Email"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Simple Email">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <template v-for="message in simpleEmail" :key="message.id">
          <Message :current-user-id="1" is-email-inbox v-bind="message" />
        </template>
      </div>
    </Variant>
    <Variant title="Newsletter">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <template v-for="message in newsletterEmail" :key="message.id">
          <Message :current-user-id="1" is-email-inbox v-bind="message" />
        </template>
      </div>
    </Variant>
  </Story>
</template>
