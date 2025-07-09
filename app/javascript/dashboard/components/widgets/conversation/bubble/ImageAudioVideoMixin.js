// Mixin to handle attachment display states and error handling
export default {
  data() {
    return {
      imageLoadRetryCount: 0,
      maxRetryCount: 3,
      retryDelay: 1000, // 1 second
    };
  },
  
  computed: {
    // Kiểm tra message status thay vì attachment status vì attachment không có status riêng
    isAttachmentLoading() {
      // Lấy message status từ parent component thông qua props
      const messageStatus = this.$parent?.data?.status || this.messageStatus;
      return messageStatus === 'sent' && !this.hasValidDataUrl;
    },

    hasValidDataUrl() {
      return this.attachment?.data_url && this.attachment.data_url !== '' && this.attachment.data_url !== null;
    },

    shouldShowLoadingState() {
      // Hiển thị loading khi message đã gửi nhưng chưa có data_url hợp lệ
      return this.isAttachmentLoading;
    },

    shouldShowErrorState() {
      // Hiển thị error khi không loading và (không có URL hợp lệ hoặc có lỗi load hình)
      return !this.isAttachmentLoading && (!this.hasValidDataUrl || this.isImageError);
    },
  },
  
  methods: {
    handleImageError() {
      if (this.imageLoadRetryCount < this.maxRetryCount && this.hasValidDataUrl) {
        // Retry loading the image after a delay
        this.imageLoadRetryCount++;
        setTimeout(() => {
          // Force re-render by updating the src
          const img = this.$el.querySelector('img');
          if (img) {
            const originalSrc = img.src;
            img.src = '';
            setTimeout(() => {
              img.src = originalSrc;
            }, 100);
          }
        }, this.retryDelay * this.imageLoadRetryCount);
      } else {
        this.isImageError = true;
        this.$emit('error');
      }
    },
    
    resetImageState() {
      this.isImageError = false;
      this.imageLoadRetryCount = 0;
    },
  },
  
  watch: {
    'attachment.data_url'(newUrl, oldUrl) {
      // Reset error state when data_url changes và có URL mới hợp lệ
      if (newUrl && newUrl !== oldUrl) {
        this.resetImageState();
      }
    },

    // Watch message status thay vì attachment status
    '$parent.data.status'(newStatus) {
      // Reset error state when message status changes to delivered/read
      if (['delivered', 'read'].includes(newStatus)) {
        this.resetImageState();
      }
    },
  },
};
