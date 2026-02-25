<script setup>
import { defineModel, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  authType: {
    type: String,
    required: true,
    validator: value => ['none', 'bearer', 'basic', 'api_key'].includes(value),
  },
});

const { t } = useI18n();

const authConfig = defineModel('authConfig', {
  type: Object,
  default: () => ({}),
});

watch(
  () => props.authType,
  () => {
    authConfig.value = {};
  }
);
</script>

<template>
  <div class="flex flex-col gap-2">
    <Input
      v-if="authType === 'bearer'"
      v-model="authConfig.token"
      :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.BEARER_TOKEN')"
      :placeholder="
        t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.BEARER_TOKEN_PLACEHOLDER')
      "
    />
    <template v-else-if="authType === 'basic'">
      <Input
        v-model="authConfig.username"
        :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.USERNAME')"
        :placeholder="
          t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.USERNAME_PLACEHOLDER')
        "
      />
      <Input
        v-model="authConfig.password"
        type="password"
        :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.PASSWORD')"
        :placeholder="
          t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.PASSWORD_PLACEHOLDER')
        "
      />
    </template>
    <template v-else-if="authType === 'api_key'">
      <Input
        v-model="authConfig.name"
        :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.API_KEY')"
        :placeholder="
          t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.API_KEY_PLACEHOLDER')
        "
      />
      <Input
        v-model="authConfig.key"
        :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.API_VALUE')"
        :placeholder="
          t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_CONFIG.API_VALUE_PLACEHOLDER')
        "
      />
    </template>
  </div>
</template>
