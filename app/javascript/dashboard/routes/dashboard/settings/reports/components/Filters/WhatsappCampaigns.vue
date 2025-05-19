<script>
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { mapGetters } from 'vuex';

export default {
  name: 'WhatsappFilterCampaign',
  emits: ['campaignFilterSelection'],
  props: {
    selectedInbox: {
      type: Object,
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
      const campaigns = this.getCampaigns(CAMPAIGN_TYPES.WHATSAPP) || [];
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
      :placeholder="$t('WHATSAPP_REPORTS.FILTER_DROPDOWN_LABEL')"
      label="name"
      track-by="id"
      :options="options"
      :option-height="24"
      :show-labels="false"
      @update:model-value="handleInput"
    >
      <template #singleLabel="props">
        <div class="flex items-center gap-2">
          <div
            :style="{ backgroundColor: props.option.color }"
            class="w-5 h-5 rounded-full"
          />
          <span class="reports-option__desc">
            <span class="my-0 text-slate-800 dark:text-slate-75">
              {{ props.option.title }}
            </span>
          </span>
        </div>
      </template>
      <template #option="props">
        <div class="flex items-center gap-2">
          <div
            :style="{ backgroundColor: props.option.color }"
            class="flex-shrink-0 w-5 h-5 border border-solid rounded-full border-slate-100 dark:border-slate-800"
          />
          <span class="reports-option__desc">
            <span class="my-0 text-slate-800 dark:text-slate-75">
              {{ props.option.title }}
            </span>
          </span>
        </div>
      </template>
    </multiselect>
  </div>
</template>
