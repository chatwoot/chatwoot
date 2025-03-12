<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

import ContactCustomAttributeItem from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributeItem.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

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

const usedAttributes = computed(() => {
  return processContactAttributes(
    contactAttributes.value,
    props.selectedContact?.customAttributes,
    (key, custom) => key in custom
  );
});

const unusedAttributes = computed(() => {
  return processContactAttributes(
    contactAttributes.value,
    props.selectedContact?.customAttributes,
    (key, custom) => !(key in custom)
  );
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
  <div v-if="hasContactAttributes" class="flex flex-col gap-6 px-6 py-6">
    <div v-if="!hasNoUsedAttributes" class="flex flex-col gap-2">
      <ContactCustomAttributeItem
        v-for="attribute in usedAttributes"
        :key="attribute.id"
        is-editing-view
        :attribute="attribute"
      />
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
          class="w-full h-8 py-2 pl-10 pr-2 text-sm border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
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
        <ContactCustomAttributeItem
          v-for="attribute in filteredUnusedAttributes"
          :key="attribute.id"
          :attribute="attribute"
        />
      </div>
    </div>
  </div>
  <p v-else class="px-6 py-10 text-sm leading-6 text-center text-n-slate-11">
    {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.EMPTY_STATE') }}
  </p>
</template>
