<script setup>
import Breadcrumb from './Breadcrumb.vue';
import { ref } from 'vue';

const singleItem = ref([{ label: 'Home', link: '#' }]);

const twoItems = ref([
  { label: 'Home', link: '#' },
  { label: 'Categories', link: '#' },
]);

const threeItems = ref([
  { label: 'Home', link: '#' },
  { label: 'Categories', link: '#' },
  { label: 'Marketing', count: 6 },
]);

const longBreadcrumb = ref([
  { label: 'Home', link: '#' },
  { label: 'Categories', link: '#' },
  { label: 'Marketing', link: '#' },
  { label: 'Digital', link: '#' },
  { label: 'Social Media', count: 12 },
]);
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Components/Breadcrumb"
    :layout="{ type: 'grid', width: '100%' }"
  >
    <Variant title="Single Item">
      <Breadcrumb :items="singleItem" />
    </Variant>

    <Variant title="Two Items">
      <Breadcrumb :items="twoItems" />
    </Variant>

    <Variant title="Three Items with Count">
      <Breadcrumb :items="threeItems" />
    </Variant>

    <Variant title="Long Breadcrumb">
      <Breadcrumb :items="longBreadcrumb" />
    </Variant>

    <Variant title="RTL Support">
      <div dir="rtl">
        <Breadcrumb :items="threeItems" />
      </div>
    </Variant>
  </Story>
</template>
