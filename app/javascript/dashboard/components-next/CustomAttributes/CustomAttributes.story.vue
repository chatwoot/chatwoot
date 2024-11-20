<script setup>
import OtherAttribute from './OtherAttribute.vue';
import ListAttribute from './ListAttribute.vue';
import DateAttribute from './DateAttribute.vue';
import CheckboxAttribute from './CheckboxAttribute.vue';

const componentMap = {
  list: ListAttribute,
  checkbox: CheckboxAttribute,
  date: DateAttribute,
  default: OtherAttribute,
};

// Sample attributes data
const attributes = [
  {
    attributeKey: 'textContact',
    attributeDisplayName: 'Text Input',
    attributeDisplayType: 'text',
    value: 'Sample text value',
  },
  {
    attributeKey: 'linkContact',
    attributeDisplayName: 'URL Input',
    attributeDisplayType: 'link',
    value: 'https://www.chatwoot.com',
  },
  {
    attributeKey: 'numberContact',
    attributeDisplayName: 'Number Input',
    attributeDisplayType: 'number',
    value: '42',
  },
  {
    attributeKey: 'listContact',
    attributeDisplayName: 'List Input',
    attributeDisplayType: 'list',
    value: 'Option 2',
    attributeValues: ['Option 1', 'Option 2', 'Option 3'],
  },
  {
    attributeKey: 'dateContact',
    attributeDisplayName: 'Date Input',
    attributeDisplayType: 'date',
    value: '2024-03-25T00:00:00.000Z',
  },
  {
    attributeKey: 'checkboxContact',
    attributeDisplayName: 'Checkbox Input',
    attributeDisplayType: 'checkbox',
    value: true,
  },
];

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
          v-for="attribute in attributes"
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
          v-for="attribute in attributes"
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
