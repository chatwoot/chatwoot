<script setup>
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
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

const features = [
  {
    key: 'handoff_enabled',
    adminKey: 'feature_handoff',
    label: 'ALOO.SETTINGS.FEATURES.HANDOFF.LABEL',
    description: 'ALOO.SETTINGS.FEATURES.HANDOFF.DESCRIPTION',
  },
  {
    key: 'resolve_enabled',
    adminKey: 'feature_resolve',
    label: 'ALOO.SETTINGS.FEATURES.RESOLVE.LABEL',
    description: 'ALOO.SETTINGS.FEATURES.RESOLVE.DESCRIPTION',
  },
  {
    key: 'snooze_enabled',
    adminKey: 'feature_snooze',
    label: 'ALOO.SETTINGS.FEATURES.SNOOZE.LABEL',
    description: 'ALOO.SETTINGS.FEATURES.SNOOZE.DESCRIPTION',
  },
  {
    key: 'labels_enabled',
    adminKey: 'feature_labels',
    label: 'ALOO.SETTINGS.FEATURES.LABELS.LABEL',
    description: 'ALOO.SETTINGS.FEATURES.LABELS.DESCRIPTION',
  },
];

const updateFeature = (adminKey, value) => {
  emit('update', { admin_config: { [adminKey]: value } });
};
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('ALOO.SETTINGS.FEATURES.TITLE')"
      :sub-title="$t('ALOO.SETTINGS.FEATURES.DESCRIPTION')"
    >
      <div class="space-y-4">
        <div
          v-for="feature in features"
          :key="feature.key"
          class="flex items-center justify-between p-4 rounded-lg bg-n-alpha-1 border border-n-weak"
        >
          <div class="flex-1 mr-4">
            <p class="text-sm font-medium text-n-slate-12">
              {{ $t(feature.label) }}
            </p>
            <p class="text-xs text-n-slate-11">
              {{ $t(feature.description) }}
            </p>
          </div>
          <Switch
            :model-value="assistant.features?.[feature.key] ?? true"
            @update:model-value="updateFeature(feature.adminKey, $event)"
          />
        </div>

        <div class="pt-4">
          <Button :is-loading="isSaving" @click="emit('save')">
            {{ $t('ALOO.ACTIONS.SAVE') }}
          </Button>
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
