<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import YearInReviewAPI from 'dashboard/api/yearInReview';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useStoreGetters } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { YEAR_IN_REVIEW_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import IntroSlide from './slides/IntroSlide.vue';
import ConversationsSlide from './slides/ConversationsSlide.vue';
import BusiestDaySlide from './slides/BusiestDaySlide.vue';
import PersonalitySlide from './slides/PersonalitySlide.vue';
import ThankYouSlide from './slides/ThankYouSlide.vue';
import ShareModal from './ShareModal.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const { uiSettings } = useUISettings();
const getters = useStoreGetters();
const isOpen = ref(false);
const currentSlide = ref(0);
const yearData = ref(null);
const isLoading = ref(false);
const error = ref(null);
const slideRefs = ref([]);
const showShareModal = ref(false);
const shareModalRef = ref(null);
const drumrollAudio = ref(null);

const hasConversations = computed(() => {
  return yearData.value?.total_conversations > 0;
});

const totalSlides = computed(() => {
  if (!hasConversations.value) {
    return 3;
  }
  return 5;
});

const slideIndexMap = computed(() => {
  if (!hasConversations.value) {
    return [0, 1, 4];
  }
  return [0, 1, 2, 3, 4];
});

const currentVisualSlide = computed(() => {
  return slideIndexMap.value.indexOf(currentSlide.value);
});

const slideBackgrounds = [
  'bg-[#5BD58A]',
  'bg-[#60a5fa]',
  'bg-[#fb923c]',
  'bg-[#f87171]',
  'bg-[#fbbf24]',
];

const playDrumroll = () => {
  try {
    if (!drumrollAudio.value) {
      drumrollAudio.value = new Audio('/audio/dashboard/drumroll.mp3');
      drumrollAudio.value.volume = 0.5;
    }

    drumrollAudio.value.currentTime = 0;
    drumrollAudio.value.play().catch(err => {
      // eslint-disable-next-line no-console
      console.log('Could not play drumroll:', err);
    });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.log('Error playing drumroll:', err);
  }
};

const fetchYearInReviewData = async () => {
  const year = 2025;
  const accountId = getters.getCurrentAccountId.value;
  const cacheKey = `year_in_review_${accountId}_${year}`;

  const cachedData = uiSettings.value?.[cacheKey];

  if (cachedData) {
    yearData.value = cachedData;
    return;
  }

  isLoading.value = true;
  error.value = null;
  try {
    const response = await YearInReviewAPI.get(year);
    yearData.value = response.data;
  } catch (err) {
    error.value = err.message;
  } finally {
    isLoading.value = false;
  }
};

const nextSlide = () => {
  if (currentSlide.value < 4) {
    useTrack(YEAR_IN_REVIEW_EVENTS.NEXT_CLICKED);
    if (!hasConversations.value && currentSlide.value === 1) {
      currentSlide.value = 4;
    } else {
      currentSlide.value += 1;
    }
  }
};

const previousSlide = () => {
  if (currentSlide.value > 0) {
    if (!hasConversations.value && currentSlide.value === 4) {
      currentSlide.value = 1;
    } else {
      currentSlide.value -= 1;
    }
  }
};

const goToSlide = visualIndex => {
  currentSlide.value = slideIndexMap.value[visualIndex];
};

const close = () => {
  currentSlide.value = 0;
  isOpen.value = false;
  yearData.value = null;
  isLoading.value = false;
  error.value = null;

  emit('close');
};

const open = () => {
  useTrack(YEAR_IN_REVIEW_EVENTS.MODAL_OPENED);
  isOpen.value = true;
  fetchYearInReviewData();
  playDrumroll();
};

const currentSlideBackground = computed(
  () => slideBackgrounds[currentSlide.value]
);

const shareCurrentSlide = async () => {
  useTrack(YEAR_IN_REVIEW_EVENTS.SHARE_CLICKED);
  showShareModal.value = true;
  nextTick(() => {
    if (shareModalRef.value) {
      shareModalRef.value.handleOpen();
    }
  });
};

const closeShareModal = () => {
  showShareModal.value = false;
};

const keyboardEvents = {
  Escape: { action: close },
  ArrowLeft: { action: previousSlide },
  ArrowRight: { action: nextSlide },
};

useKeyboardEvents(keyboardEvents);

defineExpose({ open, close });

watch(
  () => props.show,
  newValue => {
    if (newValue) {
      open();
    }
  }
);
</script>

<template>
  <Teleport to="body">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-[9999] bg-black font-interDisplay"
    >
      <div class="relative w-full h-full overflow-hidden">
        <div
          v-if="isLoading"
          class="flex items-center justify-center w-full h-full bg-n-slate-2"
        >
          <div class="text-center">
            <div
              class="inline-block w-12 h-12 border-4 rounded-full border-n-slate-6 border-t-n-slate-11 animate-spin"
            />
            <p class="mt-4 text-sm text-n-slate-11">
              {{ t('YEAR_IN_REVIEW.LOADING') }}
            </p>
          </div>
        </div>

        <div
          v-else-if="error"
          class="flex items-center justify-center w-full h-full bg-n-slate-2"
        >
          <div class="text-center">
            <p class="text-lg font-semibold text-red-600">
              {{ t('YEAR_IN_REVIEW.ERROR') }}
            </p>
            <p class="mt-2 text-sm text-n-slate-11">{{ error }}</p>
            <button
              class="mt-4 px-4 py-2 rounded-full text-n-slate-12 dark:text-n-slate-1 bg-white bg-opacity-20 hover:bg-opacity-30 transition-colors"
              @click="close"
            >
              <span class="text-sm font-medium">{{
                t('YEAR_IN_REVIEW.CLOSE')
              }}</span>
            </button>
          </div>
        </div>

        <div
          v-else-if="yearData"
          class="relative w-full h-full"
          :class="currentSlideBackground"
        >
          <Transition
            enter-active-class="transition-all duration-300 ease-out"
            leave-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 translate-x-[30px]"
            leave-to-class="opacity-0 -translate-x-[30px]"
          >
            <IntroSlide
              v-if="currentSlide === 0"
              :key="0"
              :ref="el => (slideRefs[0] = el)"
              :year="yearData.year"
            />
          </Transition>

          <Transition
            enter-active-class="transition-all duration-300 ease-out"
            leave-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 translate-x-[30px]"
            leave-to-class="opacity-0 -translate-x-[30px]"
          >
            <ConversationsSlide
              v-if="currentSlide === 1"
              :key="1"
              :ref="el => (slideRefs[1] = el)"
              :total-conversations="yearData.total_conversations"
            />
          </Transition>

          <Transition
            enter-active-class="transition-all duration-300 ease-out"
            leave-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 translate-x-[30px]"
            leave-to-class="opacity-0 -translate-x-[30px]"
          >
            <BusiestDaySlide
              v-if="
                currentSlide === 2 && hasConversations && yearData.busiest_day
              "
              :key="2"
              :ref="el => (slideRefs[2] = el)"
              :busiest-day="yearData.busiest_day"
            />
          </Transition>

          <Transition
            enter-active-class="transition-all duration-300 ease-out"
            leave-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 translate-x-[30px]"
            leave-to-class="opacity-0 -translate-x-[30px]"
          >
            <PersonalitySlide
              v-if="
                currentSlide === 3 &&
                hasConversations &&
                yearData.support_personality
              "
              :key="3"
              :ref="el => (slideRefs[3] = el)"
              :support-personality="yearData.support_personality"
            />
          </Transition>

          <Transition
            enter-active-class="transition-all duration-300 ease-out"
            leave-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 translate-x-[30px]"
            leave-to-class="opacity-0 -translate-x-[30px]"
          >
            <ThankYouSlide
              v-if="currentSlide === 4"
              :key="4"
              :ref="el => (slideRefs[4] = el)"
              :year="yearData.year"
            />
          </Transition>

          <div
            class="absolute bottom-8 left-0 right-0 flex items-center justify-between px-8"
          >
            <button
              v-if="currentSlide > 0"
              class="px-4 py-2 flex items-center gap-2 rounded-full text-n-slate-12 dark:text-n-slate-1 bg-white bg-opacity-20 hover:bg-opacity-30 transition-colors"
              @click="previousSlide"
            >
              <i class="i-lucide-chevron-left w-5 h-5" />
              <span class="text-sm font-medium">
                {{ t('YEAR_IN_REVIEW.NAVIGATION.PREVIOUS') }}
              </span>
            </button>
            <div v-else class="w-20" />

            <div class="flex gap-2">
              <button
                v-for="index in totalSlides"
                :key="index"
                class="w-2 h-2 rounded-full transition-all"
                :class="
                  currentVisualSlide === index - 1
                    ? 'bg-white w-8'
                    : 'bg-white bg-opacity-50'
                "
                @click="goToSlide(index - 1)"
              />
            </div>

            <button
              class="px-4 py-2 flex items-center gap-2 rounded-full text-n-slate-12 dark:text-n-slate-1 bg-white bg-opacity-20 hover:bg-opacity-30 transition-colors"
              :class="{ invisible: currentVisualSlide === totalSlides - 1 }"
              @click="nextSlide"
            >
              <span
                v-if="currentVisualSlide < totalSlides - 1"
                class="text-sm font-medium"
              >
                {{ t('YEAR_IN_REVIEW.NAVIGATION.NEXT') }}
              </span>
              <i
                v-if="currentVisualSlide < totalSlides - 1"
                class="i-lucide-chevron-right w-5 h-5"
              />
            </button>
          </div>

          <button
            class="absolute top-4 left-4 px-4 py-2 flex items-center gap-2 rounded-full text-n-slate-12 dark:text-n-slate-1 bg-white bg-opacity-20 hover:bg-opacity-30 transition-colors"
            @click="shareCurrentSlide"
          >
            <i class="i-lucide-share-2 w-5 h-5" />
            <span class="text-sm font-medium">{{
              t('YEAR_IN_REVIEW.NAVIGATION.SHARE')
            }}</span>
          </button>

          <button
            class="absolute top-4 right-4 w-10 h-10 flex items-center justify-center rounded-full text-n-slate-12 dark:text-n-slate-1 hover:bg-white hover:bg-opacity-20 transition-colors"
            @click="close"
          >
            <i class="i-lucide-x w-6 h-6" />
          </button>
        </div>
      </div>
    </div>

    <ShareModal
      ref="shareModalRef"
      :show="showShareModal"
      :slide-element="slideRefs[currentSlide]"
      :slide-background="currentSlideBackground"
      :year="yearData?.year"
      @close="closeShareModal"
    />
  </Teleport>
</template>
