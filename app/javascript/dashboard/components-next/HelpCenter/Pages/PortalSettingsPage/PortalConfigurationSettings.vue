<script setup>
import { reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

const props = defineProps({
  activePortal: {
    type: Object,
    required: true,
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['updatePortalConfiguration']);

const { t } = useI18n();

const configurationState = reactive({
  customDomain: '',
});

const hasCustomDomainConfigured = computed(
  () => props.activePortal.custom_domain
);

watch(
  () => props.activePortal,
  newVal => {
    if (newVal && !props.isFetching) {
      configurationState.customDomain = newVal.custom_domain;
    }
  },
  { immediate: true, deep: true }
);

const handleUpdatePortalConfiguration = () => {
  const portal = {
    id: props.activePortal.id,
    custom_domain: configurationState.customDomain,
  };
  emit('updatePortalConfiguration', portal);
};
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-n-slate-12">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.HEADER'
          )
        }}
      </h6>
      <span class="text-sm text-n-slate-11">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DESCRIPTION'
          )
        }}
      </span>
    </div>
    <div class="flex flex-col w-full gap-4">
      <div class="flex justify-between w-full gap-2">
        <InlineInput
          v-if="hasCustomDomainConfigured"
          v-model="configurationState.customDomain"
          :placeholder="
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.PLACEHOLDER'
            )
          "
          :label="
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.LABEL'
            )
          "
        />
        <div class="flex items-center justify-end w-full">
          <Button
            v-if="hasCustomDomainConfigured"
            :label="
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.EDIT_BUTTON'
              )
            "
            variant="secondary"
            @click="handleUpdatePortalConfiguration"
          />
          <Button
            v-else
            :label="
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.ADD_BUTTON'
              )
            "
            variant="secondary"
            @click="handleUpdatePortalConfiguration"
          />
        </div>
      </div>
    </div>
  </div>
</template>
