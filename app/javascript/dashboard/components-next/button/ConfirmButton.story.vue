<script setup>
import ConfirmButton from './ConfirmButton.vue';
</script>

<template>
  <Story
    title="Components/ConfirmButton"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant title="Basic">
      <div class="flex gap-2 p-4 bg-white dark:bg-slate-900">
        <ConfirmButton
          label="Delete"
          confirm-label="Hold to confirm"
          @click="() => alert('Deleted!')"
        />
      </div>
    </Variant>

    <Variant title="Color Change">
      <div class="flex gap-2 p-4 bg-white dark:bg-slate-900">
        <ConfirmButton
          label="Archive"
          confirm-label="Hold to confirm"
          color="slate"
          confirm-color="amber"
          @click="() => alert('Archived!')"
        />
      </div>
    </Variant>
  </Story>
</template>
