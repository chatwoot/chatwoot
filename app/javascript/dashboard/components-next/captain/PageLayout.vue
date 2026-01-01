<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { usePolicy } from 'dashboard/composables/usePolicy';
import Button from 'dashboard/components-next/button/Button.vue';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Policy from 'dashboard/components/policy.vue';
import AssistantSwitcher from 'dashboard/components-next/captain/pageComponents/switcher/AssistantSwitcher.vue';
import CreateAssistantDialog from 'dashboard/components-next/captain/pageComponents/assistant/CreateAssistantDialog.vue';

const props = defineProps({
  currentPage: {
    type: Number,
    default: 1,
  },
  totalCount: {
    type: Number,
    default: 100,
  },
  itemsPerPage: {
    type: Number,
    default: 25,
  },
  headerTitle: {
    type: String,
    default: '',
  },
  backUrl: {
    type: [String, Object],
    default: '',
  },
  buttonPolicy: {
    type: Array,
    default: () => [],
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  featureFlag: {
    type: String,
    default: '',
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  showKnowMore: {
    type: Boolean,
    default: true,
  },
  isEmpty: {
    type: Boolean,
    default: false,
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
  showAssistantSwitcher: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['click', 'close', 'update:currentPage']);

const { t } = useI18n();

const route = useRoute();
const { shouldShowPaywall } = usePolicy();

const showAssistantSwitcherDropdown = ref(false);
const createAssistantDialogRef = ref(null);

const assistants = useMapGetter('captainAssistants/getRecords');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');

const currentAssistantId = computed(() => route.params.assistantId);
const isFetchingAssistants = computed(() => uiFlags.value?.fetchingList);

const activeAssistantName = computed(() => {
  return (
    assistants.value?.find(
      assistant => assistant.id === Number(currentAssistantId.value)
    )?.name || t('CAPTAIN.ASSISTANT_SWITCHER.NEW_ASSISTANT')
  );
});

const showPaywall = computed(() => {
  return shouldShowPaywall(props.featureFlag);
});

const handleButtonClick = () => {
  emit('click');
};

const handlePageChange = event => {
  emit('update:currentPage', event);
};

const toggleAssistantSwitcher = () => {
  showAssistantSwitcherDropdown.value = !showAssistantSwitcherDropdown.value;
};

const handleCreateAssistant = () => {
  showAssistantSwitcherDropdown.value = false;
  createAssistantDialogRef.value.dialogRef.open();
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header class="sticky top-0 z-10 px-6">
      <div class="w-full max-w-[60rem] mx-auto">
        <div
          class="flex items-start lg:items-center justify-between w-full py-6 lg:py-0 lg:h-20 gap-4 lg:gap-2 flex-col lg:flex-row"
        >
          <div class="flex gap-3 items-center">
            <BackButton v-if="backUrl" :back-url="backUrl" />
            <div
              v-if="showAssistantSwitcher && !showPaywall"
              class="flex items-center gap-2"
            >
              <div class="flex items-center gap-2">
                <span
                  v-if="!isFetchingAssistants"
                  class="text-xl font-medium truncate text-n-slate-12"
                >
                  {{ activeAssistantName }}
                </span>
                <div class="relative group">
                  <OnClickOutside
                    @trigger="showAssistantSwitcherDropdown = false"
                  >
                    <Button
                      icon="i-lucide-chevron-down"
                      variant="ghost"
                      color="slate"
                      size="xs"
                      :disabled="isFetchingAssistants"
                      :is-loading="isFetchingAssistants"
                      class="rounded-md group-hover:bg-n-slate-3 hover:bg-n-slate-3 [&>span]:size-4"
                      @click="toggleAssistantSwitcher"
                    />

                    <AssistantSwitcher
                      v-if="showAssistantSwitcherDropdown"
                      class="absolute ltr:left-0 rtl:right-0 top-9"
                      @close="showAssistantSwitcherDropdown = false"
                      @create-assistant="handleCreateAssistant"
                    />
                  </OnClickOutside>
                </div>
              </div>
            </div>
            <div class="flex items-center gap-4">
              <div
                v-if="showAssistantSwitcher && !showPaywall && headerTitle"
                class="w-0.5 h-4 rounded-2xl bg-n-weak"
              />
              <span
                v-if="headerTitle"
                class="text-xl font-medium text-n-slate-12"
              >
                {{ headerTitle }}
              </span>
              <div
                v-if="!isEmpty && showKnowMore"
                class="flex items-center gap-2"
              >
                <div class="w-0.5 h-4 rounded-2xl bg-n-weak" />
                <slot name="knowMore" />
              </div>
            </div>
          </div>

          <div class="flex gap-2">
            <slot name="search" />
            <div
              v-if="!showPaywall && buttonLabel"
              v-on-clickaway="() => emit('close')"
              class="relative group/captain-button"
            >
              <Policy :permissions="buttonPolicy">
                <Button
                  :label="buttonLabel"
                  icon="i-lucide-plus"
                  size="sm"
                  class="group-hover/captain-button:brightness-110"
                  @click="handleButtonClick"
                />
              </Policy>
              <slot name="action" />
            </div>
          </div>
        </div>
        <slot name="subHeader" />
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full max-w-[60rem] h-full mx-auto py-4">
        <slot v-if="!showPaywall" name="controls" />
        <div
          v-if="isFetching"
          class="flex items-center justify-center py-10 text-n-slate-11"
        >
          <Spinner />
        </div>
        <div v-else-if="showPaywall">
          <slot name="paywall" />
        </div>
        <div v-else-if="isEmpty">
          <slot name="emptyState" />
        </div>
        <slot v-else name="body" />
        <slot />
      </div>
    </main>
    <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10 px-4 pb-4">
      <PaginationFooter
        :current-page="currentPage"
        :total-items="totalCount"
        :items-per-page="itemsPerPage"
        @update:current-page="handlePageChange"
      />
    </footer>
    <CreateAssistantDialog ref="createAssistantDialogRef" type="create" />
  </section>
</template>
