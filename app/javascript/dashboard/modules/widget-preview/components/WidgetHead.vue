<template>
  <div class="header-wrapper">
    <div class="header-branding">
      <div class="header">
        <img
          v-if="config.logo"
          :src="config.logo"
          class="logo"
          :class="{ small: !config.isDefaultScreen }"
        />
        <div v-if="!config.isDefaultScreen">
          <div class="title-block text-base font-medium">
            <span class="mr-1">{{ config.websiteName }}</span>
            <div v-if="config.isOnline" class="online-dot" />
          </div>
          <div class="text-xs mt-1 text-black-700">
            {{ config.replyTime }}
          </div>
        </div>
      </div>
      <div v-if="config.isDefaultScreen" class="header-expanded">
        <h2>{{ config.welcomeHeading }}</h2>
        <p>{{ config.welcomeTagline }}</p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    config: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    responseTime() {
      switch (this.config.replyTime) {
        case 'in_a_few_minutes':
          return this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_MINUTES'
          );
        case 'in_a_few_hours':
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
        case 'in_a_day':
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_DAY');
        default:
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
      }
    },
  },
};
</script>

<style lang="scss" scoped>
$sucess-green: #10b981;
.header-wrapper {
  flex-shrink: 0;
  transition: max-height 300ms;
  background-color: var(--white);
  padding: var(--space-two);
  border-top-left-radius: var(--border-radius-large);
  border-top-right-radius: var(--border-radius-large);

  .header-branding {
    .header {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: start;
      .logo {
        width: var(--space-jumbo);
        height: var(--space-jumbo);
        border-radius: 100%;
        transition: all 0.5s ease;
        margin-right: var(--space-small);
        &.small {
          width: var(--space-large);
          height: var(--space-large);
        }
      }
    }

    .header-expanded {
      h2 {
        font-size: var(--font-size-big);
        margin-bottom: var(--space-small);
        margin-top: var(--space-medium);
        overflow-wrap: break-word;
      }

      p {
        font-size: var(--font-size-small);
        overflow-wrap: break-word;
      }
    }
  }
  .text-base {
    font-size: var(--font-size-default);
  }
  .mt-6 {
    margin-top: var(--space-medium);
  }
  .title-block {
    display: flex;
    align-items: center;
    .online-dot {
      background-color: $sucess-green;
      height: var(--space-small);
      width: var(--space-small);
      border-radius: 100%;
      margin: var(--space-zero) var(--space-smaller);
    }
  }
}
</style>
