<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import CompanyCustomAttributeItem from 'dashboard/components-next/Companies/CompanyDetail/CompanyCustomAttributeItem.vue';

const props = defineProps({
  company: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const store = useStore();

const searchQuery = ref('');
const companyAttributes = useMapGetter('attributes/getCompanyAttributes');

const customAttributes = computed(() => props.company?.customAttributes || {});
const hasCompanyAttributes = computed(
  () => companyAttributes.value?.length > 0
);

const processCompanyAttributes = (
  attributes,
  attributeValues,
  filterCondition
) => {
  if (!attributes.length) {
    return [];
  }

  return attributes.reduce((result, attribute) => {
    const { attributeKey } = attribute;

    if (filterCondition(attributeKey, attributeValues)) {
      result.push({
        ...attribute,
        value: attributeValues[attributeKey] ?? '',
      });
    }

    return result;
  }, []);
};

const usedAttributes = computed(() =>
  processCompanyAttributes(
    companyAttributes.value,
    customAttributes.value,
    (key, values) => key in values
  )
);

const unusedAttributes = computed(() =>
  processCompanyAttributes(
    companyAttributes.value,
    customAttributes.value,
    (key, values) => !(key in values)
  )
);

const filteredUnusedAttributes = computed(() =>
  unusedAttributes.value.filter(attribute =>
    attribute.attributeDisplayName
      .toLowerCase()
      .includes(searchQuery.value.toLowerCase())
  )
);

const unusedAttributesCount = computed(() => unusedAttributes.value.length);
const hasNoUnusedAttributes = computed(() => unusedAttributesCount.value === 0);
const hasNoUsedAttributes = computed(() => usedAttributes.value.length === 0);

onMounted(() => {
  store.dispatch('attributes/get');
});
</script>

<template>
  <div v-if="hasCompanyAttributes" class="flex flex-col gap-6 px-6 py-6">
    <div v-if="!hasNoUsedAttributes" class="flex flex-col gap-2">
      <CompanyCustomAttributeItem
        v-for="attribute in usedAttributes"
        :key="`${company.id}-${attribute.id}`"
        is-editing-view
        :company-id="company.id"
        :attribute="attribute"
      />
    </div>

    <div v-if="!hasNoUnusedAttributes" class="flex items-center gap-3">
      <div class="flex-1 h-px bg-n-slate-5" />
      <span class="text-sm font-medium text-n-slate-10">
        {{
          t('COMPANIES.DETAIL.ATTRIBUTES.UNUSED_ATTRIBUTES', {
            count: unusedAttributesCount,
          })
        }}
      </span>
      <div class="flex-1 h-px bg-n-slate-5" />
    </div>

    <div class="flex flex-col gap-3">
      <div v-if="!hasNoUnusedAttributes" class="relative">
        <span
          class="absolute i-lucide-search size-3.5 top-2 ltr:left-3 rtl:right-3"
        />
        <input
          v-model="searchQuery"
          type="search"
          :placeholder="t('COMPANIES.DETAIL.ATTRIBUTES.SEARCH_PLACEHOLDER')"
          class="w-full h-8 py-2 pl-10 pr-2 text-sm reset-base outline-none border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
        />
      </div>

      <div
        v-if="filteredUnusedAttributes.length === 0 && !hasNoUnusedAttributes"
        class="flex items-center justify-start h-11"
      >
        <p class="text-sm text-n-slate-11">
          {{ t('COMPANIES.DETAIL.ATTRIBUTES.NO_ATTRIBUTES') }}
        </p>
      </div>

      <div v-if="!hasNoUnusedAttributes" class="flex flex-col gap-2">
        <CompanyCustomAttributeItem
          v-for="attribute in filteredUnusedAttributes"
          :key="`${company.id}-${attribute.id}`"
          :company-id="company.id"
          :attribute="attribute"
        />
      </div>
    </div>
  </div>

  <p v-else class="px-6 py-10 text-sm leading-6 text-center text-n-slate-11">
    {{ t('COMPANIES.DETAIL.ATTRIBUTES.EMPTY_STATE') }}
  </p>
</template>
