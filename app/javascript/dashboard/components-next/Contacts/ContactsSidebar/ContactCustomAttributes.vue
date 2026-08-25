<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

import ContactCustomAttributeItem from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributeItem.vue';
import ContactSidebarSection from 'dashboard/components-next/Contacts/ContactsSidebar/ContactSidebarSection.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

const { uiSettings } = useUISettings();

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
  // Get saved order from UI settings
  // Same as conversation panel contact attribute order
  const order = sortAttributesOrder.value;

  // If no order defined, return original array
  if (!order?.length) return attributes;

  const orderMap = new Map(order.map((key, index) => [key, index]));

  // Sort attributes based on their position in saved order
  return [...attributes].sort((a, b) => {
    // Get positions, use Infinity if not found in order (pushes to end)
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

const unusedAttributesCount = computed(() => unusedAttributes.value?.length);
const hasNoUnusedAttributes = computed(() => unusedAttributesCount.value === 0);
const hasNoUsedAttributes = computed(() => usedAttributes.value.length === 0);
</script>

<template>
  <ContactSidebarSection
    v-if="hasContactAttributes"
    :title="t('CONTACTS_LAYOUT.SIDEBAR.TABS.ATTRIBUTES')"
    body-class="p-0"
  >
    <div v-if="!hasNoUsedAttributes" class="flex flex-col px-4 py-1.5">
      <ContactCustomAttributeItem
        v-for="attribute in usedAttributes"
        :key="attribute.id"
        is-editing-view
        :attribute="attribute"
      />
    </div>

    <div
      v-if="!hasNoUnusedAttributes"
      class="flex flex-col gap-3 px-4 py-4"
      :class="{ 'border-t border-n-weak': !hasNoUsedAttributes }"
    >
      <span
        class="text-xs font-semibold tracking-wider uppercase text-n-slate-10"
      >
        {{
          t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.UNUSED_ATTRIBUTES', {
            count: unusedAttributesCount,
          })
        }}
      </span>
      <div class="relative">
        <span
          class="absolute i-lucide-search size-3.5 top-2.5 left-3 text-n-slate-10"
        />
        <input
          v-model="searchQuery"
          type="search"
          :placeholder="
            t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.SEARCH_PLACEHOLDER')
          "
          class="w-full h-8 py-2 pl-10 pr-2 text-sm border outline-none reset-base rounded-lg border-n-weak bg-n-alpha-black2 dark:bg-n-solid-2 text-n-slate-12"
        />
      </div>
      <div
        v-if="filteredUnusedAttributes.length === 0"
        class="flex items-center justify-start h-11"
      >
        <p class="text-sm text-n-slate-11">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.NO_ATTRIBUTES') }}
        </p>
      </div>
      <div v-else class="flex flex-col">
        <ContactCustomAttributeItem
          v-for="attribute in filteredUnusedAttributes"
          :key="attribute.id"
          :attribute="attribute"
        />
      </div>
    </div>
  </ContactSidebarSection>
  <p v-else class="px-6 py-10 text-sm leading-6 text-center text-n-slate-11">
    {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.EMPTY_STATE') }}
  </p>
</template>
