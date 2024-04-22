<template>
  <div class="flex flex-row justify-between gap-4 mb-8">
    <form-input
      name="access_token"
      class="flex-1"
      type="password"
      :value="value"
      :class="{ error: false }"
      placeholder="Please enter your new password"
      :has-error="false"
      :error-message="$t('REGISTER.FULL_NAME.ERROR')"
    />
    <v3-button
      type="submit"
      size="large"
      icon="text-copy"
      variant="hollow"
      color-scheme="secondary"
      @click="onClick"
    >
      Copy
    </v3-button>
  </div>
</template>
<script setup>
import FormInput from 'v3/components/Form/Input.vue';
import V3Button from 'v3/components/Form/Button.vue';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

const props = defineProps({
  value: {
    type: String,
    default: '',
  },
});

const onClick = async e => {
  e.preventDefault();
  await copyTextToClipboard(props.value);
};
</script>
