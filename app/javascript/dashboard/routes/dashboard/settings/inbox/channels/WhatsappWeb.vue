<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WhatsappWebChannel from 'dashboard/api/channel/whatsappWebChannel';
import {
  isValidWhatsappWebPhone,
  normalizeWhatsappWebPhone,
} from './whatsappWebPhone';

export default {
  components: {
    PageHeader,
    NextButton,
  },
  data() {
    return {
      phoneForPairCode: '',
      phonePrefix: '+',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
      accountId: 'getCurrentAccountId',
      inboxes: 'inboxes/getInboxes',
    }),
    normalizedPhone() {
      return normalizeWhatsappWebPhone(this.phoneForPairCode);
    },
    isPhoneValid() {
      return isValidWhatsappWebPhone(this.phoneForPairCode);
    },
    isSubmitDisabled() {
      return !this.isPhoneValid;
    },
    isDuplicatePhone() {
      if (!this.isPhoneValid) {
        return false;
      }

      return this.inboxes.some(inbox => {
        const attributes = inbox.additional_attributes || {};
        const isWhatsappWeb =
          inbox.channel_type === 'Channel::Api' &&
          attributes.integration_type === 'whatsapp_web';
        if (!isWhatsappWeb) {
          return false;
        }

        const existingPhone = normalizeWhatsappWebPhone(
          attributes?.whatsapp_web?.phone || inbox.name || ''
        );
        return existingPhone === this.normalizedPhone;
      });
    },
    phoneError() {
      if (this.phoneForPairCode.trim() && !this.isPhoneValid) {
        return this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.PAIR_PHONE.ERROR');
      }

      return '';
    },
  },
  methods: {
    onPhoneInput(event) {
      this.phoneForPairCode = normalizeWhatsappWebPhone(event.target.value);
    },
    buildChannelAdditionalAttributes(phone) {
      return {
        integration_type: 'whatsapp_web',
        whatsapp_web: {
          phone,
        },
      };
    },
    setupErrorMessage(error) {
      return (
        error?.response?.data?.error ||
        error?.response?.data?.message ||
        error?.message ||
        this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.ERROR_MESSAGE')
      );
    },
    async createChannel() {
      const phone = this.normalizedPhone;
      if (!isValidWhatsappWebPhone(phone)) {
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.PAIR_PHONE.ERROR'));
        return;
      }

      if (this.isDuplicatePhone) {
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.PAIR_PHONE.DUPLICATE'));
        return;
      }

      let channel;

      try {
        channel = await this.$store.dispatch('inboxes/createChannel', {
          name: phone,
          channel: {
            type: 'api',
            webhook_url: '',
            additional_attributes: this.buildChannelAdditionalAttributes(phone),
          },
        });
      } catch (error) {
        useAlert(this.setupErrorMessage(error));
        return;
      }

      try {
        await WhatsappWebChannel.setup(channel.id, { phone });
        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: channel.id,
          },
          query: { pair_phone: phone },
        });
      } catch (error) {
        useAlert(this.setupErrorMessage(error));
        router.replace({
          name: 'settings_inbox_show',
          params: {
            inboxId: channel.id,
            accountId: this.accountId,
          },
        });
      }
    },
  },
};
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.DESC_SIMPLE')"
    />

    <form
      class="mx-0 flex w-full max-w-[32rem] flex-col gap-4"
      @submit.prevent="createChannel"
    >
      <div class="w-full">
        <label class="mb-0.5 block text-heading-3 text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PAIR_PHONE.LABEL') }}
        </label>
        <div class="mt-1 flex w-full items-center gap-2">
          <span class="shrink-0 select-none text-base font-medium text-n-brand">
            {{ phonePrefix }}
          </span>
          <div
            class="flex h-10 w-full items-center rounded-lg bg-n-alpha-black2 outline outline-1 outline-offset-[-1px]"
            :class="
              phoneError
                ? 'outline-n-ruby-8'
                : 'outline-n-weak hover:outline-n-slate-6 focus-within:outline-n-brand'
            "
          >
            <input
              :value="phoneForPairCode"
              type="text"
              inputmode="numeric"
              pattern="[0-9]*"
              maxlength="11"
              :placeholder="
                $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PAIR_PHONE.PLACEHOLDER')
              "
              class="reset-base no-margin h-full min-w-0 flex-1 border-0 bg-transparent px-3 py-2.5 text-sm text-n-slate-12 shadow-none placeholder:text-n-slate-10 focus:outline-none"
              @input="onPhoneInput"
            />
          </div>
        </div>
        <p v-if="phoneError" class="mt-1 text-label-small text-n-ruby-9">
          {{ phoneError }}
        </p>
        <p class="mt-1 text-label-small text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PAIR_PHONE.SUBTITLE') }}
        </p>
      </div>

      <div class="w-full pt-1">
        <NextButton
          :is-loading="uiFlags.isCreating"
          :disabled="isSubmitDisabled"
          type="submit"
          :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
