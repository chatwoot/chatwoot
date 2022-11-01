<template>
  <div class="main-nav secondary-menu">
    <sidebar-header
      :thumbnail-src="thumbnailSrc"
      :header-title="headerTitle"
      :sub-title="subTitle"
      :portal-link="portalLink"
      @open-popover="openPortalPopover"
    />
    <transition-group name="menu-list" tag="ul" class="menu vertical">
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
        class="empty-text text-muted"
      >
        {{ $t('SIDEBAR.HELP_CENTER.CATEGORY_EMPTY_MESSAGE') }}
      </p>
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

<style scoped lang="scss">
@import '~dashboard/assets/scss/woot';
.secondary-menu {
  display: flex;
  flex-direction: column;
  background: var(--white);
  border-right: 1px solid var(--s-50);
  height: 100%;
  width: var(--space-giga);
  flex-shrink: 0;
  overflow: hidden;
  padding: var(--space-small);

  @include breakpoint(xlarge down) {
    position: absolute;
  }

  @include breakpoint(xlarge up) {
    position: unset;
  }

  &:hover {
    overflow: auto;
  }

  .menu {
    padding: var(--space-small);
    overflow-y: auto;
  }
}

.empty-text {
  padding: var(--space-smaller) var(--space-normal);
}
</style>
