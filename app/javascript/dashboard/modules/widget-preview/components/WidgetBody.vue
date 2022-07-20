<template>
  <div>
    <div v-if="config.isDefaultScreen" class="availabilty-container">
      <div class="availabilty-info">
        <div class="team-status">
          <!-- {{
              isOnline
                ? $t('TEAM_AVAILABILITY.ONLINE')
                : $t('TEAM_AVAILABILITY.OFFLINE')
            }} -->
          We are Online
        </div>
        <div class="reply-wait-message">
          {{ config.replyTime }}
        </div>
      </div>
      <div class="user-thumbnail-box" style="height: 40px; width: 40px;">
        <div
          aria-hidden="true"
          class="avatar-container user-thumbnail border thumbnail-rounded"
          style="width: 40px;height: 40px;border-radius: 50%;line-height: 42px;font-size: 16px;background-color: rgb(194, 225, 255);color: rgb(25, 118, 204);text-align:center;"
        >
          <span>J</span>
        </div>
      </div>
    </div>
    <div v-else class="conversation--container">
      <div class="conversation-wrap">
        <div class="message-wrap">
          <div class="user-message-wrap">
            <div class="user-message">
              <div class="message-wrap">
                <div
                  class="chat-bubble user"
                  :style="{ background: config.color }"
                >
                  <p>Hi</p>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="agent-message-wrap">
          <div class="agent-message">
            <div class="avatar-wrap" />
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
  </div>
</template>

<script>
export default {
  name: 'WidgetBody',
  props: {
    config: {
      type: Object,
      default: () => {},
    },
  },
};
</script>

<style scoped lang="scss">
.availabilty-container {
  display: flex;
  flex-direction: row;
  align-items: flex-end;
  min-height: 220px;
  padding-left: var(--space-two);
  padding-right: var(--space-two);
  margin-bottom: 1.5rem;

  .availabilty-info {
    width: 100%;
    .team-status {
      font-size: 1.5rem;
      font-weight: 500;
    }
    .reply-wait-message {
      font-size: 1.2rem;
    }
  }
}
.conversation--container {
  width: 100%;
  padding: var(--space-two);
  .conversation-wrap {
    min-height: 320px;
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
        // box-shadow: var(--shadow-medium);
        // background: var(--color-woot);
        // border-radius: var(--border-radius-large);
        // color: var(--white);
        // display: inline-block;
        // font-size: var(--font-size-nano);
        // line-height: 1.5;
        // padding: var(--space-small) var(--space-one);
        // text-align: left;
        // word-break: break-word;
        // max-width: 100%;

        box-shadow: 0 0.25rem 6px rgb(50 50 93 / 8%), 0 1px 3px rgb(0 0 0 / 5%);
        border-radius: 2rem;
        color: #fff;
        display: inline-block;
        font-size: 0.875rem;
        line-height: 1.5;
        padding: 1.5rem 1.75rem;
        text-align: left;
        word-break: break-word;

        p {
          margin: 0;
        }

        &.user {
          border-bottom-right-radius: var(--border-radius-small);
          background: var(--color-woot);
        }
        &.agent {
          background: var(--white);
          border-bottom-left-radius: var(--border-radius-small);
          color: black;
        }
      }
    }
  }
}
</style>
