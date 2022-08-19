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
        @delete="onClickOpenDeleteModal"
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
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="onClickDeletePortal"
      :title="$t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.TITLE')"
      :message="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
    <woot-modal :show.sync="isAddModalOpen" :on-close="closeModal">
      <add-portal :show="isAddModalOpen" @cancel="closeModal" />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
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
  mixins: [alertMixin],
  data() {
    return {
      isAddModalOpen: false,
      showDeleteConfirmationPopup: false,
      alertMessage: '',
      selectedPortalForDelete: {},
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
    // Delete portal modal
    deleteConfirmText() {
      return `${this.$t(
        'HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.YES'
      )} ${this.selectedPortalForDelete.name}`;
    },
    deleteRejectText() {
      return `${this.$t(
        'HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.NO'
      )} ${this.selectedPortalForDelete.name}`;
    },
    deleteMessage() {
      return `${this.$t(
        'HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.MESSAGE'
      )} ${this.selectedPortalForDelete.name} ?`;
    },
  },
  methods: {
    addPortal() {
      this.$router.push({ name: 'new_portal_information' });
    },
    closeModal() {
      this.isAddModalOpen = false;
    },
    onClickOpenDeleteModal(portal) {
      this.selectedPortalForDelete = portal;
      this.showDeleteConfirmationPopup = true;
    },
    async onClickDeletePortal() {
      const { id, slug } = this.selectedPortalForDelete;
      try {
        await this.$store.dispatch('portals/delete', {
          id: id,
          slug: slug,
        });
        this.selectedPortalForDelete = {};
        this.closeDeletePopup();
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.API.DELETE_SUCCESS'
        );
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t(
            'HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.API.DELETE_ERROR'
          );
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
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
