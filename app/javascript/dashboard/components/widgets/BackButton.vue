<script setup>
import router from '../../routes/index';
const props = defineProps({
  backUrl: {
    type: [String, Object],
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  compact: {
    type: Boolean,
    default: false,
  },
});

const goBack = () => {
  if (props.backUrl !== '') {
    router.push(props.backUrl);
  } else {
    router.go(-1);
  }
};

const buttonStyleClass = props.compact
  ? 'text-sm text-slate-600 dark:text-slate-300'
  : 'text-base text-woot-500 dark:text-woot-500';
</script>

<template>
  <button
    class="flex items-center font-normal p-0 cursor-pointer"
    :class="buttonStyleClass"
    @click.capture="goBack"
  >
    <fluent-icon icon="chevron-left" class="-ml-1" />
    {{ buttonLabel || $t('GENERAL_SETTINGS.BACK') }}
  </button>
</template>
