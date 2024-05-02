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
        <button
          class="absolute top-1.5 ltr:right-0.5 rtl:left-0.5"
          @click="toggleMasked"
        >
          <fluent-icon
            :icon="`${inputType === 'password' ? 'eye-hide' : 'eye-show'}`"
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
const toggleMasked = () => {
  inputType.value = inputType.value === 'password' ? 'text' : 'password';
};
const onClick = () => {
  emit('on-copy', props.value);
};
</script>
