<template>
  <div
    v-on-clickaway="closePortalPopover"
    class="absolute top-[4.5rem] left-2 overflow-y-auto max-h-[96vh] px-2 py-3 min-w-[12rem] w-[calc(100%-1rem)] bg-white dark:bg-slate-800 rounded-md shadow-lg z-[1000]"
  >
    <portal-switch
      :portals="portals"
      :active-portal-slug="activePortalSlug"
      :active-locale="activeLocale"
      @settings="portalSettingsPage"
      @switch-portal="switchPortal"
      @all-portals="allPortalPage"
    />
    <div class="px-1 mt-2 sticky bottom-0">
      <woot-button
        color-scheme="primary"
        icon="add"
        size="tiny"
        :is-expanded="true"
        @click="createPortalPage"
      >
        {{
          $t(
            'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BASIC_SETTINGS_PAGE.HEADER'
          )
        }}
      </woot-button>
    </div>
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
      this.$emit('close-popover');
    },
    createPortalPage() {
      this.closePortalPopover();
      this.$router.push({
        name: 'new_portal_information',
      });
    },
    allPortalPage() {
      this.closePortalPopover();
      this.$router.push({
        name: 'list_all_portals',
      });
    },
    portalSettingsPage() {
      this.closePortalPopover();
      this.$router.push({
        name: 'edit_portal_information',
        params: {
          portalSlug: this.activePortalSlug,
        },
      });
    },
    switchPortal({ portalSlug, locale }) {
      this.closePortalPopover();
      if (portalSlug !== this.activePortalSlug) {
        this.$router.push({
          name: 'list_all_locale_articles',
          params: {
            portalSlug,
            locale,
          },
        });
      }
    },
  },
};
</script>
