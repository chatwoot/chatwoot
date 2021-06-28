<template>
  <div class="widget-wrapper">
    <div class="header-wrapper">
      <div class="header-branding">
        <div class="header">
          <img
            v-if="logo"
            :src="logo"
            class="logo"
            :class="{ small: !isExpanded }"
          />
          <div v-if="!isExpanded">
            <div class="title-block text-base font-medium">
              <span class="mr-1">{{ websiteName }}</span>
              <div v-if="isOnline" class="online-dot"></div>
            </div>
            <div class="text-xs mt-1 text-black-700">
              {{ responseTime }}
            </div>
          </div>
        </div>
        <div v-if="isExpanded" class="header-expanded">
          <h2 class="text-slate-900 mt-6 text-4xl mb-3 font-normal">
            {{ welcomeHeading }}
          </h2>
          <p class="text-lg text-black-700 leading-normal">
            {{ welcomeTagLine }}
          </p>
        </div>
      </div>
    </div>
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
    <div class="footer-wrap">
      <div class="input-wrap">
        <footer class="footer">
          <div class="chat-message--input">
            <text-area
              aria-placeholder="Type your message"
              class="form-input user-message-input"
            />
            <div class="button-wrap">
              <span class="file-uploads file-uploads-html5">
                <span class="attachment-button">
                  <i class="ion-android-attach"></i>
                </span>
              </span>
            </div>
          </div>
        </footer>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Widget',
  props: {
    welcomeHeading: {
      type: String,
      default: 'Hi There,',
    },
    welcomeTagLine: {
      type: String,
      default: '',
    },
    websiteName: {
      type: String,
      default: '',
      required: true,
    },
    websiteDomain: {
      type: String,
      default: '',
    },
    logo: {
      type: String,
      default: '',
    },
    isExpanded: {
      type: Boolean,
      default: true,
    },
    isOnline: {
      type: Boolean,
      default: true,
    },
    replyTime: {
      type: String,
      default: 'few minutes',
    },
  },
  computed: {
    // eslint-disable-next-line func-names
    responseTime: function() {
      return `Typically replies in a ${this.replyTime}`;
    },
  },
};
</script>

<style lang="scss" scoped>
.text-lg {
  font-size: var(--font-size-default);
}
.widget-wrapper {
  width: 400px;
  box-shadow: var(--shadow-larger);
  border-radius: var(--border-radius-large);
  background-color: #f4f6fb;
  z-index: 99;
}

.title-block {
  display: flex;
  align-items: center;
  .online-dot {
    background-color: #10b981;
    height: 8px;
    width: 8px;
    border-radius: 100%;
    margin: 0 10px;
  }
}
.header-wrapper {
  flex-shrink: 0;
  transition: max-height 300ms;
  background-color: #fff;
  padding: 20px;

  .header-branding {
    max-height: 16rem;
    .header {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: start;
      .logo {
        width: 56px;
        height: 56px;
        border-radius: 100%;
        transition: all 0.5s ease;
        margin-right: var(--space-small);
        &.small {
          width: 32px;
          height: 32px;
        }
      }
    }
  }
  .text-base {
    font-size: 16px;
  }
  .mt-6 {
    margin-top: var(--space-medium);
  }
}
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

.footer-wrap {
  flex-shrink: 0;
  width: 100%;
  display: flex;
  flex-direction: column;
  position: relative;
  &::before {
    content: '';
    position: absolute;
    top: -1rem;
    left: 0;
    width: 100%;
    height: 1rem;
    opacity: 0.1;
    background: linear-gradient(to top, #f4f6fb, rgba(244, 246, 251, 0));
  }
  .input-wrap {
    padding: 0 20px 20px;
    .footer {
      background: #fff;
      box-sizing: border-box;
      padding: 1rem;
      width: 100%;
      border-radius: 7px;
      box-shadow: 0 20px 25px -20px rgb(50 50 93 / 8%),
        0 10px 10px -10px rgb(50 50 93 / 4%);

      .chat-message--input {
        align-items: center;
        display: flex;

        text-area {
          border: 0;
          width: 85%;
          height: 2rem;
          min-height: 2rem;
          max-height: 15rem;
          resize: none;
          padding-top: 0.5rem;
        }
        .button-wrap {
          display: flex;
          align-items: center;
          .file-uploads {
            margin-right: 0.5rem;
            overflow: hidden;
            position: relative;
            text-align: center;
            display: inline-block;

            .attachment-button {
              background: transparent;
              border: 0;
              cursor: pointer;
              position: relative;
              width: 20px;
              .i {
                font-size: 1.25rem;
                color: #6e6f73;
              }
            }
          }
        }
      }
    }
  }
}
</style>
