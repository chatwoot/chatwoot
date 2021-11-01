<template>
  <span class="back-button ion-ios-arrow-left" @click.capture="goBack">
    {{ buttonLabel || $t('GENERAL_SETTINGS.BACK') }}
  </span>
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
