<script setup>
import Attributes from './fixtures';

import OtherAttribute from '../OtherAttribute.vue';
import ListAttribute from '../ListAttribute.vue';
import DateAttribute from '../DateAttribute.vue';
import CheckboxAttribute from '../CheckboxAttribute.vue';

const componentMap = {
  list: ListAttribute,
  checkbox: CheckboxAttribute,
  date: DateAttribute,
  default: OtherAttribute,
};

const getCurrentComponent = type => {
  return componentMap[type] || componentMap.default;
};

const handleUpdate = (type, value) => {
  console.log(`${type} updated:`, value);
};

const handleDelete = type => {
  console.log(`${type} deleted`);
};
</script>

<template>
  <Story
    title="Components/CustomAttributes"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Create View">
      <div class="flex flex-col gap-4 p-4 border rounded-lg border-n-strong">
        <div
          v-for="attribute in Attributes"
          :key="attribute.attributeKey"
          class="grid grid-cols-[140px,1fr] group-hover/attribute items-center gap-1 min-h-10"
        >
          <div class="flex items-center justify-between truncate">
            <span class="text-sm font-medium text-n-slate-12">
              {{ attribute.attributeDisplayName }}
            </span>
          </div>
          <component
            :is="getCurrentComponent(attribute.attributeDisplayType)"
            :attribute="attribute"
            @update="
              value => handleUpdate(attribute.attributeDisplayType, value)
            "
            @delete="() => handleDelete(attribute.attributeDisplayType)"
          />
        </div>
      </div>
    </Variant>

    <Variant title="Saved View">
      <div class="flex flex-col gap-4 p-4 border rounded-lg border-n-strong">
        <div
          v-for="attribute in Attributes"
          :key="attribute.attributeKey"
          class="grid grid-cols-[140px,1fr] group-hover/attribute items-center gap-1 min-h-10"
        >
          <div class="flex items-center justify-between truncate">
            <span class="text-sm font-medium text-n-slate-12">
              {{ attribute.attributeDisplayName }}
            </span>
          </div>
          <component
            :is="getCurrentComponent(attribute.attributeDisplayType)"
            :attribute="attribute"
            is-editing-view
            @update="
              value => handleUpdate(attribute.attributeDisplayType, value)
            "
            @delete="() => handleDelete(attribute.attributeDisplayType)"
          />
        </div>
      </div>
    </Variant>
  </Story>
</template>
