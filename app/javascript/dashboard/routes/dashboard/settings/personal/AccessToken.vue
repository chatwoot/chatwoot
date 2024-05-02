<template>
  <div class="flex flex-row justify-between gap-4">
    <woot-input
      name="access_token"
      class="flex-1 focus:[&>input]:!border-slate-200 focus:[&>input]:dark:!border-slate-600 [&>input]:cursor-not-allowed relative"
      :styles="{
        borderRadius: '12px',
        padding: '6px 12px',
        fontSize: '14px',
        marginBottom: '2px',
      }"
      :type="inputType"
      :value="value"
      readonly
    >
      <template #masked>
        <button class="cursor-pointer reset-base" @click="toggleMasked">
          <fluent-icon
            class="absolute top-3 ltr:right-4 rtl:left-4"
            :icon="maskedIcon"
            :size="16"
          />
        </button>
      </template>
    </woot-input>
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
import { ref } from 'vue';
import FormButton from 'v3/components/Form/Button.vue';
const props = defineProps({
  value: {
    type: String,
    default: '',
  },
});
const emit = defineEmits(['on-copy']);
const inputType = ref('password');
const maskedIcon = ref('eye-hide');
const toggleMasked = () => {
  inputType.value = inputType.value === 'password' ? 'text' : 'password';
  maskedIcon.value = maskedIcon.value === 'eye-hide' ? 'eye-show' : 'eye-hide';
};
const onClick = () => {
  emit('on-copy', props.value);
};
</script>
