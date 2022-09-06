<template>
  <div class="sidebar-header--wrap">
    <div class="header-left--side">
      <thumbnail
        size="32px"
        :src="thumbnailSrc"
        :username="headerTitle"
        variant="square"
      />
      <div class="header-title--wrap">
        <h4 class="text-block-title title-view text-truncate">
          {{ headerTitle }}
        </h4>
        <span class="sub-title--view">{{ subTitle }}</span>
      </div>
    </div>
    <div class="header-right--side">
      <woot-button
        variant="clear"
        color-scheme="secondary"
        size="small"
        icon="arrow-up-right"
        @click="popoutHelpCenter"
      />
      <woot-button
        variant="clear"
        size="small"
        color-scheme="secondary"
        icon="arrow-swap"
        @click="openPortalPopover"
      />
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
export default {
  components: {
    Thumbnail,
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
    portalLink: {
      type: String,
      default: '',
    },
  },
  methods: {
    popoutHelpCenter() {
      window.open(this.portalLink, '_blank');
    },
    openPortalPopover() {
      this.$emit('open-popover');
    },
  },
};
</script>

<style lang="scss" scoped>
.sidebar-header--wrap {
  display: flex;
  height: var(--space-jumbo);
  align-items: center;
  justify-content: space-between;
  padding: var(--space-normal);
  margin: var(--space-minus-small);
  margin-bottom: var(--space-small);
  border-bottom: 1px solid var(--color-border-light);
}

.header-title--wrap {
  display: flex;
  align-items: flex-start;
  flex-direction: column;
  margin-left: var(--space-small);
}

.title-view {
  width: var(--space-mega);
  margin-bottom: var(--space-zero);
  height: var(--space-normal);
  line-height: var(--space-normal);
}

.sub-title--view {
  font-size: var(--font-size-mini);
  color: var(--s-600);
  height: var(--space-normal);
  line-height: var(--space-normal);
}

.header-left--side {
  display: flex;
  align-items: center;
}

.header-right--side {
  display: flex;
  align-items: flex-end;
}
</style>
