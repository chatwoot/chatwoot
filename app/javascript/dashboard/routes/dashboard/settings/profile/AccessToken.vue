<script setup>
import { ref, computed } from 'vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ConfirmButton from 'dashboard/components-next/button/ConfirmButton.vue';

const props = defineProps({
  value: { type: String, default: '' },
  showResetButton: { type: Boolean, default: true },
});

const emit = defineEmits(['onCopy', 'onReset']);

const inputType = ref('password');

const toggleMasked = () => {
  inputType.value = inputType.value === 'password' ? 'text' : 'password';
};

const maskIcon = computed(() => {
  return inputType.value === 'password' ? 'eye-hide' : 'eye-show';
});

const onClick = () => {
  emit('onCopy', props.value);
};

const onReset = () => {
  emit('onReset');
};
</script>

<template>
  <div class="flex flex-row justify-between gap-4">
    <woot-input
      name="access_token"
      class="flex-1 [&>input]:!py-1.5 ltr:[&>input]:!pr-9 ltr:[&>input]:!pl-3 rtl:[&>input]:!pl-9 rtl:[&>input]:!pr-3 focus:[&>input]:!border-slate-200 focus:[&>input]:dark:!border-slate-600 [&>input]:cursor-not-allowed relative"
      :styles="{
        borderRadius: '12px',
        fontSize: '14px',
        marginBottom: '2px',
      }"
      :type="inputType"
      :model-value="value"
      readonly
    >
      <template #masked>
        <button
          class="absolute top-0 bottom-0 ltr:right-0.5 rtl:left-0.5"
          type="button"
          @click="toggleMasked"
        >
          <fluent-icon :icon="maskIcon" :size="16" />
        </button>
      </template>
    </woot-input>
    <div class="flex flex-row gap-2">
      <NextButton
        :label="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.COPY')"
        slate
        outline
        type="button"
        icon="i-lucide-copy"
        class="rounded-xl"
        @click="onClick"
      />
      <ConfirmButton
        v-if="showResetButton"
        :label="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.RESET')"
        :confirm-label="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.CONFIRM_RESET')"
        :confirm-hint="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.CONFIRM_HINT')"
        color="slate"
        confirm-color="ruby"
        variant="outline"
        icon="i-lucide-key-round"
        class="rounded-xl"
        @click="onReset"
      />
    </div>
  </div>
</template>
