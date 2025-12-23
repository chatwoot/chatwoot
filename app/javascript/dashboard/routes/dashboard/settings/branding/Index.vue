<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, url, email } from '@vuelidate/validators';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import NextInput from 'next/input/Input.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import brandingAPI from 'dashboard/api/branding';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    BaseSettingsHeader,
    NextButton,
    NextInput,
    WithLabel,
    Spinner,
  },
  setup() {
    const v$ = useVuelidate();
    return { v$ };
  },
  data() {
    return {
      brandName: 'SynkiCRM',
      brandWebsite: 'https://synkicrm.com.br/',
      supportEmail: 'suporte@synkicrm.com.br',
      logoMain: null,
      logoMainPreview: null,
      logoCompact: null,
      logoCompactPreview: null,
      favicon: null,
      faviconPreview: null,
      appleTouchIcon: null,
      appleTouchIconPreview: null,
      uiFlags: {
        isFetching: false,
        isUpdating: false,
      },
    };
  },
  validations: {
    brandName: { required },
    brandWebsite: { required, url },
    supportEmail: { required, email },
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    this.fetchBranding();
  },
  methods: {
    async fetchBranding() {
      this.uiFlags.isFetching = true;
      try {
        const response = await brandingAPI.get();
        const data = response.data;
        this.brandName = data.brand_name || 'SynkiCRM';
        this.brandWebsite = data.brand_website || 'https://synkicrm.com.br/';
        this.supportEmail = data.support_email || 'suporte@synkicrm.com.br';
        this.logoMainPreview = data.logo_main_url;
        this.logoCompactPreview = data.logo_compact_url;
        this.faviconPreview = data.favicon_url;
        this.appleTouchIconPreview = data.apple_touch_icon_url;
      } catch (error) {
        useAlert(this.$t('BRANDING.FETCH_ERROR'));
      } finally {
        this.uiFlags.isFetching = false;
      }
    },
    async updateBranding() {
      const isFormValid = await this.v$.$validate();
      if (!isFormValid) return;

      this.uiFlags.isUpdating = true;
      try {
        const formData = new FormData();
        formData.append('brand_name', this.brandName);
        formData.append('brand_website', this.brandWebsite);
        formData.append('support_email', this.supportEmail);

        if (this.logoMain) {
          formData.append('logo_main', this.logoMain);
        }
        if (this.logoCompact) {
          formData.append('logo_compact', this.logoCompact);
        }
        if (this.favicon) {
          formData.append('favicon', this.favicon);
        }
        if (this.appleTouchIcon) {
          formData.append('apple_touch_icon', this.appleTouchIcon);
        }

        const response = await brandingAPI.update(formData);
        const data = response.data;

        // Update previews with new URLs
        if (data.logo_main_url) this.logoMainPreview = data.logo_main_url;
        if (data.logo_compact_url) this.logoCompactPreview = data.logo_compact_url;
        if (data.favicon_url) this.faviconPreview = data.favicon_url;
        if (data.apple_touch_icon_url) this.appleTouchIconPreview = data.apple_touch_icon_url;

        // Clear file inputs
        this.logoMain = null;
        this.logoCompact = null;
        this.favicon = null;
        this.appleTouchIcon = null;

        // Reset file input refs
        this.$refs.logoMainInput.value = '';
        this.$refs.logoCompactInput.value = '';
        this.$refs.faviconInput.value = '';
        this.$refs.appleTouchIconInput.value = '';

        useAlert(this.$t('BRANDING.UPDATE_SUCCESS'));
        
        // Update global config and reload branding
        await this.$store.dispatch('globalConfig/fetch');
        this.fetchBranding();
      } catch (error) {
        useAlert(error.response?.data?.errors?.join(', ') || this.$t('BRANDING.UPDATE_ERROR'));
      } finally {
        this.uiFlags.isUpdating = false;
      }
    },
    onLogoMainChange(event) {
      const file = event.target.files[0];
      if (file) {
        this.logoMain = file;
        this.createPreview(file, 'logoMainPreview');
      }
    },
    onLogoCompactChange(event) {
      const file = event.target.files[0];
      if (file) {
        this.logoCompact = file;
        this.createPreview(file, 'logoCompactPreview');
      }
    },
    onFaviconChange(event) {
      const file = event.target.files[0];
      if (file) {
        this.favicon = file;
        this.createPreview(file, 'faviconPreview');
      }
    },
    onAppleTouchIconChange(event) {
      const file = event.target.files[0];
      if (file) {
        this.appleTouchIcon = file;
        this.createPreview(file, 'appleTouchIconPreview');
      }
    },
    createPreview(file, previewKey) {
      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = e => {
          this[previewKey] = e.target.result;
        };
        reader.readAsDataURL(file);
      }
    },
  },
};
</script>

<template>
  <div class="w-full">
    <BaseSettingsHeader
      :header-title="$t('BRANDING.TITLE')"
      :header-content="$t('BRANDING.DESCRIPTION')"
    />
    <div v-if="uiFlags.isFetching" class="flex justify-center p-8">
      <Spinner />
    </div>
    <div v-else class="mx-8">
      <div class="space-y-6">
        <!-- Text Fields -->
        <div class="space-y-4">
          <WithLabel :label="$t('BRANDING.BRAND_NAME')" :required="true">
            <NextInput
              v-model="brandName"
              :placeholder="$t('BRANDING.BRAND_NAME_PLACEHOLDER')"
              :error="v$.brandName.$error ? $t('BRANDING.BRAND_NAME_REQUIRED') : ''"
            />
          </WithLabel>

          <WithLabel :label="$t('BRANDING.BRAND_WEBSITE')" :required="true">
            <NextInput
              v-model="brandWebsite"
              :placeholder="$t('BRANDING.BRAND_WEBSITE_PLACEHOLDER')"
              :error="v$.brandWebsite.$error ? $t('BRANDING.BRAND_WEBSITE_INVALID') : ''"
            />
          </WithLabel>

          <WithLabel :label="$t('BRANDING.SUPPORT_EMAIL')" :required="true">
            <NextInput
              v-model="supportEmail"
              type="email"
              :placeholder="$t('BRANDING.SUPPORT_EMAIL_PLACEHOLDER')"
              :error="v$.supportEmail.$error ? $t('BRANDING.SUPPORT_EMAIL_INVALID') : ''"
            />
          </WithLabel>
        </div>

        <!-- File Uploads -->
        <div class="space-y-6 border-t border-slate-200 pt-6">
          <h3 class="text-lg font-semibold">{{ $t('BRANDING.ASSETS') }}</h3>

          <!-- Logo Main -->
          <div class="space-y-2">
            <label class="block text-sm font-medium">{{ $t('BRANDING.LOGO_MAIN') }}</label>
            <div class="flex items-center gap-4">
              <input
                ref="logoMainInput"
                type="file"
                accept="image/png,image/jpeg,image/jpg,image/svg+xml,image/gif,image/webp"
                class="hidden"
                @change="onLogoMainChange"
              />
              <button
                type="button"
                class="px-4 py-2 border border-slate-300 rounded hover:bg-slate-50"
                @click="$refs.logoMainInput.click()"
              >
                {{ $t('BRANDING.CHOOSE_FILE') }}
              </button>
              <div v-if="logoMainPreview" class="flex items-center gap-2">
                <img :src="logoMainPreview" alt="Logo Main" class="h-12 max-w-xs object-contain" />
                <span class="text-sm text-slate-600">{{ $t('BRANDING.PREVIEW') }}</span>
              </div>
            </div>
            <p class="text-xs text-slate-500">{{ $t('BRANDING.LOGO_MAIN_HELP') }}</p>
          </div>

          <!-- Logo Compact -->
          <div class="space-y-2">
            <label class="block text-sm font-medium">{{ $t('BRANDING.LOGO_COMPACT') }}</label>
            <div class="flex items-center gap-4">
              <input
                ref="logoCompactInput"
                type="file"
                accept="image/png,image/jpeg,image/jpg,image/svg+xml,image/gif,image/webp"
                class="hidden"
                @change="onLogoCompactChange"
              />
              <button
                type="button"
                class="px-4 py-2 border border-slate-300 rounded hover:bg-slate-50"
                @click="$refs.logoCompactInput.click()"
              >
                {{ $t('BRANDING.CHOOSE_FILE') }}
              </button>
              <div v-if="logoCompactPreview" class="flex items-center gap-2">
                <img :src="logoCompactPreview" alt="Logo Compact" class="h-8 max-w-xs object-contain" />
                <span class="text-sm text-slate-600">{{ $t('BRANDING.PREVIEW') }}</span>
              </div>
            </div>
            <p class="text-xs text-slate-500">{{ $t('BRANDING.LOGO_COMPACT_HELP') }}</p>
          </div>

          <!-- Favicon -->
          <div class="space-y-2">
            <label class="block text-sm font-medium">{{ $t('BRANDING.FAVICON') }}</label>
            <div class="flex items-center gap-4">
              <input
                ref="faviconInput"
                type="file"
                accept="image/png,image/x-icon,image/svg+xml,image/vnd.microsoft.icon"
                class="hidden"
                @change="onFaviconChange"
              />
              <button
                type="button"
                class="px-4 py-2 border border-slate-300 rounded hover:bg-slate-50"
                @click="$refs.faviconInput.click()"
              >
                {{ $t('BRANDING.CHOOSE_FILE') }}
              </button>
              <div v-if="faviconPreview" class="flex items-center gap-2">
                <img :src="faviconPreview" alt="Favicon" class="h-8 w-8 object-contain" />
                <span class="text-sm text-slate-600">{{ $t('BRANDING.PREVIEW') }}</span>
              </div>
            </div>
            <p class="text-xs text-slate-500">{{ $t('BRANDING.FAVICON_HELP') }}</p>
          </div>

          <!-- Apple Touch Icon -->
          <div class="space-y-2">
            <label class="block text-sm font-medium">{{ $t('BRANDING.APPLE_TOUCH_ICON') }}</label>
            <div class="flex items-center gap-4">
              <input
                ref="appleTouchIconInput"
                type="file"
                accept="image/png,image/jpeg,image/jpg"
                class="hidden"
                @change="onAppleTouchIconChange"
              />
              <button
                type="button"
                class="px-4 py-2 border border-slate-300 rounded hover:bg-slate-50"
                @click="$refs.appleTouchIconInput.click()"
              >
                {{ $t('BRANDING.CHOOSE_FILE') }}
              </button>
              <div v-if="appleTouchIconPreview" class="flex items-center gap-2">
                <img :src="appleTouchIconPreview" alt="Apple Touch Icon" class="h-16 w-16 object-contain" />
                <span class="text-sm text-slate-600">{{ $t('BRANDING.PREVIEW') }}</span>
              </div>
            </div>
            <p class="text-xs text-slate-500">{{ $t('BRANDING.APPLE_TOUCH_ICON_HELP') }}</p>
          </div>
        </div>

        <!-- Save Button -->
        <div class="flex justify-end pt-4 border-t border-slate-200">
          <NextButton
            :is-loading="uiFlags.isUpdating"
            :disabled="v$.$invalid"
            @click="updateBranding"
          >
            {{ $t('BRANDING.SAVE') }}
          </NextButton>
        </div>
      </div>
    </div>
  </div>
</template>

