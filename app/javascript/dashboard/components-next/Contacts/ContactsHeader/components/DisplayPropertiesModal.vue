<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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
  return contactAttributes.value.filter(attr =>
    selectedAttributeKeys.value.includes(attr.attributeKey)
  );
});

const otherAttributes = computed(() => {
  return contactAttributes.value.filter(
    attr => !selectedAttributeKeys.value.includes(attr.attributeKey)
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

const dialogRef = ref(null);

const handleClose = () => {
  // Close the dialog after saving
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.TITLE')"
    :confirm-button-label="t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.SAVE')"
    :cancel-button-label="t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.CANCEL')"
    width="2xl"
    @confirm="handleClose"
  >
    <div class="flex flex-col gap-6">
      <p class="text-body-main text-n-slate-11 m-0">
        {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.DESCRIPTION') }}
      </p>

      <div v-if="selectedAttributes.length > 0" class="flex flex-col gap-3">
        <h3 class="text-heading-3 text-n-slate-12 m-0">
          {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.SELECTED_ATTRIBUTES') }}
        </h3>
        <div class="flex flex-wrap gap-2">
          <div
            v-for="attribute in selectedAttributes"
            :key="attribute.attributeKey"
            class="inline-flex items-center gap-2 px-3 py-1.5 rounded-md bg-n-brand-alpha text-n-brand border border-n-brand"
          >
            <Checkbox
              model-value
              @change="removeAttribute(attribute.attributeKey)"
            />
            <span class="text-label-main">
              {{ attribute.attributeDisplayName }}
            </span>
            <button
              class="flex items-center justify-center size-4 rounded hover:bg-n-brand-alpha-hover transition-colors"
              @click="removeAttribute(attribute.attributeKey)"
            >
              <Icon icon="i-lucide-x" class="size-3" />
            </button>
          </div>
        </div>
      </div>

      <div v-if="otherAttributes.length > 0" class="flex flex-col gap-3">
        <h3 class="text-heading-3 text-n-slate-12 m-0">
          {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.OTHER_ATTRIBUTES') }}
        </h3>
        <div class="flex flex-wrap gap-2">
          <div
            v-for="attribute in otherAttributes"
            :key="attribute.attributeKey"
            class="inline-flex items-center gap-2 px-3 py-1.5 rounded-md transition-colors"
            :class="[
              canSelectMore
                ? 'bg-n-alpha-2 hover:bg-n-alpha-3 cursor-pointer border border-n-weak'
                : 'bg-n-alpha-1 border border-n-weak opacity-50 cursor-not-allowed',
            ]"
            @click="canSelectMore && toggleAttribute(attribute.attributeKey)"
          >
            <Checkbox
              :model-value="false"
              :disabled="!canSelectMore"
              @change="toggleAttribute(attribute.attributeKey)"
            />
            <span class="text-label-main text-n-slate-12">
              {{ attribute.attributeDisplayName }}
            </span>
            <Icon
              v-if="attribute.attributeDescription"
              v-tooltip.top="{
                content: attribute.attributeDescription,
                delay: { show: 500, hide: 0 },
              }"
              icon="i-lucide-info"
              class="size-3.5 text-n-slate-11"
            />
          </div>
        </div>
      </div>

      <div
        v-if="contactAttributes.length === 0"
        class="flex flex-col items-center justify-center gap-3 py-8"
      >
        <Icon
          icon="i-lucide-inbox"
          class="size-12 text-n-slate-11 opacity-50"
        />
        <p class="text-body-main text-n-slate-11 m-0">
          {{ t('CONTACTS_LAYOUT.DISPLAY_PROPERTIES.NO_ATTRIBUTES') }}
        </p>
      </div>
    </div>
  </Dialog>
</template>
