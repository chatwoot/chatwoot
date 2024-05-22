<script setup>
import FormButton from 'v3/components/Form/Button.vue';

const emits = defineEmits(['on-dismiss']);

const onDismiss = () => {
  emits('on-dismiss');
};
</script>

<template>
  <div
    class="absolute flex flex-col items-start bg-ash-50 dark:bg-slate-800 z-50 px-4 py-3 border border-solid border-ash-200 w-[270px] rounded-xl gap-4 max-h-96 overflow-auto"
  >
    <div class="flex flex-col w-full">
      <div class="flex flex-row justify-between">
        <img
          class="w-8 h-8"
          :src="`/dashboard/images/integrations/linear.png`"
          alt="Linear-logo"
        />
        <div class="flex items-center">
          <woot-button
            variant="clear"
            icon="dismiss"
            color-scheme="secondary"
            @click="onDismiss"
          />
        </div>
      </div>

      <span class="mt-3 font-medium text-ash-900">Connect to Linear</span>
      <span class="mt-2 text-sm text-ash-800">
        Create Linear issues from conversations, or link existing ones for
        seamless tracking.
      </span>
      <form-button
        type="submit"
        size="large"
        class="justify-center w-full mt-6"
        variant="solid"
        color-scheme="secondary"
      >
        Connect to Linear
      </form-button>
    </div>
  </div>
</template>
