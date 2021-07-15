<template>
  <div class="column content-box">
    <div class="row button-wrapper">
      <woot-button icon="ion-android-add-circle" @click="openAddPopup">
        {{ $t('CAMPAIGN.HEADER_BTN_TXT') }}
      </woot-button>
    </div>
    <campaigns-table
      :campaigns="records"
      :show-empty-result="showEmptyResult"
      :is-loading="uiFlags.isFetching"
      :campaign-type="type"
      @on-edit-click="openEditPopup"
      @on-delete-click="openDeletePopup"
    />

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-campaign
        :sender-list="selectedAgents"
        :audience-list="labelList"
        :campaign-type="type"
        @on-close="hideAddPopup"
      />
    </woot-modal>
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-campaign
        :selected-campaign="selectedCampaign"
        :sender-list="selectedAgents"
        @on-close="hideEditPopup"
      />
    </woot-modal>
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CAMPAIGN.DELETE.CONFIRM.TITLE')"
      :message="$t('CAMPAIGN.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="$t('CAMPAIGN.DELETE.CONFIRM.YES')"
      :reject-text="$t('CAMPAIGN.DELETE.CONFIRM.NO')"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import AddCampaign from './AddCampaign';
import CampaignsTable from './CampaignsTable';
import EditCampaign from './EditCampaign';
export default {
  components: {
    AddCampaign,
    CampaignsTable,
    EditCampaign,
  },
  mixins: [alertMixin],
  props: {
    selectedAgents: {
      type: Array,
      default: () => [],
    },
    type: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      campaigns: [],
      showAddPopup: false,
      showEditPopup: false,
      selectedCampaign: {},
      showDeleteConfirmationPopup: false,
    };
  },
  computed: {
    ...mapGetters({
      records: 'campaigns/getCampaigns',
      uiFlags: 'campaigns/getUIFlags',
      labelList: 'labels/getLabels',
    }),
    showEmptyResult() {
      const hasEmptyResults =
        !this.uiFlags.isFetching && this.records.length === 0;
      return hasEmptyResults;
    },
  },
  mounted() {
    this.$store.dispatch('campaigns/get', {
      inboxId: this.$route.params.inboxId,
    });
  },
  methods: {
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openEditPopup(response) {
      const { row: campaign } = response;
      this.selectedCampaign = campaign;
      this.showEditPopup = true;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedCampaign = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.closeDeletePopup();
      const {
        row: { id },
      } = this.selectedCampaign;
      this.deleteCampaign(id);
    },
    async deleteCampaign(id) {
      try {
        await this.$store.dispatch('campaigns/delete', id);
        this.showAlert(this.$t('CAMPAIGN.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('CAMPAIGN.DELETE.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<style scoped lang="scss">
.button-wrapper {
  display: flex;
  justify-content: flex-end;
  padding-bottom: var(--space-one);
}

.content-box .page-top-bar::v-deep {
  padding: var(--space-large) var(--space-large) var(--space-zero);
}
</style>
