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
      justify-content: start;

      .logo {
        border-radius: 100%;
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
      max-height: var(--space-giga);
      overflow: auto;

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
