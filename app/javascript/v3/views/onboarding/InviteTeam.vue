<template>
  <div
    id="modal-body"
    class="dark:shadow-[#000] rounded-3xl p-10 pt-14 border shadow border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 z-10 relative w-full max-w-[560px]"
  >
    <h2
      class="font-bold text-[28px] leading-8 tracking-[2%] text-slate-900 dark:text-white"
    >
      {{ $t('START_ONBOARDING.INVITE_TEAM.TITLE') }}
    </h2>
    <p
      class="text-base text-slate-600 leading-6 tracking-[-1.1%] mt-2 dark:text-slate-200"
    >
      {{ $t('START_ONBOARDING.INVITE_TEAM.BODY') }}
    </p>
    <div class="mt-10">
      <section class="space-y-5">
        <div class="flex gap-2">
          <form-input
            v-model="emailToAdd"
            name="email"
            spacing="compact"
            class="flex-grow"
            :placeholder="$t('START_ONBOARDING.INVITE_TEAM.PLACEHOLDER')"
            @keyup.enter="pushEmail"
          />
          <woot-button
            variant="smooth"
            color-scheme="secondary"
            @click="pushEmail"
          >
            {{ $t('START_ONBOARDING.INVITE_TEAM.ADD') }}
          </woot-button>
        </div>
        <div
          class="rounded-md divide-y divide-slate-100 dark:divide-slate-700 border border-slate-200 dark:border-slate-700 max-h-[40vh] overflow-auto"
          :class="{
            ' border-dashed grid place-content-center':
              emailsToInvite.length === 0,
          }"
        >
          <div v-if="emailsToInvite.length === 0" class="px-5 py-16">
            <p class="text-sm text-slate-400">
              {{ $t('START_ONBOARDING.INVITE_TEAM.LIST_EMPTY') }}
            </p>
          </div>
          <div
            v-for="email in emailsToInvite"
            :key="email"
            class="flex items-center justify-between p-4"
          >
            <div class="flex items-center gap-2">
              <woot-thumbnail :username="email" size="24px" />
              <span
                class="text-slate-700 dark:text-slate-200 text-sm font-medium"
              >
                {{ email }}
              </span>
            </div>
            <woot-button
              variant="clear"
              size="small"
              color-scheme="secondary"
              icon="dismiss"
              @click="emailsToInvite.splice(emailsToInvite.indexOf(email), 1)"
            />
          </div>
        </div>
        <div class="space-y-2 flex flex-col items-center">
          <submit-button
            button-class="flex justify-center w-full text-sm text-center"
            :button-text="$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.BUTTON')"
            @click="onSubmit"
          />

          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="expanded"
            is-expanded
            @click="skipToFoundersNote"
          >
            {{ $t('START_ONBOARDING.INVITE_TEAM.SKIP') }}
          </woot-button>
        </div>
      </section>
    </div>
  </div>
</template>

<script>
import FormInput from 'v3/components/Form/Input.vue';
import SubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';

import AgentAPI from 'dashboard/api/agents.js';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    SubmitButton,
    FormInput,
  },
  mixins: [alertMixin],
  data() {
    return {
      emailsToInvite: [],
      emailToAdd: '',
    };
  },
  methods: {
    pushEmail() {
      if (!this.emailToAdd) return;
      this.emailsToInvite.push(this.emailToAdd);
      this.emailsToInvite = [...new Set(this.emailsToInvite)];
      this.emailToAdd = '';
    },
    async skipToFoundersNote() {
      try {
        await AgentAPI.bulkInvite({ emails: [] });
        this.$router.push({ name: 'onboarding_founders_note' });
      } catch (error) {
        this.showAlert(this.$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.ERROR'));
      }
      this.$router.push({ name: 'onboarding_founders_note' });
    },
    async onSubmit() {
      if (this.emailsToInvite.length === 0) {
        this.showAlert(
          this.$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.NO_MEMBER_ERROR')
        );
        return;
      }

      try {
        await AgentAPI.bulkInvite({ emails: this.emailsToInvite });
        this.showAlert(this.$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.SUCCESS'));
        this.$router.push({ name: 'onboarding_founders_note' });
      } catch (error) {
        this.showAlert(this.$t('START_ONBOARDING.INVITE_TEAM.SUBMIT.ERROR'));
      }
    },
  },
};
</script>
