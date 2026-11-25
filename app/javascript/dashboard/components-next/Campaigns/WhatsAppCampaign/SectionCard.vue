<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  isDirty: {
    type: Boolean,
    default: false,
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
  isSaveDisabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['discard', 'save']);

const { t } = useI18n();

const isExpanded = ref(true);
</script>

<template>
  <section
    class="flex flex-col w-full rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
  >
    <button
      type="button"
      class="flex items-center justify-between w-full gap-2 px-6 py-5"
      @click="isExpanded = !isExpanded"
    >
      <h2 class="text-heading-2 text-n-slate-12">{{ title }}</h2>
      <span
        class="transition-transform duration-200 size-4 text-n-slate-11 i-lucide-chevron-down"
        :class="{ 'rotate-180': isExpanded }"
      />
    </button>
    <template v-if="isExpanded">
      <div class="flex flex-col gap-4 px-6 pb-6">
        <slot />
      </div>
      <div class="flex items-center justify-between gap-2 px-6 pb-5 w-full">
        <Button
          variant="faded"
          color="slate"
          size="md"
          class="w-full"
          :label="t('CAMPAIGN.WHATSAPP.FORM.DISCARD')"
          :disabled="!isDirty"
          @click="emit('discard')"
        />
        <Button
          size="md"
          :label="t('CAMPAIGN.WHATSAPP.FORM.SAVE')"
          :is-loading="isSaving"
          :disabled="!isDirty || isSaving || isSaveDisabled"
          class="w-full"
          @click="emit('save')"
        />
      </div>
    </template>
  </section>
</template>
