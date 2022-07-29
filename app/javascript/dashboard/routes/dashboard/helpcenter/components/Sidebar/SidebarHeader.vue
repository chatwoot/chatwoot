<template>
  <div class="sidebar-header--wrap">
    <div class="header-left--side">
      <thumbnail
        size="40px"
        :src="thumbnailSrc"
        :username="headerTitle"
        variant="square"
      />
      <div class="header-title--wrap">
        <h4 class="sub-block-title title-view">{{ headerTitle }}</h4>
        <span class="sub-title--view">{{ subTitle }}</span>
      </div>
    </div>
    <div class="header-right--side">
      <woot-button
        variant="link"
        color-scheme="secondary"
        @click="popOutHelpCenter"
      >
        <fluent-icon
          icon="arrow-up-right"
          size="28px"
          class="pop-out--icon"
          @click="popOutHelpCenter"
        />
      </woot-button>
      <woot-button
        variant="link"
        color-scheme="secondary"
        @click="openPortalPopover"
      >
        <fluent-icon
          icon="arrow-swap"
          size="28px"
          class="portal-switch--icon"
        />
      </woot-button>
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
  },
  methods: {
    popOutHelpCenter() {
      this.$emit('pop-out');
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
  padding: var(--space-small) 0 var(--space-normal) 0;
  border-bottom: 1px solid var(--color-border-light);
}

.header-title--wrap {
  display: flex;
  align-items: flex-start;
  flex-direction: column;
  margin-left: var(--space-small);
}

.title-view {
  margin-bottom: var(--space-zero);
}

.sub-title--view {
  font-size: var(--font-size-mini);
  color: var(--b-600);
}

.header-left--side {
  display: flex;
  align-items: center;
}

.header-right--side {
  display: flex;
  align-items: center;
}

.pop-out--icon {
  padding: var(--space-smaller);
}

.portal-switch--icon {
  padding: var(--space-smaller);
  margin-left: var(--space-small);

  &:hover {
    cursor: pointer;
    background: var(--s-50);
    border-radius: var(--border-radius-normal);
  }
}
</style>
