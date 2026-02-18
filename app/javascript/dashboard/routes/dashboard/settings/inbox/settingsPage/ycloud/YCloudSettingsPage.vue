<script>
import YCloudDashboard from './YCloudDashboard.vue';
import YCloudTemplates from './YCloudTemplates.vue';
import YCloudFlows from './YCloudFlows.vue';
import YCloudProfile from './YCloudProfile.vue';
import YCloudCalling from './YCloudCalling.vue';
import YCloudContacts from './YCloudContacts.vue';
import YCloudMultiChannel from './YCloudMultiChannel.vue';
import YCloudUnsubscribers from './YCloudUnsubscribers.vue';

export default {
  components: {
    YCloudDashboard,
    YCloudTemplates,
    YCloudFlows,
    YCloudProfile,
    YCloudCalling,
    YCloudContacts,
    YCloudMultiChannel,
    YCloudUnsubscribers,
  },
  props: {
    inbox: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      activeSection: 'dashboard',
    };
  },
  computed: {
    sections() {
      return [
        { key: 'dashboard', label: this.$t('YCLOUD.SECTIONS.DASHBOARD'), icon: 'i-lucide-layout-dashboard' },
        { key: 'templates', label: this.$t('YCLOUD.SECTIONS.TEMPLATES'), icon: 'i-lucide-file-text' },
        { key: 'flows', label: this.$t('YCLOUD.SECTIONS.FLOWS'), icon: 'i-lucide-git-branch' },
        { key: 'profile', label: this.$t('YCLOUD.SECTIONS.PROFILE'), icon: 'i-lucide-building-2' },
        { key: 'calling', label: this.$t('YCLOUD.SECTIONS.CALLING'), icon: 'i-lucide-phone' },
        { key: 'contacts', label: this.$t('YCLOUD.SECTIONS.CONTACTS'), icon: 'i-lucide-users' },
        { key: 'multichannel', label: this.$t('YCLOUD.SECTIONS.MULTICHANNEL'), icon: 'i-lucide-send' },
        { key: 'unsubscribers', label: this.$t('YCLOUD.SECTIONS.UNSUB_WEBHOOKS'), icon: 'i-lucide-shield' },
      ];
    },
  },
};
</script>

<template>
  <div>
    <!-- Section Navigation -->
    <div class="flex flex-wrap gap-1 mb-6 border-b border-n-weak overflow-x-auto">
      <button
        v-for="section in sections"
        :key="section.key"
        class="px-3 py-2 text-sm font-medium whitespace-nowrap border-b-2 transition-colors"
        :class="activeSection === section.key
          ? 'border-n-blue-text text-n-blue-text'
          : 'border-transparent text-n-slate-11 hover:text-n-slate-12'"
        @click="activeSection = section.key"
      >
        {{ section.label }}
      </button>
    </div>

    <!-- Active Section Content -->
    <YCloudDashboard v-if="activeSection === 'dashboard'" :inbox="inbox" />
    <YCloudTemplates v-if="activeSection === 'templates'" :inbox="inbox" />
    <YCloudFlows v-if="activeSection === 'flows'" :inbox="inbox" />
    <YCloudProfile v-if="activeSection === 'profile'" :inbox="inbox" />
    <YCloudCalling v-if="activeSection === 'calling'" :inbox="inbox" />
    <YCloudContacts v-if="activeSection === 'contacts'" :inbox="inbox" />
    <YCloudMultiChannel v-if="activeSection === 'multichannel'" :inbox="inbox" />
    <YCloudUnsubscribers v-if="activeSection === 'unsubscribers'" :inbox="inbox" />
  </div>
</template>
