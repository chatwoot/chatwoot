<template>
  <span class="message-text-wrap">
    <span class="message-text" v-html="message"></span>
    <span class="time">{{ readableTime }}</span>
  </span>
</template>

<script>
export default {
  props: ['message', 'readableTime'],
};
</script>
