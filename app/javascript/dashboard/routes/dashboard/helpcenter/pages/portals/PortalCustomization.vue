<template>
  <div class="wizard-body columns content-box small-9">
    <div class="medium-12 columns">
      <page-header header-title="Help center customisation" />
    </div>
    <div class="medium-7 columns">
      <div class="medium-12 columns" />
      <div class="medium-12 columns">
        <woot-button @click="changeRoute">Next</woot-button>
      </div>
    </div>
  </div>
</template>

<script>
import PageHeader from 'dashboard/routes/dashboard/settings/SettingsSubPageHeader.vue';
export default {
  components: {
    PageHeader,
  },
  methods: {
    changeRoute() {
      this.$router.push({
        name: 'portal_finish',
      });
    },
  },
};
</script>
