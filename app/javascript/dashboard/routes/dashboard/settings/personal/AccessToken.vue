<template>
  <div class="flex flex-row justify-between gap-4 mb-8">
    <form-input
      name="access_token"
      class="flex-1"
      type="password"
      value="1234567890"
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
      @click="$emit('click')"
    >
      Copy
    </v3-button>
  </div>
</template>
<script setup>
import FormInput from 'v3/components/Form/Input.vue';
import V3Button from 'v3/components/Form/Button.vue';
</script>
