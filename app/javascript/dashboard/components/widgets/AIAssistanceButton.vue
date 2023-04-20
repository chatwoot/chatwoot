<template>
  <div v-if="isAIIntegrationEnabled" style="position: relative;">
    <woot-button
      v-tooltip.top-end="'Summarize With AI'"
      icon="wand"
      color-scheme="secondary"
      variant="smooth"
      size="small"
      :title="'AI'"
      @click="toggleDropdown"
    />
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open basic-filter"
    >
      <h4 class="sub-block-title">
        Summarize with AI
      </h4>
      <p>
        {{ message }}
      </p>
      <label>
        Tone
      </label>
      <div class="filter__item">
        <select v-model="activeValue" class="status--filter">
          <option v-for="item in items" :key="item.status" :value="item.status">
            {{ item.value }}
          </option>
        </select>
      </div>
      <div class="medium-12 columns">
        <div class="modal-footer justify-content-end w-full buttons">
          <woot-button class="button clear" size="tiny" @click="closeDropdown">
            Cancel
          </woot-button>
          <woot-button
            :is-loading="isGenerating"
            size="tiny"
            @click="processText"
          >
            {{ buttonText }}
          </woot-button>
        </div>
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
      showActionsDropdown: false,
      items: [
        {
          value: 'Professional',
          status: 'Professional',
        },
      ],
      activeValue: 'Professional',
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
      return this.isGenerating ? 'Generating...' : 'Generate';
    },
  },
  mounted() {
    if (!this.appIntegrations.length) {
      this.$store.dispatch('integrations/get');
    }
  },
  methods: {
    toggleDropdown() {
      this.showActionsDropdown = !this.showActionsDropdown;
    },
    closeDropdown() {
      this.showActionsDropdown = false;
    },
    async processText() {
      this.isGenerating = true;
      try {
        const result = await OpenAPI.processEvent({
          hookId: this.hookId,
          type: 'rephrase',
          content: this.message,
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
.basic-filter {
  width: 400px;
  margin-top: var(--space-smaller);
  right: 0;
  left: 0;
  padding: var(--space-normal) var(--space-small);
  bottom: 34px;
  position: absolute;
  span {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
  }
  .filter__item {
    justify-content: space-between;
    display: flex;
    align-items: center;

    &:last-child {
      margin-top: var(--space-normal);
    }

    span {
      font-size: var(--font-size-mini);
    }
  }
}
.icon {
  margin-right: var(--space-smaller);
}
.dropdown-icon {
  margin-left: var(--space-smaller);
}

.status--filter {
  background-color: var(--color-background-light);
  border: 1px solid var(--color-border);
  font-size: var(--font-size-mini);
  height: var(--space-medium);
  margin: 0 var(--space-smaller);
  padding: 0 var(--space-medium) 0 var(--space-small);
}

.buttons {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--space-normal);
}
</style>
