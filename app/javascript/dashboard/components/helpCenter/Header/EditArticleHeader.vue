<template>
  <div class="header--wrap">
    <div class="header-left--wrap">
      <woot-button
        icon="chevron-left"
        class-names="article--buttons"
        variant="clear"
        color-scheme="primary"
        @click="onClickGoBack"
      >
        {{ backButtonLabel }}
      </woot-button>
    </div>
    <div class="header-right--wrap">
      <span v-if="newChanges" class="draft-status">
        {{ draftStatusText }}
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
        v-if="isSidebarOpen"
        v-tooltip.top-end="$t('HELP_CENTER.EDIT_HEADER.OPEN_SIDEBAR')"
        icon="pane-open"
        class-names="article--buttons"
        variant="hollow"
        size="small"
        color-scheme="secondary"
        @click="openSidebar"
      />
      <woot-button
        v-else
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
        {{ actionButtonLabel }}
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
    actionButtonLabel: {
      type: String,
      default: '',
    },
    isSaving: {
      type: Boolean,
      default: false,
    },
    newChanges: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isSidebarOpen: true,
    };
  },
  computed: {
    draftStatusText() {
      return this.isSaving
        ? this.$t('HELP_CENTER.EDIT_HEADER.SAVING')
        : this.$t('HELP_CENTER.EDIT_HEADER.SAVED');
    },
  },
  methods: {
    onClickGoBack() {
      this.$emit('goBack');
    },
    showPreview() {
      this.$emit('show');
    },
    onClickAdd() {
      this.$emit('add');
    },
    openSidebar() {
      this.$emit('open');
      this.isSidebarOpen = true;
    },
    closeSidebar() {
      this.$emit('close');
      this.isSidebarOpen = false;
    },
  },
};
</script>

<style scoped lang="scss">
.header--wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-small) var(--space-normal);
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
.article--buttons {
  margin-left: var(--space-half);
}
.draft-status {
  margin-left: var(--space-half);
  margin-right: var(--space-one);
  color: var(--s-500);
  align-items: center;
  font-size: var(--font-size-mini);
}
</style>
