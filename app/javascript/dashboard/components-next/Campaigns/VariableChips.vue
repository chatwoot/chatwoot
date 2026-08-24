<script setup>
import { useI18n } from 'vue-i18n';
import { CAMPAIGN_MESSAGE_VARIABLES } from 'dashboard/helper/campaignHelper';

defineProps({
  label: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['insert']);

const { t } = useI18n();
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <span class="text-xs text-n-slate-11">
      {{ label || t('CAMPAIGN.VARIABLES.LABEL') }}
    </span>
    <div class="flex flex-wrap gap-1.5">
      <button
        v-for="variable in CAMPAIGN_MESSAGE_VARIABLES"
        :key="variable.name"
        type="button"
        class="px-2 py-0.5 text-xs rounded-md bg-n-alpha-2 text-n-slate-12 hover:bg-n-alpha-3"
        @click="emit('insert', variable.token)"
      >
        {{ variable.token }}
      </button>
    </div>
  </div>
</template>
