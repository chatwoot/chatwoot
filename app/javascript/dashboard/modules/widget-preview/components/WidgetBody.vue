<template>
  <div class="conversation--container">
    <div class="conversation-wrap">
      <div class="message-wrap">
        <div class="user-message-wrap">
          <div class="user-message">
            <div class="message-wrap">
              <div class="chat-bubble user">
                <p>Hello</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="agent-message-wrap">
        <div class="agent-message">
          <div class="avatar-wrap"></div>
          <div class="message-wrap">
            <div class="chat-bubble agent">
              <div class="message-content">
                <p>Hello</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'WidgetBody',
};
</script>

<style scoped lang="scss">
$tailwind-black-700: #3c4858;
.conversation--container {
  width: 100%;
  padding: var(--space-two);
  .conversation-wrap {
    min-height: 200px;
    .user-message {
      align-items: flex-end;
      display: flex;
      flex-direction: row;
      justify-content: flex-end;
      margin-top: 0;
      margin-bottom: var(--space-smaller);
      margin-left: auto;
      max-width: 85%;
      text-align: right;
    }
    .message-wrap {
      margin-right: var(--space-smaller);
      max-width: 100%;
      .chat-bubble {
        box-shadow: var(--shadow-medium);
        background: var(--color-woot);
        border-radius: var(--border-radius-large);
        color: var(--white);
        display: inline-block;
        font-size: var(--font-size-nano);
        line-height: 1.5;
        padding: var(--space-small) var(--space-one);
        text-align: left;
        word-break: break-word;
        max-width: 100%;
        &.user {
          border-bottom-right-radius: var(--border-radius-small);
        }
        &.agent {
          background: var(--white);
          border-bottom-left-radius: var(--border-radius-small);
          color: $tailwind-black-700;
        }
      }
    }
  }
}
</style>
