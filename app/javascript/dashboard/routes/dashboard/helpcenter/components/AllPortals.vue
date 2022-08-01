<template>
  <div>
    <div class="header-wrap">
      <h1 class="page-title">{{ $t('HELP_CENTER.PORTAL.HEADER') }}</h1>
      <woot-button color-scheme="primary" size="small" @click="createPortal">
        {{ $t('HELP_CENTER.PORTAL.NEW_BUTTON') }}
      </woot-button>
    </div>
    <div class="portal-container">
      <portal-list-item
        :portals="portals"
        status="published"
        selected-locale-code="en-US"
      />
    </div>
  </div>
</template>

<script>
import PortalListItem from './PortalListItem.vue';
export default {
  components: {
    PortalListItem,
  },
  props: {
    portals: {
      type: Array,
      default: () => [],
    },
  },
  methods: {
    createPortal() {
      this.$emit('create-portal');
    },
  },
};
</script>

<style lang="scss" scoped>
.header-wrap {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 0 0 var(--space-small) 0;
  height: var(--space-larger);
}
.portal-container {
  height: 90vh;
  overflow-y: scroll;
}
</style>
