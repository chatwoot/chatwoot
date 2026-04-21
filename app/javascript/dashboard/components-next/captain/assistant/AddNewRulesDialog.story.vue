<script setup>
import AddNewRulesDialog from './AddNewRulesDialog.vue';
</script>

<template>
  <Story
    title="Captain/Assistant/AddNewRulesDialog"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Default">
      <div class="px-4 py-4 bg-n-background h-[200px]">
        <AddNewRulesDialog
          button-label="Add a guardrail"
          placeholder="Type in another guardrail..."
          confirm-label="Create"
          cancel-label="Cancel"
        />
      </div>
    </Variant>
  </Story>
</template>
