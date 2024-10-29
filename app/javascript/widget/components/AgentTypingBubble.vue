<script>
import { useDarkMode } from 'widget/composables/useDarkMode';
export default {
  name: 'AgentTypingBubble',
  setup() {
    const { getThemeClass } = useDarkMode();
    return { getThemeClass };
  },
};
</script>

<template>
  <div class="agent-message-wrap">
    <div class="agent-message">
      <div class="avatar-wrap" />
      <div class="message-wrap mt-2">
        <div
          class="typing-bubble chat-bubble agent"
          :class="getThemeClass('bg-white', 'dark:bg-slate-700')"
        >
          <img src="assets/images/typing.gif" alt="Agent is typing a message" />
        </div>
      </div>
    </div>
  </div>
</template>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
@import 'widget/assets/scss/variables.scss';

.agent-message-wrap {
  position: sticky;
  bottom: $space-smaller;
}

.typing-bubble {
  max-width: $space-normal * 2.4;
  padding: $space-small;
  border-bottom-left-radius: $space-two;
  border-top-left-radius: $space-small;

  img {
    width: 100%;
  }
}
</style>
