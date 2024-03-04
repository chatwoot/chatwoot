<template>
  <div
    class="h-full overflow-auto w-60 flex flex-col bg-white dark:bg-slate-900 border-r dark:border-slate-700 rtl:border-r-0 rtl:border-l border-slate-50 text-sm"
  >
    <sidebar-header
      :thumbnail-src="thumbnailSrc"
      :header-title="headerTitle"
      :sub-title="subTitle"
      :portal-link="portalLink"
      class="px-4"
      @open-popover="openPortalPopover"
    />
    <transition-group
      name="menu-list"
      tag="ul"
      class="py-2 px-4 list-none ml-0 mb-0"
    >
      <secondary-nav-item
        v-for="menuItem in accessibleMenuItems"
        :key="menuItem.toState"
        :menu-item="menuItem"
      />
      <secondary-nav-item
        v-for="menuItem in additionalSecondaryMenuItems"
        :key="menuItem.key"
        :menu-item="menuItem"
        @open="onClickOpenAddCatogoryModal"
      />
      <p
        v-if="!hasCategory"
        key="empty-category-nessage"
        class="p-1.5 px-4 text-slate-300"
      >
        {{ $t('SIDEBAR.HELP_CENTER.CATEGORY_EMPTY_MESSAGE') }}
      </p>
    </transition-group>
  </div>
</template>

<script>
import SecondaryNavItem from 'dashboard/components/layout/sidebarComponents/SecondaryNavItem.vue';
import SidebarHeader from './SidebarHeader.vue';

export default {
  components: {
    SecondaryNavItem,
    SidebarHeader,
  },
  props: {
    thumbnailSrc: {
      type: String,
      default: '',
    },
    headerTitle: {
      type: String,
      default: '',
    },
    subTitle: {
      type: String,
      default: '',
    },
    portalSlug: {
      type: String,
      default: '',
    },
    localeSlug: {
      type: String,
      default: '',
    },
    accessibleMenuItems: {
      type: Array,
      default: () => [],
    },
    additionalSecondaryMenuItems: {
      type: Array,
      default: () => [],
    },
  },
  computed: {
    hasCategory() {
      return (
        this.additionalSecondaryMenuItems[0] &&
        this.additionalSecondaryMenuItems[0].children.length > 0
      );
    },
    portalLink() {
      return `/hc/${this.portalSlug}/${this.localeSlug}`;
    },
  },
  methods: {
    onSearch(value) {
      this.$emit('input', value);
    },
    openPortalPopover() {
      this.$emit('open-popover');
    },
    onClickOpenAddCatogoryModal() {
      this.$emit('open-modal');
    },
  },
};
</script>
