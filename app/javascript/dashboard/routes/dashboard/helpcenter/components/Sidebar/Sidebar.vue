<template>
  <div class="main-nav secondary-menu">
    <sidebar-header
      :thumbnail-src="thumbnailSrc"
      :header-title="headerTitle"
      :sub-title="subTitle"
      @open-popover="openPortalPopover"
    />
    <transition-group name="menu-list" tag="ul" class="menu vertical">
      <secondary-nav-item
        v-for="menuItem in accessibleMenuItems"
        :key="menuItem.toState"
        :menu-item="menuItem"
        :is-help-center-sidebar="true"
      />
      <secondary-nav-item
        v-for="menuItem in additionalSecondaryMenuItems"
        :key="menuItem.key"
        :menu-item="menuItem"
        :is-help-center-sidebar="true"
        :is-category-empty="!hasCategory"
        @open="onClickOpenAddCatogoryModal"
      />
    </transition-group>
  </div>
</template>

<script>
import SecondaryNavItem from 'dashboard/components/layout/sidebarComponents/SecondaryNavItem';
import SidebarHeader from './SidebarHeader';

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
    accessibleMenuItems: {
      type: Array,
      default: () => [],
    },
    additionalSecondaryMenuItems: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {};
  },
  computed: {
    hasCategory() {
      return (
        this.additionalSecondaryMenuItems[0] &&
        this.additionalSecondaryMenuItems[0].children.length > 0
      );
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

<style scoped lang="scss">
.secondary-menu {
  background: var(--white);
  border-right: 1px solid var(--s-50);
  height: 100%;
  width: var(--space-giga);
  flex-shrink: 0;
  overflow: hidden;
  padding: var(--space-small);

  &:hover {
    overflow: auto;
  }
}
</style>
