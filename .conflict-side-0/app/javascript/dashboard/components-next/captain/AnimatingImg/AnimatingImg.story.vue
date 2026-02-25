<script setup>
import Guardrails from './Guardrails.vue';
import Scenarios from './Scenarios.vue';
import ResponseGuidelines from './ResponseGuidelines.vue';
import Settings from './Settings.vue';
</script>

<template>
  <Story
    title="Captain/AnimatingImg/AnimatingImg"
    :layout="{ type: 'grid', width: '300px' }"
  >
    <Variant title="Guardrails">
      <div class="p-4 bg-n-background w-full h-full">
        <Guardrails class="size-60" />
      </div>
    </Variant>
    <Variant title="Scenarios">
      <div class="p-4 bg-n-background w-full h-full">
        <Scenarios class="size-60" />
      </div>
    </Variant>
    <Variant title="ResponseGuidelines">
      <div class="p-4 bg-n-background w-full h-full">
        <ResponseGuidelines class="size-60" />
      </div>
    </Variant>
    <Variant title="Settings">
      <div class="p-4 bg-n-background w-full h-full">
        <Settings class="size-60" />
      </div>
    </Variant>
  </Story>
</template>
