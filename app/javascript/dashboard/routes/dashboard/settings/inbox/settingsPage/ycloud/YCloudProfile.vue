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
      profile: { about: '', address: '', description: '', email: '', vertical: '', websites: [] },
      commerce: { isCatalogVisible: false, isCartEnabled: false },
      phoneNumbers: [],
      isLoading: false,
      isSaving: false,
      isSavingCommerce: false,
      newWebsite: '',
    };
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    async fetchData() {
      this.isLoading = true;
      try {
        const [profileRes, commerceRes, phonesRes] = await Promise.allSettled([
          YCloudAPI.getProfile(this.inbox.id),
          YCloudAPI.getCommerceSettings(this.inbox.id),
          YCloudAPI.listPhoneNumbers(this.inbox.id),
        ]);
        if (profileRes.status === 'fulfilled') {
          Object.assign(this.profile, profileRes.value.data);
          this.profile.websites = this.profile.websites || [];
        }
        if (commerceRes.status === 'fulfilled') {
          Object.assign(this.commerce, commerceRes.value.data);
        }
        if (phonesRes.status === 'fulfilled') {
          this.phoneNumbers = phonesRes.value.data.items || [];
        }
      } catch {
        useAlert(this.$t('YCLOUD.PROFILE.FETCH_ERROR'));
      }
      this.isLoading = false;
    },
    async saveProfile() {
      this.isSaving = true;
      try {
        await YCloudAPI.updateProfile(this.inbox.id, {
          about: this.profile.about,
          address: this.profile.address,
          description: this.profile.description,
          email: this.profile.email,
          vertical: this.profile.vertical,
          websites: this.profile.websites,
        });
        useAlert(this.$t('YCLOUD.PROFILE.SAVE_SUCCESS'));
      } catch {
        useAlert(this.$t('YCLOUD.PROFILE.SAVE_ERROR'));
      }
      this.isSaving = false;
    },
    async saveCommerceSettings() {
      this.isSavingCommerce = true;
      try {
        await YCloudAPI.updateCommerceSettings(this.inbox.id, this.commerce);
        useAlert(this.$t('YCLOUD.PROFILE.COMMERCE_SAVE_SUCCESS'));
      } catch {
        useAlert(this.$t('YCLOUD.PROFILE.COMMERCE_SAVE_ERROR'));
      }
      this.isSavingCommerce = false;
    },
    addWebsite() {
      if (this.newWebsite && !this.profile.websites.includes(this.newWebsite)) {
        this.profile.websites.push(this.newWebsite);
        this.newWebsite = '';
      }
    },
    removeWebsite(index) {
      this.profile.websites.splice(index, 1);
    },
  },
};
</script>

<template>
  <div class="py-4">
    <div v-if="isLoading" class="text-center py-8"><span class="spinner" /></div>
    <div v-else>
      <!-- Business Profile -->
      <SettingsSection
        :title="$t('YCLOUD.PROFILE.TITLE')"
        :sub-title="$t('YCLOUD.PROFILE.DESC')"
      >
        <label class="block mb-3">
          {{ $t('YCLOUD.PROFILE.ABOUT') }}
          <input v-model="profile.about" type="text" class="mt-1" maxlength="139" />
        </label>
        <label class="block mb-3">
          {{ $t('YCLOUD.PROFILE.DESCRIPTION') }}
          <textarea v-model="profile.description" rows="3" class="mt-1" maxlength="512" />
        </label>
        <label class="block mb-3">
          {{ $t('YCLOUD.PROFILE.ADDRESS') }}
          <input v-model="profile.address" type="text" class="mt-1" maxlength="256" />
        </label>
        <label class="block mb-3">
          {{ $t('YCLOUD.PROFILE.EMAIL') }}
          <input v-model="profile.email" type="email" class="mt-1" />
        </label>
        <label class="block mb-3">
          {{ $t('YCLOUD.PROFILE.VERTICAL') }}
          <select v-model="profile.vertical" class="mt-1">
            <option value="">—</option>
            <option v-for="v in ['AUTOMOTIVE','BEAUTY','APPAREL','EDU','ENTERTAIN','EVENT_PLAN','FINANCE','GROCERY','GOVT','HOTEL','HEALTH','NONPROFIT','PROF_SERVICES','RETAIL','TRAVEL','RESTAURANT','OTHER']" :key="v" :value="v">{{ v }}</option>
          </select>
        </label>
        <div class="mb-3">
          <p class="font-medium text-sm mb-1">{{ $t('YCLOUD.PROFILE.WEBSITES') }}</p>
          <div v-for="(site, i) in profile.websites" :key="i" class="flex items-center gap-2 mb-1">
            <span class="text-sm flex-1">{{ site }}</span>
            <button class="text-red-600 text-xs hover:underline" @click="removeWebsite(i)">{{ $t('YCLOUD.COMMON.DELETE') }}</button>
          </div>
          <div class="flex gap-2">
            <input v-model="newWebsite" type="url" :placeholder="$t('YCLOUD.PROFILE.WEBSITE_PLACEHOLDER')" class="flex-1" @keyup.enter="addWebsite" />
            <NextButton :label="$t('YCLOUD.COMMON.ADD')" size="sm" @click="addWebsite" />
          </div>
        </div>
        <NextButton :label="$t('YCLOUD.COMMON.SAVE')" :is-loading="isSaving" @click="saveProfile" />
      </SettingsSection>

      <!-- Commerce Settings -->
      <SettingsSection
        :title="$t('YCLOUD.PROFILE.COMMERCE_TITLE')"
        :sub-title="$t('YCLOUD.PROFILE.COMMERCE_DESC')"
      >
        <label class="flex items-center gap-3 mb-3">
          <input v-model="commerce.isCatalogVisible" type="checkbox" />
          {{ $t('YCLOUD.PROFILE.CATALOG_VISIBLE') }}
        </label>
        <label class="flex items-center gap-3 mb-3">
          <input v-model="commerce.isCartEnabled" type="checkbox" />
          {{ $t('YCLOUD.PROFILE.CART_ENABLED') }}
        </label>
        <NextButton :label="$t('YCLOUD.COMMON.SAVE')" :is-loading="isSavingCommerce" @click="saveCommerceSettings" />
      </SettingsSection>

      <!-- Phone Numbers -->
      <SettingsSection
        :title="$t('YCLOUD.PROFILE.PHONE_NUMBERS')"
        :sub-title="$t('YCLOUD.PROFILE.PHONE_NUMBERS_DESC')"
        :show-border="false"
      >
        <div v-if="phoneNumbers.length">
          <div v-for="phone in phoneNumbers" :key="phone.id" class="p-3 bg-n-slate-1 rounded-lg mb-2">
            <p class="font-medium">{{ phone.phoneNumber || phone.phone_number }}</p>
            <p class="text-sm text-n-slate-11">
              {{ phone.displayName || phone.display_name || '' }} | Quality: {{ phone.qualityRating || '—' }}
            </p>
          </div>
        </div>
        <p v-else class="text-n-slate-11">{{ $t('YCLOUD.PROFILE.NO_PHONES') }}</p>
      </SettingsSection>
    </div>
  </div>
</template>
