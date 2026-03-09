<script setup>
import AddLabel from '../AddLabel.vue';
import { labelMenuItems } from './fixtures';

function onUpdateLabel(label) {
  console.log('Label updated:', label);
}
</script>

<template>
  <Story title="Components/Label/Add Label">
    <Variant title="Default (button with label menu items with active state)">
      <div class="h-[300px] p-4">
        <AddLabel
          :label-menu-items="labelMenuItems"
          @update-label="onUpdateLabel"
        />
      </div>
    </Variant>

    <Variant title="Empty List (button with empty label menu)">
      <div class="h-[300px] p-4">
        <AddLabel :label-menu-items="[]" @update-label="onUpdateLabel" />
      </div>
    </Variant>
  </Story>
</template>
