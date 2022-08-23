<template>
  <div class="header--wrap">
    <div class="header-left--wrap">
      <woot-button
        icon="chevron-left"
        class-names="article-back-buttons"
        variant="clear"
        color-scheme="primary"
        @click="onClickGoBack"
      >
        {{ backButtonLabel }}
      </woot-button>
    </div>
    <div class="header-right--wrap">
      <span v-if="isUpdating || isSaved" class="draft-status">
        {{ statusText }}
      </span>

      <woot-button
        class-names="article--buttons"
        icon="globe"
        color-scheme="secondary"
        variant="hollow"
        size="small"
        @click="showPreview"
      >
        {{ $t('HELP_CENTER.EDIT_HEADER.PREVIEW') }}
      </woot-button>
      <woot-button
        class-names="article--buttons"
        icon="add"
        color-scheme="secondary"
        variant="hollow"
        size="small"
        @click="onClickAdd"
      >
        {{ $t('HELP_CENTER.EDIT_HEADER.ADD_TRANSLATION') }}
      </woot-button>
      <woot-button
        v-if="!isSidebarOpen"
        v-tooltip.top-end="$t('HELP_CENTER.EDIT_HEADER.OPEN_SIDEBAR')"
        icon="pane-open"
        class-names="article--buttons"
        variant="hollow"
        size="small"
        color-scheme="secondary"
        @click="openSidebar"
      />
      <woot-button
        v-if="isSidebarOpen"
        v-tooltip.top-end="$t('HELP_CENTER.EDIT_HEADER.CLOSE_SIDEBAR')"
        icon="pane-close"
        class-names="article--buttons"
        variant="hollow"
        size="small"
        color-scheme="secondary"
        @click="closeSidebar"
      />
      <woot-button
        class-names="article--buttons"
        size="small"
        color-scheme="primary"
      >
        {{ $t('HELP_CENTER.EDIT_HEADER.PUBLISH_BUTTON') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    backButtonLabel: {
      type: String,
      default: '',
    },
    isUpdating: {
      type: Boolean,
      default: false,
    },
    isSaved: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isSidebarOpen: false,
    };
  },
  computed: {
    statusText() {
      return this.isUpdating
        ? this.$t('HELP_CENTER.EDIT_HEADER.SAVING')
        : this.$t('HELP_CENTER.EDIT_HEADER.SAVED');
    },
  },
  methods: {
    onClickGoBack() {
      this.$emit('back');
    },
    showPreview() {
      this.$emit('show');
    },
    onClickAdd() {
      this.$emit('add');
    },
    openSidebar() {
      this.isSidebarOpen = true;
      this.$emit('open');
    },
    closeSidebar() {
      this.isSidebarOpen = false;
      this.$emit('close');
    },
  },
};
</script>

<style scoped lang="scss">
.header--wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  height: var(--space-larger);
}
.header-left--wrap {
  display: flex;
  align-items: center;
}
.header-right--wrap {
  display: flex;
  align-items: center;
}
.article-back-buttons {
  padding-left: 0;
}
.article--buttons {
  margin-left: var(--space-smaller);
}
.draft-status {
  margin-right: var(--space-smaller);
  margin-left: var(--space-normal);
  color: var(--s-400);
  align-items: center;
  font-size: var(--font-size-mini);
  animation: fadeIn 1s;
  @keyframes fadeIn {
    0% {
      opacity: 0;
    }
    100% {
      opacity: 1;
    }
  }
}
</style>
