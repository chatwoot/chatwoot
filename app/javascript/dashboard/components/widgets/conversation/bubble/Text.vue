<template>
  <div class="message-text__wrap">
    <div class="text-content" v-html="message"></div>
  </div>
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
