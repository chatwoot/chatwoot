
export default {
  computed: {
    checkerObjects() {
      return this.aiCheckResponse?.response;
    },
    checkPassed(){
      return this.aiCheckResponse?.passed || this.aiCheckResponse?.skipped;
    },
    languageGrammarPassed() {
      return !!this.languageGrammarCheck?.passed;
    },
    canSendDespiteCheckFailure() {
      return (!this.answerQualityCheck?.passed || !this.customerCentricityCheck?.passed ) && this.languageGrammarCheck?.passed;
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
      return this.withResponse && !this.checkPassed;
    },
    withResponse() {
      return !!this.aiCheckResponse;
    },
  },
};
