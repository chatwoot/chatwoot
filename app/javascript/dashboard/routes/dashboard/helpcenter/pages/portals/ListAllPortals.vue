<template>
  <div class="container">
    <div class="header-wrap">
      <div class="header-left-wrap">
        <woot-sidemenu-icon />
        <h1 class="page-title">{{ $t('HELP_CENTER.PORTAL.HEADER') }}</h1>
      </div>
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
        @add-locale="addLocale"
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
    <woot-modal
      :show.sync="isAddLocaleModalOpen"
      :on-close="closeAddLocaleModal"
    >
      <add-locale
        :show="isAddLocaleModalOpen"
        :portal="selectedPortal"
        @cancel="closeAddLocaleModal"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import PortalListItem from '../../components/PortalListItem';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState';
import AddLocale from '../../components/AddLocale';
export default {
  components: {
    PortalListItem,
    EmptyState,
    Spinner,
    AddLocale,
  },
  mixins: [alertMixin],
  data() {
    return {
      isAddLocaleModalOpen: false,
      selectedPortal: {},
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
      this.$router.push({ name: 'new_portal_information' });
    },
    closeAddLocaleModal() {
      this.isAddLocaleModalOpen = false;
      this.selectedPortal = {};
    },
    addLocale(portalId) {
      this.isAddLocaleModalOpen = true;
      this.selectedPortal = this.portals.find(portal => portal.id === portalId);
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

    .header-left-wrap {
      display: flex;
      align-items: center;
      .page-title {
        margin-bottom: 0;
      }
    }
  }
  .portal-container {
    height: 90vh;
    overflow-y: scroll;
  }
}
</style>
