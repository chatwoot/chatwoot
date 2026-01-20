<script setup>
import CsatMetricCard from './CsatMetricCard.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Components/Reports/CsatMetricCard"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant title="Default">
      <div class="p-4 bg-n-background">
        <CsatMetricCard
          label="Total Responses"
          tooltip="Total number of responses received"
          value="1,234"
        />
      </div>
    </Variant>

    <Variant title="Percentage Value">
      <div class="p-4 bg-n-background">
        <CsatMetricCard
          label="Satisfaction Score"
          tooltip="Percentage of positive responses"
          value="85%"
        />
      </div>
    </Variant>

    <Variant title="Loading State">
      <div class="p-4 bg-n-background">
        <CsatMetricCard
          label="Response Rate"
          tooltip="Percentage of conversations with responses"
          value="0"
          is-loading
        />
      </div>
    </Variant>

    <Variant title="Zero Value">
      <div class="p-4 bg-n-background">
        <CsatMetricCard
          label="Total Responses"
          tooltip="Total number of responses received"
          value="0"
        />
      </div>
    </Variant>
  </Story>
</template>
