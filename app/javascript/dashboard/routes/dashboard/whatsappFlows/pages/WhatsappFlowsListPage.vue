<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const selectedInboxId = ref('');
const searchQuery = ref('');
const selectedStatus = ref('');
const flowToDelete = ref(null);
const flowToPublish = ref(null);
const deleteDialogRef = ref(null);
const publishDialogRef = ref(null);

const uiFlags = computed(() => store.getters['whatsappFlows/getUIFlags']);
const allFlows = computed(
  () => store.getters['whatsappFlows/getWhatsappFlows']
);

const flows = computed(() => {
  let result = allFlows.value;
  if (selectedInboxId.value) {
    result = result.filter(f => f.inbox_id === selectedInboxId.value);
  }
  if (selectedStatus.value) {
    result = result.filter(f => f.status === selectedStatus.value);
  }
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    result = result.filter(f => f.name?.toLowerCase().includes(q));
  }
  return result;
});

const hasFlows = computed(
  () => allFlows.value.length > 0 && !uiFlags.value.isFetching
);
const hasFilteredResults = computed(() => flows.value.length > 0);
const isFiltering = computed(
  () => searchQuery.value || selectedInboxId.value || selectedStatus.value
);

// Pagination
const ITEMS_PER_PAGE = 15;
const currentPage = ref(1);
const paginatedFlows = computed(() => {
  const start = (currentPage.value - 1) * ITEMS_PER_PAGE;
  return flows.value.slice(start, start + ITEMS_PER_PAGE);
});
const showPagination = computed(() => flows.value.length > ITEMS_PER_PAGE);

watch([searchQuery, selectedInboxId, selectedStatus], () => {
  currentPage.value = 1;
});

const whatsappInboxes = computed(() =>
  store.getters['inboxes/getInboxes'].filter(
    inbox => inbox.channel_type === 'Channel::Whatsapp'
  )
);
const inboxOptions = computed(() => [
  { value: '', label: t('WHATSAPP_FLOWS.LIST.ALL_INBOXES') },
  ...whatsappInboxes.value.map(i => ({ value: i.id, label: i.name })),
]);

const statusOptions = [
  { value: '', label: t('WHATSAPP_FLOWS.LIST.ALL_STATUSES') },
  { value: 'draft', label: t('WHATSAPP_FLOWS.LIST.STATUS_DRAFT') },
  { value: 'published', label: t('WHATSAPP_FLOWS.LIST.STATUS_PUBLISHED') },
  { value: 'deprecated', label: t('WHATSAPP_FLOWS.LIST.STATUS_DEPRECATED') },
  { value: 'blocked', label: t('WHATSAPP_FLOWS.LIST.STATUS_BLOCKED') },
];

onMounted(() => {
  store.dispatch('whatsappFlows/get');
  store.dispatch('inboxes/get');
});

function navigateToBuilder() {
  router.push({ name: 'whatsapp_flows_new' });
}

function editFlow(flow) {
  router.push({
    name: 'whatsapp_flows_edit',
    params: { flowId: flow.id },
  });
}

function cloneFlow(flow) {
  router.push({
    name: 'whatsapp_flows_new',
    query: { cloneFrom: flow.id },
  });
}

function confirmDelete(flow) {
  flowToDelete.value = flow;
  deleteDialogRef.value?.open();
}

function confirmPublish(flow) {
  flowToPublish.value = flow;
  publishDialogRef.value?.open();
}

async function deleteFlow() {
  try {
    await store.dispatch('whatsappFlows/delete', flowToDelete.value.id);
    useAlert(t('WHATSAPP_FLOWS.LIST.DELETE_SUCCESS'));
  } catch {
    useAlert(t('WHATSAPP_FLOWS.LIST.DELETE_ERROR'));
  } finally {
    deleteDialogRef.value?.close();
    flowToDelete.value = null;
  }
}

async function publishFlow() {
  try {
    await store.dispatch('whatsappFlows/publish', flowToPublish.value.id);
    useAlert(t('WHATSAPP_FLOWS.LIST.PUBLISH_SUCCESS'));
  } catch {
    useAlert(t('WHATSAPP_FLOWS.LIST.PUBLISH_ERROR'));
  } finally {
    publishDialogRef.value?.close();
    flowToPublish.value = null;
  }
}

function clearFilters() {
  searchQuery.value = '';
  selectedInboxId.value = '';
  selectedStatus.value = '';
  currentPage.value = 1;
}

function statusBadgeClass(status) {
  const classes = {
    draft: 'text-n-amber-11 bg-n-amber-3',
    published: 'text-n-green-11 bg-n-green-3',
    deprecated: 'text-n-slate-11 bg-n-slate-3',
    blocked: 'text-n-ruby-11 bg-n-ruby-3',
    throttled: 'text-n-amber-11 bg-n-amber-3',
  };
  return classes[status] || classes.draft;
}
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="sticky top-0 z-10 px-6">
      <div class="w-full max-w-5xl mx-auto">
        <div class="flex items-center justify-between w-full h-20 gap-2">
          <span class="text-heading-1 text-n-slate-12">
            {{ t('WHATSAPP_FLOWS.TITLE') }}
          </span>
          <Button
            :label="t('WHATSAPP_FLOWS.LIST.CREATE')"
            icon="i-lucide-plus"
            size="sm"
            @click="navigateToBuilder"
          />
        </div>
        <!-- Filter bar -->
        <div class="flex items-center gap-3 pb-4">
          <div class="flex-1 max-w-xs">
            <Input
              v-model="searchQuery"
              :placeholder="t('WHATSAPP_FLOWS.LIST.SEARCH_PLACEHOLDER')"
              custom-input-class="ltr:!pl-8 rtl:!pr-8"
              size="sm"
              type="search"
            >
              <template #prefix>
                <span
                  class="i-lucide-search size-4 absolute top-1/2 -translate-y-1/2 text-n-slate-11 ltr:left-2.5 rtl:right-2.5"
                />
              </template>
            </Input>
          </div>
          <Select
            v-model="selectedInboxId"
            :options="inboxOptions"
            class="w-48"
          />
          <Select
            v-model="selectedStatus"
            :options="statusOptions"
            class="w-40"
          />
        </div>
      </div>
    </header>

    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full max-w-5xl mx-auto py-4">
        <!-- Loading -->
        <div
          v-if="uiFlags.isFetching"
          class="flex items-center justify-center py-10 text-n-slate-11"
        >
          <Spinner />
        </div>

        <!-- Flow list -->
        <div v-else-if="hasFlows">
          <!-- No filtered results -->
          <div
            v-if="!hasFilteredResults && isFiltering"
            class="flex flex-col items-center justify-center py-16 text-center"
          >
            <span class="i-lucide-search-x size-10 text-n-slate-7 mb-3" />
            <p class="text-sm text-n-slate-11 mb-4">
              {{ t('WHATSAPP_FLOWS.LIST.NO_RESULTS') }}
            </p>
            <Button
              :label="t('WHATSAPP_FLOWS.LIST.CLEAR_FILTERS')"
              variant="ghost"
              color-scheme="secondary"
              size="sm"
              @click="clearFilters"
            />
          </div>

          <!-- Flow cards -->
          <div v-else class="space-y-3">
            <div
              v-for="flow in paginatedFlows"
              :key="flow.id"
              class="flex items-center justify-between p-4 bg-white rounded-xl border border-n-weak hover:border-n-brand-subtle transition-colors"
            >
              <div class="flex items-center gap-4 flex-1 min-w-0">
                <div
                  class="flex items-center justify-center size-10 rounded-lg bg-n-violet-2"
                >
                  <span class="i-lucide-git-branch size-5 text-n-violet-11" />
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2">
                    <h3 class="text-sm font-medium text-n-slate-12 truncate">
                      {{ flow.name }}
                    </h3>
                    <span
                      :class="statusBadgeClass(flow.status)"
                      class="px-2 py-0.5 text-xs font-medium rounded-full capitalize"
                    >
                      {{ flow.status }}
                    </span>
                  </div>
                  <p class="text-xs text-n-slate-9 mt-0.5">
                    {{ flow.flow_json?.screens?.length || 0 }}
                    {{ t('WHATSAPP_FLOWS.LIST.SCREENS') }}
                    <span v-if="flow.flow_id" class="ml-2">
                      {{ t('WHATSAPP_FLOWS.LIST.FLOW_ID_PREFIX')
                      }}{{ flow.flow_id }}
                    </span>
                  </p>
                </div>
              </div>

              <div class="flex items-center gap-1 ml-4">
                <Button
                  v-if="flow.status === 'draft'"
                  icon="i-lucide-send"
                  size="xs"
                  variant="ghost"
                  color-scheme="secondary"
                  @click="confirmPublish(flow)"
                />
                <Button
                  icon="i-lucide-copy"
                  size="xs"
                  variant="ghost"
                  color-scheme="secondary"
                  @click="cloneFlow(flow)"
                />
                <Button
                  icon="i-lucide-pencil"
                  size="xs"
                  variant="ghost"
                  color-scheme="secondary"
                  @click="editFlow(flow)"
                />
                <Button
                  icon="i-lucide-trash-2"
                  size="xs"
                  variant="ghost"
                  color-scheme="alert"
                  @click="confirmDelete(flow)"
                />
              </div>
            </div>
          </div>
          <footer v-if="showPagination" class="sticky bottom-0 z-0 mt-2">
            <PaginationFooter
              :current-page="currentPage"
              :total-items="flows.length"
              :items-per-page="ITEMS_PER_PAGE"
              @update:current-page="currentPage = $event"
            />
          </footer>
        </div>

        <!-- Empty state (no flows at all) -->
        <div
          v-else
          class="flex flex-col items-center justify-center py-20 text-center"
        >
          <div
            class="flex items-center justify-center w-16 h-16 rounded-full bg-n-alpha-black2 mb-4"
          >
            <span class="i-lucide-git-branch text-3xl text-n-slate-9" />
          </div>
          <h3 class="text-lg font-semibold text-n-slate-12 mb-2">
            {{ t('WHATSAPP_FLOWS.LIST.EMPTY_TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11 mb-6 max-w-md">
            {{ t('WHATSAPP_FLOWS.LIST.EMPTY') }}
          </p>
          <Button
            :label="t('WHATSAPP_FLOWS.LIST.CREATE_FIRST')"
            icon="i-lucide-plus"
            @click="navigateToBuilder"
          />
        </div>
      </div>
    </main>

    <!-- Delete confirmation dialog -->
    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('WHATSAPP_FLOWS.LIST.DELETE_CONFIRM_TITLE')"
      :description="t('WHATSAPP_FLOWS.LIST.DELETE_CONFIRM_DESC')"
      :confirm-button-label="t('WHATSAPP_FLOWS.LIST.DELETE')"
      :cancel-button-label="t('WHATSAPP_FLOWS.LIST.CANCEL')"
      @confirm="deleteFlow"
    />

    <!-- Publish confirmation dialog -->
    <Dialog
      ref="publishDialogRef"
      type="alert"
      :title="t('WHATSAPP_FLOWS.LIST.PUBLISH_CONFIRM_TITLE')"
      :description="t('WHATSAPP_FLOWS.LIST.PUBLISH_CONFIRM_DESC')"
      :confirm-button-label="t('WHATSAPP_FLOWS.LIST.PUBLISH')"
      :cancel-button-label="t('WHATSAPP_FLOWS.LIST.CANCEL')"
      @confirm="publishFlow"
    />
  </section>
</template>
