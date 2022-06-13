<template>
  <div class="header-wrapper">
    <div class="header-branding">
      <div class="header">
        <img
          v-if="config.logo"
          :src="config.logo"
          class="logo"
          :class="{ small: !config.isExpanded }"
        />
        <div v-if="!config.isExpanded">
          <div class="title-block text-base font-medium">
            <span class="mr-1">{{ config.websiteName }}</span>
            <div v-if="config.isOnline" class="online-dot" />
          </div>
          <div class="text-xs mt-1 text-black-700">
            {{ responseTime }}
          </div>
        </div>
      </div>
      <div v-if="config.isExpanded" class="header-expanded">
        <h2 class="text-slate-900 mt-6 text-4xl mb-3 font-normal">
          {{ config.welcomeHeading }}
        </h2>
        <p class="text-lg text-black-700 leading-normal">
          {{ config.welcomeTagLine }}
        </p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    config: {
      type: Object,
      default() {
        return {};
      },
    },
  },
  computed: {
    responseTime() {
      switch (this.config.replyTime) {
        case 'in_a_few_minutes':
          return this.$t(
            'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_MINUTES'
          );
        case 'in_a_few_hours':
          return this.$t(
            'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_HOURS'
          );
        case 'in_a_day':
          return this.$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_DAY');
        default:
          return this.$t(
            'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_HOURS'
          );
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

  .header-branding {
    max-height: 16rem;
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
      margin: var(--space-zero) var(--space-one);
    }
  }
}
</style>
