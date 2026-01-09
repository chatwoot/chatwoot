<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper.js';
import FormSelect from 'v3/components/Form/Select.vue';

defineProps({
  label: { type: String, default: '' },
  description: { type: String, default: '' },
});

const { t } = useI18n();
const { updateUISettings, uiSettings } = useUISettings();

const currentTheme = computed(() => {
  return (
    uiSettings.value?.color_scheme ||
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) ||
    'auto'
  );
});

const themeOptions = computed(() => [
  {
    label: t(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.APPEARANCE.OPTIONS.SYSTEM'
    ),
    value: 'auto',
  },
  {
    label: t(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.APPEARANCE.OPTIONS.LIGHT'
    ),
    value: 'light',
  },
  {
    label: t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.APPEARANCE.OPTIONS.DARK'),
    value: 'dark',
  },
]);

const updateTheme = async theme => {
  try {
    LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, theme);
    const isOSOnDarkMode = window.matchMedia(
      '(prefers-color-scheme: dark)'
    ).matches;
    setColorTheme(isOSOnDarkMode);

    await updateUISettings({ color_scheme: theme });

    useAlert(
      t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.APPEARANCE.UPDATE_SUCCESS')
    );
  } catch (error) {
    //
  }
};

const selectedValue = computed({
  get: () => currentTheme.value,
  set: value => {
    updateTheme(value);
  },
});
</script>

<template>
  <div class="flex gap-2 justify-between w-full items-start text-sm">
    <div class="flex flex-col">
      <label class="text-n-gray-12 font-medium leading-6">
        {{ label }}
      </label>
      <p class="text-n-gray-11">
        {{ description }}
      </p>
    </div>
    <FormSelect
      v-model="selectedValue"
      name="appearance"
      spacing="compact"
      class="min-w-28 mt-px"
      :options="themeOptions"
      label=""
    >
      <option
        v-for="option in themeOptions"
        :key="option.value"
        :value="option.value"
        :selected="option.value === selectedValue"
      >
        {{ option.label }}
      </option>
    </FormSelect>
  </div>
</template>
