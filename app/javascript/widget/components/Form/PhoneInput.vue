<script setup>
import { ref } from 'vue';

// مقدار ثابت کشور
const activeCountryCode = ref('IR'); // کد کشور ایران
const activeDialCode = ref('+98'); // کد تماس ایران
const phoneNumber = ref(''); // ورودی شماره تلفن

// تابع تغییر مقدار شماره تلفن
function onChange(e) {
  phoneNumber.value = e.target.value;
}
</script>

<template>
  <div class="relative mt-2 phone-input--wrap">
    <div
      class="flex items-center justify-start w-full border border-solid rounded outline-none phone-input"
    >
      <!-- نمایش ثابت پرچم یا آیکون کشور -->
      <div
        class="flex items-center justify-between h-full px-2 py-2 cursor-pointer country-emoji--wrap"
      >
        <h5 class="mb-0 text-xl">🇮🇷</h5>
      </div>

      <!-- نمایش کد کشور ثابت -->
      <span class="py-2 pl-2 pr-0 text-base"> {{ activeDialCode }} </span>

      <!-- فیلد شماره تلفن -->
      <input
        :value="phoneNumber"
        type="text"
        class="w-full h-full py-2 pl-2 pr-3 leading-tight border-0 rounded-r outline-none"
        name="phoneNumber"
        placeholder="Enter your phone number"
        @input="onChange"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.phone-input--wrap {
  .phone-input {
    height: 2.8rem;
  }

  .country-emoji--wrap {
    border-bottom-left-radius: 0.18rem;
    border-top-left-radius: 0.18rem;
    min-width: 3.6rem;
    width: 3.6rem;
  }
}
</style>
