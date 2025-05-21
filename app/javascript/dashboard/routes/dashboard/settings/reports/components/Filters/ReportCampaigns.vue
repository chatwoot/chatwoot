<script>
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { mapGetters } from 'vuex';

export default {
  name: 'FilterCampaign',
  emits: ['campaignFilterSelection'],
  props: {
    selectedInbox: {
      type: Object,
      required: true,
    },
    selectedChannel: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedOption: null,
    };
  },
  computed: {
    ...mapGetters({
      getCampaigns: 'campaigns/getCampaigns',
    }),
    options() {
      const campaignTypeMap = {
        'Channel::SMS': CAMPAIGN_TYPES.ONE_OFF,
        'Channel::WebWidget': CAMPAIGN_TYPES.ONGOING,
        'Channel::Whatsapp': CAMPAIGN_TYPES.WHATSAPP,
      };
      console.log('selected channel was: ', this.selectedChannel);
      const campaigns =
        this.getCampaigns(campaignTypeMap[this.selectedChannel]) || [];
      console.log("Before filter, ", campaigns)
      return campaigns.filter(e => e.inbox_id == this.selectedInbox.id);
    },
  },
  mounted() {
    this.$store.dispatch('campaigns/get');
  },
  methods: {
    handleInput() {
      this.$emit('campaignFilterSelection', this.selectedOption);
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      :placeholder="$t('CAMPAIGN_REPORTS.FILTER_DROPDOWN_LABEL')"
      label="title"
      track-by="id"
      :options="options"
      :option-height="24"
      :show-labels="false"
      @update:model-value="handleInput"
    >
    </multiselect>
  </div>
</template>
