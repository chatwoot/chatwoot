<template>
  <span class="message-text__wrap">
    <span v-html="message"></span>
  </span>
</template>

<script>
export default {
  props: {
    message: {
      type: String,
      default: '',
    },
    readableTime: {
      type: String,
      default: '',
    },
    isEmail: {
      type: Boolean,
      default: true,
    },
  },
};
</script>
