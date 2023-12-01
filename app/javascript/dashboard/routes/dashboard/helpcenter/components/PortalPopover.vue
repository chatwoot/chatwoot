<template>
  <div
    v-on-clickaway="closePortalPopover"
    class="absolute top-16 overflow-y-scroll max-h-[96vh] p-4 min-w-[12rem] w-full bg-white dark:bg-slate-800 rounded-md shadow-lg z-[1000]"
  >
    <portal-switch
      :portals="portals"
      :active-portal-slug="activePortalSlug"
      :active-locale="activeLocale"
      @open-portal-page="closePortalPopover"
      @fetch-portal="fetchPortalAndItsCategories"
    />
    <woot-button
      class="mt-4 sticky bottom-4"
      variant="smooth"
      color-scheme="secondary"
      icon="add"
      size="small"
      :is-expanded="true"
      @click="openPortalPage"
    >
      {{ $t('Add portal') }}
    </woot-button>
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
    openPortalPage() {
      this.closePortalPopover();
      this.$router.push({
        name: 'list_all_portals',
      });
    },
    fetchPortalAndItsCategories() {
      this.$emit('fetch-portal');
    },
  },
};
</script>
