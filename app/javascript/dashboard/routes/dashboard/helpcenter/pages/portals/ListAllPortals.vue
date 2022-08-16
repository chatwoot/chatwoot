<template>
  <div class="container">
    <div class="header-wrap">
      <h1 class="page-title">{{ $t('HELP_CENTER.PORTAL.HEADER') }}</h1>
      <woot-button color-scheme="primary" size="small" @click="addPortal">
        {{ $t('HELP_CENTER.PORTAL.NEW_BUTTON') }}
      </woot-button>
    </div>
    <div class="portal-container">
      <portal-list-item
        v-for="portal in portals"
        :key="portal.id"
        :portal="portal"
        :status="portalStatus"
      />
      <div v-if="isFetching" class="portals--loader">
        <spinner />
        <span>{{ $t('HELP_CENTER.PORTAL.LOADING_MESSAGE') }}</span>
      </div>
      <empty-state
        v-else-if="shouldShowEmptyState"
        :title="$t('HELP_CENTER.PORTAL.NO_PORTALS_MESSAGE')"
      />
    </div>
    <woot-modal :show.sync="isAddModalOpen" :on-close="closeModal">
      <add-portal :show="isAddModalOpen" @cancel="closeModal" />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import PortalListItem from '../../components/PortalListItem';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState';
import AddPortal from '../../components/AddPortal';
export default {
  components: {
    PortalListItem,
    EmptyState,
    Spinner,
    AddPortal,
  },
  data() {
    return {
      isAddModalOpen: false,
    };
  },
  computed: {
    ...mapGetters({
      portals: 'portals/allPortals',
      meta: 'portals/getMeta',
      isFetching: 'portals/isFetchingPortals',
    }),
    portalStatus() {
      return this.archived ? 'Archived' : 'Live';
    },
    shouldShowEmptyState() {
      return !this.isFetching && !this.portals.length;
    },
  },
  methods: {
    addPortal() {
      this.isAddModalOpen = !this.isAddModalOpen;
    },
    closeModal() {
      this.isAddModalOpen = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.container {
  padding: var(--space-small) var(--space-normal);
  width: 100%;
  .portals--loader {
    align-items: center;
    display: flex;
    font-size: var(--font-size-default);
    justify-content: center;
    padding: var(--space-big);
  }
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
}
</style>
