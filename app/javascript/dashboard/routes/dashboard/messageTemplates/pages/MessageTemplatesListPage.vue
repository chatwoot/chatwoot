<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter, useStoreGetters } from 'dashboard/composables/store';
import { useStore } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();

const uiFlags = useMapGetter('messageTemplates/getUIFlags');
const isFetching = computed(() => uiFlags.value.isFetching);
const isSyncing = computed(() => uiFlags.value.isSyncing);

const templates = computed(
  () => getters['messageTemplates/getMessageTemplates'].value
);

const hasTemplates = computed(
  () => templates.value.length > 0 && !isFetching.value
);

// Filters
const selectedInboxId = ref('');
const searchQuery = ref('');
const selectedStatus = ref('');
const selectedCategory = ref('');

const inboxes = computed(() => {
  const allInboxes = getters['inboxes/getInboxes'].value || [];
  return allInboxes.filter(
    inbox =>
      inbox.channel_type === 'Channel::Whatsapp' ||
      inbox.channel_type === 'Channel::TwilioSms'
  );
});
const inboxOptions = computed(() => [
  { value: '', label: t('MESSAGE_TEMPLATES.ALL_INBOXES') },
  ...inboxes.value.map(i => ({ value: i.id, label: i.name })),
]);

const statusOptions = [
  { value: '', label: t('MESSAGE_TEMPLATES.FILTERS.ALL_STATUSES') },
  { value: 'approved', label: t('MESSAGE_TEMPLATES.FILTERS.APPROVED') },
  { value: 'pending', label: t('MESSAGE_TEMPLATES.FILTERS.PENDING') },
  { value: 'rejected', label: t('MESSAGE_TEMPLATES.FILTERS.REJECTED') },
  { value: 'draft', label: t('MESSAGE_TEMPLATES.FILTERS.DRAFT') },
  { value: 'paused', label: t('MESSAGE_TEMPLATES.FILTERS.PAUSED') },
  { value: 'disabled', label: t('MESSAGE_TEMPLATES.FILTERS.DISABLED') },
];

const categoryFilterOptions = [
  { value: '', label: t('MESSAGE_TEMPLATES.FILTERS.ALL_CATEGORIES') },
  { value: 'marketing', label: t('MESSAGE_TEMPLATES.CATEGORIES.MARKETING') },
  { value: 'utility', label: t('MESSAGE_TEMPLATES.CATEGORIES.UTILITY') },
  {
    value: 'authentication',
    label: t('MESSAGE_TEMPLATES.CATEGORIES.AUTHENTICATION'),
  },
];

const filteredTemplates = computed(() => {
  let result = templates.value;
  if (selectedInboxId.value) {
    result = result.filter(
      tmpl => tmpl.inbox_id === Number(selectedInboxId.value)
    );
  }
  if (selectedStatus.value) {
    result = result.filter(tmpl => tmpl.status === selectedStatus.value);
  }
  if (selectedCategory.value) {
    result = result.filter(tmpl => tmpl.category === selectedCategory.value);
  }
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    result = result.filter(tmpl => tmpl.name?.toLowerCase().includes(q));
  }
  return result;
});

const hasFilteredResults = computed(() => filteredTemplates.value.length > 0);
const isFiltering = computed(
  () =>
    searchQuery.value ||
    selectedInboxId.value ||
    selectedStatus.value ||
    selectedCategory.value
);

// Pagination
const ITEMS_PER_PAGE = 15;
const currentPage = ref(1);
const paginatedTemplates = computed(() => {
  const start = (currentPage.value - 1) * ITEMS_PER_PAGE;
  return filteredTemplates.value.slice(start, start + ITEMS_PER_PAGE);
});
const showPagination = computed(
  () => filteredTemplates.value.length > ITEMS_PER_PAGE
);

// Reset to page 1 when filters change
watch([searchQuery, selectedInboxId, selectedStatus, selectedCategory], () => {
  currentPage.value = 1;
});

const deleteDialogRef = ref(null);
const templateToDelete = ref(null);
const previewDialogRef = ref(null);
const templateToPreview = ref(null);

const openPreview = template => {
  templateToPreview.value = template;
  previewDialogRef.value?.open();
};

const getComponent = (tmpl, type) =>
  tmpl?.content?.components?.find(c => c.type === type);

const previewHeaderText = computed(() => {
  const comp = getComponent(templateToPreview.value, 'HEADER');
  return comp?.format === 'TEXT' ? comp.text : '';
});
const previewBodyText = computed(() => {
  const comp = getComponent(templateToPreview.value, 'BODY');
  return comp?.text || '';
});
const previewFooterText = computed(() => {
  const comp = getComponent(templateToPreview.value, 'FOOTER');
  return comp?.text || '';
});
const previewButtons = computed(() => {
  const comp = getComponent(templateToPreview.value, 'BUTTONS');
  return comp?.buttons || [];
});

const confirmDelete = template => {
  templateToDelete.value = template;
  deleteDialogRef.value?.open();
};

const handleDelete = async () => {
  if (!templateToDelete.value) return;
  try {
    await store.dispatch('messageTemplates/delete', templateToDelete.value.id);
  } catch {
    // handled by store
  }
  deleteDialogRef.value?.close();
};

const handleSync = () => {
  if (!selectedInboxId.value) return;
  store.dispatch('messageTemplates/sync', selectedInboxId.value);
};

function clearFilters() {
  searchQuery.value = '';
  selectedInboxId.value = '';
  selectedStatus.value = '';
  selectedCategory.value = '';
  currentPage.value = 1;
}

const statusColor = status => {
  const colors = {
    approved: 'text-n-green-11 bg-n-green-3',
    pending: 'text-n-amber-11 bg-n-amber-3',
    rejected: 'text-n-ruby-11 bg-n-ruby-3',
    draft: 'text-n-slate-11 bg-n-slate-3',
    paused: 'text-n-amber-11 bg-n-amber-3',
    disabled: 'text-n-slate-9 bg-n-slate-3',
  };
  return colors[status] || colors.draft;
};

const categoryLabel = category => {
  const labels = {
    marketing: t('MESSAGE_TEMPLATES.CATEGORIES.MARKETING'),
    utility: t('MESSAGE_TEMPLATES.CATEGORIES.UTILITY'),
    authentication: t('MESSAGE_TEMPLATES.CATEGORIES.AUTHENTICATION'),
  };
  return labels[category] || category;
};

const goToBuilder = () => {
  router.push({ name: 'message_templates_new' });
};

const goToEdit = template => {
  router.push({
    name: 'message_templates_edit',
    params: { templateId: template.id },
  });
};

const goToClone = template => {
  router.push({
    name: 'message_templates_new',
    query: { cloneFrom: template.id },
  });
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="sticky top-0 z-10 px-6">
      <div class="w-full max-w-5xl mx-auto">
        <div class="flex items-center justify-between w-full h-20 gap-2">
          <span class="text-heading-1 text-n-slate-12">
            {{ t('MESSAGE_TEMPLATES.HEADER_TITLE') }}
          </span>
          <div class="flex items-center gap-2">
            <Button
              v-if="selectedInboxId"
              :label="t('MESSAGE_TEMPLATES.SYNC')"
              icon="i-lucide-refresh-cw"
              size="sm"
              variant="ghost"
              color-scheme="secondary"
              :is-loading="isSyncing"
              @click="handleSync"
            />
            <Button
              :label="t('MESSAGE_TEMPLATES.NEW_TEMPLATE')"
              icon="i-lucide-plus"
              size="sm"
              @click="goToBuilder"
            />
          </div>
        </div>
        <!-- Filter bar -->
        <div class="flex items-center gap-3 pb-4">
          <div class="flex-1 max-w-xs">
            <Input
              v-model="searchQuery"
              :placeholder="t('MESSAGE_TEMPLATES.FILTERS.SEARCH_PLACEHOLDER')"
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
            class="w-36"
          />
          <Select
            v-model="selectedCategory"
            :options="categoryFilterOptions"
            class="w-40"
          />
        </div>
      </div>
    </header>

    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full max-w-5xl mx-auto py-4">
        <div
          v-if="isFetching"
          class="flex items-center justify-center py-10 text-n-slate-11"
        >
          <Spinner />
        </div>

        <!-- Template list table -->
        <div v-else-if="hasTemplates">
          <!-- No filtered results -->
          <div
            v-if="!hasFilteredResults && isFiltering"
            class="flex flex-col items-center justify-center py-16 text-center"
          >
            <span class="i-lucide-search-x size-10 text-n-slate-7 mb-3" />
            <p class="text-sm text-n-slate-11 mb-4">
              {{ t('MESSAGE_TEMPLATES.FILTERS.NO_RESULTS') }}
            </p>
            <Button
              :label="t('MESSAGE_TEMPLATES.FILTERS.CLEAR_FILTERS')"
              variant="ghost"
              color-scheme="secondary"
              size="sm"
              @click="clearFilters"
            />
          </div>

          <table v-else class="w-full">
            <thead>
              <tr
                class="text-left text-xs text-n-slate-11 border-b border-n-strong"
              >
                <th class="pb-3 font-medium">
                  {{ t('MESSAGE_TEMPLATES.TABLE.NAME') }}
                </th>
                <th class="pb-3 font-medium">
                  {{ t('MESSAGE_TEMPLATES.TABLE.CATEGORY') }}
                </th>
                <th class="pb-3 font-medium">
                  {{ t('MESSAGE_TEMPLATES.TABLE.LANGUAGE') }}
                </th>
                <th class="pb-3 font-medium">
                  {{ t('MESSAGE_TEMPLATES.TABLE.STATUS') }}
                </th>
                <th class="pb-3 font-medium text-right">
                  {{ t('MESSAGE_TEMPLATES.TABLE.ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="template in paginatedTemplates"
                :key="template.id"
                class="border-b border-n-weak hover:bg-n-alpha-black2 transition-colors"
              >
                <td class="py-3">
                  <span class="text-sm font-medium text-n-slate-12">
                    {{ template.name }}
                  </span>
                </td>
                <td class="py-3">
                  <span class="text-sm text-n-slate-11">
                    {{ categoryLabel(template.category) }}
                  </span>
                </td>
                <td class="py-3">
                  <span
                    class="text-xs px-2 py-0.5 rounded bg-n-alpha-black2 text-n-slate-11"
                  >
                    {{ template.language }}
                  </span>
                </td>
                <td class="py-3">
                  <span
                    class="text-xs font-medium px-2 py-0.5 rounded capitalize"
                    :class="statusColor(template.status)"
                  >
                    {{ template.status }}
                  </span>
                </td>
                <td class="py-3 text-right">
                  <div class="flex items-center justify-end gap-1">
                    <Button
                      icon="i-lucide-eye"
                      size="xs"
                      variant="ghost"
                      color-scheme="secondary"
                      @click="openPreview(template)"
                    />
                    <Button
                      icon="i-lucide-copy"
                      size="xs"
                      variant="ghost"
                      color-scheme="secondary"
                      @click="goToClone(template)"
                    />
                    <Button
                      icon="i-lucide-pencil"
                      size="xs"
                      variant="ghost"
                      color-scheme="secondary"
                      @click="goToEdit(template)"
                    />
                    <Button
                      icon="i-lucide-trash-2"
                      size="xs"
                      variant="ghost"
                      color-scheme="alert"
                      @click="confirmDelete(template)"
                    />
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
          <footer v-if="showPagination" class="sticky bottom-0 z-0 mt-2">
            <PaginationFooter
              :current-page="currentPage"
              :total-items="filteredTemplates.length"
              :items-per-page="ITEMS_PER_PAGE"
              @update:current-page="currentPage = $event"
            />
          </footer>
        </div>

        <!-- Empty state -->
        <div
          v-else
          class="flex flex-col items-center justify-center py-20 text-center"
        >
          <div
            class="flex items-center justify-center w-16 h-16 rounded-full bg-n-alpha-black2 mb-4"
          >
            <span class="i-lucide-file-text text-3xl text-n-slate-9" />
          </div>
          <h3 class="text-lg font-semibold text-n-slate-12 mb-2">
            {{ t('MESSAGE_TEMPLATES.EMPTY_STATE.TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11 mb-6 max-w-md">
            {{ t('MESSAGE_TEMPLATES.EMPTY_STATE.SUBTITLE') }}
          </p>
          <Button
            :label="t('MESSAGE_TEMPLATES.NEW_TEMPLATE')"
            icon="i-lucide-plus"
            @click="goToBuilder"
          />
        </div>
      </div>
    </main>

    <!-- Delete confirmation dialog -->
    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('MESSAGE_TEMPLATES.DELETE.TITLE')"
      :description="t('MESSAGE_TEMPLATES.DELETE.DESCRIPTION')"
      :confirm-button-label="t('MESSAGE_TEMPLATES.DELETE.CONFIRM')"
      :cancel-button-label="t('MESSAGE_TEMPLATES.DELETE.CANCEL')"
      @confirm="handleDelete"
    />

    <!-- Quick preview dialog -->
    <Dialog
      ref="previewDialogRef"
      :title="templateToPreview?.name || ''"
      :show-confirm-button="false"
      :cancel-button-label="t('MESSAGE_TEMPLATES.PREVIEW.CLOSE')"
      width="sm"
      @close="templateToPreview = null"
    >
      <div
        v-if="templateToPreview"
        class="bg-[#e5ddd5] rounded-lg p-4 flex justify-end"
      >
        <div class="bg-[#dcf8c6] rounded-lg p-3 max-w-[280px] shadow-sm">
          <p
            v-if="previewHeaderText"
            class="font-bold text-sm text-[#111b21] mb-1"
          >
            {{ previewHeaderText }}
          </p>
          <p
            v-if="previewBodyText"
            class="text-sm text-[#111b21] whitespace-pre-wrap"
          >
            {{ previewBodyText }}
          </p>
          <p v-if="previewFooterText" class="text-xs text-[#667781] mt-1">
            {{ previewFooterText }}
          </p>
          <div v-if="previewButtons.length" class="mt-2 space-y-1">
            <div
              v-for="(btn, idx) in previewButtons"
              :key="idx"
              class="text-center text-xs text-[#00a884] py-1.5 border-t border-[#c6e2d0]"
            >
              {{ btn.text }}
            </div>
          </div>
        </div>
      </div>
    </Dialog>
  </section>
</template>
