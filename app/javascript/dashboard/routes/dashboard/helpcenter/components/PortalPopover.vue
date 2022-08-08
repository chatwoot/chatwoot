<template>
  <div v-on-clickaway="closePortalPopover" class="portal-popover__container">
    <header>
      <div class="actions">
        <h2 class="block-title">
          {{ $t('HELP_CENTER.PORTAL.POPOVER.TITLE') }}
        </h2>
        <woot-button
          variant="smooth"
          color-scheme="secondary"
          icon="settings"
          size="small"
        >
          {{ $t('HELP_CENTER.PORTAL.POPOVER.PORTAL_SETTINGS') }}
        </woot-button>
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
        :active="portal.id === activePortal.id"
        @open-portal-page="openPortalPage"
      />
    </div>
    <footer>
      <woot-button variant="link" @click="closePortalPopover">
        {{ $t('HELP_CENTER.PORTAL.POPOVER.CANCEL_BUTTON_LABEL') }}
      </woot-button>
      <woot-button>
        {{ $t('HELP_CENTER.PORTAL.POPOVER.CHOOSE_LOCALE_BUTTON') }}
      </woot-button>
    </footer>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import PortalSwitch from './PortalSwitch.vue';
export default {
  components: {
    PortalSwitch,
  },
  mixins: [clickaway],
  props: {
    portals: {
      type: Array,
      default: () => [],
    },
    activePortal: {
      type: Object,
      default: () => ({}),
    },
  },
  methods: {
    closePortalPopover() {
      this.$emit('close-popover');
    },
    openPortalPage({ slug, locale }) {
      this.$emit('close-popover');
      const portal = this.portals.find(p => p.slug === slug);
      this.$store.dispatch('portals/setPortalId', portal.id);
      this.$router.push({
        name: 'list_all_locale_articles',
        params: {
          portalSlug: slug,
          locale: locale,
        },
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.portal-popover__container {
  position: absolute;
  overflow: scroll;
  max-height: 96vh;
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
