<script>
import IframeLoader from 'shared/components/IframeLoader.vue';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

export default {
  name: 'ArticleViewer',
  components: {
    IframeLoader,
  },
  computed: {
    isRTL() {
      return this.$root.$i18n.locale
        ? getLanguageDirection(this.$root.$i18n.locale)
        : false;
    },
  },
};
</script>

<template>
  <div class="bg-white h-full">
    <IframeLoader :url="$route.query.link" :is-rtl="isRTL" />
  </div>
</template>
