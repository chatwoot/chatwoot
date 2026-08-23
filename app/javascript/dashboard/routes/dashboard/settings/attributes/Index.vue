<script setup>
import { computed, onMounted, ref } from 'vue';
import { useToggle } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@chatwoot/pico-search';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsFilterDropdown from '../components/SettingsFilterDropdown.vue';
import AddAttribute from './AddAttribute.vue';
import EditAttribute from './EditAttribute.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import AttributeListItem from 'dashboard/components-next/ConversationWorkflow/AttributeListItem.vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

const { t } = useI18n();

const getters = useStoreGetters();
const store = useStore();
const { currentAccount } = useAccount();
const inboxes = useMapGetter('inboxes/getInboxes');

const [showAddPopup, toggleAddPopup] = useToggle(false);
const selectedTabIndex = ref(0);
const searchQuery = ref('');
const selectedCategory = ref('all');
const uiFlags = computed(() => getters['attributes/getUIFlags'].value);
const [showEditPopup, toggleEditPopup] = useToggle(false);
const [showDeletePopup, toggleDeletePopup] = useToggle(false);
const selectedAttribute = ref({});
const attributeModels = ['conversation_attribute', 'contact_attribute'];

const openAddPopup = () => {
  toggleAddPopup(true);
};
const hideAddPopup = () => {
  toggleAddPopup(false);
};
const hideEditPopup = () => {
  toggleEditPopup(false);
  selectedAttribute.value = {};
};
const closeDelete = () => {
  toggleDeletePopup(false);
  selectedAttribute.value = {};
};

const tabs = computed(() => {
  return [
    {
      key: 0,
      name: t('ATTRIBUTES_MGMT.TABS.CONVERSATION'),
    },
    {
      key: 1,
      name: t('ATTRIBUTES_MGMT.TABS.CONTACT'),
    },
  ];
});

const tabsForTabBar = computed(() =>
  tabs.value.map(tab => ({ label: tab.name, key: tab.key }))
);

onMounted(() => {
  store.dispatch('attributes/get');
});

const attributeModel = computed(
  () => attributeModels[selectedTabIndex.value] || 'conversation_attribute'
);

const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(attributeModel.value)
);

const onClickTabChange = tab => {
  selectedTabIndex.value = tab.key;
  searchQuery.value = '';
  selectedCategory.value = 'all';
};

const handleEditAttribute = attribute => {
  selectedAttribute.value = attribute;
  toggleEditPopup(true);
};

const handleDeleteAttribute = attribute => {
  selectedAttribute.value = attribute;
  toggleDeletePopup(true);
};

const uniqueAttributeKey = baseKey => {
  const taken = new Set(attributes.value.map(item => item.attribute_key));
  let candidate = `${baseKey}_copy`;
  let n = 2;
  while (taken.has(candidate)) {
    candidate = `${baseKey}_copy_${n}`;
    n += 1;
  }
  return candidate;
};

const uniqueAttributeName = baseName => {
  const taken = new Set(
    attributes.value.map(item => item.attribute_display_name)
  );
  let candidate = `${baseName} (copy)`;
  let n = 2;
  while (taken.has(candidate)) {
    candidate = `${baseName} (copy ${n})`;
    n += 1;
  }
  return candidate;
};

const handleDuplicateAttribute = async attribute => {
  try {
    await store.dispatch('attributes/create', {
      attribute_display_name: uniqueAttributeName(
        attribute.attribute_display_name
      ),
      attribute_description: attribute.attribute_description || '',
      attribute_model: attribute.attribute_model,
      attribute_display_type: attribute.attribute_display_type,
      attribute_key: uniqueAttributeKey(attribute.attribute_key),
      attribute_values: attribute.attribute_values || [],
      regex_pattern: attribute.regex_pattern || null,
      regex_cue: attribute.regex_cue || null,
      featured: false,
      category: attribute.category || '',
      formula: attribute.formula || null,
    });
    useAlert(t('ATTRIBUTES_MGMT.DUPLICATE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.message || t('ATTRIBUTES_MGMT.DUPLICATE.API.ERROR_MESSAGE')
    );
  }
};

const confirmDeleteAttribute = async () => {
  try {
    await store.dispatch('attributes/delete', selectedAttribute.value.id);
    useAlert(t('ATTRIBUTES_MGMT.DELETE.API.SUCCESS_MESSAGE'));
    closeDelete();
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('ATTRIBUTES_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const requiredAttributeKeys = computed(
  () => currentAccount.value?.settings?.conversation_required_attributes || []
);

const hasPreChatBadge = attribute => {
  return (inboxes.value || []).some(inbox => {
    const fields =
      inbox?.pre_chat_form_options?.pre_chat_fields ||
      inbox?.channel?.pre_chat_form_options?.pre_chat_fields ||
      [];
    return fields.some(field => field.name === attribute.attribute_key);
  });
};

const buildBadges = attribute => {
  const badges = [];
  if (hasPreChatBadge(attribute)) {
    badges.push({
      type: 'pre-chat',
    });
  }

  if (
    attribute.attribute_model === 'conversation_attribute' &&
    requiredAttributeKeys.value.includes(attribute.attribute_key)
  ) {
    badges.push({
      type: 'resolution',
    });
  }

  return badges;
};

const attributeCategory = attribute =>
  (attribute?.category || attribute?.Category || '').trim();

const derivedAttributes = computed(() =>
  attributes.value.map(attribute => ({
    ...attribute,
    label: attribute.attribute_display_name,
    type: attribute.attribute_display_type,
    value: attribute.attribute_key,
    badges: buildBadges(attribute),
  }))
);

const categories = computed(() => {
  const set = new Set();
  derivedAttributes.value.forEach(attribute => {
    const category = attributeCategory(attribute);
    if (category) set.add(category);
  });
  return [...set].sort((a, b) => a.localeCompare(b));
});

const hasUncategorized = computed(() =>
  derivedAttributes.value.some(attribute => !attributeCategory(attribute))
);

const showCategoryFilters = computed(
  () => categories.value.length > 0 || hasUncategorized.value
);

const categoryOptions = computed(() => {
  const options = [
    { value: 'all', label: t('ATTRIBUTES_MGMT.ALL_CATEGORIES') },
    ...categories.value.map(category => ({
      value: category,
      label: category,
    })),
  ];
  if (hasUncategorized.value) {
    options.push({
      value: '',
      label: t('ATTRIBUTES_MGMT.UNCATEGORIZED'),
    });
  }
  return options;
});

const categoryFilteredAttributes = computed(() => {
  if (selectedCategory.value === 'all') return derivedAttributes.value;
  if (selectedCategory.value === '') {
    return derivedAttributes.value.filter(
      attribute => !attributeCategory(attribute)
    );
  }
  return derivedAttributes.value.filter(
    attribute => attributeCategory(attribute) === selectedCategory.value
  );
});

const filteredAttributes = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return categoryFilteredAttributes.value;
  return picoSearch(categoryFilteredAttributes.value, query, [
    'attribute_display_name',
    'attribute_key',
    'attribute_description',
    'category',
  ]);
});

const sortAttributesByName = list =>
  [...list].sort((a, b) =>
    (a.attribute_display_name || a.label || '').localeCompare(
      b.attribute_display_name || b.label || ''
    )
  );

// When "All categories" is selected and named categories exist, show section
// headers (A–Z, Uncategorized last). A single-category filter skips headers.
const groupedAttributes = computed(() => {
  const list = filteredAttributes.value;
  const shouldGroup =
    selectedCategory.value === 'all' && categories.value.length > 0;

  if (!shouldGroup) {
    return [
      {
        key: selectedCategory.value ?? '__all__',
        title: null,
        attributes: sortAttributesByName(list),
      },
    ];
  }

  const groups = new Map();
  list.forEach(attribute => {
    const category = attributeCategory(attribute);
    const key = category || '__uncategorized__';
    if (!groups.has(key)) {
      groups.set(key, {
        key,
        title: category || t('ATTRIBUTES_MGMT.UNCATEGORIZED'),
        attributes: [],
      });
    }
    groups.get(key).attributes.push(attribute);
  });

  return [...groups.values()]
    .map(group => ({
      ...group,
      attributes: sortAttributesByName(group.attributes),
    }))
    .sort((a, b) => {
      if (a.key === '__uncategorized__') return 1;
      if (b.key === '__uncategorized__') return -1;
      return a.title.localeCompare(b.title);
    });
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('ATTRIBUTES_MGMT.HEADER')"
        :description="$t('ATTRIBUTES_MGMT.DESCRIPTION')"
        :link-text="$t('ATTRIBUTES_MGMT.LEARN_MORE')"
        :search-placeholder="$t('ATTRIBUTES_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="custom_attributes"
      >
        <template v-if="filteredAttributes.length" #count>
          <span class="text-body-main text-n-slate-11 truncate min-w-0">
            {{ $t('ATTRIBUTES_MGMT.COUNT', { n: filteredAttributes.length }) }}
          </span>
        </template>
        <template #tabs>
          <div class="flex items-center gap-2 flex-wrap">
            <TabBar
              :tabs="tabsForTabBar"
              :initial-active-tab="selectedTabIndex"
              @tab-changed="onClickTabChange"
            />
            <SettingsFilterDropdown
              v-if="attributes.length && showCategoryFilters"
              v-model="selectedCategory"
              :options="categoryOptions"
              icon="i-lucide-tags"
              action-key="category"
            />
          </div>
        </template>
        <template #actions>
          <Button
            :label="$t('ATTRIBUTES_MGMT.HEADER_BTN_TXT')"
            size="sm"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="flex flex-col gap-4">
        <span
          v-if="
            !filteredAttributes.length &&
            (searchQuery || selectedCategory !== 'all')
          "
          class="flex-1 flex items-center justify-center py-20 text-center text-body-main !text-base text-n-slate-11"
        >
          {{ $t('ATTRIBUTES_MGMT.NO_RESULTS') }}
        </span>
        <div v-else-if="filteredAttributes.length" class="flex flex-col gap-6">
          <section
            v-for="group in groupedAttributes"
            :key="group.key"
            class="flex flex-col gap-1"
          >
            <div
              v-if="group.title"
              class="flex w-full items-center justify-between gap-2 px-1 py-1.5 text-start"
            >
              <span class="text-xs font-medium text-n-slate-11 truncate">
                {{ group.title }}
                <span class="font-normal">{{
                  `(${group.attributes.length})`
                }}</span>
              </span>
            </div>
            <div
              class="flex flex-col divide-y divide-n-weak border-t border-n-weak"
              :class="{ 'pl-1': group.title }"
            >
              <AttributeListItem
                v-for="attribute in group.attributes"
                :key="attribute.id"
                :attribute="attribute"
                :badges="attribute.badges"
                @edit="handleEditAttribute"
                @delete="handleDeleteAttribute"
                @duplicate="handleDuplicateAttribute"
              />
            </div>
          </section>
        </div>
        <p
          v-else
          class="flex-1 py-20 text-n-slate-12 flex items-center justify-center text-base"
        >
          {{ $t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404') }}
        </p>
      </div>
    </template>
    <AddAttribute
      v-if="showAddPopup"
      v-model:show="showAddPopup"
      :on-close="hideAddPopup"
      :selected-attribute-model-tab="selectedTabIndex"
    />
    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditAttribute
        :selected-attribute="selectedAttribute"
        :is-updating="uiFlags.isUpdating"
        @on-close="hideEditPopup"
      />
    </woot-modal>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="
        $t('ATTRIBUTES_MGMT.DELETE.CONFIRM.TITLE', {
          attributeName: selectedAttribute.attribute_display_name,
        })
      "
      :message="$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="`${$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.YES')} ${
        selectedAttribute.attribute_display_name || ''
      }`"
      :reject-text="$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.NO')"
      :confirm-value="selectedAttribute.attribute_display_name"
      :confirm-place-holder-text="
        $t('ATTRIBUTES_MGMT.DELETE.CONFIRM.PLACE_HOLDER', {
          attributeName: selectedAttribute.attribute_display_name,
        })
      "
      @on-confirm="confirmDeleteAttribute"
      @on-close="closeDelete"
    />
  </SettingsLayout>
</template>
