<script setup>
import { useAlert } from 'dashboard/composables';
import AddCanned from './AddCanned.vue';
import EditCanned from './EditCanned.vue';
import CannedListItem from './CannedListItem.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsFilterDropdown from '../components/SettingsFilterDropdown.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import { picoSearch } from '@chatwoot/pico-search';
import { useAdmin } from 'dashboard/composables/useAdmin';

import Button from 'dashboard/components-next/button/Button.vue';

defineOptions({
  name: 'CannedResponseSettings',
});

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();
const currentUser = useMapGetter('getCurrentUser');

const showAddPopup = ref(false);
const loading = ref({});
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});
const cannedResponseAPI = ref({ message: '' });

const sortOrder = ref('asc');
const searchQuery = ref('');
const selectedCategory = ref('all');
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

const hasUncategorized = computed(() =>
  records.value.some(item => !item.category)
);

const visibilityOptions = computed(() => {
  const filters = [
    { value: 'all', label: t('CANNED_MGMT.FILTER_VISIBILITY.ALL') },
    { value: 'mine', label: t('CANNED_MGMT.FILTER_VISIBILITY.MINE') },
    { value: 'account', label: t('CANNED_MGMT.FILTER_VISIBILITY.ACCOUNT') },
  ];
  if (isAdmin.value) {
    filters.splice(1, 0, {
      value: 'pending',
      label: t('CANNED_MGMT.FILTER_VISIBILITY.PENDING'),
    });
  }
  return filters;
});

const categoryOptions = computed(() => {
  const options = [
    { value: 'all', label: t('CANNED_MGMT.ALL_CATEGORIES') },
    ...categories.value.map(category => ({
      value: category,
      label: category,
    })),
  ];
  if (hasUncategorized.value) {
    options.push({
      value: '',
      label: t('CANNED_MGMT.UNCATEGORIZED'),
    });
  }
  return options;
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
  if (selectedCategory.value === 'all') return visibilityFilteredRecords.value;
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

const uniqueShortCode = baseCode => {
  const taken = new Set(records.value.map(item => item.short_code));
  let candidate = `${baseCode}_copy`;
  let n = 2;
  while (taken.has(candidate)) {
    candidate = `${baseCode}_copy_${n}`;
    n += 1;
  }
  return candidate;
};

const duplicateCanned = async item => {
  loading.value[item.id] = true;
  try {
    const visibility =
      item.visibility === 'global' && !isAdmin.value
        ? 'personal'
        : item.visibility || 'personal';

    await store.dispatch('createCannedResponse', {
      short_code: uniqueShortCode(item.short_code),
      content: item.content,
      category: item.category || null,
      visibility,
    });
    useAlert(
      isAdmin.value
        ? t('CANNED_MGMT.DUPLICATE.API.SUCCESS_MESSAGE')
        : t('CANNED_MGMT.DUPLICATE.API.SUCCESS_MESSAGE_PENDING')
    );
  } catch (error) {
    useAlert(error?.message || t('CANNED_MGMT.DUPLICATE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[item.id] = false;
  }
};
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
        <template v-if="records.length" #tabs>
          <div class="flex items-center gap-2">
            <SettingsFilterDropdown
              v-model="visibilityFilter"
              :options="visibilityOptions"
              icon="i-lucide-eye"
              action-key="visibility"
            />
            <SettingsFilterDropdown
              v-if="categories.length || hasUncategorized"
              v-model="selectedCategory"
              :options="categoryOptions"
              icon="i-lucide-tags"
              action-key="category"
            />
          </div>
        </template>
        <template v-if="filteredRecords.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('CANNED_MGMT.COUNT', { n: filteredRecords.length }) }}
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
      <div
        v-if="!filteredRecords.length"
        class="flex items-center justify-center p-8"
      >
        <span class="text-base text-n-slate-11">
          {{
            !records.length
              ? emptyListMessage
              : searchQuery ||
                  selectedCategory !== 'all' ||
                  visibilityFilter !== 'all'
                ? $t('CANNED_MGMT.NO_RESULTS')
                : emptyListMessage
          }}
        </span>
      </div>
      <div v-else class="border-t divide-y divide-n-weak border-n-weak">
        <CannedListItem
          v-for="cannedItem in filteredRecords"
          :key="cannedItem.id || cannedItem.short_code"
          :canned="cannedItem"
          :is-admin="isAdmin"
          :is-loading="!!loading[cannedItem.id]"
          @edit="openEditPopup(cannedItem)"
          @delete="openDeletePopup(cannedItem)"
          @duplicate="duplicateCanned(cannedItem)"
          @approve="visibility => approveResponse(cannedItem, visibility)"
          @reject="rejectResponse(cannedItem)"
        />
      </div>
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
