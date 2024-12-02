<script setup>
import { ref, computed } from 'vue';
import { useDarkMode } from 'widget/composables/useDarkMode';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

const { context } = defineProps({
  context: {
    type: Object,
    default: () => ({}),
  },
});

const localValue = ref(context.value || '');

const { getThemeClass: $dm } = useDarkMode();

const phoneNumber = ref('');

const placeholder = computed(() => context?.attrs?.placeholder || '');
const hasErrorInPhoneInput = computed(() => context.hasErrorInPhoneInput);

const inputLightAndDarkModeColor = computed(() =>
  $dm('bg-white text-slate-700', 'dark:bg-slate-600 dark:text-slate-50')
);

const inputBorderColor = computed(
  () => `${$dm('border-black-200', 'dark:border-black-500')}`
);

const inputHasError = computed(() =>
  hasErrorInPhoneInput.value
    ? `border-red-200 hover:border-red-300 focus:border-red-300 ${inputLightAndDarkModeColor.value}`
    : `hover:border-black-300 focus:border-black-300 ${inputLightAndDarkModeColor.value} ${inputBorderColor.value}`
);

function setContextValue() {
  // This function is used to set the context value.
  // The context value is used to set the value of the phone number field in the pre-chat form.
  localValue.value = `+98${phoneNumber.value}`;
  context.node.input(localValue.value);
}

function onChange(e) {
  phoneNumber.value = e.target.value;
  // This function is used to set the context value when the user types in the phone number field.
  setContextValue();
}
</script>

<template>
  <div class="relative mt-2 phone-input--wrap">
    <div
      style="direction: ltr;" class="flex items-center justify-start w-full border border-solid rounded outline-none phone-input"
      :class="inputHasError"
    >
      <div
        class="flex items-center justify-between h-full px-2 py-2 cursor-pointer country-emoji--wrap"
        :class="$dm('bg-slate-100 text-slate-700', 'dark:bg-slate-700 dark:text-slate-50')"
      >
        <h5 class="mb-0 text-xl">🇮🇷</h5>
      </div>
      <span
        class="py-2 pl-2 pr-0 text-base"
        :class="$dm('text-slate-700', 'dark:text-slate-50')"
      >
        +98
      </span>
      <input
        :value="phoneNumber"
        type="phoneInput"
        class="w-full h-full py-2 pl-2 pr-3 leading-tight border-0 rounded-r outline-none"
        name="phoneNumber"
        :placeholder="placeholder"
        :class="inputLightAndDarkModeColor"
        @input="onChange"
        @blur="context.blurHandler"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import 'widget/assets/scss/variables.scss';

.phone-input--wrap {
  .phone-input {
    height: 2.8rem;

    input:placeholder-shown {
      text-overflow: ellipsis;
      direction: rtl;
    }
  }

  .country-emoji--wrap {
    border-bottom-left-radius: 0.18rem;
    border-top-left-radius: 0.18rem;
    min-width: 3.6rem;
    width: 3.6rem;
  }
}
</style>
