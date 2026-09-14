<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
  error: {
    type: String,
    default: '',
  },
  loadingLabel: {
    type: String,
    default: '',
  },
  errorTitle: {
    type: String,
    default: '',
  },
  emptyLabel: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="flex justify-center items-center p-8 text-center">
    <div v-if="isLoading" class="flex flex-col gap-2 items-center">
      <Spinner class="text-n-slate-11" />
      <p class="text-body-main text-n-slate-11">{{ loadingLabel }}</p>
    </div>
    <div v-else-if="error" class="flex flex-col gap-2 items-center max-w-lg">
      <Icon icon="i-lucide-plug-zap" class="w-8 h-8 text-n-ruby-11" />
      <p class="text-body-main font-medium text-n-slate-12">
        {{ errorTitle }}
      </p>
      <p class="text-body-main break-words text-n-slate-11">{{ error }}</p>
    </div>
    <div v-else class="flex flex-col gap-2 items-center">
      <Icon icon="i-lucide-activity" class="w-8 h-8 text-n-slate-11" />
      <p class="text-body-main text-n-slate-11">{{ emptyLabel }}</p>
    </div>
  </div>
</template>
