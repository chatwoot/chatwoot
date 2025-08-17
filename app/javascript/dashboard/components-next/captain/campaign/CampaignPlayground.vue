<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';

const props = defineProps({
  campaignId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const allCampaigns = computed(() => store.getters['campaigns/getAllCampaigns']);

const campaign = computed(() =>
  allCampaigns.value.find(c => c.id === Number(props.campaignId))
);
const previewData = ref({
  title: '',
  message: '',
  template: '',
  audience: '',
  campaignType: '',
});

const updatePreview = () => {
  if (campaign.value) {
    previewData.value = {
      title: campaign.value.title || '',
      message: campaign.value.message || '',
      template: campaign.value.template || '',
      audience: campaign.value.audience || '',
      campaignType: campaign.value.campaign_type || '',
    };
  }
};

watch(
  () => campaign.value,
  () => updatePreview(),
  { immediate: true, deep: true }
);
</script>

<template>
  <div class="p-4 h-full bg-white rounded-lg border">
    <h3 class="mb-4 text-lg font-semibold">
      {{ t('CAMPAIGN.PLAYGROUND.TITLE') }}
    </h3>

    <div class="space-y-4">
      <!-- Campaign Title Preview -->
      <div class="p-4 bg-gray-50 rounded-lg border">
        <h4 class="mb-2 text-sm font-medium text-gray-700">
          {{ t('CAMPAIGN.PLAYGROUND.CAMPAIGN_TITLE') }}
        </h4>
        <p class="text-sm text-gray-900">
          {{ previewData.title || t('CAMPAIGN.PLAYGROUND.NO_TITLE') }}
        </p>
      </div>

      <!-- Message Preview -->
      <div class="p-4 bg-gray-50 rounded-lg border">
        <h4 class="mb-2 text-sm font-medium text-gray-700">
          {{ t('CAMPAIGN.PLAYGROUND.MESSAGE_PREVIEW') }}
        </h4>
        <div
          class="text-sm text-gray-900 whitespace-pre-wrap"
          v-html="previewData.message || t('CAMPAIGN.PLAYGROUND.NO_MESSAGE')"
        />
      </div>

      <!-- Template Info -->
      <div v-if="previewData.template" class="p-4 bg-blue-50 rounded-lg border">
        <h4 class="mb-2 text-sm font-medium text-blue-700">
          {{ t('CAMPAIGN.PLAYGROUND.TEMPLATE') }}
        </h4>
        <p class="text-sm text-blue-900">
          {{ previewData.template }}
        </p>
      </div>

      <!-- Audience Info -->
      <div
        v-if="previewData.audience"
        class="p-4 bg-green-50 rounded-lg border"
      >
        <h4 class="mb-2 text-sm font-medium text-green-700">
          {{ t('CAMPAIGN.PLAYGROUND.AUDIENCE') }}
        </h4>
        <p class="text-sm text-green-900">
          {{ previewData.audience }}
        </p>
      </div>

      <!-- Campaign Type -->
      <div class="p-4 bg-yellow-50 rounded-lg border">
        <h4 class="mb-2 text-sm font-medium text-yellow-700">
          {{ t('CAMPAIGN.PLAYGROUND.CAMPAIGN_TYPE') }}
        </h4>
        <p class="text-sm text-yellow-900">
          {{ previewData.campaignType || t('CAMPAIGN.PLAYGROUND.NO_TYPE') }}
        </p>
      </div>

      <!-- Preview Note -->
      <div class="mt-4 text-xs italic text-gray-500">
        {{ t('CAMPAIGN.PLAYGROUND.PREVIEW_NOTE') }}
      </div>
    </div>
  </div>
</template>
