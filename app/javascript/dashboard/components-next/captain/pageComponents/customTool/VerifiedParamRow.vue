<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const emit = defineEmits(['remove']);
const { t } = useI18n();
const showErrors = ref(false);

const name = defineModel('name', {
  type: String,
  required: true,
});

const isNameMissing = computed(() => !name.value || name.value.trim() === '');

watch(name, () => {
  showErrors.value = false;
});

const validate = () => {
  showErrors.value = true;
  return !isNameMissing.value;
};

defineExpose({ validate });
</script>

<template>
  <li class="list-none">
    <div
      class="flex flex-col gap-2 p-3 rounded-lg border border-n-weak"
      :class="{
        'animate-wiggle border-n-ruby-9': showErrors && isNameMissing,
      }"
    >
      <div class="grid grid-cols-3 gap-2">
        <Input
          v-model="name"
          :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_NAME.PLACEHOLDER')"
          class="col-span-2 [&_input]:font-mono"
        />
        <span
          class="flex items-center gap-1.5 h-10 px-3 rounded-lg outline outline-1 outline-offset-[-1px] outline-n-weak bg-n-alpha-black2 text-sm text-n-slate-12 min-w-0"
        >
          <span class="i-lucide-lock size-3.5 shrink-0 text-n-slate-11" />
          <span class="truncate">{{
            t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.EMAIL')
          }}</span>
        </span>
      </div>
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-n-slate-11">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.VERIFIED_VALUES.HELP') }}
        </span>
        <Button
          type="button"
          ghost
          slate
          xs
          icon="i-lucide-trash-2"
          @click.stop="emit('remove')"
        />
      </div>
    </div>
    <span
      v-if="showErrors && isNameMissing"
      class="block mt-1 text-sm text-n-ruby-11"
    >
      {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.ERRORS.PARAM_NAME_REQUIRED') }}
    </span>
  </li>
</template>
