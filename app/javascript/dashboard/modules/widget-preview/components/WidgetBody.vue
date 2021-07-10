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
.conversation--container {
  width: 100%;
  padding: 20px;
  .conversation-wrap {
    min-height: 200px;
    .user-message {
      align-items: flex-end;
      display: flex;
      flex-direction: row;
      justify-content: flex-end;
      margin: 0 0.25rem 0.125rem auto;
      max-width: 85%;
      text-align: right;
    }
    .message-wrap {
      margin-right: 0.5rem;
      max-width: 100%;
      .chat-bubble {
        box-shadow: var(--shadow-medium);
        background: var(--color-woot);
        border-radius: 1.25rem;
        color: #fff;
        display: inline-block;
        font-size: 0.875rem;
        line-height: 1.5;
        padding: 0.75rem 1rem 0.75rem 1rem;
        text-align: left;
        word-break: break-word;
        max-width: 100%;
        &.user {
          border-bottom-right-radius: 0.25rem;
        }
        &.agent {
          background: #fff;
          border-bottom-left-radius: 0.25rem;
          color: #3c4858;
        }
      }
    }
  }
}
</style>
