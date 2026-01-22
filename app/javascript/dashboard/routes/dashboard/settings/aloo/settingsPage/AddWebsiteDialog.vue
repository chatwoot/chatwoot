<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const emit = defineEmits(['submit']);

const MAX_SELECTED_PAGES = 50;

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const currentStep = ref(1);
const websiteUrl = ref('');
const customTitle = ref('');
const autoRefresh = ref(false);
const isDiscovering = ref(false);
const isSubmitting = ref(false);
const discoveryError = ref('');

const discoveredPages = ref([]);
const selectedPageUrls = ref(new Set());

// Computed properties
const isValidUrl = computed(() => {
  if (!websiteUrl.value) return false;
  try {
    const url = new URL(
      websiteUrl.value.startsWith('http')
        ? websiteUrl.value
        : `https://${websiteUrl.value}`
    );
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch {
    return false;
  }
});

const selectedCount = computed(() => selectedPageUrls.value.size);
const canProceedToStep2 = computed(
  () => isValidUrl.value && !isDiscovering.value
);
const canProceedToStep3 = computed(() => selectedCount.value > 0);
const canSubmit = computed(
  () => selectedCount.value > 0 && selectedCount.value <= MAX_SELECTED_PAGES
);

const stepTitle = computed(() => {
  const titles = {
    1: t('ALOO.KNOWLEDGE.WEBSITE.STEP_1_TITLE'),
    2: t('ALOO.KNOWLEDGE.WEBSITE.STEP_2_TITLE'),
    3: t('ALOO.KNOWLEDGE.WEBSITE.STEP_3_TITLE'),
  };
  return titles[currentStep.value];
});

const stepDescription = computed(() => {
  const descriptions = {
    1: t('ALOO.KNOWLEDGE.WEBSITE.STEP_1_DESCRIPTION'),
    2: t('ALOO.KNOWLEDGE.WEBSITE.STEP_2_DESCRIPTION'),
    3: t('ALOO.KNOWLEDGE.WEBSITE.STEP_3_DESCRIPTION'),
  };
  return descriptions[currentStep.value];
});

// Methods
const open = () => {
  currentStep.value = 1;
  websiteUrl.value = '';
  customTitle.value = '';
  autoRefresh.value = false;
  isDiscovering.value = false;
  isSubmitting.value = false;
  discoveryError.value = '';
  discoveredPages.value = [];
  selectedPageUrls.value = new Set();
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const discoverPages = async () => {
  if (!isValidUrl.value) return;

  isDiscovering.value = true;
  discoveryError.value = '';

  try {
    const url = websiteUrl.value.startsWith('http')
      ? websiteUrl.value
      : `https://${websiteUrl.value}`;

    const result = await store.dispatch('alooDocuments/discoverPages', {
      assistantId: props.assistantId,
      url,
    });

    discoveredPages.value = result.pages || [];

    if (discoveredPages.value.length === 0) {
      discoveryError.value = t('ALOO.KNOWLEDGE.WEBSITE.NO_PAGES_FOUND');
      return;
    }

    // Pre-select important pages
    selectedPageUrls.value = new Set(
      discoveredPages.value.filter(p => p.important).map(p => p.url)
    );

    // Ensure at least some pages are selected
    if (selectedPageUrls.value.size === 0 && discoveredPages.value.length > 0) {
      selectedPageUrls.value.add(discoveredPages.value[0].url);
    }

    currentStep.value = 2;
  } catch (error) {
    discoveryError.value =
      error?.response?.data?.message || t('ALOO.MESSAGES.ERROR');
  } finally {
    isDiscovering.value = false;
  }
};

const togglePage = url => {
  if (selectedPageUrls.value.has(url)) {
    selectedPageUrls.value.delete(url);
  } else if (selectedPageUrls.value.size < MAX_SELECTED_PAGES) {
    selectedPageUrls.value.add(url);
  }
  // Force reactivity update
  selectedPageUrls.value = new Set(selectedPageUrls.value);
};

const selectAll = () => {
  selectedPageUrls.value = new Set(
    discoveredPages.value.slice(0, MAX_SELECTED_PAGES).map(p => p.url)
  );
};

const deselectAll = () => {
  selectedPageUrls.value = new Set();
};

const goBack = () => {
  if (currentStep.value > 1) {
    currentStep.value -= 1;
  }
};

const goNext = () => {
  if (currentStep.value === 1 && canProceedToStep2.value) {
    discoverPages();
  } else if (currentStep.value === 2 && canProceedToStep3.value) {
    currentStep.value = 3;
  }
};

const handleSubmit = async () => {
  if (!canSubmit.value || isSubmitting.value) return;

  isSubmitting.value = true;
  try {
    const url = websiteUrl.value.startsWith('http')
      ? websiteUrl.value
      : `https://${websiteUrl.value}`;

    await emit('submit', {
      url,
      title: customTitle.value.trim() || undefined,
      selectedPages: Array.from(selectedPageUrls.value),
      autoRefresh: autoRefresh.value,
    });
    close();
  } finally {
    isSubmitting.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('ALOO.KNOWLEDGE.WEBSITE.MODAL_TITLE')"
    :show-confirm-button="false"
    :show-cancel-button="false"
    width="2xl"
    overflow-y-auto
  >
    <!-- Step Header -->
    <div class="mb-6">
      <!-- Step Indicator -->
      <div class="flex items-center gap-2 mb-4">
        <template v-for="step in 3" :key="step">
          <div
            class="flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium"
            :class="
              currentStep >= step
                ? 'bg-n-blue-9 text-white'
                : 'bg-n-alpha-2 text-n-slate-10'
            "
          >
            {{ step }}
          </div>
          <div
            v-if="step < 3"
            class="flex-1 h-0.5"
            :class="currentStep > step ? 'bg-n-blue-9' : 'bg-n-alpha-3'"
          />
        </template>
      </div>
      <h3 class="text-base font-medium text-n-slate-12">{{ stepTitle }}</h3>
      <p class="text-sm text-n-slate-10 mt-1">{{ stepDescription }}</p>
    </div>

    <!-- Step 1: Enter URL -->
    <div v-if="currentStep === 1" class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
          {{ $t('ALOO.KNOWLEDGE.WEBSITE.URL_LABEL') }}
        </label>
        <input
          v-model="websiteUrl"
          type="url"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 text-sm focus:outline-none focus:ring-2 focus:ring-n-blue-7 focus:border-transparent"
          :placeholder="$t('ALOO.KNOWLEDGE.WEBSITE.URL_PLACEHOLDER')"
          @keyup.enter="discoverPages"
        />
        <p v-if="discoveryError" class="mt-2 text-sm text-n-ruby-11">
          {{ discoveryError }}
        </p>
      </div>
    </div>

    <!-- Step 2: Select Pages -->
    <div v-if="currentStep === 2" class="space-y-4">
      <!-- Selection Controls -->
      <div class="flex items-center justify-between">
        <span class="text-sm text-n-slate-11">
          {{
            $t('ALOO.KNOWLEDGE.WEBSITE.PAGES_SELECTED', {
              count: selectedCount,
              total: discoveredPages.length,
            })
          }}
        </span>
        <div class="flex gap-2">
          <Button xs faded @click="selectAll">
            {{ $t('ALOO.KNOWLEDGE.WEBSITE.SELECT_ALL') }}
          </Button>
          <Button xs faded @click="deselectAll">
            {{ $t('ALOO.KNOWLEDGE.WEBSITE.DESELECT_ALL') }}
          </Button>
        </div>
      </div>

      <!-- Max Pages Warning -->
      <div
        v-if="selectedCount >= MAX_SELECTED_PAGES"
        class="flex items-center gap-2 p-3 rounded-lg bg-n-amber-2 text-n-amber-11"
      >
        <span class="i-lucide-alert-triangle text-lg" />
        <span class="text-sm">
          {{ $t('ALOO.KNOWLEDGE.WEBSITE.MAX_PAGES_WARNING') }}
        </span>
      </div>

      <!-- Page List -->
      <div
        class="max-h-80 overflow-y-auto border border-n-weak rounded-lg divide-y divide-n-weak"
      >
        <label
          v-for="page in discoveredPages"
          :key="page.url"
          class="flex items-start gap-3 p-3 cursor-pointer hover:bg-n-alpha-1 transition-colors"
          :class="{ 'bg-n-blue-2': selectedPageUrls.has(page.url) }"
        >
          <input
            type="checkbox"
            :checked="selectedPageUrls.has(page.url)"
            :disabled="
              !selectedPageUrls.has(page.url) &&
              selectedCount >= MAX_SELECTED_PAGES
            "
            class="mt-0.5 rounded border-n-weak text-n-blue-9 focus:ring-n-blue-7"
            @change="togglePage(page.url)"
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-n-slate-12 truncate">
                {{ page.title }}
              </span>
              <span
                v-if="page.important"
                class="px-1.5 py-0.5 text-xs font-medium rounded bg-n-blue-3 text-n-blue-11"
              >
                {{ $t('ALOO.KNOWLEDGE.WEBSITE.IMPORTANT') }}
              </span>
            </div>
            <p class="text-xs text-n-slate-10 truncate mt-0.5">
              {{ page.url }}
            </p>
          </div>
        </label>
      </div>
    </div>

    <!-- Step 3: Configure Options -->
    <div v-if="currentStep === 3" class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
          {{ $t('ALOO.KNOWLEDGE.WEBSITE.TITLE_LABEL') }}
        </label>
        <input
          v-model="customTitle"
          type="text"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 text-sm focus:outline-none focus:ring-2 focus:ring-n-blue-7 focus:border-transparent"
          :placeholder="$t('ALOO.KNOWLEDGE.WEBSITE.TITLE_PLACEHOLDER')"
        />
      </div>

      <div class="p-4 rounded-lg bg-n-alpha-1 border border-n-weak">
        <label class="flex items-start gap-3 cursor-pointer">
          <input
            v-model="autoRefresh"
            type="checkbox"
            class="mt-0.5 rounded border-n-weak text-n-blue-9 focus:ring-n-blue-7"
          />
          <div>
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('ALOO.KNOWLEDGE.WEBSITE.AUTO_REFRESH') }}
            </span>
            <p class="text-xs text-n-slate-10 mt-0.5">
              {{ $t('ALOO.KNOWLEDGE.WEBSITE.AUTO_REFRESH_DESC') }}
            </p>
          </div>
        </label>
      </div>

      <!-- Summary -->
      <div class="p-4 rounded-lg bg-n-alpha-2 border border-n-weak">
        <h4 class="text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('ALOO.KNOWLEDGE.WEBSITE.SUMMARY') }}
        </h4>
        <ul class="space-y-1 text-sm text-n-slate-11">
          <li class="flex items-center gap-2">
            <span class="i-lucide-globe text-n-slate-9" />
            <span class="truncate">{{ websiteUrl }}</span>
          </li>
          <li class="flex items-center gap-2">
            <span class="i-lucide-files text-n-slate-9" />
            <span>
              {{
                $t('ALOO.KNOWLEDGE.WEBSITE.PAGES_TO_SCRAPE', {
                  count: selectedCount,
                })
              }}
            </span>
          </li>
          <li v-if="autoRefresh" class="flex items-center gap-2">
            <span class="i-lucide-refresh-cw text-n-slate-9" />
            <span>{{ $t('ALOO.KNOWLEDGE.WEBSITE.WEEKLY_REFRESH') }}</span>
          </li>
        </ul>
      </div>
    </div>

    <!-- Footer Actions -->
    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          v-if="currentStep > 1"
          variant="faded"
          color="slate"
          :label="$t('ALOO.KNOWLEDGE.WEBSITE.BACK')"
          @click="goBack"
        />
        <div v-else />

        <div class="flex gap-2">
          <Button
            variant="faded"
            color="slate"
            :label="$t('ALOO.ACTIONS.CANCEL')"
            @click="close"
          />
          <Button
            v-if="currentStep < 3"
            color="blue"
            :label="
              currentStep === 1
                ? $t('ALOO.KNOWLEDGE.WEBSITE.DISCOVER_PAGES')
                : $t('ALOO.KNOWLEDGE.WEBSITE.NEXT')
            "
            :is-loading="isDiscovering"
            :disabled="
              currentStep === 1 ? !canProceedToStep2 : !canProceedToStep3
            "
            @click="goNext"
          />
          <Button
            v-else
            color="blue"
            :label="$t('ALOO.KNOWLEDGE.WEBSITE.ADD')"
            :is-loading="isSubmitting"
            :disabled="!canSubmit"
            @click="handleSubmit"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>
