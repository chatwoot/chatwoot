<script>
export default {
  props: {
    url: {
      type: String,
      default: '',
    },
  },
  emits: ['error'],
  methods: {
    onAudioError() {
      this.$emit('error');
    },
  },
};
</script>

<template>
  <audio
    controls
    preload="auto"
    class="skip-context-menu mb-0.5"
    @error="onAudioError"
  >
    <source :src="url" />
  </audio>
</template>
