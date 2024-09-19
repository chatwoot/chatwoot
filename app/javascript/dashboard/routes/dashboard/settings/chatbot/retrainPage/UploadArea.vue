<script>
import { mapGetters, mapState } from 'vuex';
import ChatbotAPI from '../../../../../api/chatbots';
import { useAlert } from 'dashboard/composables';
import Loader from '../helpers/Loader.vue';
import {
  processTextFile,
  processDocxFile,
} from '../../../../../helper/chatbotHelper';

export default {
  components: {
    Loader,
  },
  props: {
    value: { type: Boolean, default: false },
    uploadType: {
      type: String,
      default: 'website',
    },
    progress: {
      type: Number,
      default: 0,
    },
    savedFiles: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      textInput: '',
      previousText: '',
      websiteInput: '',
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      loading: {},
    };
  },
  computed: {
    ...mapState({
      text: state => state.chatbots.text,
    }),
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      accountId: 'getCurrentAccountId',
      text: 'chatbots/getText',
      files: 'chatbots/getFiles',
      links: 'chatbots/getLinks',
      detectedChar: 'chatbots/getChar',
    }),
    accountCharLimit() {
      const currentAccount = this.getAccount(this.accountId);
      return currentAccount?.custom_attributes?.chatbot_char_limit ?? 1000000;
    },
    limitExceeded() {
      return this.detectedChar > this.accountCharLimit;
    },
    deleteMessage() {
      return ` ${this.selectedResponse.filename}?`;
    },
  },
  watch: {
    text(newText) {
      this.textInput = newText;
    },
  },
  methods: {
    async uploadFile(event) {
      const files = Array.from(event.target.files);
      const filesData = await Promise.all(
        files.map(async file => {
          try {
            const charCount = await this.processFile(file);
            return {
              file,
              char_count: charCount,
            };
          } catch (error) {
            return {
              file,
              char_count: 0,
            };
          }
        })
      );
      this.$store.dispatch('chatbots/addFiles', filesData);
    },
    async processFile(file) {
      const fileType = file.type;

      if (fileType === 'text/plain') {
        return processTextFile(file);
      }
      if (fileType === 'application/pdf') {
        return ChatbotAPI.processPdfFile(file).then(res => {
          return res.data.char_count;
        });
      }
      if (
        fileType ===
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      ) {
        return processDocxFile(file);
      }
      return Promise.resolve(0); // Unsupported file type
    },
    deleteFile(file, index) {
      this.$store.dispatch('chatbots/decChar', file.char_count);
      this.$store.dispatch('chatbots/deleteFile', index);
    },
    setText() {
      const newText = this.textInput;
      const previousText = this.previousText;
      const newTextLength = newText.length;
      const previousTextLength = previousText.length;

      this.$store.dispatch('chatbots/setText', newText);

      if (newTextLength > previousTextLength) {
        const addedChars = newTextLength - previousTextLength;
        this.$store.dispatch('chatbots/incChar', addedChars);
      } else if (newTextLength < previousTextLength) {
        const removedChars = previousTextLength - newTextLength;
        this.$store.dispatch('chatbots/decChar', removedChars);
      }

      this.previousText = newText;
    },
    async fetchLinks() {
      const pattern = new RegExp(
        '^https:\\/\\/' + // protocol
          '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|' + // domain name
          '((\\d{1,3}\\.){3}\\d{1,3}))' + // OR IP (v4) address
          '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*' + // port and path
          '(\\?[;&a-z\\d%_.~+=-]*)?' + // query string
          '(\\#[-a-z\\d_]*)?$', // fragment locator
        'i'
      );
      const websiteUrl = this.websiteInput.trim();
      if (websiteUrl !== '' && pattern.test(websiteUrl)) {
        if (!this.links.some(obj => obj.link === websiteUrl)) {
          this.$emit('startProgress');
          await ChatbotAPI.fetchLinks(websiteUrl);
        }
      } else {
        useAlert(this.$t('Please enter a valid https Url'));
      }
    },
    deleteLink(url, index) {
      this.$store.dispatch('chatbots/decChar', url.char_count);
      this.$store.dispatch('chatbots/deleteLink', index);
    },
    deleteLinks() {
      this.$store.dispatch('chatbots/decChar', this.detectedChar);
      this.$store.dispatch('chatbots/deleteLinks');
    },
    retrain() {
      this.$emit('retrainChatbot');
    },
    extractCharCounts(files) {
      files.forEach(file => {
        const char_count = file.metadata.char_count;
        this.$store.dispatch('chatbots/incChar', char_count);
      });
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedResponse = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteSavedFile(this.selectedResponse);
    },
    async deleteSavedFile(response) {
      try {
        await this.$store
          .dispatch('chatbots/destroyAttachment', response)
          .then(res => {
            const filename = res.data.filename;
            this.$emit('removeFile', filename);
          });
        await this.$store.dispatch(
          'chatbots/decChar',
          response.metadata.char_count
        );
        useAlert(this.$t('CHATBOTS.RETRAIN.FILE.DELETE.API.SUCCESS_MESSAGE'));
        this.loading[this.selectedResponse.id] = false;
      } catch (error) {
        useAlert(this.$t('CHATBOTS.RETRAIN.FILE.DELETE.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-4 w-full max-w-full"
  >
    <!-- File Upload Area -->
    <div v-if="uploadType === 'file'">
      <label for="file" class="file-upload-label">
        <div class="file-upload-design">
          <fluent-icon icon="cloud-backup" size="36" />
          <p>
            {{ $t('CHATBOTS.SUPPORTED_FILE_TYPES') }}
          </p>
          <span class="browse-button">{{ $t('CHATBOTS.BROWSE_FILES') }}</span>
        </div>
        <input
          id="file"
          type="file"
          accept=".pdf,.docx,.txt"
          multiple
          @change="uploadFile"
        />
      </label>
      <span class="text-slate-700 text-sm">{{
        $t('CHATBOTS.FORM.UPLOAD_FILES_DESC')
      }}</span>
      <div class="file-container">
        <ul v-if="savedFiles.length > 0">
          <li
            v-for="(file, index) in savedFiles"
            :key="index"
            class="file-item"
          >
            <input type="text" :value="file.filename" readonly />
            <woot-button
              v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
              size="small"
              class="mt-1 ml-2"
              variant="smooth"
              color-scheme="alert"
              icon="delete"
              @click="openDeletePopup(file, index)"
            />
          </li>
        </ul>
        <ul v-if="files.length > 0">
          <li v-for="(file, index) in files" :key="index" class="file-item">
            <input type="text" :value="file['file']['name']" readonly />
            <woot-button
              v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
              size="small"
              class="mt-1 ml-2"
              variant="smooth"
              color-scheme="alert"
              icon="delete"
              @click="deleteFile(file, index)"
            />
          </li>
        </ul>
      </div>
    </div>
    <!-- Text Upload Area -->
    <div v-else-if="uploadType === 'text'">
      <div class="text-input">
        <textarea
          v-model="textInput"
          placeholder="Enter your text here"
          @input="setText"
        />
      </div>
    </div>
    <!-- Website Upload Area -->
    <div v-else-if="uploadType === 'website'">
      <div class="website-input">
        <input
          v-model="websiteInput"
          type="text"
          :placeholder="$t('CHATBOTS.PLACEHOLDER')"
        />
        <woot-button :disabled="value" @click="fetchLinks">
          {{ $t('CHATBOTS.FORM.FETCH_LINKS') }}
        </woot-button>
      </div>
      <span class="text-slate-700 text-sm">{{
        $t('CHATBOTS.FORM.FETCH_LINKS_DESC')
      }}</span>
      <div class="mt-4">
        <Loader :progress="progress" />
      </div>
      <div v-if="links.length > 0" class="flex justify-end mt-4">
        <woot-button
          size="small"
          variant="smooth"
          color-scheme="alert"
          @click="deleteLinks()"
        >
          {{ $t('CHATBOTS.DELETE_ALL') }}
        </woot-button>
      </div>
      <div class="website-links">
        <ul>
          <li v-for="(url, index) in links" :key="index" class="links">
            <input type="text" :value="url['link']" readonly />
            <woot-button
              v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
              size="small"
              class="mt-1 ml-2"
              variant="smooth"
              color-scheme="alert"
              icon="delete"
              @click="deleteLink(url, index)"
            />
          </li>
        </ul>
      </div>
    </div>
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('CHATBOTS.RETRAIN.FILE.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('CHATBOTS.RETRAIN.FILE.DELETE.CONFIRM.YES')"
      :reject-text="$t('CHATBOTS.RETRAIN.FILE.DELETE.CONFIRM.NO')"
    />
  </div>
</template>

<style scoped>
.file-upload-label input {
  display: none;
}
.file-upload-label {
  cursor: pointer;
  padding: 40px;
  border-radius: 4px;
  justify-content: center;
  border: 1px solid #e8e9ea;
}
.file-upload-design {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 5px;
  height: 100%;
}
.browse-button {
  background-color: #369eff;
  padding: 5px 15px;
  border-radius: 4px;
  color: white;
  transition: all 0.3s;
}
.browse-button:hover {
  background-color: #007ee5;
}
.text-input {
  width: 100%;
  margin: 0 auto;
}
.text-input textarea {
  width: 100%;
  height: 180px;
  resize: none;
  overflow: auto;
  scrollbar-width: none;
  -ms-overflow-style: none;
}
.text-input textarea::-webkit-scrollbar {
  display: none;
}
.website-input {
  display: flex;
}
.website-input input {
  margin-right: 10px;
}
.file-container {
  margin-top: 20px;
  height: 300px;
  overflow: scroll;
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.file-container::-webkit-scrollbar {
  display: none;
}
.file-item {
  display: flex;
}
.website-links {
  margin-top: 20px;
  height: 300px;
  overflow: scroll;
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.website-links::-webkit-scrollbar {
  display: none;
}
.links {
  display: flex;
}
</style>
