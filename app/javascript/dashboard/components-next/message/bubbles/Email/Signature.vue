<script>
export default {
  name: 'EmailSignature',
  props: {
    html: {
      type: String,
      required: true,
    },
    lineString: {
      type: String,
      default: '--',
    },
  },
};
</script>

<template>
  <div>
    <br />
    <br />
    <p class="m-0">{{ lineString }}</p>
    <br />
    <div v-html="html" />
  </div>
</template>
