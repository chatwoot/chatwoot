<script setup>
import AddNewRulesInput from './AddNewRulesInput.vue';
</script>

<template>
  <Story
    title="Captain/Assistant/AddNewRulesInput"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Default">
      <div class="bg-surface px-6 py-4">
        <AddNewRulesInput
          placeholder="Type in another response guideline..."
          label="Add and save (↵)"
        />
      </div>
    </Variant>
  </Story>
</template>
