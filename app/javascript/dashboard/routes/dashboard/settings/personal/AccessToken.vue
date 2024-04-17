<template>
  <div class="flex flex-row justify-between gap-4">
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
    <woot-button
      icon="copy"
      variant="hollow"
      color-scheme="secondary"
      class="rounded-xl w-fit"
      @click="$emit('click')"
    >
      Copy
    </woot-button>
  </div>
</template>
<script setup>
import FormInput from 'v3/components/Form/Input.vue';
</script>
