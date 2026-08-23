<script>
import { mapGetters, mapActions } from 'vuex';
import { useAvailability } from 'widget/composables/useAvailability';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  name: 'OfflineForm',
  components: { FluentIcon },
  setup() {
    const { isOnline } = useAvailability();
    return { isOnline };
  },
  data() {
    return {
      name: '',
      email: '',
      message: '',
      isSubmitting: false,
      isSubmitted: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      unavailableMessage: 'appConfig/getUnavailableMessage',
    }),
    canSubmit() {
      return this.email.trim() && this.message.trim() && !this.isSubmitting;
    },
  },
  methods: {
    ...mapActions('conversation', ['createConversation']),
    async handleSubmit() {
      if (!this.canSubmit) return;
      this.isSubmitting = true;
      try {
        await this.createConversation({
          fullName: this.name,
          emailAddress: this.email,
          message: this.message,
        });
        this.isSubmitted = true;
      } catch (e) {
        // silent
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col items-center justify-center flex-1 w-full p-6 gap-5">
    <!-- Success state -->
    <template v-if="isSubmitted">
      <div class="flex flex-col items-center gap-3 text-center">
        <div
          class="flex items-center justify-center w-14 h-14 rounded-full"
          :style="{ backgroundColor: widgetColor + '20' }"
        >
          <FluentIcon icon="checkmark-circle" :size="28" :style="{ color: widgetColor }" />
        </div>
        <h3 class="text-lg font-medium text-n-slate-12">
          {{ $t('OFFLINE_FORM.SUCCESS_TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 max-w-[260px]">
          {{ $t('OFFLINE_FORM.SUCCESS_MESSAGE') }}
        </p>
      </div>
    </template>

    <!-- Offline form -->
    <template v-else>
      <div class="flex flex-col items-center gap-3 text-center">
        <div
          class="flex items-center justify-center w-14 h-14 rounded-full"
          :style="{ backgroundColor: widgetColor + '20' }"
        >
          <FluentIcon icon="clock" :size="28" :style="{ color: widgetColor }" />
        </div>
        <h3 class="text-lg font-medium text-n-slate-12">
          {{ $t('OFFLINE_FORM.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 max-w-[260px]">
          {{ unavailableMessage || $t('OFFLINE_FORM.DESCRIPTION') }}
        </p>
      </div>

      <form class="flex flex-col w-full gap-3 mt-2" @submit.prevent="handleSubmit">
        <input
          v-model="name"
          type="text"
          :placeholder="$t('OFFLINE_FORM.NAME_PLACEHOLDER')"
          class="w-full px-3 py-2.5 text-sm rounded-lg border border-n-slate-6 bg-n-background text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:border-n-brand"
        />
        <input
          v-model="email"
          type="email"
          required
          :placeholder="$t('OFFLINE_FORM.EMAIL_PLACEHOLDER')"
          class="w-full px-3 py-2.5 text-sm rounded-lg border border-n-slate-6 bg-n-background text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:border-n-brand"
        />
        <textarea
          v-model="message"
          required
          rows="3"
          :placeholder="$t('OFFLINE_FORM.MESSAGE_PLACEHOLDER')"
          class="w-full px-3 py-2.5 text-sm rounded-lg border border-n-slate-6 bg-n-background text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:border-n-brand resize-none"
        />
        <button
          type="submit"
          :disabled="!canSubmit"
          class="w-full py-2.5 text-sm font-medium text-white rounded-lg transition-colors disabled:opacity-50"
          :style="{ backgroundColor: widgetColor }"
        >
          {{ isSubmitting ? $t('OFFLINE_FORM.SENDING') : $t('OFFLINE_FORM.SUBMIT') }}
        </button>
      </form>
    </template>
  </div>
</template>
