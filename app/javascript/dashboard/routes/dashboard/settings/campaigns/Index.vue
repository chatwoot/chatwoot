<script>
import campaignMixin from 'shared/mixins/campaignMixin';
import Campaign from './Campaign.vue';
import AddCampaign from './AddCampaign.vue';
import AddWhatsappCampaign from './AddWhatsappCampaign.vue'; // New import

export default {
  components: {
    Campaign,
    AddCampaign,
    AddWhatsappCampaign,
  },
  mixins: [campaignMixin],
  data() {
    return { showAddPopup: false };
  },
  computed: {
    buttonText() {
      if (this.isOngoingType) {
        return this.$t('CAMPAIGN.HEADER_BTN_TXT.ONGOING');
      }
      if (this.isWhatsappType) {
        return this.$t('CAMPAIGN.HEADER_BTN_TXT.WHATSAPP');
      }
      return this.$t('CAMPAIGN.HEADER_BTN_TXT.ONE_OFF');
    },
    campaignFormComponent() {
      return this.isWhatsappType ? 'AddWhatsappCampaign' : 'AddCampaign';
    },
    isWhatsappType() {
      // Logic to determine if it's a WhatsApp campaign type
      return this.campaignType === 'whatsapp';
    },
    refresh() {
      return this.$t('CAMPAIGN.HEADER_BTN_TXT.REFRESH');
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
    reloadPage() {
      window.location.reload();
    },
  },
};
</script>

<template>
  <div class="flex-1 p-4 overflow-auto">
    <div class="flex items-center space-x-2">
      <!-- Reload button to the left of add campaign button -->
      <woot-button
        v-if="isWhatsappType"
        color-scheme="secondary"
        class-names="button--fixed-left"
        icon="repeat"
        @click="reloadPage"
      >
        {{ refresh }}
      </woot-button>

      <!-- Add campaign button -->
      <woot-button
        color-scheme="success"
        class-names="button--fixed-top"
        icon="add-circle"
        @click="openAddPopup"
      >
        {{ buttonText }}
      </woot-button>
    </div>

    <Campaign />

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <component :is="campaignFormComponent" @onClose="hideAddPopup" />
    </woot-modal>
  </div>
</template>

<style>
.button--fixed-left {
  @apply fixed ltr:right-[17rem] rtl:left-[17rem] top-2 flex flex-row;
}
</style>
