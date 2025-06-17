<script>
import conversationAdsTrackingAPI from 'dashboard/api/conversation/adsTracking';
import { formatDistanceToNow } from 'date-fns';
import { vi } from 'date-fns/locale';

export default {
  name: 'AdsTrackingInfo',
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      adsTrackingData: [],
      isLoading: false,
      error: null,
    };
  },
  computed: {
    hasAdsData() {
      return this.adsTrackingData && this.adsTrackingData.length > 0;
    },
    latestAdsData() {
      return this.hasAdsData ? this.adsTrackingData[0] : null;
    },
  },
  mounted() {
    this.fetchAdsTrackingData();
  },
  methods: {
    async fetchAdsTrackingData() {
      if (!this.conversationId) return;
      
      this.isLoading = true;
      this.error = null;
      
      try {
        const response = await conversationAdsTrackingAPI.getAdsTracking(this.conversationId);
        this.adsTrackingData = response.data.data || [];
      } catch (error) {
        console.error('Error fetching ads tracking data:', error);
        this.error = 'Không thể tải thông tin quảng cáo';
      } finally {
        this.isLoading = false;
      }
    },
    formatDate(date) {
      if (!date) return '';
      return formatDistanceToNow(new Date(date), { 
        addSuffix: true, 
        locale: vi 
      });
    },
    getPlatformIcon(platform) {
      return platform === 'Instagram' ? 'i-ph-instagram-logo' : 'i-ph-facebook-logo';
    },
    getPlatformColor(platform) {
      return platform === 'Instagram' ? 'text-pink-600' : 'text-blue-600';
    },
    getSourceLabel(source) {
      const sourceLabels = {
        'ADS': 'Quảng cáo',
        'SHORTLINK': 'Liên kết ngắn',
        'MESSENGER_CODE': 'Mã Messenger',
        'DISCOVER_TAB': 'Tab khám phá',
        'CUSTOMER_CHAT_PLUGIN': 'Plugin chat',
        'UNKNOWN': 'Không xác định'
      };
      return sourceLabels[source] || source;
    },
    getTypeLabel(type) {
      const typeLabels = {
        'OPEN_THREAD': 'Mở cuộc trò chuyện',
        'UNKNOWN': 'Không xác định'
      };
      return typeLabels[type] || type;
    },
  },
};
</script>

<template>
  <div class="ads-tracking-info">
    <div v-if="isLoading" class="flex items-center justify-center p-4">
      <div class="spinner" />
      <span class="ml-2 text-sm text-n-slate-11">Đang tải thông tin quảng cáo...</span>
    </div>
    
    <div v-else-if="error" class="p-4 text-center">
      <p class="text-sm text-red-600">{{ error }}</p>
    </div>
    
    <div v-else-if="!hasAdsData" class="p-4 text-center">
      <p class="text-sm text-n-slate-11">Không có thông tin quảng cáo</p>
    </div>
    
    <div v-else class="space-y-3">
      <div 
        v-for="adsData in adsTrackingData" 
        :key="adsData.id"
        class="p-3 bg-n-slate-1 rounded-lg border border-n-slate-3"
      >
        <!-- Header với platform và thời gian -->
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center space-x-2">
            <i 
              :class="[getPlatformIcon(adsData.platform), getPlatformColor(adsData.platform)]"
              class="text-lg"
            />
            <span class="font-medium text-sm">{{ adsData.platform }}</span>
          </div>
          <span class="text-xs text-n-slate-11">
            {{ formatDate(adsData.created_at) }}
          </span>
        </div>
        
        <!-- Thông tin nguồn -->
        <div class="space-y-2 text-sm">
          <div class="flex justify-between">
            <span class="text-n-slate-11">Nguồn:</span>
            <span class="font-medium">{{ getSourceLabel(adsData.referral_source) }}</span>
          </div>
          
          <div class="flex justify-between">
            <span class="text-n-slate-11">Loại:</span>
            <span class="font-medium">{{ getTypeLabel(adsData.referral_type) }}</span>
          </div>
          
          <div v-if="adsData.ref_parameter" class="flex justify-between">
            <span class="text-n-slate-11">Tham số:</span>
            <span class="font-mono text-xs bg-n-slate-2 px-2 py-1 rounded">
              {{ adsData.ref_parameter }}
            </span>
          </div>
        </div>
        
        <!-- Thông tin quảng cáo -->
        <div v-if="adsData.ad_id || adsData.campaign_id || adsData.adset_id" class="mt-3 pt-3 border-t border-n-slate-3">
          <h4 class="text-sm font-medium text-n-slate-12 mb-2">Thông tin quảng cáo</h4>
          <div class="space-y-1 text-xs">
            <div v-if="adsData.ad_id" class="flex justify-between">
              <span class="text-n-slate-11">ID Quảng cáo:</span>
              <span class="font-mono">{{ adsData.ad_id }}</span>
            </div>
            
            <div v-if="adsData.campaign_id" class="flex justify-between">
              <span class="text-n-slate-11">ID Chiến dịch:</span>
              <span class="font-mono">{{ adsData.campaign_id }}</span>
            </div>
            
            <div v-if="adsData.adset_id" class="flex justify-between">
              <span class="text-n-slate-11">ID Nhóm quảng cáo:</span>
              <span class="font-mono">{{ adsData.adset_id }}</span>
            </div>
            
            <div v-if="adsData.ad_title" class="flex justify-between">
              <span class="text-n-slate-11">Tiêu đề:</span>
              <span class="truncate max-w-32" :title="adsData.ad_title">{{ adsData.ad_title }}</span>
            </div>
          </div>
        </div>
        
        <!-- Trạng thái conversion -->
        <div v-if="adsData.conversion_sent !== undefined" class="mt-3 pt-3 border-t border-n-slate-3">
          <div class="flex items-center justify-between">
            <span class="text-sm text-n-slate-11">Conversion:</span>
            <span 
              :class="[
                'text-xs px-2 py-1 rounded-full',
                adsData.conversion_sent 
                  ? 'bg-green-100 text-green-800' 
                  : 'bg-yellow-100 text-yellow-800'
              ]"
            >
              {{ adsData.conversion_sent ? 'Đã gửi' : 'Chờ gửi' }}
            </span>
          </div>
          
          <div v-if="adsData.event_name" class="flex justify-between mt-1">
            <span class="text-xs text-n-slate-11">Sự kiện:</span>
            <span class="text-xs">{{ adsData.event_name }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.spinner {
  @apply w-4 h-4 border-2 border-n-slate-3 border-t-n-brand rounded-full animate-spin;
}
</style>
