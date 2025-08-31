<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const footerData = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});

const updateFooterText = value => {
  footerData.value = {
    ...footerData.value,
    text: value,
  };
};
</script>

<template>
  <div class="bg-n-solid-2 rounded-lg p-4 border border-n-weak">
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-3">
        <span class="i-lucide-panel-bottom size-5 text-n-slate-11" />
        <h4 class="font-medium text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.BUILDER.FOOTER.TITLE') }}
        </h4>
        <span class="text-xs text-n-slate-11 bg-n-solid-3 px-2 py-1 rounded">
          {{ t('SETTINGS.TEMPLATES.BUILDER.OPTIONAL') }}
        </span>
      </div>
      <div class="flex items-center">
        <Switch v-model="footerData.enabled" />
      </div>
    </div>

    <div v-if="footerData.enabled" class="space-y-4">
      <!-- Footer Text -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.BUILDER.FOOTER.TEXT_LABEL') }}
        </label>
        <Input
          :model-value="footerData.text"
          :placeholder="t('SETTINGS.TEMPLATES.BUILDER.FOOTER.TEXT_PLACEHOLDER')"
          show-character-count
          :max-length="60"
          @update:model-value="updateFooterText"
        />
        <div class="mt-1">
          <span class="text-xs text-n-slate-11">
            {{ t('SETTINGS.TEMPLATES.BUILDER.FOOTER.TEXT_HELP') }}
          </span>
        </div>
      </div>

      <!-- Footer Guidelines -->
      <div class="text-xs text-n-slate-11 bg-n-alpha-2 p-3 rounded-lg">
        <span class="i-lucide-info size-3 mr-1" />
        {{ t('SETTINGS.TEMPLATES.BUILDER.FOOTER.GUIDELINES') }}
      </div>
    </div>

    <div v-else class="text-center py-8 text-n-slate-11">
      <span
        class="i-lucide-layout-panel-bottom size-12 mx-auto mb-3 opacity-50"
      />
      <p class="text-sm">
        {{ t('SETTINGS.TEMPLATES.BUILDER.FOOTER.DISABLED_TEXT') }}
      </p>
    </div>
  </div>
</template>
