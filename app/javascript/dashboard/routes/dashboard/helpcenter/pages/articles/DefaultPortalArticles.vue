<template>
  <div
    class="text-slate-600 dark:text-slate-200 flex items-center justify-center w-full"
  >
    Loading...
  </div>
</template>
<script>
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  mixins: [uiSettingsMixin],
  mounted() {
    const {
      last_active_portal_slug: lastActivePortalSlug,
      last_active_locale_code: lastActiveLocaleCode,
    } = this.uiSettings || {};

    if (lastActivePortalSlug)
      this.$router.replace({
        name: 'list_all_locale_articles',
        params: {
          portalSlug: lastActivePortalSlug,
          locale: lastActiveLocaleCode,
        },
        replace: true,
      });
    else
      this.$router.replace({
        name: 'list_all_portals',
        replace: true,
      });
  },
};
</script>
