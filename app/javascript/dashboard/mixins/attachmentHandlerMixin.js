export default {
  data() {
    return {
      attachedFiles: [],
    };
  },
  computed: {
    hasAttachments() {
      return this.attachedFiles.length;
    },
  },
  methods: {
    attachFile({ blob, file }) {
      const reader = new FileReader();
      reader.readAsDataURL(file.file);
      reader.onloadend = () => {
        this.attachedFiles.push({
          currentChatId: this.currentChat.id,
          resource: blob || file,
          isPrivate: this.isPrivate,
          thumb: reader.result,
          blobSignedId: blob ? blob.signed_id : undefined,
        });
      };
    },
    removeAttachment(itemIndex) {
      this.attachedFiles = this.attachedFiles.filter(
        (item, index) => itemIndex !== index
      );
    },
    clearAttachments() {
      this.attachedFiles = [];
    },
  },
};
