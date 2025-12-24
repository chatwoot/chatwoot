<template>
  <div class="widget-body-container">
    <div v-if="config.isDefaultScreen">
      <div class="default-screen-content">
        <div class="faq-card">
          <h2>FAQs</h2>
          <div
            v-for="(faq, index) in config.faqs"
            :key="index"
            class="faq-card-main"
          >
            <div
              v-if="index !== 0"
              style="border-top: 1px solid #e0e0e0; margin-top: 2px"
            />
            <div class="faq-question">
              <h3>{{ faq.question }}</h3>
              <fluent-icon icon="chevron-right" size="14" />
            </div>
          </div>
        </div>
        <div class="ask-question-card">
          <h2>{{ config.askQuestionText || 'Ask a question' }}</h2>
          <div class="ask-question-input-wrap">
            <input
              type="text"
              :placeholder="config.askQuestionText || 'Ask a question'"
            />
            <button>
              <img src="~dashboard/assets/images/send-icon.svg" alt="send" />
            </button>
          </div>
        </div>
        <div
          v-if="config.chatOnWhatsappSettings.enabled"
          class="chat-on-whatsapp-settings-card"
        >
          <div class="chat-on-whatsapp-settings">
            <img
              class="w-8 h-8"
              src="~dashboard/assets/images/WA_icon.svg"
              alt="Whatsapp Icon"
            />
            <p>{{ config.chatOnWhatsappSettings.buttonText }}</p>
            <button>
              <img src="~dashboard/assets/images/send-icon.svg" alt="send" />
            </button>
          </div>
        </div>
      </div>
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
export default {
  name: 'WidgetBody',
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
  height: 80%;
  .default-screen-content {
    height: fit-content;
    display: flex;
    gap: 20px;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    margin-top: 60px;
    .faq-card {
      height: 100%;
      max-height: 200px;
      overflow-y: auto;
      background-color: var(--white);
      border-radius: var(--border-radius-large);
      display: flex;
      flex-direction: column;
      width: 95%;
      padding: 16px;
      box-shadow: 0px 2px 10px 0px #0000001a;

      h2 {
        margin-bottom: 10px;
      }
      .faq-card-main {
        width: 100%;
        display: flex;
        flex-direction: column;
        gap: 5px;
        .faq-question {
          padding: 5px 10px;
          width: 100%;
          display: flex;
          justify-content: space-between;
          align-items: center;
          h3 {
            margin: 0;
            font-size: 12px;
            color: #262626;
            font-weight: 500;
          }
        }
      }
    }
    .ask-question-card {
      height: 100%;
      background-color: var(--white);
      border-radius: var(--border-radius-large);
      display: flex;
      flex-direction: column;
      width: 95%;
      padding: 16px;
      box-shadow: 0px 2px 10px 0px #0000001a;
      gap: 10px;

      .ask-question-input-wrap {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        input {
          border: 1px solid #d9d9d9;
          padding: 10px 16px;
          width: 80%;
          margin: 0;
        }
        button {
          margin: 0;
          background-color: #f0f0f0;
          box-shadow: 0px 1.25px 0px 0px #0000000d;
          padding: 10px 16px;
        }
      }
    }
    .chat-on-whatsapp-settings-card {
      height: 100%;
      background-color: var(--white);
      border-radius: var(--border-radius-large);
      display: flex;
      flex-direction: column;
      width: 95%;
      padding: 16px;
      box-shadow: 0px 2px 10px 0px #0000001a;
      gap: 10px;
      color: #262626;
      cursor: pointer;

      .chat-on-whatsapp-settings {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        p {
          margin: 0;
        }
      }
      .icon {
        color: #25d366 !important;
      }
    }
  }
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
          box-shadow: var(--shadow-medium);
          color: var(--white);
          display: inline-block;
          font-size: var(--font-size-nano);
          line-height: 1.5;
          padding: 10px;
          border-radius: 10px;
          text-align: left;
          width: 120px;
          margin-top: 10px;
          p {
            margin: var(--space-zero);
          }

          &.user {
            background: var(--color-woot);
          }

          &.agent {
            background: var(--white);
            color: var(--b-900);
          }
        }
      }
    }
  }
}
</style>
