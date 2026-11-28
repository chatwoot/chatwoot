import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { getMaxUploadSizeByChannel } from '@chatwoot/utils';
import { DirectUpload } from 'activestorage';
import { setDirectUploadAuthHeaders } from 'dashboard/helper/directUploadsHelper';
import {
  DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE,
  resolveMaximumFileUploadSize,
} from 'shared/helpers/FileHelper';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  getImageOptimizationPolicy,
  imageNeedsOptimization,
  getImageLadder,
  getProfileMaxSide,
} from 'dashboard/helper/imageOptimizationPolicy';
import {
  optimizeImage,
  getLongestSide,
  ImageOptimizationError,
  IMAGE_OPTIMIZATION_ERRORS,
} from 'shared/helpers/imageOptimizer';

export default {
  data() {
    // Composer contexts with an image being optimized or a file being uploaded
    return { optimizingImages: [], uploadingFiles: [] };
  },
  computed: {
    isOptimizingImage() {
      return this.optimizingImages.some(this.isSameComposerContext);
    },
    isUploadingFile() {
      return this.uploadingFiles.some(this.isSameComposerContext);
    },
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    installationLimit() {
      return resolveMaximumFileUploadSize(
        this.globalConfig.maximumFileUploadSize
      );
    },
  },

  methods: {
    maxSizeFor(mime) {
      // Use default/installation limit for private notes
      if (this.isOnPrivateNote) {
        return this.installationLimit;
      }

      const channelType = this.inbox?.channel_type;

      if (!channelType || channelType === INBOX_TYPES.WEB) {
        return this.installationLimit;
      }

      const channelLimit = getMaxUploadSizeByChannel({
        channelType,
        medium: this.inbox?.medium, // e.g. 'sms' | 'whatsapp'
        mime, // e.g. 'image/png'
      });

      if (channelLimit === DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE) {
        return this.installationLimit;
      }

      return Math.min(channelLimit, this.installationLimit);
    },
    alertOverLimit(maxSizeMB) {
      useAlert(
        this.$t('CONVERSATION.FILE_SIZE_LIMIT', {
          MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE: maxSizeMB,
        })
      );
    },
    async prepareImageForUpload(file, profile = 'standard') {
      const mime = file.file?.type || file.type;
      if (this.isOnPrivateNote) return file;

      const policy = getImageOptimizationPolicy({
        inbox: this.inbox,
        mime,
        installationLimit: this.installationLimit,
      });
      if (!policy) return file;

      const native = file.file || file;
      const { size } = native;
      let longestSide;
      if (getProfileMaxSide(policy, profile) && size <= policy.limitBytes) {
        try {
          longestSide = await getLongestSide(native);
        } catch (e) {
          longestSide = undefined;
        }
      }

      if (!imageNeedsOptimization(policy, profile, { size, longestSide })) {
        return file;
      }

      const optimizing = this.getComposerContext();
      this.optimizingImages.push(optimizing);
      try {
        const optimized = await optimizeImage(native, {
          maxBytes: policy.maxBytes,
          ladder: getImageLadder(policy, profile),
        });
        return {
          ...file,
          file: optimized.file,
          name: optimized.file.name,
          type: optimized.file.type,
          size: optimized.file.size,
          originalFile: file.originalFile || file,
        };
      } catch (error) {
        const code =
          error instanceof ImageOptimizationError
            ? error.code
            : IMAGE_OPTIMIZATION_ERRORS.DECODE_FAILED;
        if (code === IMAGE_OPTIMIZATION_ERRORS.TOO_LARGE) {
          useAlert(this.$t('CONVERSATION.IMAGE_OPTIMIZATION.TOO_LARGE'));
          return null;
        }
        const fits = size <= policy.limitBytes;
        const unsupported = code === IMAGE_OPTIMIZATION_ERRORS.UNSUPPORTED;
        let message;
        if (unsupported) {
          message = fits
            ? this.$t(
                'CONVERSATION.IMAGE_OPTIMIZATION.UNSUPPORTED_USING_ORIGINAL'
              )
            : this.$t('CONVERSATION.IMAGE_OPTIMIZATION.UNSUPPORTED');
        } else {
          message = fits
            ? this.$t('CONVERSATION.IMAGE_OPTIMIZATION.FAILED_USING_ORIGINAL')
            : this.$t('CONVERSATION.IMAGE_OPTIMIZATION.FAILED');
        }
        useAlert(message);
        // An original that is over the channel limit must never be attached
        return fits ? file : null;
      } finally {
        this.untrack('optimizingImages', optimizing);
      }
    },

    untrack(list, context) {
      const index = this[list].indexOf(context);
      if (index !== -1) this[list].splice(index, 1);
    },

    // The prepared file belongs to the conversation and reply mode it was picked in
    getComposerContext() {
      return {
        chatId: this.currentChat?.id,
        isOnPrivateNote: this.isOnPrivateNote,
      };
    },
    isSameComposerContext(context) {
      const current = this.getComposerContext();
      return (
        current.chatId === context.chatId &&
        current.isOnPrivateNote === context.isOnPrivateNote
      );
    },

    async onFileUpload(file) {
      if (!file) return;

      const context = this.getComposerContext();
      // Keeps Send disabled until the file is attached, including the direct upload
      this.uploadingFiles.push(context);
      try {
        const prepared = await this.prepareImageForUpload(file);
        // The agent may have switched conversation or reply mode while it was prepared
        if (!prepared || !this.isSameComposerContext(context)) return;

        if (this.globalConfig.directUploadsEnabled) {
          await this.onDirectFileUpload(prepared);
        } else {
          await this.onIndirectFileUpload(prepared);
        }
      } finally {
        this.untrack('uploadingFiles', context);
      }
    },

    uploadDirectly(file) {
      const upload = new DirectUpload(
        file.file,
        `/api/v1/accounts/${this.accountId}/conversations/${this.currentChat.id}/direct_uploads`,
        {
          directUploadWillCreateBlobWithXHR: xhr => {
            setDirectUploadAuthHeaders(xhr);
          },
        }
      );

      return new Promise((resolve, reject) => {
        upload.create((error, blob) => {
          if (error) {
            reject(error);
          } else {
            resolve(blob);
          }
        });
      });
    },

    onDirectFileUpload(file) {
      if (!file) return undefined;

      const mime = file.file?.type || file.type;
      const maxSizeMB = this.maxSizeFor(mime);

      if (!checkFileSizeLimit(file, maxSizeMB)) {
        this.alertOverLimit(maxSizeMB);
        return undefined;
      }

      const context = this.getComposerContext();
      return this.uploadDirectly(file).then(
        blob => {
          if (!this.isSameComposerContext(context)) return undefined;
          return this.attachFile({ file, blob });
        },
        error => useAlert(error)
      );
    },

    onIndirectFileUpload(file) {
      if (!file) return undefined;

      const mime = file.file?.type || file.type;
      const maxSizeMB = this.maxSizeFor(mime);

      if (!checkFileSizeLimit(file, maxSizeMB)) {
        this.alertOverLimit(maxSizeMB);
        return undefined;
      }

      return this.attachFile({ file });
    },
  },
};
