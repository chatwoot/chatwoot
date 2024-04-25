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
    <form-button
      type="submit"
      size="large"
      icon="text-copy"
      variant="ghost"
      color-scheme="secondary"
      @click="onClick"
    >
      {{ $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.COPY') }}
    </form-button>
  </div>
</template>
<script setup>
import FormInput from 'v3/components/Form/Input.vue';
import FormButton from 'v3/components/Form/Button.vue';

const props = defineProps({
  value: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['on-copy']);

const onClick = () => {
  emit('on-copy', props.value);
};
</script>
