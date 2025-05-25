<script setup>
import Banner from 'dashboard/components-next/banner/Banner.vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['reauthorize']);

// Xác định loại kênh để hiển thị thông báo phù hợp
const channelType = props.inbox?.channel_type || 'unknown';
const isEmailChannel = ['Email', 'Microsoft', 'Google'].includes(channelType);
const isFacebookChannel = channelType === 'Channel::FacebookPage';
const isInstagramChannel = channelType === 'Channel::Instagram';

// Tạo thông báo chi tiết dựa trên loại kênh
const getDetailedMessage = () => {
  if (isFacebookChannel) {
    return 'Facebook access token đã hết hạn hoặc không hợp lệ. Vui lòng kết nối lại để tiếp tục nhận và gửi tin nhắn.';
  } else if (isInstagramChannel) {
    return 'Instagram access token đã hết hạn hoặc không hợp lệ. Vui lòng kết nối lại để tiếp tục nhận và gửi tin nhắn.';
  } else if (isEmailChannel) {
    return 'Email authentication đã hết hạn. Vui lòng kết nối lại để tiếp tục nhận email.';
  }
  return 'Kết nối đã hết hạn. Vui lòng kết nối lại để tiếp tục sử dụng.';
};

const getActionLabel = () => {
  if (isFacebookChannel) {
    return 'Kết nối lại Facebook';
  } else if (isInstagramChannel) {
    return 'Kết nối lại Instagram';
  } else if (isEmailChannel) {
    return 'Kết nối lại Email';
  }
  return 'Kết nối lại';
};
</script>

<template>
  <Banner
    color="ruby"
    :action-label="getActionLabel()"
    @action="emit('reauthorize')"
  >
    <div class="flex flex-col gap-2">
      <div class="font-medium">
        {{ $t('INBOX_MGMT.RECONNECTION_REQUIRED') }}
      </div>
      <div class="text-sm opacity-90">
        {{ getDetailedMessage() }}
      </div>
      <div v-if="isFacebookChannel" class="text-xs opacity-75">
        💡 Mẹo: Token Facebook thường hết hạn khi bạn thay đổi mật khẩu hoặc cài đặt bảo mật. Việc kết nối lại sẽ không làm mất tin nhắn cũ.
      </div>
    </div>
  </Banner>
</template>
