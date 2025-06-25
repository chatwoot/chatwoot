<template>
  <div class="widget-body-container">
    <div v-if="config.isDefaultScreen" class="availability-content">
      <div class="availability-info">
        <div class="team-status">
          {{ getStatusText }}
        </div>
        <div class="reply-wait-message">
          {{ config.replyTime }}
        </div>
      </div>
      <thumbnail username="J" size="40px" />
    </div>
    <div v-else class="conversation-content">
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
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
export default {
  name: 'WidgetBody',
  components: {
    Thumbnail,
  },
  props: {
    config: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    getStatusText() {
      return this.config.isOnline
        ? this.$t('INBOX_MGMT.WIDGET_BUILDER.BODY.TEAM_AVAILABILITY.ONLINE')
        : this.$t('INBOX_MGMT.WIDGET_BUILDER.BODY.TEAM_AVAILABILITY.OFFLINE');
    },
    getWidgetBodyClass() {
      return {
        'with-chat-view': !this.config.isDefaultScreen,
        'with-heading-or-title':
          this.config.isDefaultScreen &&
          (this.config.welcomeHeading || this.config.welcomeTagline),
        'with-heading-or-title-without-logo':
          this.config.isDefaultScreen &&
          (this.config.welcomeHeading || this.config.welcomeTagline) &&
          !this.config.logo,
        'without-heading-and-title':
          this.config.isDefaultScreen &&
          !this.config.welcomeHeading &&
          !this.config.welcomeTagline,
      };
    },
  },
};
</script>

<style scoped lang="scss">
.widget-body-container {
  .availability-content {
    align-items: flex-end;
    display: flex;
    flex-direction: row;
    min-height: inherit;
    padding: var(--space-one) var(--space-two) var(--space-one) var(--space-two);

    .availability-info {
      width: 100%;

      .team-status {
        font-size: var(--font-size-default);
        font-weight: var(--font-weight-medium);
      }

      .reply-wait-message {
        font-size: var(--font-size-mini);
      }
    }
  }
  .conversation-content {
    height: calc(var(--space-large) * 10);
    padding: 0 var(--space-two);

    .conversation-wrap {
      .user-message {
        align-items: flex-end;
        display: flex;
        flex-direction: row;
        justify-content: flex-end;
        margin-bottom: var(--space-smaller);
        margin-left: auto;
        margin-top: var(--space-zero);
        max-width: 85%;
        text-align: right;
      }

      .message-wrap {
        margin-right: var(--space-smaller);
        max-width: 100%;

        .chat-bubble {
          border-radius: 2rem;
          box-shadow: var(--shadow-medium);
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
            color: var(--b-900);
          }
        }
      }
    }
  }
}
</style>
