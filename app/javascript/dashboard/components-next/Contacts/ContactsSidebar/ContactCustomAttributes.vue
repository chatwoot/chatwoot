<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { groupAttributesByCategory } from 'dashboard/helper/attributeCategoryGroups';

import ContactCustomAttributeItem from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributeItem.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

const { uiSettings, isContactSidebarItemOpen, toggleSidebarUIState } =
  useUISettings();

const searchQuery = ref('');

const contactAttributes = useMapGetter('attributes/getContactAttributes') || [];

const hasContactAttributes = computed(
  () => contactAttributes.value?.length > 0
);

const processContactAttributes = (
  attributes,
  customAttributes,
  filterCondition
) => {
  if (!attributes.length || !customAttributes) {
    return [];
  }

  return attributes.reduce((result, attribute) => {
    const { attributeKey } = attribute;
    const meetsCondition = filterCondition(attributeKey, customAttributes);

    if (meetsCondition) {
      result.push({
        ...attribute,
        value: customAttributes[attributeKey] ?? '',
      });
    }

    return result;
  }, []);
};

const sortAttributesOrder = computed(
  () =>
    uiSettings.value.conversation_elements_order_conversation_contact_panel ??
    []
);

const sortByUISettings = attributes => {
  const order = sortAttributesOrder.value;
  if (!order?.length) return attributes;

  const orderMap = new Map(order.map((key, index) => [key, index]));

  return [...attributes].sort((a, b) => {
    const aPos = orderMap.get(a.attributeKey) ?? Infinity;
    const bPos = orderMap.get(b.attributeKey) ?? Infinity;
    return aPos - bPos;
  });
};

const usedAttributes = computed(() => {
  const attributes = processContactAttributes(
    contactAttributes.value,
    props.selectedContact?.customAttributes,
    (key, custom) => key in custom
  );

  return sortByUISettings(attributes);
});

const unusedAttributes = computed(() => {
  const attributes = processContactAttributes(
    contactAttributes.value,
    props.selectedContact?.customAttributes,
    (key, custom) => !(key in custom)
  );

  return sortByUISettings(attributes);
});

const filteredUnusedAttributes = computed(() => {
  return unusedAttributes.value?.filter(attribute =>
    attribute.attributeDisplayName
      .toLowerCase()
      .includes(searchQuery.value.toLowerCase())
  );
});

const categoryOpenKey = slug => `contact_attr_category_open_${slug}`;

const isCategoryOpen = slug => {
  const key = categoryOpenKey(slug);
  if (uiSettings.value[key] === undefined) return true;
  return isContactSidebarItemOpen(key);
};

const toggleCategoryOpen = slug => toggleSidebarUIState(categoryOpenKey(slug));

const usedCategoryGroups = computed(() =>
  groupAttributesByCategory(usedAttributes.value, {
    uncategorizedLabel: t('CUSTOM_ATTRIBUTES.UNCATEGORIZED'),
  })
);

const unusedCategoryGroups = computed(() =>
  groupAttributesByCategory(filteredUnusedAttributes.value, {
    uncategorizedLabel: t('CUSTOM_ATTRIBUTES.UNCATEGORIZED'),
  })
);

const showUsedCategoryFolders = computed(
  () => usedCategoryGroups.value.length > 1
);

const unusedAttributesCount = computed(() => unusedAttributes.value?.length);
const hasNoUnusedAttributes = computed(() => unusedAttributesCount.value === 0);
const hasNoUsedAttributes = computed(() => usedAttributes.value.length === 0);
</script>

<template>
  <div v-if="hasContactAttributes" class="flex flex-col gap-6 px-6">
    <div v-if="!hasNoUsedAttributes" class="flex flex-col gap-2">
      <template v-if="showUsedCategoryFolders">
        <div
          v-for="group in usedCategoryGroups"
          :key="group.key"
          class="flex flex-col gap-1"
        >
          <button
            type="button"
            class="flex w-full items-center gap-1.5 px-1 py-1.5 rounded-md text-start hover:bg-n-alpha-2"
            @click="toggleCategoryOpen(group.slug)"
          >
            <span
              class="i-lucide-chevron-down size-3.5 text-n-slate-11 transition-transform shrink-0"
              :class="{ '-rotate-90': !isCategoryOpen(group.slug) }"
            />
            <span class="text-sm font-medium text-n-slate-11 truncate">
              {{
                t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.CATEGORY_COUNT', {
                  title: group.title,
                  count: group.attributes.length,
                })
              }}
            </span>
          </button>
          <div
            v-show="isCategoryOpen(group.slug)"
            class="flex flex-col gap-2 ps-1"
          >
            <ContactCustomAttributeItem
              v-for="attribute in group.attributes"
              :key="attribute.id"
              is-editing-view
              :attribute="attribute"
            />
          </div>
        </div>
      </template>
      <template v-else>
        <ContactCustomAttributeItem
          v-for="attribute in usedAttributes"
          :key="attribute.id"
          is-editing-view
          :attribute="attribute"
        />
      </template>
    </div>
    <div v-if="!hasNoUnusedAttributes" class="flex items-center gap-3">
      <div class="flex-1 h-[1px] bg-n-slate-5" />
      <span class="text-sm font-medium text-n-slate-10">{{
        t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.UNUSED_ATTRIBUTES', {
          count: unusedAttributesCount,
        })
      }}</span>
      <div class="flex-1 h-[1px] bg-n-slate-5" />
    </div>
    <div class="flex flex-col gap-3">
      <div v-if="!hasNoUnusedAttributes" class="relative">
        <span class="absolute i-lucide-search size-3.5 top-2 left-3" />
        <input
          v-model="searchQuery"
          type="search"
          :placeholder="
            t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.SEARCH_PLACEHOLDER')
          "
          class="w-full h-8 py-2 pl-10 pr-2 text-sm reset-base outline-none border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
        />
      </div>
      <div
        v-if="filteredUnusedAttributes.length === 0 && !hasNoUnusedAttributes"
        class="flex items-center justify-start h-11"
      >
        <p class="text-sm text-n-slate-11">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.NO_ATTRIBUTES') }}
        </p>
      </div>
      <div v-if="!hasNoUnusedAttributes" class="flex flex-col gap-2">
        <div
          v-for="group in unusedCategoryGroups"
          :key="`unused-${group.key}`"
          class="flex flex-col gap-1"
        >
          <p
            v-if="unusedCategoryGroups.length > 1"
            class="text-xs font-medium text-n-slate-10 px-1"
          >
            {{ group.title }}
          </p>
          <ContactCustomAttributeItem
            v-for="attribute in group.attributes"
            :key="attribute.id"
            :attribute="attribute"
          />
        </div>
      </div>
    </div>
  </div>
  <p v-else class="px-6 py-10 text-sm leading-6 text-center text-n-slate-11">
    {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.EMPTY_STATE') }}
  </p>
</template>
