<script>
import { mapGetters, mapActions } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import WButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'VoiceAgentForm',
  components: {
    WButton,
  },
  setup() {
    const router = useRouter();
    const route = useRoute();
    return { router, route, showAlert: useAlert };
  },
  data() {
    return {
      mode: 'create', // 'create' or 'import'
      form: {
        name: '',
        inbox_id: '',
        phone_number: '',
        active: true,
        first_message: 'Hello! How can I help you today?',
        system_prompt: 'You are a helpful voice assistant.',
        voice_provider: '11labs',
        voice_id: '',
        use_preset_voice: true,
        model_provider: 'openai',
        model_name: 'gpt-4o-mini',
        transcriber_provider: 'deepgram',
        transcriber_language: 'en',
      },
      errors: {},
      isSubmitting: false,
      isImporting: false,
      importVapiAgentId: '',
      presetVoices: {
        '11labs': [
          { id: '21m00Tcm4TlvDq8ikWAM', name: 'Rachel - Calm (EN)' },
          { id: 'EXAVITQu4vr4xnSDxMaL', name: 'Bella - Soft (EN)' },
          { id: 'XB0fDUnXU5powFXDhCwa', name: 'Charlotte - Warm (EN)' },
          { id: 'UkO7OCLgMp3WYf4UPjE5', name: 'Tiago - Jovem (PT)' },
          { id: 'aLFUti4k8YKvtQGXv0UO', name: 'Paulo - Forte (PT)' },
          { id: 'WsQeRzWJvoDvhPPJj5r7', name: 'Francisco - Nítida (PT)' },
          { id: 'RROBrqjHiRb8zmRgGV11', name: 'Dinis - Suave (PT)' },
        ],
        azure: [
          { id: 'en-US-JennyNeural', name: 'Jenny (US English)' },
          { id: 'en-US-GuyNeural', name: 'Guy (US English)' },
          {
            id: 'pt-BR-FranciscaNeural',
            name: 'Francisca (Brazilian Portuguese)',
          },
          { id: 'pt-BR-AntonioNeural', name: 'Antonio (Brazilian Portuguese)' },
          { id: 'es-ES-ElviraNeural', name: 'Elvira (Spanish)' },
        ],
        playht: [
          { id: 'larry', name: 'Larry - Professional' },
          { id: 'jennifer', name: 'Jennifer - Friendly' },
          { id: 'melissa', name: 'Melissa - Warm' },
        ],
        rime: [
          { id: 'sophia', name: 'Sophia - Clear' },
          { id: 'marcus', name: 'Marcus - Deep' },
        ],
        deepgram: [
          { id: 'aura-asteria-en', name: 'Asteria (English)' },
          { id: 'aura-luna-en', name: 'Luna (English)' },
          { id: 'aura-stella-en', name: 'Stella (English)' },
        ],
      },
    };
  },
  computed: {
    ...mapGetters('inboxes', ['getInboxes']),
    availableInboxes() {
      return this.getInboxes;
    },
    isEditing() {
      return !!this.route.params.id;
    },
    availableVoices() {
      return this.presetVoices[this.form.voice_provider] || [];
    },
  },
  async mounted() {
    await this.fetchInboxes();
    if (this.isEditing) {
      await this.loadAgent();
    }
  },
  methods: {
    ...mapActions('inboxes', ['get']),
    ...mapActions('vapiAgents', [
      'show',
      'create',
      'update',
      'fetchFromVapi',
      'importFromVapi',
    ]),
    async fetchInboxes() {
      await this.get();
    },
    async handleImportFromVapi() {
      if (!this.importVapiAgentId.trim()) {
        this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.IMPORT_ID_REQUIRED'));
        return;
      }

      // Check for empty string or falsy value
      if (!this.form.inbox_id || this.form.inbox_id === '') {
        this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.IMPORT_SELECT_INBOX'));
        return;
      }

      this.isImporting = true;
      try {
        // In import mode, use importFromVapi which creates directly in DB
        if (this.mode === 'import') {
          const result = await this.importFromVapi({
            vapiAgentId: this.importVapiAgentId.trim(),
            inboxId: this.form.inbox_id,
          });

          if (result && result.data) {
            this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.CREATED'));
            this.router.push({ name: 'vapi_agents_index' });
          } else {
            this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.IMPORT_ERROR'));
          }
        } else {
          // In create mode, fetch data to populate form
          const result = await this.fetchFromVapi({
            vapiAgentId: this.importVapiAgentId.trim(),
            inboxId: this.form.inbox_id,
          });

          if (result && result.data) {
            // Handle both array and object responses
            const importedData = Array.isArray(result.data)
              ? result.data[0]
              : result.data;

            if (!importedData) {
              this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.IMPORT_ERROR'));
              return;
            }

            // Populate form for manual editing
            this.form = {
              ...this.form,
              name: importedData.name || this.form.name,
              phone_number: importedData.phone_number || this.form.phone_number,
              first_message:
                importedData.first_message || this.form.first_message,
              system_prompt:
                importedData.system_prompt || this.form.system_prompt,
              voice_provider:
                importedData.voice_provider || this.form.voice_provider,
              voice_id: importedData.voice_id || this.form.voice_id,
              model_provider:
                importedData.model_provider || this.form.model_provider,
              model_name: importedData.model_name || this.form.model_name,
              transcriber_provider:
                importedData.transcriber_provider ||
                this.form.transcriber_provider,
              transcriber_language:
                importedData.transcriber_language ||
                this.form.transcriber_language,
            };

            // Check if voice_id is in presets
            const presets = this.presetVoices[this.form.voice_provider] || [];
            this.form.use_preset_voice = presets.some(
              v => v.id === this.form.voice_id
            );

            this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.IMPORT_SUCCESS'));
            // Clear the import field
            this.importVapiAgentId = '';
          } else {
            this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.IMPORT_ERROR'));
          }
        }
      } catch (error) {
        // Error message is shown by throwErrorMessage in store
      } finally {
        this.isImporting = false;
      }
    },
    async loadAgent() {
      try {
        const agent = await this.show(this.route.params.id);
        const voiceId = agent.settings?.voice_id || '';
        const voiceProvider = agent.settings?.voice_provider || '11labs';

        // Check if voice_id matches a preset
        const presets = this.presetVoices[voiceProvider] || [];
        const isPreset = presets.some(v => v.id === voiceId);

        this.form = {
          name: agent.name,
          inbox_id: agent.inbox.id,
          phone_number: agent.phone_number || '',
          active: agent.active,
          first_message: agent.settings?.first_message || '',
          system_prompt: agent.settings?.system_prompt || '',
          voice_provider: voiceProvider,
          voice_id: voiceId,
          use_preset_voice: isPreset,
          model_provider: agent.settings?.model_provider || 'openai',
          model_name: agent.settings?.model_name || 'gpt-4o-mini',
          transcriber_provider:
            agent.settings?.transcriber_provider || 'deepgram',
          transcriber_language: agent.settings?.transcriber_language || 'en',
        };
      } catch (error) {
        this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.LOAD_ERROR'));
        this.router.push({ name: 'vapi_agents_index' });
      }
    },
    validateForm() {
      this.errors = {};

      if (!this.form.name.trim()) {
        this.errors.name = this.$t('VOICE_AGENTS.VALIDATION.NAME_REQUIRED');
      }

      if (!this.form.inbox_id) {
        this.errors.inbox_id = this.$t(
          'VOICE_AGENTS.VALIDATION.INBOX_REQUIRED'
        );
      }

      if (!this.form.system_prompt.trim()) {
        this.errors.system_prompt = this.$t(
          'VOICE_AGENTS.VALIDATION.SYSTEM_PROMPT_REQUIRED'
        );
      }

      if (!this.form.voice_id.trim()) {
        this.errors.voice_id = this.$t(
          'VOICE_AGENTS.VALIDATION.VOICE_ID_REQUIRED'
        );
      }

      return Object.keys(this.errors).length === 0;
    },
    async handleSubmit() {
      if (!this.validateForm()) {
        return;
      }

      this.isSubmitting = true;
      try {
        if (this.isEditing) {
          await this.update({
            id: this.route.params.id,
            ...this.form,
          });
          this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.UPDATED'));
        } else {
          await this.create(this.form);
          this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.CREATED'));
        }
        this.router.push({ name: 'vapi_agents_index' });
      } catch (error) {
        this.showAlert(
          this.isEditing
            ? this.$t('VOICE_AGENTS.MESSAGES.UPDATE_ERROR')
            : this.$t('VOICE_AGENTS.MESSAGES.CREATE_ERROR')
        );
      } finally {
        this.isSubmitting = false;
      }
    },
    handleCancel() {
      this.router.push({ name: 'vapi_agents_index' });
    },
  },
};
</script>

<template>
  <div class="max-w-3xl mx-auto">
    <div
      class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-6"
    >
      <!-- Header -->
      <div class="mb-6">
        <h1 class="text-xl font-semibold text-slate-900 dark:text-slate-100">
          {{
            isEditing
              ? $t('VOICE_AGENTS.FORM.TITLE_EDIT')
              : $t('VOICE_AGENTS.FORM.TITLE_NEW')
          }}
        </h1>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
          {{
            isEditing
              ? $t('VOICE_AGENTS.FORM.EDIT_DESCRIPTION')
              : $t('VOICE_AGENTS.FORM.NEW_DESCRIPTION')
          }}
        </p>
      </div>

      <!-- Mode Selector (only when creating new agent) -->
      <div v-if="!isEditing" class="mb-6">
        <div
          class="flex gap-4 p-4 bg-slate-50 dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              v-model="mode"
              type="radio"
              value="create"
              class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-slate-300 dark:border-slate-600"
            />
            <span
              class="text-sm font-medium text-slate-700 dark:text-slate-300"
            >
              {{ $t('VOICE_AGENTS.FORM.CREATE_MANUALLY') }}
            </span>
          </label>
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              v-model="mode"
              type="radio"
              value="import"
              class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-slate-300 dark:border-slate-600"
            />
            <span
              class="text-sm font-medium text-slate-700 dark:text-slate-300"
            >
              {{ $t('VOICE_AGENTS.FORM.IMPORT_FROM_VAPI_LABEL') }}
            </span>
          </label>
        </div>
      </div>

      <!-- Import from Vapi Section -->
      <div v-if="!isEditing && mode === 'import'" class="space-y-4">
        <!-- Inbox Selection for Import -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.INBOX') }} *
          </label>
          <select
            v-model="form.inbox_id"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
          >
            <option value="">{{ $t('VOICE_AGENTS.FORM.SELECT_INBOX') }}</option>
            <option
              v-for="inbox in availableInboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }}
            </option>
          </select>
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {{ $t('VOICE_AGENTS.FORM.INBOX_HELP') }}
          </p>
        </div>

        <!-- Import Section -->
        <div
          class="p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg"
        >
          <h3 class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">
            {{ $t('VOICE_AGENTS.FORM.IMPORT_FROM_VAPI') }}
          </h3>
          <p class="text-xs text-blue-700 dark:text-blue-300 mb-3">
            {{ $t('VOICE_AGENTS.FORM.IMPORT_VAPI_HELP') }}
          </p>
          <div class="flex gap-2">
            <input
              v-model="importVapiAgentId"
              type="text"
              class="flex-1 px-3 py-2 border border-blue-300 dark:border-blue-700 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100 text-sm"
              :placeholder="$t('VOICE_AGENTS.FORM.IMPORT_PLACEHOLDER')"
            />
            <WButton
              variant="solid"
              size="sm"
              :loading="isImporting"
              @click="handleImportFromVapi"
            >
              {{ $t('VOICE_AGENTS.FORM.IMPORT_BUTTON') }}
            </WButton>
          </div>
          <p class="mt-2 text-xs text-blue-700 dark:text-blue-300">
            {{ $t('VOICE_AGENTS.FORM.IMPORT_AUTO_CREATE_HELP') }}
          </p>
        </div>
      </div>

      <!-- Manual Form (only in create mode or when editing) -->
      <form
        v-if="isEditing || mode === 'create'"
        class="space-y-6"
        @submit.prevent="handleSubmit"
      >
        <!-- Name -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.NAME') }} *
          </label>
          <input
            v-model="form.name"
            type="text"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
            :placeholder="$t('VOICE_AGENTS.FORM.NAME_PLACEHOLDER')"
          />
          <p v-if="errors.name" class="mt-1 text-sm text-red-600">
            {{ errors.name }}
          </p>
        </div>

        <!-- Inbox -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.INBOX') }} *
          </label>
          <select
            v-model="form.inbox_id"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
          >
            <option value="">{{ $t('VOICE_AGENTS.FORM.SELECT_INBOX') }}</option>
            <option
              v-for="inbox in availableInboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }}
            </option>
          </select>
          <p v-if="errors.inbox_id" class="mt-1 text-sm text-red-600">
            {{ errors.inbox_id }}
          </p>
        </div>

        <!-- First Message -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.FIRST_MESSAGE') }}
          </label>
          <textarea
            v-model="form.first_message"
            rows="2"
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
            :placeholder="$t('VOICE_AGENTS.FORM.FIRST_MESSAGE_PLACEHOLDER')"
          />
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {{ $t('VOICE_AGENTS.FORM.FIRST_MESSAGE_HELP') }}
          </p>
        </div>

        <!-- System Prompt -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.SYSTEM_PROMPT') }} *
          </label>
          <textarea
            v-model="form.system_prompt"
            rows="4"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100 font-mono text-sm"
            :placeholder="$t('VOICE_AGENTS.FORM.SYSTEM_PROMPT_PLACEHOLDER')"
          />
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {{ $t('VOICE_AGENTS.FORM.SYSTEM_PROMPT_HELP') }}
          </p>
          <p v-if="errors.system_prompt" class="mt-1 text-sm text-red-600">
            {{ errors.system_prompt }}
          </p>
        </div>

        <!-- Voice Configuration -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.VOICE_PROVIDER') }} *
          </label>
          <select
            v-model="form.voice_provider"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
          >
            <option value="11labs">
              {{ $t('VOICE_AGENTS.FORM.PROVIDER_11LABS') }}
            </option>
            <option value="azure">
              {{ $t('VOICE_AGENTS.FORM.PROVIDER_AZURE') }}
            </option>
            <option value="playht">
              {{ $t('VOICE_AGENTS.FORM.PROVIDER_PLAYHT') }}
            </option>
            <option value="rime">
              {{ $t('VOICE_AGENTS.FORM.PROVIDER_RIME') }}
            </option>
            <option value="deepgram">
              {{ $t('VOICE_AGENTS.FORM.PROVIDER_DEEPGRAM') }}
            </option>
          </select>
        </div>

        <!-- Voice Selection Toggle -->
        <div class="flex items-center">
          <input
            id="use_preset_voice"
            v-model="form.use_preset_voice"
            type="checkbox"
            class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-slate-300 dark:border-slate-600 rounded"
          />
          <label
            for="use_preset_voice"
            class="ml-2 block text-sm text-slate-700 dark:text-slate-300"
          >
            {{ $t('VOICE_AGENTS.FORM.USE_PRESET_VOICE') }}
          </label>
        </div>

        <!-- Preset Voice Selection -->
        <div v-if="form.use_preset_voice">
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.SELECT_VOICE') }} *
          </label>
          <select
            v-model="form.voice_id"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
          >
            <option value="">{{ $t('VOICE_AGENTS.FORM.CHOOSE_VOICE') }}</option>
            <option
              v-for="voice in availableVoices"
              :key="voice.id"
              :value="voice.id"
            >
              {{ voice.name }}
            </option>
          </select>
          <p v-if="errors.voice_id" class="mt-1 text-sm text-red-600">
            {{ errors.voice_id }}
          </p>
        </div>

        <!-- Custom Voice ID -->
        <div v-else>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.VOICE_ID') }} *
          </label>
          <input
            v-model="form.voice_id"
            type="text"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
            :placeholder="$t('VOICE_AGENTS.FORM.VOICE_ID_PLACEHOLDER')"
          />
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {{ $t('VOICE_AGENTS.FORM.VOICE_ID_HELP') }}
          </p>
          <p v-if="errors.voice_id" class="mt-1 text-sm text-red-600">
            {{ errors.voice_id }}
          </p>
        </div>

        <!-- Model Configuration -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('VOICE_AGENTS.FORM.MODEL_PROVIDER') }} *
            </label>
            <select
              v-model="form.model_provider"
              required
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
            >
              <option value="openai">
                {{ $t('VOICE_AGENTS.FORM.PROVIDER_OPENAI') }}
              </option>
              <option value="anthropic">
                {{ $t('VOICE_AGENTS.FORM.PROVIDER_ANTHROPIC') }}
              </option>
              <option value="groq">
                {{ $t('VOICE_AGENTS.FORM.PROVIDER_GROQ') }}
              </option>
              <option value="together-ai">
                {{ $t('VOICE_AGENTS.FORM.PROVIDER_TOGETHER_AI') }}
              </option>
            </select>
          </div>
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('VOICE_AGENTS.FORM.MODEL_NAME') }} *
            </label>
            <select
              v-model="form.model_name"
              required
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
            >
              <optgroup
                v-if="form.model_provider === 'openai'"
                :label="$t('VOICE_AGENTS.FORM.MODEL_GROUP_OPENAI')"
              >
                <option value="gpt-4.1">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_GPT_41_BEST') }}
                </option>
                <option value="gpt-4.1-mini">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_GPT_41_MINI') }}
                </option>
                <option value="gpt-4o">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_GPT_4O') }}
                </option>
                <option value="gpt-4o-mini">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_GPT_4O_MINI') }}
                </option>
                <option value="o4-mini">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_O4_MINI') }}
                </option>
              </optgroup>
              <optgroup
                v-if="form.model_provider === 'anthropic'"
                :label="$t('VOICE_AGENTS.FORM.MODEL_GROUP_ANTHROPIC')"
              >
                <option value="claude-3-5-sonnet">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_CLAUDE_35_SONNET') }}
                </option>
                <option value="claude-3-opus">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_CLAUDE_3_OPUS') }}
                </option>
                <option value="claude-3-sonnet">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_CLAUDE_3_SONNET') }}
                </option>
                <option value="claude-3-haiku">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_CLAUDE_3_HAIKU') }}
                </option>
              </optgroup>
              <optgroup
                v-if="form.model_provider === 'groq'"
                :label="$t('VOICE_AGENTS.FORM.MODEL_GROUP_GROQ')"
              >
                <option value="llama-3.3-70b">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_LLAMA_33_70B') }}
                </option>
                <option value="llama-3.1-70b">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_LLAMA_31_70B') }}
                </option>
                <option value="mixtral-8x7b">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_MIXTRAL_8X7B') }}
                </option>
              </optgroup>
              <optgroup
                v-if="form.model_provider === 'together-ai'"
                :label="$t('VOICE_AGENTS.FORM.MODEL_GROUP_TOGETHER_AI')"
              >
                <option value="meta-llama/Llama-3.3-70B-Instruct-Turbo">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_LLAMA_33_70B_TURBO') }}
                </option>
                <option value="meta-llama/Llama-3.1-70B-Instruct-Turbo">
                  {{ $t('VOICE_AGENTS.FORM.MODEL_LLAMA_31_70B_TURBO') }}
                </option>
              </optgroup>
            </select>
          </div>
        </div>

        <!-- Transcriber Configuration -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('VOICE_AGENTS.FORM.TRANSCRIBER_PROVIDER') }} *
            </label>
            <select
              v-model="form.transcriber_provider"
              required
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
            >
              <option value="deepgram">
                {{ $t('VOICE_AGENTS.FORM.PROVIDER_DEEPGRAM') }}
              </option>
              <option value="assemblyai">
                {{ $t('VOICE_AGENTS.FORM.PROVIDER_ASSEMBLYAI') }}
              </option>
              <option value="azure">
                {{ $t('VOICE_AGENTS.FORM.PROVIDER_AZURE') }}
              </option>
            </select>
          </div>
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('VOICE_AGENTS.FORM.LANGUAGE') }} *
            </label>
            <select
              v-model="form.transcriber_language"
              required
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
            >
              <option value="pt-BR">
                {{ $t('VOICE_AGENTS.FORM.LANG_PT_BR') }}
              </option>
              <option value="pt">{{ $t('VOICE_AGENTS.FORM.LANG_PT') }}</option>
              <option value="en">{{ $t('VOICE_AGENTS.FORM.LANG_EN') }}</option>
              <option value="en-US">
                {{ $t('VOICE_AGENTS.FORM.LANG_EN_US') }}
              </option>
              <option value="en-GB">
                {{ $t('VOICE_AGENTS.FORM.LANG_EN_GB') }}
              </option>
              <option value="en-AU">
                {{ $t('VOICE_AGENTS.FORM.LANG_EN_AU') }}
              </option>
              <option value="en-NZ">
                {{ $t('VOICE_AGENTS.FORM.LANG_EN_NZ') }}
              </option>
              <option value="en-IN">
                {{ $t('VOICE_AGENTS.FORM.LANG_EN_IN') }}
              </option>
              <option value="es">{{ $t('VOICE_AGENTS.FORM.LANG_ES') }}</option>
              <option value="es-419">
                {{ $t('VOICE_AGENTS.FORM.LANG_ES_419') }}
              </option>
              <option value="fr">{{ $t('VOICE_AGENTS.FORM.LANG_FR') }}</option>
              <option value="fr-CA">
                {{ $t('VOICE_AGENTS.FORM.LANG_FR_CA') }}
              </option>
              <option value="de">{{ $t('VOICE_AGENTS.FORM.LANG_DE') }}</option>
              <option value="de-CH">
                {{ $t('VOICE_AGENTS.FORM.LANG_DE_CH') }}
              </option>
              <option value="it">{{ $t('VOICE_AGENTS.FORM.LANG_IT') }}</option>
              <option value="ja">{{ $t('VOICE_AGENTS.FORM.LANG_JA') }}</option>
              <option value="ko">{{ $t('VOICE_AGENTS.FORM.LANG_KO') }}</option>
              <option value="zh">{{ $t('VOICE_AGENTS.FORM.LANG_ZH') }}</option>
              <option value="zh-CN">
                {{ $t('VOICE_AGENTS.FORM.LANG_ZH_CN') }}
              </option>
              <option value="zh-TW">
                {{ $t('VOICE_AGENTS.FORM.LANG_ZH_TW') }}
              </option>
              <option value="ru">{{ $t('VOICE_AGENTS.FORM.LANG_RU') }}</option>
              <option value="nl">{{ $t('VOICE_AGENTS.FORM.LANG_NL') }}</option>
              <option value="pl">{{ $t('VOICE_AGENTS.FORM.LANG_PL') }}</option>
              <option value="tr">{{ $t('VOICE_AGENTS.FORM.LANG_TR') }}</option>
              <option value="sv">{{ $t('VOICE_AGENTS.FORM.LANG_SV') }}</option>
              <option value="da">{{ $t('VOICE_AGENTS.FORM.LANG_DA') }}</option>
              <option value="no">{{ $t('VOICE_AGENTS.FORM.LANG_NO') }}</option>
              <option value="fi">{{ $t('VOICE_AGENTS.FORM.LANG_FI') }}</option>
              <option value="cs">{{ $t('VOICE_AGENTS.FORM.LANG_CS') }}</option>
              <option value="multi">
                {{ $t('VOICE_AGENTS.FORM.LANG_MULTI') }}
              </option>
            </select>
          </div>
        </div>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ $t('VOICE_AGENTS.FORM.TRANSCRIBER_HELP') }}
        </p>

        <!-- Phone Number -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('VOICE_AGENTS.FORM.PHONE_NUMBER') }}
          </label>
          <input
            v-model="form.phone_number"
            type="tel"
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-slate-100"
            :placeholder="$t('VOICE_AGENTS.FORM.PHONE_NUMBER_PLACEHOLDER')"
          />
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {{ $t('VOICE_AGENTS.FORM.PHONE_NUMBER_HELP') }}
          </p>
        </div>

        <!-- Active Toggle -->
        <div class="flex items-center">
          <input
            id="active"
            v-model="form.active"
            type="checkbox"
            class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-slate-300 dark:border-slate-600 rounded"
          />
          <label
            for="active"
            class="ml-2 block text-sm text-slate-700 dark:text-slate-300"
          >
            {{ $t('VOICE_AGENTS.FORM.ACTIVE') }}
          </label>
        </div>

        <!-- Actions -->
        <div
          class="flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-slate-700"
        >
          <WButton variant="ghost" @click="handleCancel">
            {{ $t('VOICE_AGENTS.FORM.CANCEL') }}
          </WButton>
          <WButton variant="solid" type="submit" :loading="isSubmitting">
            {{
              isEditing
                ? $t('VOICE_AGENTS.FORM.UPDATE')
                : $t('VOICE_AGENTS.FORM.CREATE')
            }}
          </WButton>
        </div>
      </form>
    </div>
  </div>
</template>
