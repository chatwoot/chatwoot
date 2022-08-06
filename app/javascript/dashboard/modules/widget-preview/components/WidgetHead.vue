<template>
  <div class="header-wrapper">
    <div class="header-branding">
      <div class="header">
        <img
          v-if="config.logo"
          :src="config.logo"
          class="logo"
          :class="{ small: !isDefaultScreen }"
        />
        <div v-if="!isDefaultScreen">
          <div class="title-block">
            <span>{{ config.websiteName }}</span>
            <div v-if="config.isOnline" class="online-dot" />
          </div>
          <div>{{ config.replyTime }}</div>
        </div>
      </div>
      <div v-if="isDefaultScreen" class="header-expanded">
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
    isDefaultScreen() {
      return (
        this.config.isDefaultScreen &&
        (this.config.welcomeHeading.length !== 0 ||
          this.config.welcomeTagline.length !== 0)
      );
    },
  },
};
</script>

<style lang="scss" scoped>
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
      max-height: var(--space-giga);
      overflow: scroll;
      h2 {
        font-size: var(--font-size-big);
        margin-bottom: var(--space-small);
        margin-top: var(--space-two);
        overflow-wrap: break-word;
      }

      p {
        font-size: var(--font-size-small);
        overflow-wrap: break-word;
      }
    }
  }

  .title-block {
    display: flex;
    align-items: center;
    font-size: var(--font-size-default);
    .online-dot {
      background-color: var(--g-500);
      height: var(--space-small);
      width: var(--space-small);
      border-radius: 100%;
      margin: var(--space-zero) var(--space-smaller);
    }
  }
}
</style>
