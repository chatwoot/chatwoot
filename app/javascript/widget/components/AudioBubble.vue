<script>
export default {
  props: {
    url: {
      type: String,
      default: '',
    },
  },
  emits: ['error'],
  data() {
    return {
      localUrl: '',
    };
  },
  watch: {
    localUrl(newUrl) {
      if (newUrl && this.$refs.audioElement) {
        this.$refs.audioElement.load();
      }
    },
  },
  mounted() {
    setTimeout(() => {
      this.localUrl = this.url;
    }, 1000);
  },
  methods: {
    onAudioError() {
      this.$emit('error');
    },
  },
};
</script>

<template>
  <audio
    ref="audioElement"
    controls
    preload="auto"
    class="skip-context-menu mb-0.5"
    @error="onAudioError"
  >
    <source :src="localUrl" />
  </audio>
</template>
