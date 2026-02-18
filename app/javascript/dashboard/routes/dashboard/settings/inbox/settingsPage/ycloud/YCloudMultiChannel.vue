<script>
import YCloudAPI from 'dashboard/api/ycloud';
import { useAlert } from 'dashboard/composables';
import SettingsSection from '../../../../../../components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: { SettingsSection, NextButton },
  props: {
    inbox: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      activeTab: 'sms',
      smsForm: { to: '', text: '', from: '' },
      emailForm: { from: '', to: '', subject: '', contentType: 'text/plain', content: '' },
      voiceForm: { to: '', verificationCode: '', language: 'en' },
      verifyForm: { channel: 'whatsapp', to: '', codeLength: 6 },
      checkForm: { verificationId: '', code: '' },
      isSending: false,
      lastVerificationId: '',
    };
  },
  methods: {
    async sendSms() {
      this.isSending = true;
      try {
        await YCloudAPI.sendSms(this.inbox.id, this.smsForm);
        useAlert(this.$t('YCLOUD.MULTICHANNEL.SMS_SUCCESS'));
        this.smsForm = { to: '', text: '', from: '' };
      } catch { useAlert(this.$t('YCLOUD.MULTICHANNEL.SMS_ERROR')); }
      this.isSending = false;
    },
    async sendEmail() {
      this.isSending = true;
      try {
        await YCloudAPI.sendEmail(this.inbox.id, this.emailForm);
        useAlert(this.$t('YCLOUD.MULTICHANNEL.EMAIL_SUCCESS'));
        this.emailForm = { from: '', to: '', subject: '', contentType: 'text/plain', content: '' };
      } catch { useAlert(this.$t('YCLOUD.MULTICHANNEL.EMAIL_ERROR')); }
      this.isSending = false;
    },
    async sendVoice() {
      this.isSending = true;
      try {
        await YCloudAPI.sendVoice(this.inbox.id, this.voiceForm);
        useAlert(this.$t('YCLOUD.MULTICHANNEL.VOICE_SUCCESS'));
        this.voiceForm = { to: '', verificationCode: '', language: 'en' };
      } catch { useAlert(this.$t('YCLOUD.MULTICHANNEL.VOICE_ERROR')); }
      this.isSending = false;
    },
    async startVerification() {
      this.isSending = true;
      try {
        const res = await YCloudAPI.startVerification(this.inbox.id, this.verifyForm);
        this.lastVerificationId = res.data.id || '';
        this.checkForm.verificationId = this.lastVerificationId;
        useAlert(this.$t('YCLOUD.MULTICHANNEL.VERIFY_SENT'));
      } catch { useAlert(this.$t('YCLOUD.MULTICHANNEL.VERIFY_ERROR')); }
      this.isSending = false;
    },
    async checkVerification() {
      this.isSending = true;
      try {
        const res = await YCloudAPI.checkVerification(this.inbox.id, this.checkForm);
        const status = res.data.status || 'unknown';
        useAlert(this.$t('YCLOUD.MULTICHANNEL.VERIFY_RESULT', { status }));
      } catch { useAlert(this.$t('YCLOUD.MULTICHANNEL.VERIFY_CHECK_ERROR')); }
      this.isSending = false;
    },
  },
};
</script>

<template>
  <div class="py-4">
    <!-- Tab Selector -->
    <div class="flex gap-1 mb-6 border-b border-n-weak">
      <button v-for="tab in ['sms', 'email', 'voice', 'verification']" :key="tab"
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="activeTab === tab ? 'border-n-blue-text text-n-blue-text' : 'border-transparent text-n-slate-11 hover:text-n-slate-12'"
        @click="activeTab = tab">
        {{ $t(`YCLOUD.MULTICHANNEL.TAB_${tab.toUpperCase()}`) }}
      </button>
    </div>

    <!-- SMS -->
    <div v-if="activeTab === 'sms'">
      <SettingsSection :title="$t('YCLOUD.MULTICHANNEL.SMS_TITLE')" :sub-title="$t('YCLOUD.MULTICHANNEL.SMS_DESC')" :show-border="false">
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.TO') }}<input v-model="smsForm.to" type="tel" class="mt-1" placeholder="+1234567890" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.FROM') }} ({{ $t('YCLOUD.COMMON.OPTIONAL') }})<input v-model="smsForm.from" type="text" class="mt-1" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.TEXT') }}<textarea v-model="smsForm.text" rows="3" class="mt-1" /></label>
        <NextButton :label="$t('YCLOUD.MULTICHANNEL.SEND')" :is-loading="isSending" @click="sendSms" />
      </SettingsSection>
    </div>

    <!-- Email -->
    <div v-if="activeTab === 'email'">
      <SettingsSection :title="$t('YCLOUD.MULTICHANNEL.EMAIL_TITLE')" :sub-title="$t('YCLOUD.MULTICHANNEL.EMAIL_DESC')" :show-border="false">
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.FROM') }}<input v-model="emailForm.from" type="email" class="mt-1" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.TO') }}<input v-model="emailForm.to" type="email" class="mt-1" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.SUBJECT') }}<input v-model="emailForm.subject" type="text" class="mt-1" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.CONTENT') }}<textarea v-model="emailForm.content" rows="5" class="mt-1" /></label>
        <NextButton :label="$t('YCLOUD.MULTICHANNEL.SEND')" :is-loading="isSending" @click="sendEmail" />
      </SettingsSection>
    </div>

    <!-- Voice -->
    <div v-if="activeTab === 'voice'">
      <SettingsSection :title="$t('YCLOUD.MULTICHANNEL.VOICE_TITLE')" :sub-title="$t('YCLOUD.MULTICHANNEL.VOICE_DESC')" :show-border="false">
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.TO') }}<input v-model="voiceForm.to" type="tel" class="mt-1" placeholder="+1234567890" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.VERIFICATION_CODE') }}<input v-model="voiceForm.verificationCode" type="text" class="mt-1" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.LANGUAGE') }}<input v-model="voiceForm.language" type="text" class="mt-1" placeholder="en" /></label>
        <NextButton :label="$t('YCLOUD.MULTICHANNEL.SEND')" :is-loading="isSending" @click="sendVoice" />
      </SettingsSection>
    </div>

    <!-- Verification (OTP) -->
    <div v-if="activeTab === 'verification'">
      <SettingsSection :title="$t('YCLOUD.MULTICHANNEL.VERIFY_TITLE')" :sub-title="$t('YCLOUD.MULTICHANNEL.VERIFY_DESC')">
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.CHANNEL') }}
          <select v-model="verifyForm.channel" class="mt-1">
            <option v-for="ch in ['whatsapp','sms','voice','email_code','auto']" :key="ch" :value="ch">{{ ch }}</option>
          </select>
        </label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.TO') }}<input v-model="verifyForm.to" type="text" class="mt-1" /></label>
        <NextButton :label="$t('YCLOUD.MULTICHANNEL.SEND_CODE')" :is-loading="isSending" @click="startVerification" />
      </SettingsSection>
      <SettingsSection :title="$t('YCLOUD.MULTICHANNEL.CHECK_TITLE')" :sub-title="$t('YCLOUD.MULTICHANNEL.CHECK_DESC')" :show-border="false">
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.VERIFY_ID') }}<input v-model="checkForm.verificationId" type="text" class="mt-1" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.MULTICHANNEL.CODE') }}<input v-model="checkForm.code" type="text" class="mt-1" maxlength="8" /></label>
        <NextButton :label="$t('YCLOUD.MULTICHANNEL.CHECK_CODE')" :is-loading="isSending" @click="checkVerification" />
      </SettingsSection>
    </div>
  </div>
</template>
