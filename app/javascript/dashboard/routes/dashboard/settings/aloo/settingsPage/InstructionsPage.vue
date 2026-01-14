<script setup>
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  assistant: {
    type: Object,
    required: true,
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'save']);

const updateField = (field, value) => {
  emit('update', { [field]: value });
};
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('ALOO.SETTINGS.INSTRUCTIONS.TITLE')"
      :sub-title="$t('ALOO.SETTINGS.INSTRUCTIONS.DESCRIPTION')"
    >
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.CUSTOM_INSTRUCTIONS.LABEL') }}
          </label>
          <textarea
            :value="assistant.custom_instructions"
            :placeholder="$t('ALOO.FORM.CUSTOM_INSTRUCTIONS.PLACEHOLDER')"
            rows="24"
            class="w-full px-3 py-2 text-sm border rounded-lg resize-y border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 font-mono min-h-[400px]"
            @input="updateField('custom_instructions', $event.target.value)"
          />
          <p class="text-xs text-n-slate-9 mt-2">
            {{ $t('ALOO.FORM.CUSTOM_INSTRUCTIONS.HINT') }}
          </p>
        </div>
        <div class="pt-2">
          <Button :is-loading="isSaving" @click="emit('save')">
            {{ $t('ALOO.ACTIONS.SAVE') }}
          </Button>
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
