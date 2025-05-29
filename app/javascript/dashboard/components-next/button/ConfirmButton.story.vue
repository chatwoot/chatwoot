<script setup>
import ConfirmButton from './ConfirmButton.vue';
import { ref } from 'vue';

const count = ref(0);

const incrementCount = () => {
  count.value += 1;
};
</script>

<template>
  <Story
    title="Components/ConfirmButton"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant title="Basic">
      <div class="grid gap-2 p-4 bg-white dark:bg-slate-900">
        <p>{{ count }}</p>
        <ConfirmButton
          label="Delete"
          confirm-label="Confirm?"
          @click="incrementCount"
        />
      </div>
    </Variant>

    <Variant title="Color Change">
      <div class="grid gap-2 p-4 bg-white dark:bg-slate-900">
        <p>{{ count }}</p>
        <ConfirmButton
          label="Archive"
          confirm-label="Confirm?"
          color="slate"
          confirm-color="amber"
          @click="incrementCount"
        />
      </div>
    </Variant>
  </Story>
</template>
