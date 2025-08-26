<template>
  <div class="agent-message-wrap">
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
