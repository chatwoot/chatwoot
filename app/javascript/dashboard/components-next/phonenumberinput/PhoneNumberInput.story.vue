<script setup>
import { ref } from 'vue';
import PhoneNumberInput from './PhoneNumberInput.vue';

const phoneNumber = ref('+14155552671');
</script>

<template>
  <Story
    title="Components/PhoneNumberInput"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant title="Default">
      <div class="flex flex-col gap-4 p-4 h-[300px]">
        <PhoneNumberInput
          v-model="phoneNumber"
          placeholder="Enter phone number"
        />
        <div class="text-sm">Phone number value: {{ phoneNumber }}</div>
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="flex flex-col gap-4 p-4 h-[300px]">
        <PhoneNumberInput
          v-model="phoneNumber"
          placeholder="Enter phone number"
          disabled
        />
      </div>
    </Variant>

    <Variant title="Without Border">
      <div class="flex flex-col gap-4 p-4 h-[300px]">
        <PhoneNumberInput
          v-model="phoneNumber"
          placeholder="Enter phone number"
          :show-border="false"
        />
      </div>
    </Variant>

    <Variant title="Empty State auto select based on time zone">
      <div class="flex flex-col gap-4 p-4 h-[300px]">
        <PhoneNumberInput placeholder="Enter phone number" />
      </div>
    </Variant>
  </Story>
</template>
