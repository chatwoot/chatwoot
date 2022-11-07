<template>
  <div>Loading...</div>
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
      this.$router.push({
        name: 'list_all_locale_articles',
        params: {
          portalSlug: lastActivePortalSlug,
          locale: lastActiveLocaleCode,
        },
        replace: true,
      });
    else
      this.$router.push({
        name: 'list_all_portals',
        replace: true,
      });
  },
};
</script>
