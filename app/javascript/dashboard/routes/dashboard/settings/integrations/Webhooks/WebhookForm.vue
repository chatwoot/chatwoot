<template>
  <form class="flex flex-col w-full" @submit.prevent="onSubmit">
    <div class="w-full">
      <label :class="{ error: $v.url.$error }">
        {{ $t('INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.LABEL') }}
        <input
          v-model.trim="url"
          type="text"
          name="url"
          :placeholder="webhookURLInputPlaceholder"
          @input="$v.url.$touch"
        />
        <span v-if="$v.url.$error" class="message">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.ERROR') }}
        </span>
      </label>
      <label :class="{ error: $v.url.$error }" class="mb-2">
        {{ $t('INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.LABEL') }}
      </label>
      <div class="flex flex-col gap-2.5 mb-4">
        <div
          v-for="event in supportedWebhookEvents"
          :key="event"
          class="flex items-center"
        >
          <input
            :id="event"
            v-model="subscriptions"
            type="checkbox"
            :value="event"
            name="subscriptions"
            class="checkbox"
          />
          <label :for="event" class="text-sm">
            {{ `${getEventLabel(event)} (${event})` }}
          </label>
        </div>
      </div>
    </div>

    <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
      <div class="w-full">
        <woot-button
          :disabled="$v.$invalid || isSubmitting"
          :is-loading="isSubmitting"
        >
          {{ submitLabel }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="$emit('cancel')">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.FORM.CANCEL') }}
        </woot-button>
      </div>
    </div>
  </form>
</template>

<script>
import { required, url, minLength } from 'vuelidate/lib/validators';
import webhookMixin from './webhookMixin';
import wootConstants from 'dashboard/constants/globals';

const { EXAMPLE_WEBHOOK_URL } = wootConstants;

const SUPPORTED_WEBHOOK_EVENTS = [
  'conversation_created',
  'conversation_status_changed',
  'conversation_updated',
  'message_created',
  'message_updated',
  'webwidget_triggered',
  'contact_created',
  'contact_updated',
];

export default {
  mixins: [webhookMixin],
  props: {
    value: {
      type: Object,
      default: () => ({}),
    },
    isSubmitting: {
      type: Boolean,
      default: false,
    },
    submitLabel: {
      type: String,
      required: true,
    },
  },
  validations: {
    url: {
      required,
      minLength: minLength(7),
      url,
    },
    subscriptions: {
      required,
    },
  },
  data() {
    return {
      url: this.value.url || '',
      subscriptions: this.value.subscriptions || [],
      supportedWebhookEvents: SUPPORTED_WEBHOOK_EVENTS,
    };
  },
  computed: {
    webhookURLInputPlaceholder() {
      return this.$t(
        'INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.PLACEHOLDER',
        {
          webhookExampleURL: EXAMPLE_WEBHOOK_URL,
        }
      );
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit', {
        url: this.url,
        subscriptions: this.subscriptions,
      });
    },
  },
};
</script>
<style lang="scss" scoped>
.checkbox {
  @apply mr-2;
}
</style>
