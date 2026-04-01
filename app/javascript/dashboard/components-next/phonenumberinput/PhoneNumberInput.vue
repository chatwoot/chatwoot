<script setup>
import { ref, computed, watch } from 'vue';
import parsePhoneNumber from 'libphonenumber-js';
import { useI18n } from 'vue-i18n';
import countries from 'shared/constants/countries.js';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, numeric } from '@vuelidate/validators';
import {
  getActiveCountryCode,
  getActiveDialCode,
} from 'shared/components/PhoneInput/helper';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  placeholder: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  showBorder: {
    type: Boolean,
    default: true,
  },
});

const modelValue = defineModel({
  type: [String, Number],
  default: '',
});

const { t } = useI18n();

const showDropdown = ref(false);
const searchQuery = ref('');
const activeCountryCode = ref(getActiveCountryCode());
const activeDialCode = ref(getActiveDialCode());
const phoneNumber = ref('');

const rules = {
  phoneNumber: {
    minLength: minLength(2),
    numeric,
  },
  activeDialCode: {
    required,
    validDialCode: value => {
      return countries.some(country => country.dial_code === value);
    },
  },
};

const v$ = useVuelidate(rules, {
  phoneNumber,
  activeDialCode,
});

const hasError = computed(() => v$.value.$invalid);

const countryList = computed(() => {
  return countries.map(country => ({
    value: country.id,
    label: country.name,
    dialCode: country.dial_code,
    emoji: country.emoji,
    isSelected: String(activeCountryCode.value) === String(country.id),
    action: 'phoneNumberInput',
  }));
});

const filteredCountries = computed(() => {
  const query = searchQuery.value.toLowerCase();
  return countryList.value.filter(({ label, dialCode, value }) =>
    [label, dialCode, value].some(field => field.toLowerCase().includes(query))
  );
});

const activeCountry = computed(() =>
  activeCountryCode.value
    ? countryList.value.find(
        country => country.value === activeCountryCode.value
      )
    : ''
);

const wrapperBorderClass = computed(() => {
  if (hasError.value) {
    return 'border-error';
  }
  if (!props.showBorder) {
    return 'border-outline-variant/25 hover:border-outline-variant/40 focus-within:border-secondary focus-within:ring-1 focus-within:ring-secondary/25';
  }
  return 'border-outline-variant/30 hover:border-outline-variant/50 focus-within:border-secondary focus-within:ring-1 focus-within:ring-secondary/25';
});

const phoneNumberError = computed(() => {
  if (!v$.value.$dirty) return '';
  return v$.value.activeDialCode.$invalid
    ? t('PHONE_INPUT.DIAL_CODE_ERROR')
    : v$.value.phoneNumber.$invalid && t('PHONE_INPUT.ERROR');
});

const emitPhoneNumber = value => {
  const newValue = value ? `${activeDialCode.value}${value}` : '';
  modelValue.value = newValue;
};

const onSelectCountry = async ({ value, dialCode }) => {
  if (!value || !showDropdown.value) return;

  activeCountryCode.value = value;
  activeDialCode.value = dialCode;
  searchQuery.value = '';
  showDropdown.value = false;
  if (!v$.value.$invalid && phoneNumber.value) {
    emitPhoneNumber(phoneNumber.value);
  }
};

const toggleCountryDropdown = () => {
  showDropdown.value = !showDropdown.value;
};

const closeCountryDropdown = () => {
  showDropdown.value = false;
};

watch(phoneNumber, async value => {
  await v$.value.$touch();
  if (!v$.value.$invalid) {
    emitPhoneNumber(value);
  }
});

watch(
  modelValue,
  newValue => {
    const number = parsePhoneNumber(newValue);
    if (number) {
      if (number?.country) activeCountryCode.value = number.country;
      if (number?.countryCallingCode)
        activeDialCode.value = `+${number.countryCallingCode}`;
      phoneNumber.value = newValue.replace(`+${number.countryCallingCode}`, '');
    }
  },
  { immediate: true }
);
</script>

<template>
  <div>
    <div
      v-on-clickaway="() => closeCountryDropdown()"
      class="relative flex h-10 items-center rounded-lg border border-solid bg-surface-container-lowest transition-all duration-200"
      :class="[
        wrapperBorderClass,
        { 'cursor-not-allowed opacity-50': disabled },
      ]"
    >
      <Input
        v-model="phoneNumber"
        type="tel"
        :placeholder="placeholder"
        :disabled="disabled"
        custom-input-class="!h-10 !border-0 !bg-transparent !py-0 !outline-none ltr:!pl-1 rtl:!pr-1"
        class="w-full !flex-row"
      >
        <template #prefix>
          <div class="flex shrink-0 items-center">
            <Button
              ghost
              slate
              sm
              :icon="
                !activeCountry ? 'i-lucide-globe' : 'i-lucide-chevron-down'
              "
              trailing-icon
              :disabled="disabled"
              type="button"
              class="!h-9 shrink-0 !rounded-lg border-0 border-r border-outline-variant/15 !px-2 ltr:!rounded-r-none rtl:!rounded-l-none rtl:!border-l rtl:!border-r-0"
              @click="toggleCountryDropdown"
            >
              <span
                v-if="activeCountry"
                class="inline-flex justify-center whitespace-nowrap text-sm leading-none"
              >
                {{ activeCountry.emoji }}
              </span>
            </Button>
            <span
              v-if="activeCountry"
              class="text-sm text-on-surface-variant ltr:!pl-2 rtl:!pr-2"
            >
              {{ activeDialCode }}
            </span>
          </div>
        </template>
      </Input>
      <DropdownMenu
        v-if="showDropdown"
        :menu-items="filteredCountries"
        show-search
        class="z-[100] w-48 mt-2 overflow-y-auto ltr:left-0 rtl:right-0 top-full max-h-52"
        @action="onSelectCountry"
      />
    </div>
    <template v-if="phoneNumberError">
      <p
        v-if="phoneNumberError"
        class="mb-0 mt-1 min-w-0 truncate text-xs text-error transition-all duration-200"
      >
        {{ phoneNumberError }}
      </p>
    </template>
  </div>
</template>
