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
    activePortalSlug: {
      type: String,
      default: '',
    },
    activeLocale: {
      type: String,
      default: '',
    },
  },

  methods: {
    closePortalPopover() {
      this.$emit('closePopover');
    },
    openPortalPage() {
      this.closePortalPopover();
      this.$router.push({
        name: 'list_all_portals',
      });
    },
    fetchPortalAndItsCategories() {
      this.$emit('fetchPortal');
    },
  },
};
</script>

<template>
  <div
    v-on-clickaway="closePortalPopover"
    class="absolute overflow-y-scroll max-h-[96vh] p-4 bg-white dark:bg-slate-800 rounded-md shadow-lg max-w-[30rem] z-[1000]"
  >
    <header>
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg text-slate-800 dark:text-slate-100">
          {{ $t('HELP_CENTER.PORTAL.POPOVER.TITLE') }}
        </h2>
        <div>
          <woot-button
            variant="smooth"
            color-scheme="secondary"
            icon="settings"
            size="small"
            @click="openPortalPage"
          >
            {{ $t('HELP_CENTER.PORTAL.POPOVER.PORTAL_SETTINGS') }}
          </woot-button>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            icon="dismiss"
            size="small"
            @click="closePortalPopover"
          />
        </div>
      </div>
      <p class="mt-2 text-xs text-slate-600 dark:text-slate-300">
        {{ $t('HELP_CENTER.PORTAL.POPOVER.SUBTITLE') }}
      </p>
    </header>
    <div>
      <PortalSwitch
        v-for="portal in portals"
        :key="portal.id"
        :portal="portal"
        :active-portal-slug="activePortalSlug"
        :active-locale="activeLocale"
        :active="portal.slug === activePortalSlug"
        @openPortalPage="closePortalPopover"
        @fetchPortal="fetchPortalAndItsCategories"
      />
    </div>
  </div>
</template>
