<script setup>
import Icon from 'next/icon/Icon.vue';
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
  ? 'text-sm text-n-slate-11'
  : 'text-base text-n-blue-text';
</script>

<template>
  <button
    class="flex items-center p-0 font-normal cursor-pointer gap-1"
    :class="buttonStyleClass"
    @click.capture="goBack"
  >
    <Icon
      icon="i-lucide-chevron-left"
      class="size-5 ltr:-ml-1 rtl:-mr-1"
      :class="props.compact ? 'text-n-slate-11' : 'text-n-blue-text'"
    />
    {{ buttonLabel || $t('GENERAL_SETTINGS.BACK') }}
  </button>
</template>
