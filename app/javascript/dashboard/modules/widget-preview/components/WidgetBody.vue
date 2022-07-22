<template>
  <div>
    <div v-if="config.isDefaultScreen" class="availabilty-container">
      <div class="availabilty-info">
        <div class="team-status">
          {{
            config.isOnline
              ? $t('INBOX_MGMT.WIDGET_BUILDER.BODY.TEAM_AVAILABILITY.ONLINE')
              : $t('INBOX_MGMT.WIDGET_BUILDER.BODY.TEAM_AVAILABILITY.OFFLINE')
          }}
        </div>
        <div class="reply-wait-message">
          {{ config.replyTime }}
        </div>
      </div>
      <div class="user-thumbnail-box">
        <div class="user-thumbnail">
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
                  <p>{{ $t('INBOX_MGMT.WIDGET_BUILDER.BODY.USER_MESSAGE') }}</p>
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
                  <p>
                    {{ $t('INBOX_MGMT.WIDGET_BUILDER.BODY.AGENT_MESSAGE') }}
                  </p>
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
  min-height: 20rem;
  padding-left: var(--space-two);
  padding-right: var(--space-two);
  margin-bottom: var(--space-normal);

  .availabilty-info {
    width: 100%;
    .team-status {
      font-size: var(--font-size-default);
      font-weight: var(--font-weight-medium);
    }
    .reply-wait-message {
      font-size: var(--font-size-mini);
    }
  }

  .user-thumbnail-box {
    .user-thumbnail {
      width: 4rem;
      height: 4rem;
      border-radius: var(--border-radius-rounded);
      line-height: 4rem;
      font-size: var(--font-size-default);
      background-color: var(--w-100);
      color: var(--w-600);
      text-align: center;
    }
  }
}
.conversation--container {
  width: 100%;
  padding: var(--space-two);
  .conversation-wrap {
    min-height: 28rem;
    .user-message {
      align-items: flex-end;
      display: flex;
      flex-direction: row;
      justify-content: flex-end;
      margin-top: var(--space-zero);
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
        border-radius: 2rem;
        color: var(--white);
        display: inline-block;
        font-size: var(--font-size-nano);
        line-height: 1.5;
        padding: 1.3rem 1.75rem;
        text-align: left;

        p {
          margin: var(--space-zero);
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
