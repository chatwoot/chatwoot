<template>
  <div v-if="isVisible" class="agent-message-wrap">
    <div class="agent-message">
      <!-- <div class="avatar-wrap" /> -->
      <div class="message-wrap mt-2">
        <div
          class="typing-bubble chat-bubble agent !px-3.5 h-11 !w-24 !flex justify-center items-center"
          :class="$dm('bg-white', 'dark:bg-slate-700')"
        >
          <img
            src="~widget/assets/images/typing.gif"
            alt="Agent is typing a message"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import darkModeMixing from 'widget/mixins/darkModeMixin.js';
export default {
  name: 'AgentTypingBubble',
  mixins: [darkModeMixing],
  data() {
    return {
      isVisible: true,
      timeout: null,
    };
  },
  mounted() {
    this.startHideTimer();
  },
  beforeDestroy() {
    // Clean up the timeout when component is destroyed
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  },
  methods: {
    startHideTimer() {
      // Clear any existing timeout
      if (this.timeout) {
        clearTimeout(this.timeout);
      }
      // Set a new timeout to hide the bubble after 15 seconds
      this.timeout = setTimeout(() => {
        this.isVisible = false;
      }, 15000);
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';
.agent-message-wrap {
  position: sticky;
  bottom: $space-normal;
}

.typing-bubble {
  max-width: 4rem;

  img {
    width: 100%;
  }
}
</style>
