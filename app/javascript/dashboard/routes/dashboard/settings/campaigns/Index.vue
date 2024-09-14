<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="button--fixed-top flex flex-row items-center gap-2">
      <woot-button
        v-if="isOneOffType || isFlexibleType"
        icon="add-circle"
        @click="openAddPlan"
      >
        {{ $t('CAMPAIGN.HEADER_BTN_TXT.CREATE_PLAN') }}
      </woot-button>
      <woot-button
        color-scheme="success"
        icon="add-circle"
        @click="openAddCampaign"
      >
        {{ $t('CAMPAIGN.HEADER_BTN_TXT.CREATE_CAMPAIGN') }}
      </woot-button>
      <woot-button
        v-if="isOneOffType || isFlexibleType"
        icon="add-circle"
        @click="openAddZnsCampaign"
      >
        {{ $t('CAMPAIGN.HEADER_BTN_TXT.CREATE_ZNS_CAMPAIGN') }}
      </woot-button>
    </div>
    <campaign />
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-campaign
        :planned-default="planned"
        :is-zns-default="isZns"
        @on-close="hideAddPopup"
      />
    </woot-modal>
  </div>
</template>

<script>
import campaignMixin from 'shared/mixins/campaignMixin';
import Campaign from './Campaign.vue';
import AddCampaign from './UpdateCampaign.vue';

export default {
  components: {
    Campaign,
    AddCampaign,
  },
  mixins: [campaignMixin],
  data() {
    return {
      showAddPopup: false,
      planned: true,
      isZns: false,
    };
  },
  mounted() {
    this.$store.dispatch('campaigns/get');
  },
  methods: {
    openAddPlan() {
      this.planned = true;
      this.isZns = false;
      this.showAddPopup = true;
    },
    openAddCampaign() {
      this.planned = false;
      this.isZns = false;
      this.showAddPopup = true;
    },
    openAddZnsCampaign() {
      this.planned = false;
      this.isZns = true;
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
  },
};
</script>
