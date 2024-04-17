<template>
  <div class="flex flex-col w-full gap-4">
    <h4 class="text-lg font-medium text-slate-900 dark:text-slate-25">
      Change password
    </h4>
    <div class="flex flex-row items-center justify-between gap-4">
      <div class="flex-grow h-0.5 bg-slate-50 dark:bg-slate-700" />
    </div>
    <form-input
      name="current_password"
      class="flex-1"
      :class="{ error: false }"
      label="Current password"
      placeholder="Please enter your current password"
      :has-error="false"
      error-message="Please enter your current password"
    />
    <form-input
      name="new_password"
      class="flex-1"
      :class="{ error: false }"
      label="New password"
      placeholder="Please enter your new password"
      :has-error="false"
      error-message="Please enter your new password"
    />

    <form-input
      name="confirm_password"
      class="flex-1"
      :class="{ error: false }"
      label="Confirm password"
      placeholder="Please confirm your new password"
      :has-error="false"
      error-message="Please confirm your new password"
    />
    <woot-button
      color-scheme="primary"
      class="rounded-xl w-fit"
      @click="$emit('click')"
    >
      Update password
    </woot-button>
  </div>
</template>
<script setup>
import FormInput from 'v3/components/Form/Input.vue';
</script>
