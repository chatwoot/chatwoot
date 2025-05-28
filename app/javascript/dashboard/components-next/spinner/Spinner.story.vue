<script setup>
import Spinner from './Spinner.vue';
</script>

<template>
  <Story title="Components/Spinner" :layout="{ type: 'grid', width: '400' }">
    <Variant title="Default">
      <Spinner size="24" class="text-n-slate-10" />
      <Spinner size="32" class="text-n-ruby-10" />
      <Spinner size="40" class="text-n-amber-10" />
      <Spinner size="48" class="text-n-teal-10" />
      <Spinner size="64" class="text-n-brand" />
    </Variant>
  </Story>
</template>
