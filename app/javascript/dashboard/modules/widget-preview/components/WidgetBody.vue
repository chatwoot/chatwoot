<script setup>
import { defineProps } from 'vue';

defineProps({
  config: {
    type: Object,
    default: () => ({}),
  },
});
</script>

<template>
  <div class="h-[calc(2rem*10)] px-4 overflow-y-auto">
    <div>
      <div>
        <div
          class="items-end flex justify-end ml-auto mb-1 mt-0 max-w-[85%] text-right"
        >
          <div
            class="rounded-[1.25rem] rounded-br-[0.25rem] text-white dark:text-white text-sm px-4 py-3"
            :style="{ background: config.color }"
          >
            <p class="m-0">
              {{ $t('INBOX_MGMT.WIDGET_BUILDER.BODY.USER_MESSAGE') }}
            </p>
          </div>
        </div>
      </div>

      <div
        class="bg-white shadow rounded-[1.25rem] rounded-bl-[0.25rem] px-4 py-3 inline-block text-sm text-slate-900 dark:text-white dark:bg-slate-700"
      >
        <div>
          <p class="m-0">
            {{ $t('INBOX_MGMT.WIDGET_BUILDER.BODY.AGENT_MESSAGE') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
<<<<<<< HEAD

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
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
          border-radius: 1.25rem;
          box-shadow: var(--shadow-medium);
          color: var(--white);
          display: inline-block;
          font-size: var(--font-size-nano);
          line-height: 1.5;
          padding: 0.8125rem 1.09375rem;
          text-align: right;

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
=======
>>>>>>> 499218cecfdd39a077cd3ddeeae1800d2d0e7cf5
