<script setup>
import TabBar from './TabBar.vue';

const defaultTabs = [
  { label: 'All articles', count: 24 },
  { label: 'Mine', count: 13 },
  { label: 'Draft', count: 5 },
  { label: 'Archived', count: 11 },
];

const customTabs = [
  { label: 'Active', count: 10 },
  { label: 'Pending', count: 5 },
  { label: 'Completed', count: 15 },
];

const handleTabChanged = tab => {
  // eslint-disable-next-line no-console
  console.log('Tab changed:', tab);
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story title="Components/TabBar" :layout="{ type: 'grid', width: '700px' }">
    <Variant title="Default">
      <TabBar :tabs="defaultTabs" @tab-changed="handleTabChanged" />
    </Variant>

    <Variant title="Custom Tabs with Initial Tab">
      <TabBar
        :tabs="customTabs"
        :initial-active-tab="2"
        @tab-changed="handleTabChanged"
      />
    </Variant>

    <Variant title="No Counts">
      <TabBar
        :tabs="[{ label: 'Tab 1' }, { label: 'Tab 2' }, { label: 'Tab 3' }]"
        @tab-changed="handleTabChanged"
      />
    </Variant>

    <Variant title="Single Tab">
      <TabBar
        :tabs="[{ label: 'Single Tab', count: 42 }]"
        @tab-changed="handleTabChanged"
      />
    </Variant>
  </Story>
</template>
