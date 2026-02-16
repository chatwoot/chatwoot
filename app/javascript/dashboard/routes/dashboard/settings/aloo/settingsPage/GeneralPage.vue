<script setup>
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Input from 'dashboard/components-next/input/Input.vue';
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
      :title="$t('ALOO.SETTINGS.GENERAL.TITLE')"
      :sub-title="$t('ALOO.SETTINGS.GENERAL.DESCRIPTION')"
    >
      <div class="space-y-6">
        <Input
          :model-value="assistant.name"
          :label="$t('ALOO.FORM.NAME.LABEL')"
          :placeholder="$t('ALOO.FORM.NAME.PLACEHOLDER')"
          @update:model-value="updateField('name', $event)"
        />
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.DESCRIPTION.LABEL') }}
          </label>
          <textarea
            :value="assistant.description"
            :placeholder="$t('ALOO.FORM.DESCRIPTION.PLACEHOLDER')"
            rows="4"
            class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            @input="updateField('description', $event.target.value)"
          />
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
