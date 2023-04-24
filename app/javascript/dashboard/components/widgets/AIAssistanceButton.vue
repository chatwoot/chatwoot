<template>
  <div v-if="isAIIntegrationEnabled" class="position-relative">
    <woot-button
      v-tooltip.top-end="$t('INTEGRATION_SETTINGS.OPEN_AI.TITLE')"
      icon="wand"
      color-scheme="secondary"
      variant="smooth"
      size="small"
      @click="toggleDropdown"
    />
    <div
      v-if="showDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open ai-modal"
    >
      <h4 class="sub-block-title margin-top-1">
        {{ $t('INTEGRATION_SETTINGS.OPEN_AI.TITLE') }}
      </h4>
      <p>
        {{ $t('INTEGRATION_SETTINGS.OPEN_AI.SUBTITLE') }}
      </p>
      <label>
        {{ $t('INTEGRATION_SETTINGS.OPEN_AI.TONE.TITLE') }}
      </label>
      <div class="tone__item">
        <select v-model="activeTone" class="status--filter small">
          <option v-for="tone in tones" :key="tone.key" :value="tone.key">
            {{ tone.value }}
          </option>
        </select>
      </div>
      <div class="modal-footer flex-container align-right">
        <woot-button variant="clear" size="small" @click="closeDropdown">
          {{ $t('INTEGRATION_SETTINGS.OPEN_AI.BUTTONS.CANCEL') }}
        </woot-button>
        <woot-button
          :is-loading="isGenerating"
          size="small"
          @click="processText"
        >
          {{ buttonText }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import OpenAPI from 'dashboard/api/integrations/openapi';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin, clickaway],
  props: {
    conversationId: {
      type: Number,
      default: 0,
    },
    message: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isGenerating: false,
      showDropdown: false,
      activeTone: 'professional',
      tones: [
        {
          key: 'professional',
          value: this.$t(
            'INTEGRATION_SETTINGS.OPEN_AI.TONE.OPTIONS.PROFESSIONAL'
          ),
        },
        {
          key: 'friendly',
          value: this.$t('INTEGRATION_SETTINGS.OPEN_AI.TONE.OPTIONS.FRIENDLY'),
        },
      ],
    };
  },
  computed: {
    ...mapGetters({ appIntegrations: 'integrations/getAppIntegrations' }),
    isAIIntegrationEnabled() {
      return this.appIntegrations.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      );
    },
    hookId() {
      return this.appIntegrations.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      ).hooks[0].id;
    },
    buttonText() {
      return this.isGenerating
        ? this.$t('INTEGRATION_SETTINGS.OPEN_AI.BUTTONS.GENERATING')
        : this.$t('INTEGRATION_SETTINGS.OPEN_AI.BUTTONS.GENERATE');
    },
  },
  mounted() {
    if (!this.appIntegrations.length) {
      this.$store.dispatch('integrations/get');
    }
  },
  methods: {
    toggleDropdown() {
      this.showDropdown = !this.showDropdown;
    },
    closeDropdown() {
      this.showDropdown = false;
    },
    async processText() {
      this.isGenerating = true;
      try {
        const result = await OpenAPI.processEvent({
          hookId: this.hookId,
          type: 'rephrase',
          content: this.message,
          tone: this.activeTone,
        });
        const {
          data: { message: generatedMessage },
        } = result;
        this.$emit('replace-text', generatedMessage || this.message);
        this.closeDropdown();
      } catch (error) {
        this.showAlert(this.$t('INTEGRATION_SETTINGS.OPEN_AI.GENERATE_ERROR'));
      } finally {
        this.isGenerating = false;
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.ai-modal {
  width: 400px;
  right: 0;
  left: 0;
  padding: var(--space-normal);
  bottom: 34px;
  position: absolute;
  span {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
  }

  p {
    color: var(--s-600);
  }

  label {
    margin-bottom: var(--space-smaller);
  }

  .status--filter {
    background-color: var(--color-background-light);
    border: 1px solid var(--color-border);
    font-size: var(--font-size-small);
    height: var(--space-large);
    padding: 0 var(--space-medium) 0 var(--space-small);
  }

  .modal-footer {
    gap: var(--space-smaller);
  }
}
</style>
