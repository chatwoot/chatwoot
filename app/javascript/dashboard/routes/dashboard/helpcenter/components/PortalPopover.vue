<template>
  <div class="portal-popover__container">
    <header>
      <div class="actions">
        <h2 class="block-title">
          {{ $t('HELP_CENTER.PORTAL.POPOVER.TITLE') }}
        </h2>
        <router-link to="#" class="new-popover-link">
          <fluent-icon icon="add" size="16" />
          <span>
            {{ $t('HELP_CENTER.PORTAL.POPOVER.NEW_PORTAL_LINK') }}
          </span>
        </router-link>
      </div>
      <p class="subtitle">
        {{ $t('HELP_CENTER.PORTAL.POPOVER.SUBTITLE') }}
      </p>
    </header>
    <div>
      <portal-switch
        v-for="portal in portals"
        :key="portal.id"
        :portal="portal"
      />
    </div>
    <footer>
      <woot-button variant="link">
        {{ $t('HELP_CENTER.PORTAL.POPOVER.CANCEL_BUTTON_LABEL') }}
      </woot-button>
      <woot-button>
        {{ $t('HELP_CENTER.PORTAL.POPOVER.CHOOSE_LOCALE_BUTTON') }}
      </woot-button>
    </footer>
  </div>
</template>

<script>
import PortalSwitch from './PortalSwitch.vue';
export default {
  components: {
    PortalSwitch,
  },
  props: {
    portals: {
      type: Array,
      default: () => [],
    },
  },
};
</script>

<style lang="scss" scoped>
.portal-popover__container {
  padding: var(--space-normal);
  background-color: var(--white);
  border-radius: var(--border-radius-normal);
  box-shadow: var(--shadow-large);
  max-width: 48rem;

  header {
    .actions {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: var(--space-smaller);

      .new-popover-link {
        display: flex;
        align-items: center;
        padding: var(--space-half) var(--space-one);
        background-color: var(--s-25);
        font-size: var(--font-size-mini);
        color: var(--s-500);
        margin-left: var(--space-small);
        border-radius: var(--border-radius-normal);
        span {
          margin-left: var(--space-small);
        }
      }

      .subtitle {
        font-size: var(--font-size-mini);
        color: var(--s-600);
      }
    }
  }

  footer {
    display: flex;
    justify-content: end;
    align-items: center;
    gap: var(--space-small);
  }
}
</style>
