<template>
  <button class="settings back-button" @click.capture="goBack">
    <fluent-icon icon="chevron-left" />
    {{ buttonLabel || $t('GENERAL_SETTINGS.BACK') }}
  </button>
</template>
<script>
import router from '../../routes/index';

export default {
  props: {
    backUrl: {
      type: [String, Object],
      default: '',
    },
    buttonLabel: {
      type: String,
      default: '',
    },
  },
  methods: {
    goBack() {
      if (this.backUrl !== '') {
        router.push(this.backUrl);
      } else {
        router.go(-1);
      }
    },
  },
};
</script>
