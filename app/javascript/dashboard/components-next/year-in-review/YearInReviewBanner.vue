<script setup>
import { ref, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useStoreGetters } from 'dashboard/composables/store';
import YearInReviewModal from './YearInReviewModal.vue';

const yearInReviewBannerImage =
  '/assets/images/dashboard/year-in-review/year-in-review-sidebar.png';
const route = useRoute();
const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();
const getters = useStoreGetters();
const showModal = ref(false);
const modalRef = ref(null);

const currentYear = new Date().getFullYear();

const isACustomBrandedInstance =
  getters['globalConfig/isACustomBrandedInstance'];

const bannerClosedKey = computed(() => {
  const accountId = getters.getCurrentAccountId.value;
  return `yir_closed_${accountId}_${currentYear}`;
});

const isBannerClosed = computed(() => {
  return uiSettings.value?.[bannerClosedKey.value] === true;
});

const shouldShowBanner = computed(
  () =>
    route.query['year-in-review'] === 'true' &&
    !isBannerClosed.value &&
    !isACustomBrandedInstance.value
);

const openModal = () => {
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
};

const closeBanner = event => {
  event.stopPropagation();
  updateUISettings({ [bannerClosedKey.value]: true });
};
</script>

<template>
  <div v-if="shouldShowBanner" class="relative">
    <div
      class="mx-2 my-1 p-3 bg-n-iris-9 rounded-lg cursor-pointer hover:shadow-md transition-all"
      @click="openModal"
    >
      <div class="flex items-start justify-between gap-2 mb-3">
        <span
          class="text-sm font-semibold text-white leading-tight tracking-tight flex-1"
        >
          {{ t('YEAR_IN_REVIEW.BANNER.TITLE', { year: currentYear }) }}
        </span>
        <button
          class="flex-shrink-0 w-5 h-5 flex items-center justify-center rounded hover:bg-white hover:bg-opacity-20 transition-colors"
          @click="closeBanner"
        >
          <i class="i-lucide-x w-4 h-4 text-white" />
        </button>
      </div>

      <div class="flex flex-col gap-3">
        <img
          :src="yearInReviewBannerImage"
          alt="Year in Review"
          class="w-full h-auto rounded"
        />
        <button
          class="w-full px-3 py-2 bg-white text-n-iris-9 text-xs font-medium rounded-mdtracking-tight"
          @click.stop="openModal"
        >
          {{ t('YEAR_IN_REVIEW.BANNER.BUTTON') }}
        </button>
      </div>
    </div>

    <YearInReviewModal ref="modalRef" :show="showModal" @close="closeModal" />
  </div>
</template>
