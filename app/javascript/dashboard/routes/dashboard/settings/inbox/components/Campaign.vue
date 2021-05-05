<template>
  <div class="column content-box">
    <div v-if="campaigns.length" class="row button-wrapper">
      <woot-button @click="openAddPopup">
        <i class="icon ion-android-add-circle"></i>
        {{ $t('CAMPAIGN.HEADER_BTN_TXT') }}
      </woot-button>
    </div>

    <div v-if="!campaigns.length" class="row">
      <div class="small-8 columns">
        <p class="no-items-error-message">
          {{ $t('CAMPAIGN.LIST.404') }}
          <a @click="openAddPopup">
            {{ $t('CAMPAIGN.HEADER_BTN_TXT') }}
          </a>
        </p>
      </div>

      <div class="small-4 columns">
        <span>
          <p>
            <b> {{ $t('CAMPAIGN.HEADER') }}</b>
          </p>
          <p v-html="$t('CAMPAIGN.SIDEBAR_TXT')" />
        </span>
      </div>
    </div>
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-campaign :on-close="hideAddPopup" />
    </woot-modal>
  </div>
</template>
<script>
import AddCampaign from './AddCampaign';
export default {
  components: {
    AddCampaign,
  },
  data() {
    return {
      campaigns: [],
      showAddPopup: false,
    };
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
}
</style>
