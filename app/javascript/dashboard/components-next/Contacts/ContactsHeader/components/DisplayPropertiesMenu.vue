<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();

const contactAttributes = useMapGetter('attributes/getContactAttributes');

const MAX_SELECTED = 3;

const selectedAttributeKeys = computed({
  get: () => uiSettings.value?.contact_list_display_properties || [],
  set: value => {
    updateUISettings({
      contact_list_display_properties: value,
    });
  },
});

const selectedAttributes = computed(() => {
  return (
    contactAttributes.value?.filter(attr =>
      selectedAttributeKeys.value.includes(attr.attributeKey)
    ) || []
  );
});

const otherAttributes = computed(() => {
  return (
    contactAttributes.value?.filter(
      attr => !selectedAttributeKeys.value.includes(attr.attributeKey)
    ) || []
  );
});

const canSelectMore = computed(() => {
  return selectedAttributeKeys.value.length < MAX_SELECTED;
});

const toggleAttribute = attributeKey => {
  const currentKeys = [...selectedAttributeKeys.value];
  const index = currentKeys.indexOf(attributeKey);

  if (index > -1) {
    currentKeys.splice(index, 1);
  } else if (currentKeys.length < MAX_SELECTED) {
    currentKeys.push(attributeKey);
  }

  selectedAttributeKeys.value = currentKeys;
};

const removeAttribute = attributeKey => {
  const currentKeys = [...selectedAttributeKeys.value];
  const index = currentKeys.indexOf(attributeKey);
  if (index > -1) {
    currentKeys.splice(index, 1);
    selectedAttributeKeys.value = currentKeys;
  }
};
</script>

<template>
  <div
    class="flex flex-col gap-2 px-3 pt-3 pb-4 bg-n-alpha-3 rounded-xl outline outline-1 outline-n-weak -outline-offset-1 w-80 z-20 backdrop-blur-md"
  >
    <div class="flex items-start gap-1 flex-col">
      <h3 class="text-heading-3 text-n-slate-12 m-0">
        {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.TITLE') }}
      </h3>
      <p class="text-body-main text-n-slate-11 m-0">
        {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.DESCRIPTION') }}
      </p>
    </div>

    <div v-if="selectedAttributes.length > 0" class="flex flex-col gap-2">
      <span class="pt-2 text-label-small text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.SELECTED_ATTRIBUTES') }}
      </span>
      <div class="flex flex-wrap gap-2">
        <div
          v-for="attribute in selectedAttributes"
          :key="attribute.attributeKey"
          class="inline-flex items-center gap-1 ltr:pl-1 rtl:pr-1 ltr:pr-2 rtl:pl-2 rounded-lg bg-n-button-color shadow-[0_1px_2px_0_rgba(27,28,29,0.04)] outline outline-1 -outline-offset-1 outline-n-container h-8"
        >
          <div class="size-5 flex items-center justify-center">
            <Checkbox
              model-value
              @change="removeAttribute(attribute.attributeKey)"
            />
          </div>
          <span class="text-body-main text-n-slate-12">
            {{ attribute.attributeDisplayName }}
          </span>
          <Button
            icon="i-lucide-x"
            slate
            xs
            ghost
            class="!size-4 !rounded-md"
            @click="removeAttribute(attribute.attributeKey)"
          />
        </div>
      </div>
    </div>

    <div v-if="otherAttributes.length > 0" class="flex flex-col gap-2">
      <span class="pt-2 text-label-small text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.OTHER_ATTRIBUTES') }}
      </span>
      <div class="flex flex-wrap gap-2">
        <div
          v-for="attribute in otherAttributes"
          :key="attribute.attributeKey"
          class="inline-flex items-center gap-1 ltr:pl-1 rtl:pr-1 ltr:pr-2 rtl:pl-2 rounded-lg shadow-[0_1px_2px_0_rgba(27,28,29,0.04)] outline outline-1 -outline-offset-1 outline-n-container h-8 bg-n-button-color"
          :class="[
            canSelectMore ? 'cursor-pointer' : 'opacity-50 cursor-not-allowed',
          ]"
          @click="canSelectMore && toggleAttribute(attribute.attributeKey)"
        >
          <div class="size-5 flex items-center justify-center">
            <Checkbox
              :model-value="false"
              :disabled="!canSelectMore"
              @change="toggleAttribute(attribute.attributeKey)"
            />
          </div>
          <span class="text-body-main text-n-slate-12">
            {{ attribute.attributeDisplayName }}
          </span>
          <Button
            v-if="attribute.attributeDescription"
            v-tooltip.top="{
              content: attribute.attributeDescription,
              delay: { show: 500, hide: 0 },
            }"
            icon="i-lucide-info"
            slate
            xs
            ghost
            :disabled="!canSelectMore"
            class="!size-4 !rounded-md"
          />
        </div>
      </div>
    </div>

    <div
      v-if="contactAttributes.length === 0"
      class="flex flex-col items-center justify-center gap-3 py-8"
    >
      <p class="text-body-main text-center text-n-slate-11 m-0">
        {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.NO_ATTRIBUTES') }}
      </p>
    </div>
  </div>
</template>
