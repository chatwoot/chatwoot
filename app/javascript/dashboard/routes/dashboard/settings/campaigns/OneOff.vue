<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="ion-android-add-circle"
      @click="openAddPopup"
    >
      {{ $t('CAMPAIGN.HEADER_BTN_TXT.ONE_OFF') }}
    </woot-button>
    <campaign />
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-campaign :audience-list="labelList" @on-close="hideAddPopup" />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Campaign from './Campaign.vue';
import AddCampaign from './AddCampaign';

export default {
  components: {
    Campaign,
    AddCampaign,
  },
  data() {
    return { showAddPopup: false };
  },
  computed: {
    ...mapGetters({
      labelList: 'labels/getLabels',
    }),
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
