
export default {
  computed: {
    checkerObjects() {
      return this.aiCheckResponse?.checks;
    },
    checkPassed(){
      return !!this.aiCheckResponse?.passed || !!this.aiCheckResponse?.skipped;
    },
    languageGrammarPassed() {
      return !!this.languageGrammarCheck?.passed;
    },
    canSendDespiteCheckFailure() {
      return !this.answerQualityCheck?.passed && this.customerCentricityCheck?.passed && this.languageGrammarPassed;
    },
    answerQualityCheck() {
      return this.checkerObjects?.quality_check;
    },
    languageGrammarCheck() {
      return this.checkerObjects?.language_grammar_check;
    },
    customerCentricityCheck() {
      return this.checkerObjects?.customer_centricity_check;
    },
    shouldShowAIAssistanceModal() {
      return this.withResponse && (!this.checkPassed || this.needsTranslation);
    },
    withResponse() {
      return !!this.aiCheckResponse;
    },
    needsTranslation() {
      if (this.uiSettings?.ai_translation_enabled === false) {
        return false;
      }

      return !this.aiCheckResponse?.using_target_language;
    },
    canShowTranslation(){
      return this.needsTranslation && this.checkPassed;
    }
  },
};
