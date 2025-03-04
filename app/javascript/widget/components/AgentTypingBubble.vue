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
          class="chat-bubble agent typing-bubble"
          :class="getThemeClass('bg-white', 'dark:bg-slate-700')"
        >
          <img
            src="assets/images/typing.gif"
            alt="Agent is typing a message"
            class="!w-full"
          />
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
  @apply max-w-[2.4rem] p-2 ltr:rounded-bl-[1.25rem] rtl:rounded-br-[1.25rem] ltr:rounded-tl-lg rtl:rounded-tr-lg;
}
</style>
