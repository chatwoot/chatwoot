<script setup>
import Switch from './Switch.vue';
import { ref } from 'vue';

// Default varian
const isEnabled = ref(false);

// States variant
const defaultValue = ref(false);
const checkedValue = ref(true);

// Events variant
const eventValue = ref(false);
const lastChange = ref('No changes yet');

const onChange = value => {
  lastChange.value = `Changed to: ${value} at ${new Date().toLocaleTimeString()}`;
};
</script>

<template>
  <Story title="Components/Switch" :layout="{ type: 'grid', width: '200px' }">
    <Variant title="Default">
      <div class="p-2">
        <Switch v-model="isEnabled" />
      </div>
    </Variant>

    <Variant title="States">
      <div class="p-2 space-y-4">
        <div class="flex items-center gap-4">
          <span class="w-20">Default:</span>
          <Switch v-model="defaultValue" />
        </div>

        <div class="flex items-center gap-4">
          <span class="w-20">Checked:</span>
          <Switch v-model="checkedValue" />
        </div>
      </div>
    </Variant>

    <Variant title="Events">
      <div class="p-2 space-y-4">
        <Switch v-model="eventValue" @change="onChange" />
        <div class="text-sm text-gray-600">Last change: {{ lastChange }}</div>
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="p-2">
        <Switch v-model="isEnabled" disabled />
      </div>
    </Variant>
  </Story>
</template>
