<script setup>
import AllCategories from './AllCategories.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story title="HelpCenter/AllCategories" :layout="{ type: 'single' }">
    <Variant title="All Categories">
      <div class="w-full min-h-screen bg-white dark:bg-slate-900">
        <AllCategories />
      </div>
    </Variant>
  </Story>
</template>
