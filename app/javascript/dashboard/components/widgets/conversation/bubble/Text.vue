<template>
  <span class="message-text__wrap">
    <span class="time">{{ readableTime }}</span>
    <span v-html="message"></span>
  </span>
</template>

<script>
export default {
  props: ['message', 'readableTime'],
};
</script>
