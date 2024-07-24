<template>
  <div
    class="flex items-center justify-center w-full text-slate-600 dark:text-slate-200"
  >
    Loading...
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';

export default {
  setup() {
    const { uiSettings } = useUISettings();

    return {
      uiSettings,
    };
  },
  computed: {
    ...mapGetters({ portals: 'portals/allPortals' }),
  },
  mounted() {
    this.performRouting();
  },
  methods: {
    isPortalPresent(portalSlug) {
      return !!this.portals.find(portal => portal.slug === portalSlug);
    },
    async performRouting() {
      await this.$store.dispatch('portals/index');
      this.$nextTick(() => this.routeToLastActivePortal());
    },
    routeToView(name, params) {
      this.$router.replace({ name, params, replace: true });
    },
    async routeToLastActivePortal() {
      // TODO: This method should be written as a navigation guard rather than
      // a method in the component.
      const {
        last_active_portal_slug: lastActivePortalSlug,
        last_active_locale_code: lastActiveLocaleCode,
      } = this.uiSettings || {};

      if (this.isPortalPresent(lastActivePortalSlug)) {
        // Check if the last active portal from the user preferences is available in the current
        // list of portals. If it is, navigate there. The last active portal is saved in the user's
        // UI settings, regardless of the account. Consequently, it's possible that the saved portal
        // slug is not available in the current account.
        this.routeToView('list_all_locale_articles', {
          portalSlug: lastActivePortalSlug,
          locale: lastActiveLocaleCode,
        });
      } else if (this.portals.length > 0) {
        // If the last active portal is available, check for the exisiting list of portals and
        // navigate to the first available portal.
        const { slug: portalSlug, meta: { default_locale: locale } = {} } =
          this.portals[0];
        this.routeToView('list_all_locale_articles', { portalSlug, locale });
      } else {
        // If no portals are available, navigate to the portal list page to prompt creation.
        this.$router.replace({ name: 'list_all_portals', replace: true });
      }
    },
  },
};
</script>
