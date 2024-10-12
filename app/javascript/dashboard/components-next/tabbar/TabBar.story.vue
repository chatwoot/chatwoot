<script setup>
import TabBar from './TabBar.vue';

const defaultTabs = [
  { label: 'All articles', count: 24 },
  { label: 'Mine', count: 13 },
  { label: 'Draft', count: 5 },
  { label: 'Archived', count: 11 },
  { label: 'Unpublished', count: 23 },
  { label: 'Published', count: 100 },
  { label: 'Scheduled', count: 49 },
];

const customTabs = [
  { label: 'Active', count: 10 },
  { label: 'Pending', count: 5 },
  { label: 'Completed', count: 15 },
];

const handleTabChanged = tab => {
  console.log('Tab changed:', tab);
};
</script>

<template>
  <Story title="Components/TabBar" :layout="{ type: 'grid', width: '920px' }">
    <Variant title="Default">
      <div class="p-4 bg-white dark:bg-slate-900">
        <TabBar :tabs="defaultTabs" @tab-changed="handleTabChanged" />
      </div>
    </Variant>

    <Variant title="Custom Tabs with Initial Tab">
      <div class="p-4 bg-white dark:bg-slate-900">
        <TabBar
          :tabs="customTabs"
          :initial-active-tab="1"
          @tab-changed="handleTabChanged"
        />
      </div>
    </Variant>

    <Variant title="No Counts">
      <div class="p-4 bg-white dark:bg-slate-900">
        <TabBar
          :tabs="[{ label: 'Tab 1' }, { label: 'Tab 2' }, { label: 'Tab 3' }]"
          @tab-changed="handleTabChanged"
        />
      </div>
    </Variant>

    <Variant title="Single Tab">
      <div class="p-4 bg-white dark:bg-slate-900">
        <TabBar
          :tabs="[{ label: 'Single Tab', count: 42 }]"
          @tab-changed="handleTabChanged"
        />
      </div>
    </Variant>
  </Story>
</template>
