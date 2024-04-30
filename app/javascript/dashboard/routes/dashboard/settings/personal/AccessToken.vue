<template>
  <div class="flex flex-row justify-between gap-4">
    <woot-input
      name="access_token"
      class="flex-1 focus:[&>input]:!border-slate-200 focus:[&>input]:dark:!border-slate-600 [&>input]:cursor-not-allowed"
      :styles="{
        borderRadius: '12px',
        padding: '6px 12px',
        fontSize: '14px',
        marginBottom: '2px',
      }"
      type="password"
      :value="value"
      readonly
    />
    <form-button
      type="submit"
      size="large"
      icon="text-copy"
      variant="outline"
      color-scheme="secondary"
      @click="onClick"
    >
      {{ $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.COPY') }}
    </form-button>
  </div>
</template>
<script setup>
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
