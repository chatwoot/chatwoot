<template>
  <div :style="{ background: config.color }" class="header-wrapper">
    <div class="header-branding">
      <div class="header">
        <img
          v-if="config.logo"
          :src="config.logo"
          class="logo"
          :class="{ small: !isDefaultScreen }"
        />
        <div v-if="!isDefaultScreen">
          <div style="color: white" class="title-block">
            <span>{{ config.websiteName }}</span>
            <div v-if="config.isOnline" class="online-dot" />
          </div>
          <div style="color: white">{{ config.replyTime }}</div>
        </div>
      </div>
      <div v-if="isDefaultScreen" class="header-expanded">
        <h2>{{ config.welcomeHeading }}</h2>
        <p>{{ config.welcomeTagline }}</p>
        <div class="track-order-card">
          <img
            class="delivery-icon"
            src="~dashboard/assets/images/delivery_icon.svg"
            alt="No Page Image"
          />
          <p>Track Order</p>
          <fluent-icon
            icon="chevron-right"
            size="14"
            class="text-slate-900 dark:text-slate-50"
          />
        </div>
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
    isDefaultScreen() {
      return (
        this.config.isDefaultScreen &&
        ((this.config.welcomeHeading &&
          this.config.welcomeHeading.length !== 0) ||
          (this.config.welcomeTagLine &&
            this.config.welcomeTagline.length !== 0))
      );
    },
  },
};
</script>

<style lang="scss" scoped>
.header-wrapper {
  background-color: var(--white);
  border-top-left-radius: var(--border-radius-large);
  border-top-right-radius: var(--border-radius-large);
  flex-shrink: 0;
  padding: var(--space-two);
  transition: max-height 300ms;

  .header-branding {
    .header {
      align-items: center;
      display: flex;
      flex-direction: row;
      justify-content: flex-start;

      .logo {
        border-radius: 4px;
        height: var(--space-larger);
        margin-right: var(--space-small);
        transition: all 0.5s ease;
        width: var(--space-larger);

        &.small {
          height: var(--space-large);
          width: var(--space-large);
        }
      }
    }

    .header-expanded {
      max-height: var(--space-giga-plus);
      overflow: visible;
      padding-bottom: var(--space-medium);
      position: relative;

      .delivery-icon {
        height: var(--space-large);
        width: var(--space-large);
      }

      .track-order-card {
        align-items: center;
        background-color: var(--white);
        border-radius: var(--border-radius-large);
        display: flex;
        position: absolute;
        top: 100%;
        width: 95%;
        gap: 10px;
        max-width: 100%;
        padding: 16px;
        overflow: hidden;
        box-shadow: 0px 2px 10px 0px #0000001a;
        box-shadow: 0px 0px 2px 0px #00000033;

        p {
          font-size: var(--font-size-small);
          font-weight: 500;
          margin: 0;
          color: var(--light-grey-new);
          margin-right: auto;
        }
      }

      h2 {
        font-size: var(--font-size-big);
        margin-top: var(--space-two);
        overflow-wrap: break-word;
        color: var(--white);
        font-weight: 500;
      }

      p {
        font-size: var(--font-size-small);
        overflow-wrap: break-word;
        color: var(--light-gray);
      }
    }
  }

  .title-block {
    align-items: center;
    display: flex;
    font-size: var(--font-size-default);

    .online-dot {
      background-color: var(--g-500);
      border-radius: 100%;
      height: var(--space-small);
      margin: var(--space-zero) var(--space-smaller);
      width: var(--space-small);
    }
  }
}
</style>
