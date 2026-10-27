<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import { contactAttributeKey, contactAttributeSource } from './paramSources';

const emit = defineEmits(['remove']);
const { t } = useI18n();
const showErrors = ref(false);
const getAttributesByModel = useMapGetter('attributes/getAttributesByModel');

const name = defineModel('name', {
  type: String,
  required: true,
});

const source = defineModel('source', {
  type: String,
  required: true,
});

const attributeKey = computed({
  get: () => contactAttributeKey(source.value),
  set: key => {
    source.value = contactAttributeSource(key);
  },
});
const readsContactAttribute = computed(() => attributeKey.value !== null);

// Customers cannot write business managed attributes, so only those can fill a parameter
const attributeOptions = computed(() =>
  getAttributesByModel
    .value('contact_attribute')
    .filter(attribute => attribute.business_managed)
    .map(attribute => ({
      value: attribute.attribute_key,
      label: attribute.attribute_display_name,
    }))
);

const validationError = computed(() => {
  if (!name.value || name.value.trim() === '') return 'PARAM_NAME_REQUIRED';
  if (readsContactAttribute.value && !attributeKey.value) {
    return 'CONTACT_ATTRIBUTE_REQUIRED';
  }
  return null;
});

watch([name, source], () => {
  showErrors.value = false;
});

const validate = () => {
  showErrors.value = true;
  return !validationError.value;
};

defineExpose({ validate });
</script>

<template>
  <li class="list-none">
    <div
      class="flex flex-col gap-2 p-3 rounded-lg border border-n-weak"
      :class="{
        'animate-wiggle border-n-ruby-9': showErrors && validationError,
      }"
    >
      <div class="grid grid-cols-3 gap-2">
        <Input
          v-model="name"
          :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_NAME.PLACEHOLDER')"
          class="col-span-2 [&_input]:font-mono"
        />
        <ComboBox
          v-if="readsContactAttribute"
          v-model="attributeKey"
          :options="attributeOptions"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.ATTRIBUTE_PLACEHOLDER')
          "
          class="[&>div>button]:bg-n-alpha-black2"
        />
        <span
          v-else
          class="flex items-center gap-1.5 h-10 px-3 rounded-lg outline outline-1 outline-offset-[-1px] outline-n-weak bg-n-alpha-black2 text-sm text-n-slate-12 min-w-0"
        >
          <span class="i-lucide-lock size-3.5 shrink-0 text-n-slate-11" />
          <span class="truncate">{{
            t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.EMAIL')
          }}</span>
        </span>
      </div>
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-n-slate-11">
          {{
            readsContactAttribute
              ? t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.ATTRIBUTE_HELP')
              : t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.HELP')
          }}
        </span>
        <Button
          type="button"
          ghost
          slate
          xs
          icon="i-lucide-trash-2"
          @click.stop="emit('remove')"
        />
      </div>
      <p
        v-if="readsContactAttribute && !attributeOptions.length"
        class="mb-0 text-sm text-n-amber-11"
      >
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.NO_ATTRIBUTES') }}
      </p>
    </div>
    <span
      v-if="showErrors && validationError"
      class="block mt-1 text-sm text-n-ruby-11"
    >
      {{ t(`CAPTAIN.CUSTOM_TOOLS.FORM.ERRORS.${validationError}`) }}
    </span>
  </li>
</template>
