<script setup>
import { ref } from 'vue';

const activeCountryCode = ref('IR'); // کشور ثابت
const activeDialCode = ref('+98'); // کد ثابت
const phoneNumber = ref(''); // ورودی شماره تلفن


const countriesList = [
  {
    name: 'United States',
    dial_code: '+1',
    emoji: '🇺🇸',
    id: 'US',
  },
];

const countries = computed(() => countriesList); // فقط همان کشور را نمایش می‌دهد

// غیرفعال کردن جستجو و نمایش منو
const showDropdown = ref(false); // منوی کشورها دیگر نمایش داده نمی‌شود

// حذف جستجو از لیست
function toggleCountryDropdown() {
  // هیچ‌کاری انجام نمی‌شود چون منو غیر فعال است
}</script>

<template>
<div class="relative mt-2 phone-input--wrap">
  <div
    class="flex items-center justify-start w-full border border-solid rounded outline-none phone-input"
    :class="inputHasError"
  >
    <div
      class="flex items-center justify-between h-full px-2 py-2 country-emoji--wrap"
      :class="dropdownClass"
    >
      <h5 v-if="activeCountry.emoji" class="mb-0 text-xl">
        {{ activeCountry.emoji }}
      </h5>
      <span
        v-if="activeDialCode"
        class="py-2 pl-2 pr-0 text-base"
        :class="$dm('text-slate-700', 'dark:text-slate-50')"
      >
        {{ activeDialCode }}
      </span>
    </div>
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

  .country-dropdown {
    min-width: 6rem;
    max-width: 14.8rem;
    width: 100%;
  }
}
</style>
