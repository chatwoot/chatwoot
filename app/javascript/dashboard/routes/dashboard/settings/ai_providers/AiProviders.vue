<script>
import { mapGetters, mapActions } from 'vuex';
import { useAlert } from 'dashboard/composables';
import PageHeader from '../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'AiProviders',
  components: {
    PageHeader,
    NextButton,
  },
  data() {
    return {
      showAddForm: false,
      editingProvider: null,
      form: {
        name: '',
        base_url: '',
        api_key: '',
        models: '',
        is_primary: false,
        monthly_cap: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      providers: 'whiskerAi/getProviders',
      uiFlags: 'whiskerAi/getUIFlags',
    }),
  },
  mounted() {
    this.fetchProviders();
  },
  methods: {
    ...mapActions('whiskerAi', ['fetchProviders', 'createProvider', 'updateProvider', 'deleteProvider', 'setPrimaryProvider']),
    resetForm() {
      this.form = {
        name: '',
        base_url: '',
        api_key: '',
        models: '',
        is_primary: false,
        monthly_cap: '',
      };
      this.editingProvider = null;
    },
    openAddForm() {
      this.resetForm();
      this.showAddForm = true;
    },
    editProvider(provider) {
      this.form = {
        name: provider.name,
        base_url: provider.base_url,
        api_key: provider.api_key || '',
        models: (provider.models || []).join(', '),
        is_primary: provider.is_primary,
        monthly_cap: provider.monthly_cap || '',
      };
      this.editingProvider = provider;
      this.showAddForm = true;
    },
    async handleSubmit() {
      const payload = {
        ...this.form,
        models: this.form.models.split(',').map(m => m.trim()).filter(Boolean),
        monthly_cap: this.form.monthly_cap ? parseFloat(this.form.monthly_cap) : null,
      };
      try {
        if (this.editingProvider) {
          await this.updateProvider({ id: this.editingProvider.id, ...payload });
          useAlert(this.$t('AI_PROVIDERS.UPDATE.SUCCESS'));
        } else {
          await this.createProvider(payload);
          useAlert(this.$t('AI_PROVIDERS.CREATE.SUCCESS'));
        }
        this.showAddForm = false;
        this.resetForm();
      } catch (error) {
        useAlert(error.message || this.$t('AI_PROVIDERS.ERROR'));
      }
    },
    async handleDelete(provider) {
      try {
        await this.deleteProvider(provider.id);
        useAlert(this.$t('AI_PROVIDERS.DELETE.SUCCESS'));
      } catch (error) {
        useAlert(error.message || this.$t('AI_PROVIDERS.ERROR'));
      }
    },
    async handleSetPrimary(provider) {
      try {
        await this.setPrimaryProvider(provider.id);
        useAlert(this.$t('AI_PROVIDERS.SET_PRIMARY.SUCCESS'));
      } catch (error) {
        useAlert(error.message || this.$t('AI_PROVIDERS.ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full overflow-auto">
    <PageHeader
      :header-title="$t('AI_PROVIDERS.TITLE')"
      :header-content="$t('AI_PROVIDERS.DESC')"
    />
    <div class="flex-1 px-6 py-4">
      <NextButton
        class="mb-4"
        solid
        blue
        :label="$t('AI_PROVIDERS.ADD_BUTTON')"
        @click="openAddForm"
      />

      <!-- Provider list -->
      <div class="space-y-3">
        <div
          v-for="provider in providers"
          :key="provider.id"
          class="flex items-center justify-between p-4 border rounded-lg"
          :class="provider.is_primary ? 'border-n-brand bg-n-brand-1' : 'border-n-slate-6'"
        >
          <div class="flex items-center gap-3">
            <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-slate-2">
              <span class="text-lg font-bold text-n-slate-12">{{ provider.name[0]?.toUpperCase() }}</span>
            </div>
            <div>
              <div class="flex items-center gap-2">
                <span class="font-medium text-n-slate-12">{{ provider.name }}</span>
                <span
                  v-if="provider.is_primary"
                  class="px-2 py-0.5 text-xs font-medium rounded-full bg-n-brand text-white"
                >
                  {{ $t('AI_PROVIDERS.PRIMARY') }}
                </span>
              </div>
              <div class="text-sm text-n-slate-11">{{ provider.base_url }}</div>
              <div class="text-xs text-n-slate-10">{{ (provider.models || []).join(', ') }}</div>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <NextButton
              v-if="!provider.is_primary"
              ghost
              :label="$t('AI_PROVIDERS.SET_AS_PRIMARY')"
              @click="handleSetPrimary(provider)"
            />
            <NextButton
              ghost
              :label="$t('AI_PROVIDERS.EDIT')"
              @click="editProvider(provider)"
            />
            <NextButton
              ghost
              red
              :label="$t('AI_PROVIDERS.DELETE.BUTTON')"
              @click="handleDelete(provider)"
            />
          </div>
        </div>
      </div>

      <!-- Add/Edit form -->
      <div v-if="showAddForm" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-full max-w-lg p-6 bg-n-background rounded-lg shadow-xl">
          <h3 class="text-lg font-medium text-n-slate-12 mb-4">
            {{ editingProvider ? $t('AI_PROVIDERS.EDIT_TITLE') : $t('AI_PROVIDERS.ADD_TITLE') }}
          </h3>
          <form @submit.prevent="handleSubmit" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">{{ $t('AI_PROVIDERS.FORM.NAME') }}</label>
              <input
                v-model="form.name"
                type="text"
                required
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                :placeholder="$t('AI_PROVIDERS.FORM.NAME_PLACEHOLDER')"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">{{ $t('AI_PROVIDERS.FORM.BASE_URL') }}</label>
              <input
                v-model="form.base_url"
                type="url"
                required
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                placeholder="https://api.openai.com"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">{{ $t('AI_PROVIDERS.FORM.API_KEY') }}</label>
              <input
                v-model="form.api_key"
                type="password"
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                placeholder="sk-..."
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">{{ $t('AI_PROVIDERS.FORM.MODELS') }}</label>
              <input
                v-model="form.models"
                type="text"
                required
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                placeholder="gpt-4o-mini, gpt-4o"
              />
              <p class="text-xs text-n-slate-10 mt-1">{{ $t('AI_PROVIDERS.FORM.MODELS_HELP') }}</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">{{ $t('AI_PROVIDERS.FORM.MONTHLY_CAP') }}</label>
              <input
                v-model="form.monthly_cap"
                type="number"
                step="0.01"
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-background text-n-slate-12"
                placeholder="10.00"
              />
            </div>
            <div class="flex items-center gap-2">
              <input
                v-model="form.is_primary"
                type="checkbox"
                class="rounded border-n-slate-6"
              />
              <label class="text-sm text-n-slate-11">{{ $t('AI_PROVIDERS.FORM.PRIMARY') }}</label>
            </div>
            <div class="flex justify-end gap-2 pt-4">
              <NextButton
                ghost
                :label="$t('AI_PROVIDERS.FORM.CANCEL')"
                @click="showAddForm = false"
              />
              <NextButton
                solid
                blue
                type="submit"
                :is-loading="uiFlags.isCreating || uiFlags.isUpdating"
                :label="$t('AI_PROVIDERS.FORM.SAVE')"
              />
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
