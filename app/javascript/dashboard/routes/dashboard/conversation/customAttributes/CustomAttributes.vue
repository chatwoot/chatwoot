<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import Draggable from 'vuedraggable';
import { useRoute } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import {
  useUISettings,
  attributeCategorySlug,
  SYSTEM_CATEGORY_SLUG,
} from 'dashboard/composables/useUISettings';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';

const props = defineProps({
  attributeType: {
    type: String,
    default: 'conversation_attribute',
  },
  contactId: { type: Number, default: null },
  attributeFrom: {
    type: String,
    required: true,
  },
  emptyStateMessage: {
    type: String,
    default: '',
  },
  // Combine static elements with custom attributes components
  // To allow for custom ordering
  staticElements: {
    type: Array,
    default: () => [],
  },
});

const store = useStore();
const getters = useStoreGetters();
const route = useRoute();
const { t } = useI18n();
const {
  uiSettings,
  updateUISettings,
  isContactSidebarItemOpen,
  toggleSidebarUIState,
  isConversationSidebarCategoryVisible,
  conversationSidebarCategoryOrder,
} = useUISettings();

const dragging = ref(false);

const currentChat = computed(() => getters.getSelectedChat.value);
const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(props.attributeType)
);

const contactIdentifier = computed(
  () =>
    currentChat.value.meta?.sender?.id ||
    route.params.contactId ||
    props.contactId
);

const contact = computed(() =>
  getters['contacts/getContact'].value(contactIdentifier.value)
);

const customAttributes = computed(() => {
  if (props.attributeType === 'conversation_attribute')
    return currentChat.value.custom_attributes || {};
  return contact.value.custom_attributes || {};
});

const conversationId = computed(() => currentChat.value.id);

const filteredCustomAttributes = computed(() =>
  attributes.value.map(attribute => {
    const hasValue = attribute.attribute_key in customAttributes.value;

    return {
      ...attribute,
      type: 'custom_attribute',
      key: attribute.attribute_key,
      value: hasValue ? customAttributes.value[attribute.attribute_key] : '',
    };
  })
);

const attributeCategory = attribute =>
  (attribute?.category || attribute?.Category || '').trim();

const orderKey = computed(
  () => `conversation_elements_order_${props.attributeFrom}`
);

const sortBySavedOrder = (elements, savedOrder) => {
  if (!savedOrder.length) return elements;

  return [...elements].sort((a, b) => {
    const aPosition = savedOrder.indexOf(a.key);
    const bPosition = savedOrder.indexOf(b.key);

    if (aPosition === -1 && bPosition === -1) return 0;
    if (aPosition === -1) return 1;
    if (bPosition === -1) return -1;

    return aPosition - bPosition;
  });
};

const combinedElements = computed(() => {
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  const allElements = [
    ...props.staticElements,
    ...filteredCustomAttributes.value,
  ];

  return sortBySavedOrder(allElements, savedOrder);
});

const displayedElements = computed(() => {
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  const systemVisible = isConversationSidebarCategoryVisible(
    props.attributeType,
    SYSTEM_CATEGORY_SLUG
  );
  const statics = systemVisible
    ? sortBySavedOrder([...props.staticElements], savedOrder)
    : [];
  const visibleAttrs = filteredCustomAttributes.value.filter(attribute =>
    isConversationSidebarCategoryVisible(
      props.attributeType,
      attributeCategorySlug(attributeCategory(attribute))
    )
  );
  return sortBySavedOrder([...statics, ...visibleAttrs], savedOrder);
});

const flatList = ref([]);
watch(
  displayedElements,
  elements => {
    if (!dragging.value) {
      flatList.value = [...elements];
    }
  },
  { immediate: true }
);

const orderedStaticElements = computed(() => {
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  return sortBySavedOrder([...props.staticElements], savedOrder);
});

const categoryOpenKey = slug =>
  `attr_category_open_${props.attributeFrom}_${slug}`;

const isCategoryOpen = slug => isContactSidebarItemOpen(categoryOpenKey(slug));

const toggleCategoryOpen = slug => toggleSidebarUIState(categoryOpenKey(slug));

const isSystemCategoryVisible = computed(() =>
  isConversationSidebarCategoryVisible(
    props.attributeType,
    SYSTEM_CATEGORY_SLUG
  )
);

const visibleStaticElements = computed(() => {
  if (!isSystemCategoryVisible.value) return [];
  return orderedStaticElements.value;
});

const categoryGroups = computed(() => {
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  const sortedAttributes = sortBySavedOrder(
    filteredCustomAttributes.value,
    savedOrder
  );
  const groups = new Map();

  if (visibleStaticElements.value.length) {
    groups.set('__system__', {
      key: '__system__',
      slug: SYSTEM_CATEGORY_SLUG,
      title: t('CUSTOM_ATTRIBUTES.SYSTEM'),
      attributes: [],
      staticElements: visibleStaticElements.value,
    });
  }

  sortedAttributes.forEach(attribute => {
    const category = attributeCategory(attribute);
    const slug = attributeCategorySlug(category);
    if (!isConversationSidebarCategoryVisible(props.attributeType, slug)) {
      return;
    }
    const key = category || '__uncategorized__';
    if (!groups.has(key)) {
      groups.set(key, {
        key,
        slug,
        title: category || t('CUSTOM_ATTRIBUTES.UNCATEGORIZED'),
        attributes: [],
        staticElements: [],
      });
    }
    groups.get(key).attributes.push(attribute);
  });

  const list = [...groups.values()];
  const categoryOrder = conversationSidebarCategoryOrder(props.attributeType);

  return list.sort((a, b) => {
    if (categoryOrder.length) {
      const aPos = categoryOrder.indexOf(a.slug);
      const bPos = categoryOrder.indexOf(b.slug);
      if (aPos !== -1 || bPos !== -1) {
        if (aPos === -1) return 1;
        if (bPos === -1) return -1;
        return aPos - bPos;
      }
    }
    if (a.key === '__system__') return -1;
    if (b.key === '__system__') return 1;
    if (a.key === '__uncategorized__') return 1;
    if (b.key === '__uncategorized__') return -1;
    return a.title.localeCompare(b.title);
  });
});

// Same gate as macros: folders only when 2+ visible groups.
const hasMultipleCategories = computed(() => categoryGroups.value.length > 1);

const showCategoryFolderView = computed(() => hasMultipleCategories.value);

const allCategoriesHidden = computed(() => {
  const hasStatics = props.staticElements.length > 0;
  const hasCustoms = filteredCustomAttributes.value.length > 0;
  if (!hasStatics && !hasCustoms) return false;

  const systemHidden =
    !hasStatics ||
    !isConversationSidebarCategoryVisible(
      props.attributeType,
      SYSTEM_CATEGORY_SLUG
    );
  const customsHidden =
    !hasCustoms ||
    filteredCustomAttributes.value.every(
      attribute =>
        !isConversationSidebarCategoryVisible(
          props.attributeType,
          attributeCategorySlug(attributeCategory(attribute))
        )
    );

  return systemHidden && customsHidden;
});

const reorderElementsWithStaticPreservation = (
  savedOrder = [],
  currentOrder = []
) => {
  const finalOrder = [...currentOrder];
  const visibleKeys = new Set(currentOrder);

  savedOrder
    .filter(key => key.startsWith('static-') && !visibleKeys.has(key))
    .forEach(staticKey => {
      const nextVisible = savedOrder
        .slice(savedOrder.indexOf(staticKey))
        .find(key => visibleKeys.has(key));

      if (nextVisible) {
        finalOrder.splice(finalOrder.indexOf(nextVisible), 0, staticKey);
      } else {
        finalOrder.push(staticKey);
      }
    });

  return finalOrder;
};

const onDragEnd = () => {
  dragging.value = false;
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  const currentOrder = flatList.value.map(({ key }) => key);

  const finalOrder = reorderElementsWithStaticPreservation(
    savedOrder,
    currentOrder
  );

  updateUISettings({
    [orderKey.value]: finalOrder,
  });
};

const onCategoryOrderChange = (categoryKey, newAttributes) => {
  dragging.value = false;
  const savedOrder = uiSettings.value[orderKey.value] ?? [];
  const newKeys = newAttributes.map(({ key }) => key);
  const categoryKeySet = new Set(newKeys);
  const result = [];
  let inserted = false;

  savedOrder.forEach(key => {
    if (categoryKeySet.has(key)) {
      if (!inserted) {
        result.push(...newKeys);
        inserted = true;
      }
      return;
    }
    result.push(key);
  });

  if (!inserted) {
    result.push(...newKeys);
  }

  const resultSet = new Set(result);
  orderedStaticElements.value.forEach(({ key }) => {
    if (!resultSet.has(key)) result.push(key);
  });
  filteredCustomAttributes.value.forEach(({ key }) => {
    if (!resultSet.has(key) && !categoryKeySet.has(key)) result.push(key);
  });

  updateUISettings({
    [orderKey.value]: result,
  });
};

const initializeSettings = () => {
  const currentOrder = uiSettings.value[orderKey.value];
  if (!currentOrder) {
    const initialOrder = combinedElements.value.map(element => element.key);
    updateUISettings({
      [orderKey.value]: initialOrder,
    });
  }
};

const onUpdate = async (key, value) => {
  const updatedAttributes = { ...customAttributes.value, [key]: value };
  try {
    if (props.attributeType === 'conversation_attribute') {
      await store.dispatch('updateCustomAttributes', {
        conversationId: conversationId.value,
        customAttributes: updatedAttributes,
      });
    } else {
      store.dispatch('contacts/update', {
        id: props.contactId,
        customAttributes: updatedAttributes,
      });
    }
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR');
    useAlert(errorMessage);
  }
};

const onDelete = async key => {
  try {
    const { [key]: remove, ...updatedAttributes } = customAttributes.value;
    if (props.attributeType === 'conversation_attribute') {
      await store.dispatch('updateCustomAttributes', {
        conversationId: conversationId.value,
        customAttributes: updatedAttributes,
      });
    } else {
      store.dispatch('contacts/deleteCustomAttributes', {
        id: props.contactId,
        customAttributes: [key],
      });
    }
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.DELETE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('CUSTOM_ATTRIBUTES.FORM.DELETE.ERROR');
    useAlert(errorMessage);
  }
};

const onCopy = async attributeValue => {
  await copyTextToClipboard(attributeValue);
  useAlert(t('CUSTOM_ATTRIBUTES.COPY_SUCCESSFUL'));
};

onMounted(() => {
  initializeSettings();
});

const evenClass = [
  '[&>*:nth-child(odd)]:!bg-n-surface-1 [&>*:nth-child(even)]:!bg-n-slate-1',
  'dark:[&>*:nth-child(odd)]:!bg-n-surface-2 dark:[&>*:nth-child(even)]:!bg-n-surface-1',
];
</script>

<template>
  <div class="conversation--details">
    <template v-if="showCategoryFolderView">
      <div class="flex flex-col gap-0.5">
        <div v-for="group in categoryGroups" :key="group.key">
          <button
            type="button"
            class="flex w-full items-center justify-between gap-2 px-2 py-1.5 rounded-md text-start hover:bg-n-alpha-2"
            @click="toggleCategoryOpen(group.slug)"
          >
            <span class="text-sm font-medium text-n-slate-11 truncate">
              {{ group.title }}
              <span class="font-normal">
                ({{
                  group.attributes.length + (group.staticElements?.length || 0)
                }})
              </span>
            </span>
            <span
              class="i-lucide-chevron-down size-3.5 text-n-slate-11 transition-transform shrink-0"
              :class="{ '-rotate-90': !isCategoryOpen(group.slug) }"
            />
          </button>

          <div
            v-show="isCategoryOpen(group.slug)"
            class="last:rounded-b-lg"
            :class="evenClass"
          >
            <div
              v-for="element in group.staticElements || []"
              :key="element.key"
              class="relative border-b border-n-weak/50 dark:border-n-weak/90"
            >
              <slot name="staticItem" :element="element" />
            </div>

            <Draggable
              v-if="group.attributes.length"
              :model-value="group.attributes"
              animation="200"
              ghost-class="ghost"
              handle=".drag-handle"
              item-key="key"
              @start="dragging = true"
              @update:model-value="
                value => onCategoryOrderChange(group.key, value)
              "
            >
              <template #item="{ element }">
                <div
                  class="drag-handle relative cursor-grab border-b border-n-weak/50 dark:border-n-weak/90 last:border-transparent dark:last:border-transparent"
                >
                  <CustomAttribute
                    :key="element.id"
                    :attribute-key="element.attribute_key"
                    :attribute-type="element.attribute_display_type"
                    :values="element.attribute_values"
                    :label="element.attribute_display_name"
                    :description="element.attribute_description"
                    :value="element.value"
                    show-actions
                    :read-only="!!element.formula"
                    :attribute-regex="element.regex_pattern"
                    :regex-cue="element.regex_cue"
                    :contact-id="contactId"
                    @update="onUpdate"
                    @delete="onDelete"
                    @copy="onCopy"
                  />
                </div>
              </template>
            </Draggable>
          </div>
        </div>
      </div>
    </template>

    <template v-else>
      <Draggable
        :list="flatList"
        animation="200"
        ghost-class="ghost"
        handle=".drag-handle"
        item-key="key"
        class="last:rounded-b-lg"
        :class="evenClass"
        @start="dragging = true"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <div
            class="drag-handle relative cursor-grab border-b border-n-weak/50 dark:border-n-weak/90 last:border-transparent dark:last:border-transparent"
          >
            <template v-if="element.type === 'static_attribute'">
              <slot name="staticItem" :element="element" />
            </template>

            <template v-else>
              <CustomAttribute
                :key="element.id"
                :attribute-key="element.attribute_key"
                :attribute-type="element.attribute_display_type"
                :values="element.attribute_values"
                :label="element.attribute_display_name"
                :description="element.attribute_description"
                :value="element.value"
                show-actions
                :read-only="!!element.formula"
                :attribute-regex="element.regex_pattern"
                :regex-cue="element.regex_cue"
                :contact-id="contactId"
                @update="onUpdate"
                @delete="onDelete"
                @copy="onCopy"
              />
            </template>
          </div>
        </template>
      </Draggable>
    </template>

    <p
      v-if="allCategoriesHidden"
      class="p-3 text-center text-sm text-n-slate-11"
    >
      {{ $t('CONVERSATION.SIDEBAR.MENU.CATEGORIES_HIDDEN') }}
    </p>
    <p
      v-else-if="
        emptyStateMessage &&
        !orderedStaticElements.length &&
        !filteredCustomAttributes.length
      "
      class="p-3 text-center"
    >
      {{ emptyStateMessage }}
    </p>
    <p
      v-else-if="
        emptyStateMessage && !showCategoryFolderView && !flatList.length
      "
      class="p-3 text-center"
    >
      {{ emptyStateMessage }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
.ghost {
  @apply opacity-50 bg-n-slate-3 dark:bg-n-slate-9;
}
</style>
