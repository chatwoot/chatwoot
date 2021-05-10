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
      :on-edit-click="openEditPopup"
    />

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-campaign :on-close="hideAddPopup" :sender-list="selectedAgents" />
    </woot-modal>
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-campaign
        :on-close="hideEditPopup"
        :selected-campaign="selectedCampaign"
        :sender-list="selectedAgents"
      />
    </woot-modal>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import AddCampaign from './AddCampaign';
import CampaignsTable from './CampaignsTable';
import EditCampaign from './EditCampaign';

export default {
  components: {
    AddCampaign,
    CampaignsTable,
    EditCampaign,
  },
  props: {
    selectedAgents: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      campaigns: [],
      showAddPopup: false,
      showEditPopup: false,
      selectedCampaign: {},
    };
  },
  computed: {
    ...mapGetters({
      records: 'campaigns/getCampaigns',
      uiFlags: 'campaigns/getUIFlags',
    }),
    showEmptyResult() {
      const hasEmptyResults =
        !this.uiFlags.isFetching && this.records.length === 0;
      return hasEmptyResults;
    },
  },
  mounted() {
    this.$store.dispatch('campaigns/get');
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
  },
};
</script>

<style scoped lang="scss">
.button-wrapper {
  display: flex;
  justify-content: flex-end;
  padding-bottom: var(--space-one);
}
</style>
