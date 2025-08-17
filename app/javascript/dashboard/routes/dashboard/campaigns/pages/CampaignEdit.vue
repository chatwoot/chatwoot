<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import EditCampaignForm from 'dashboard/components-next/captain/pageComponents/campaign/EditCampaignForm.vue';
import CampaignPlayground from 'dashboard/components-next/captain/campaign/CampaignPlayground.vue';

const route = useRoute();
const store = useStore();
const { t } = useI18n();
const campaignId = route.params.campaignId;
const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingItem);
const allCampaigns = computed(() => store.getters['campaigns/getAllCampaigns']);
const campaign = computed(() =>
  allCampaigns.value.find(c => c.id === Number(campaignId))
);

const isCampaignAvailable = computed(() => !!campaign.value?.id);

const campaignStatus = computed(() => {
  if (!campaign.value) return '';

  // For WhatsApp campaigns, check if it's completed or scheduled
  const STATUS_COMPLETED = 'completed';

  return campaign.value.campaign_status === STATUS_COMPLETED
    ? t('CAMPAIGN.WHATSAPP.CARD.STATUS.COMPLETED')
    : t('CAMPAIGN.WHATSAPP.CARD.STATUS.SCHEDULED');
});

const statusTextColor = computed(() => {
  if (!campaign.value) return 'text-n-slate-12';

  const STATUS_COMPLETED = 'completed';
  const isActive = campaign.value.campaign_status !== STATUS_COMPLETED;

  return !isActive ? 'text-n-teal-11' : 'text-n-slate-12';
});

const handleSubmit = async updatedCampaign => {
  try {
    await store.dispatch('campaigns/update', {
      id: campaignId,
      ...updatedCampaign,
    });
    useAlert(t('CAMPAIGN.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage = error?.message || t('CAMPAIGN.EDIT.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

onMounted(() => {
  if (!isCampaignAvailable.value) {
    store.dispatch('campaigns/get');
  }
});
</script>

<template>
  <PageLayout
    :show-pagination-footer="false"
    :is-fetching="isFetching"
    :show-know-more="false"
    :back-url="{ name: 'campaigns_ongoing_index' }"
  >
    <template #headerTitle>
      <div class="flex gap-2 items-center">
        <span>{{ campaign?.title }}</span>
        <span
          class="inline-flex items-center px-2 py-0.5 h-6 text-xs font-medium rounded-md bg-n-alpha-2"
          :class="statusTextColor"
        >
          {{ campaignStatus }}
        </span>
      </div>
    </template>
    <template #body>
      <div v-if="!isCampaignAvailable">
        {{ t('CAMPAIGN.EDIT.NOT_FOUND') }}
      </div>
      <div v-else class="flex gap-4 h-full">
        <div class="flex-1 pr-4 h-full lg:overflow-auto md:h-auto">
          <EditCampaignForm
            :campaign="campaign"
            mode="edit"
            @submit="handleSubmit"
          />
        </div>
        <div class="w-[400px] hidden lg:block h-full">
          <CampaignPlayground :campaign-id="Number(campaignId)" />
        </div>
      </div>
    </template>
  </PageLayout>
</template>
