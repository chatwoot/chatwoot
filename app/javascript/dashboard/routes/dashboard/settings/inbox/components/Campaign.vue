<template>
  <div class="column content-box">
    <div class="row button-wrapper">
      <woot-button @click="openAddPopup">
        <i class="icon ion-android-add-circle"></i>
        {{ $t('CAMPAIGN.HEADER_BTN_TXT') }}
      </woot-button>
    </div>
    <campaigns-table
      :campaigns="records"
      :show-empty-state="showEmptyResult"
      :is-loading="uiFlags.isFetching"
    />

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-campaign :on-close="hideAddPopup" :sender-list="selectedAgents" />
    </woot-modal>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import AddCampaign from './AddCampaign';
import CampaignsTable from './CampaignsTable';

export default {
  components: {
    AddCampaign,
    CampaignsTable,
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
    };
  },
  computed: {
    ...mapGetters({
      records: 'campaigns/getCampaigns',
      uiFlags: 'campaigns/getUIFlags',
    }),
    showEmptyResult() {
      const hasEmptyResults = this.records.length === 0;
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
