<script setup>
import { ref, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import YearInReviewModal from './YearInReviewModal.vue';

const yearInReviewBannerImage =
  '/assets/images/dashboard/year-in-review/year-in-review-sidebar.png';
const route = useRoute();
const { t } = useI18n();
const showModal = ref(false);
const modalRef = ref(null);
const isMinimized = ref(false);

const currentYear = new Date().getFullYear();

const shouldShowBanner = computed(
  () => route.query['year-in-review'] === 'true'
);

const openModal = () => {
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
};

const toggleMinimize = event => {
  event.stopPropagation();
  isMinimized.value = !isMinimized.value;
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
          class="text-sm font-semibold text-white leading-tight tracking-tight"
        >
          {{ t('YEAR_IN_REVIEW.BANNER.TITLE', { year: currentYear }) }}
        </span>
        <button
          class="flex-shrink-0 w-6 h-6 flex items-center justify-center text-white hover:bg-white hover:bg-opacity-20 rounded transition-colors"
          @click="toggleMinimize"
        >
          <i
            :class="
              isMinimized ? 'i-lucide-chevron-down' : 'i-lucide-chevron-up'
            "
            class="w-5 h-5"
          />
        </button>
      </div>

      <div v-if="!isMinimized" class="flex flex-col gap-3">
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
