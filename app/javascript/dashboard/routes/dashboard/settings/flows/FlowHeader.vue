<script setup>
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';

defineProps({
  name: { type: String, default: '' },
  description: { type: String, default: '' },
  category: { type: String, default: '' },
  saving: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:name',
  'update:description',
  'update:category',
  'open-exit',
  'submit',
]);

const { t } = useI18n();
</script>

<template>
  <div
    class="flex-shrink-0 border-b border-n-weak bg-n-solid-2 px-4 py-3 w-full"
  >
    <div class="flex flex-col lg:flex-row lg:items-end gap-3 w-full">
      <NextInput
        class="flex-1 min-w-[12rem]"
        :model-value="name"
        :label="t('FLOWS.ADD.FORM.NAME.LABEL')"
        :placeholder="t('FLOWS.ADD.FORM.NAME.PLACEHOLDER')"
        @update:model-value="emit('update:name', $event)"
      />
      <NextInput
        class="flex-1 min-w-[12rem]"
        :model-value="description"
        :label="t('FLOWS.ADD.FORM.DESCRIPTION.LABEL')"
        :placeholder="t('FLOWS.ADD.FORM.DESCRIPTION.PLACEHOLDER')"
        @update:model-value="emit('update:description', $event)"
      />
      <NextInput
        class="w-full lg:w-44 flex-shrink-0"
        :model-value="category"
        :label="t('FLOWS.ADD.FORM.CATEGORY.LABEL')"
        :placeholder="t('FLOWS.ADD.FORM.CATEGORY.PLACEHOLDER')"
        @update:model-value="emit('update:category', $event)"
      />
      <!-- Same label + h-10 control stack as NextInput -->
      <div class="relative flex flex-col min-w-0 gap-1 flex-shrink-0">
        <span
          class="mb-0.5 text-heading-3 invisible select-none pointer-events-none"
          aria-hidden="true"
        >
          {{ t('FLOWS.HEADER_BTN_TXT_SAVE') }}
        </span>
        <div class="flex items-center gap-2 h-10">
          <NextButton
            slate
            faded
            class="!h-10 !min-h-10 !px-3 !py-0"
            :label="t('FLOWS.EXIT.OPEN_BUTTON')"
            @click="emit('open-exit')"
          />
          <NextButton
            blue
            solid
            class="!h-10 !min-h-10 !px-3 !py-0"
            :label="t('FLOWS.HEADER_BTN_TXT_SAVE')"
            :is-loading="saving"
            @click="emit('submit')"
          />
        </div>
      </div>
    </div>
  </div>
</template>
