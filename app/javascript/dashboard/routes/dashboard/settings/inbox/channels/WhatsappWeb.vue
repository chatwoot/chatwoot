<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../../index';
import WhatsappWebForm from './whatsapp/WhatsappWebForm.vue';

export default {
  components: {
    WhatsappWebForm,
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  methods: {
    async createChannel(formData) {
      try {
        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: formData.name,
            channel: {
              type: 'whatsapp',
              phone_number: formData.phone_number,
              provider: 'whatsapp_web',
              provider_config: formData.provider_config,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: whatsappChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <WhatsappWebForm
    mode="create"
    :is-loading="uiFlags.isCreating"
    @submit="createChannel"
  />
</template>
