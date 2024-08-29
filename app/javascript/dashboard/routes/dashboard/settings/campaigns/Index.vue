<script>
import { useCampaign } from 'shared/composables/useCampaign';
import Campaign from './Campaign.vue';
import AddCampaign from './AddCampaign.vue';

export default {
  components: {
    Campaign,
    AddCampaign,
  },
  setup() {
    const { isOngoingType } = useCampaign();
    return { isOngoingType };
  },
  data() {
    return { showAddPopup: false };
  },
  computed: {
    buttonText() {
      if (this.isOngoingType) {
        return this.$t('CAMPAIGN.HEADER_BTN_TXT.ONGOING');
      }
      return this.$t('CAMPAIGN.HEADER_BTN_TXT.ONE_OFF');
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

<template>
  <div class="flex-1 p-4 overflow-auto">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openAddPopup"
    >
      {{ buttonText }}
    </woot-button>
    <Campaign />
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <AddCampaign @onClose="hideAddPopup" />
    </woot-modal>
  </div>
</template>
