<template>
  <form class="row" @submit.prevent="onSubmit">
    <div class="medium-12 columns">
      <label :class="{ error: $v.url.$error }">
        {{ $t('INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.LABEL') }}
        <input
          v-model.trim="url"
          type="text"
          name="url"
          :placeholder="
            $t('INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.PLACEHOLDER')
          "
          @input="$v.url.$touch"
        />
        <span v-if="$v.url.$error" class="message">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.ERROR') }}
        </span>
      </label>
      <label :class="{ error: $v.url.$error }" class="margin-bottom-small">
        {{ $t('INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.LABEL') }}
      </label>
      <div v-for="event in supportedWebhookEvents" :key="event">
        <input
          :id="event"
          v-model="subscriptions"
          type="checkbox"
          :value="event"
          name="subscriptions"
          class="margin-right-small"
        />
        <span class="fs-small">
          {{ `${getEventLabel(event)} (${event})` }}
        </span>
      </div>
    </div>

    <div class="modal-footer">
      <div class="medium-12 columns">
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

const SUPPORTED_WEBHOOK_EVENTS = [
  'conversation_created',
  'conversation_status_changed',
  'conversation_updated',
  'message_created',
  'message_updated',
  'webwidget_triggered',
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
