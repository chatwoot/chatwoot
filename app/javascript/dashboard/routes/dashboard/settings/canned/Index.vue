<script setup>
import { useAlert } from 'dashboard/composables';
import AddCanned from './AddCanned.vue';
import EditCanned from './EditCanned.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import { picoSearch } from '@chatwoot/pico-search';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useAdmin } from 'dashboard/composables/useAdmin';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

defineOptions({
  name: 'CannedResponseSettings',
});

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();
const currentUser = useMapGetter('getCurrentUser');

const { getPlainText } = useMessageFormatter();

const showAddPopup = ref(false);
const loading = ref({});
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});
const cannedResponseAPI = ref({ message: '' });

const sortOrder = ref('asc');
const searchQuery = ref('');
const selectedCategory = ref(null);
const visibilityFilter = ref('all');

const records = computed(() =>
  getters.getSortedCannedResponses.value(sortOrder.value)
);

const categories = computed(() => {
  const set = new Set();
  records.value.forEach(item => {
    if (item.category) set.add(item.category);
  });
  return [...set].sort((a, b) => a.localeCompare(b));
});

const visibilityFilteredRecords = computed(() => {
  const userId = currentUser.value?.id;
  if (visibilityFilter.value === 'mine') {
    return records.value.filter(item => item.created_by_id === userId);
  }
  if (visibilityFilter.value === 'account') {
    return records.value.filter(item => item.visibility === 'global');
  }
  if (visibilityFilter.value === 'pending') {
    return records.value.filter(item => item.approval_status === 'pending');
  }
  return records.value;
});

const categoryFilteredRecords = computed(() => {
  if (selectedCategory.value === null) return visibilityFilteredRecords.value;
  if (selectedCategory.value === '') {
    return visibilityFilteredRecords.value.filter(item => !item.category);
  }
  return visibilityFilteredRecords.value.filter(
    item => item.category === selectedCategory.value
  );
});

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return categoryFilteredRecords.value;
  return picoSearch(categoryFilteredRecords.value, query, [
    { name: 'short_code', weight: 4 },
    { name: 'category', weight: 2 },
    'content',
  ]);
});
const uiFlags = computed(() => getters.getUIFlags.value);

const deleteConfirmText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.YES')} ${activeResponse.value.short_code}`
);

const deleteRejectText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.NO')} ${activeResponse.value.short_code}`
);

const deleteMessage = computed(() => {
  return ` ${activeResponse.value.short_code} ? `;
});

const emptyListMessage = computed(() =>
  isAdmin.value ? t('CANNED_MGMT.LIST.404') : t('CANNED_MGMT.LIST.404_AGENT')
);

const visibilityFilters = computed(() => {
  const filters = [
    { key: 'all', label: t('CANNED_MGMT.FILTER_VISIBILITY.ALL') },
    { key: 'mine', label: t('CANNED_MGMT.FILTER_VISIBILITY.MINE') },
    { key: 'account', label: t('CANNED_MGMT.FILTER_VISIBILITY.ACCOUNT') },
  ];
  if (isAdmin.value) {
    filters.splice(1, 0, {
      key: 'pending',
      label: t('CANNED_MGMT.FILTER_VISIBILITY.PENDING'),
    });
  }
  return filters;
});

const toggleSort = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
};

const fetchCannedResponses = async () => {
  try {
    await store.dispatch('getCannedResponse');
  } catch (error) {
    // Ignore Error
  }
};

onMounted(() => {
  fetchCannedResponses();
});

const showAlertMessage = message => {
  loading.value[activeResponse.value.id] = false;
  activeResponse.value = {};
  cannedResponseAPI.value.message = message;
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  activeResponse.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  activeResponse.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteCannedResponse = async id => {
  try {
    await store.dispatch('deleteCannedResponse', id);
    showAlertMessage(t('CANNED_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CANNED_MGMT.DELETE.API.ERROR_MESSAGE');
    showAlertMessage(errorMessage);
  }
};

const confirmDeletion = () => {
  loading.value[activeResponse.value.id] = true;
  closeDeletePopup();
  deleteCannedResponse(activeResponse.value.id);
};

const approveResponse = async (item, visibility) => {
  loading.value[item.id] = true;
  try {
    await store.dispatch('approveCannedResponse', {
      id: item.id,
      visibility,
    });
    useAlert(t('CANNED_MGMT.APPROVE.SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('CANNED_MGMT.APPROVE.ERROR'));
  } finally {
    loading.value[item.id] = false;
  }
};

const rejectResponse = async item => {
  loading.value[item.id] = true;
  try {
    await store.dispatch('rejectCannedResponse', item.id);
    useAlert(t('CANNED_MGMT.REJECT.SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('CANNED_MGMT.REJECT.ERROR'));
  } finally {
    loading.value[item.id] = false;
  }
};

const visibilityLabel = item =>
  t(`CANNED_MGMT.VISIBILITY_LABEL.${item.visibility || 'global'}`);

const statusLabel = item =>
  t(`CANNED_MGMT.STATUS_LABEL.${item.approval_status || 'pending'}`);

const statusBadgeClass = status => {
  if (status === 'approved') return 'bg-n-brand/15 text-n-brand';
  if (status === 'rejected') return 'bg-n-ruby-3 text-n-ruby-12';
  return 'bg-n-slate-3 text-n-slate-12';
};

const chipClass = active =>
  active
    ? 'bg-n-brand text-white border-n-brand'
    : 'bg-n-alpha-black2 text-n-slate-12 border-n-weak hover:bg-n-alpha-2';

const tableHeaders = computed(() => {
  return [
    t('CANNED_MGMT.LIST.TABLE_HEADER.SHORT_CODE'),
    t('CANNED_MGMT.LIST.TABLE_HEADER.CATEGORY'),
    t('CANNED_MGMT.LIST.TABLE_HEADER.VISIBILITY'),
    t('CANNED_MGMT.LIST.TABLE_HEADER.STATUS'),
    t('CANNED_MGMT.LIST.TABLE_HEADER.ACTIONS'),
  ];
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('CANNED_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="emptyListMessage"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('CANNED_MGMT.HEADER')"
        :description="$t('CANNED_MGMT.DESCRIPTION')"
        :link-text="$t('CANNED_MGMT.LEARN_MORE')"
        :search-placeholder="$t('CANNED_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="canned_responses"
      >
        <template v-if="records?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('CANNED_MGMT.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="$t('CANNED_MGMT.HEADER_BTN_TXT')"
            size="sm"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div v-if="records.length" class="flex flex-col gap-3 mb-4">
        <div class="flex flex-wrap gap-2">
          <button
            v-for="filter in visibilityFilters"
            :key="filter.key"
            type="button"
            class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
            :class="chipClass(visibilityFilter === filter.key)"
            @click="visibilityFilter = filter.key"
          >
            {{ filter.label }}
          </button>
        </div>
        <div
          v-if="categories.length || records.some(r => !r.category)"
          class="flex flex-wrap gap-2"
        >
          <button
            type="button"
            class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
            :class="chipClass(selectedCategory === null)"
            @click="selectedCategory = null"
          >
            {{ $t('CANNED_MGMT.ALL_CATEGORIES') }}
          </button>
          <button
            v-for="cat in categories"
            :key="cat"
            type="button"
            class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
            :class="chipClass(selectedCategory === cat)"
            @click="selectedCategory = cat"
          >
            {{ cat }}
          </button>
          <button
            v-if="records.some(r => !r.category)"
            type="button"
            class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
            :class="chipClass(selectedCategory === '')"
            @click="selectedCategory = ''"
          >
            {{ $t('CANNED_MGMT.UNCATEGORIZED') }}
          </button>
        </div>
      </div>

      <BaseTable
        :headers="tableHeaders"
        :items="filteredRecords"
        :no-data-message="
          !records.length
            ? emptyListMessage
            : searchQuery ||
                selectedCategory !== null ||
                visibilityFilter !== 'all'
              ? $t('CANNED_MGMT.NO_RESULTS')
              : ''
        "
      >
        <template #header-0>
          <button
            class="flex items-center gap-2 p-0 cursor-pointer"
            @click="toggleSort"
          >
            <span class="mb-0">
              {{ tableHeaders[0] }}
            </span>
            <Icon
              class="size-5 text-n-slate-11 flex-shrink-0"
              :icon="
                sortOrder === 'desc'
                  ? 'i-woot-sort-descending'
                  : 'i-woot-sort-ascending'
              "
            />
          </button>
        </template>
        <template #header-1>
          {{ tableHeaders[1] }}
        </template>
        <template #header-2>
          {{ tableHeaders[2] }}
        </template>
        <template #header-3>
          {{ tableHeaders[3] }}
        </template>
        <template #header-4>
          <div class="text-end">
            {{ tableHeaders[4] }}
          </div>
        </template>

        <template #row="{ items }">
          <BaseTableRow
            v-for="cannedItem in items"
            :key="cannedItem.id || cannedItem.short_code"
            :item="cannedItem"
          >
            <template #default>
              <BaseTableCell class="max-w-0">
                <div class="flex flex-col gap-2 min-w-0">
                  <span class="text-heading-3 text-n-slate-12 truncate block">
                    {{ cannedItem.short_code }}
                  </span>
                  <p class="text-body-main text-n-slate-11 line-clamp-5">
                    {{ getPlainText(cannedItem.content) }}
                  </p>
                </div>
              </BaseTableCell>

              <BaseTableCell class="w-32">
                <span
                  v-if="cannedItem.category"
                  class="inline-block px-2 py-0.5 text-xs rounded-lg bg-n-slate-3 text-n-slate-12"
                >
                  {{ cannedItem.category }}
                </span>
                <span v-else class="text-xs text-n-slate-10">—</span>
              </BaseTableCell>

              <BaseTableCell class="w-28">
                <span class="text-xs text-n-slate-11">
                  {{ visibilityLabel(cannedItem) }}
                </span>
              </BaseTableCell>

              <BaseTableCell class="w-28">
                <span
                  class="inline-block px-2 py-0.5 text-xs rounded-lg"
                  :class="statusBadgeClass(cannedItem.approval_status)"
                >
                  {{ statusLabel(cannedItem) }}
                </span>
              </BaseTableCell>

              <BaseTableCell align="end" class="min-w-[9rem]">
                <div class="flex gap-2 justify-end flex-wrap flex-shrink-0">
                  <template
                    v-if="isAdmin && cannedItem.approval_status === 'pending'"
                  >
                    <Button
                      v-tooltip.top="$t('CANNED_MGMT.APPROVE.PERSONAL')"
                      icon="i-lucide-user-check"
                      slate
                      sm
                      :is-loading="loading[cannedItem.id]"
                      @click="approveResponse(cannedItem, 'personal')"
                    />
                    <Button
                      v-tooltip.top="$t('CANNED_MGMT.APPROVE.ACCOUNT')"
                      icon="i-lucide-users"
                      slate
                      sm
                      :is-loading="loading[cannedItem.id]"
                      @click="approveResponse(cannedItem, 'global')"
                    />
                    <Button
                      v-tooltip.top="$t('CANNED_MGMT.REJECT.BUTTON')"
                      icon="i-lucide-x"
                      slate
                      sm
                      class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                      :is-loading="loading[cannedItem.id]"
                      @click="rejectResponse(cannedItem)"
                    />
                  </template>
                  <Button
                    v-tooltip.top="$t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
                    icon="i-woot-edit-pen"
                    slate
                    sm
                    @click="openEditPopup(cannedItem)"
                  />
                  <Button
                    v-tooltip.top="$t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
                    icon="i-woot-bin"
                    slate
                    sm
                    class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                    :is-loading="loading[cannedItem.id]"
                    @click="openDeletePopup(cannedItem)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>
    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddCanned :on-close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditCanned
        v-if="showEditPopup"
        :id="activeResponse.id"
        :edshort-code="activeResponse.short_code"
        :edcontent="activeResponse.content"
        :edcategory="activeResponse.category"
        :edvisibility="activeResponse.visibility"
        :on-close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CANNED_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('CANNED_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </SettingsLayout>
</template>
