<template>
  <div
    class="bg-white dark:bg-slate-900 h-full w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0 pl-2"
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
          accept=".doc,.pdf,.txt"
          multiple
          @change="handleFileUpload"
        />
      </label>
      <div v-if="botFiles.length > 0" class="file-names-container">
        <ul>
          <li v-for="(file, index) in botFiles" :key="index" class="file-item">
            <input type="text" :value="file.name" readonly />
            <woot-button
              v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
              size="small"
              class="mt-1 ml-2"
              variant="smooth"
              color-scheme="alert"
              icon="delete"
              @click="handleFileDelete(index)"
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
          @focus="isTextInputFocused = true"
          @blur="isTextInputFocused = false"
        />
      </div>
    </div>
    <!-- Website Upload Area -->
    <div v-else-if="uploadType === 'website'">
      <div class="website-input">
        <input
          v-model="websiteInput"
          type="text"
          placeholder="https://www.example.com"
        />
        <woot-submit-button
          :button-text="$t('CHATBOTS.FORM.ADD_URL')"
          @click="addUrl"
        />
      </div>
      <div class="website-urls-container">
        <ul>
          <li v-for="(url, index) in websiteUrls" :key="index" class="url-item">
            <input type="text" :value="url" readonly />
            <woot-button
              v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
              size="small"
              class="mt-1 ml-2"
              variant="smooth"
              color-scheme="alert"
              icon="delete"
              @click="deleteUrl(index)"
            />
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapState } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import accountMixin from '../../../../../mixins/account';

export default {
  mixins: [alertMixin, accountMixin],
  props: {
    uploadType: {
      type: String,
      default: 'website',
    },
  },
  data() {
    return {
      textInput: '',
      websiteInput: '',
    };
  },
  computed: {
    ...mapState({
      botText: state => state.chatbots.botText,
    }),
    ...mapGetters({
      files: 'chatbots/getFiles',
      websiteUrls: 'chatbots/getUrls',
    }),
  },
  methods: {
    handleFileUpload(event) {
      const files = event.target.files;
      this.$store.dispatch('chatbots/addFiles', files);
    },
    handleFileDelete(index) {
      this.$store.dispatch('chatbots/deleteFiles', index);
    },
    setText() {
      const text = this.textInput;
      this.$store.dispatch('chatbots/setText', text);
    },
    addUrl() {
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
        this.$store.dispatch('chatbots/addUrls', websiteUrl);
        this.websiteInput = '';
      } else {
        this.showAlert(this.$t('Please enter a valid https Url'));
      }
    },
    deleteUrl(index) {
      this.$store.dispatch('chatbots/deleteUrls', index);
    },
  },
};
</script>

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
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}
.file-names-container {
  margin-top: 10px;
}
.file-item {
  display: flex;
}
.website-urls-container {
  margin-top: 10px;
}
.url-item {
  display: flex;
}
</style>
