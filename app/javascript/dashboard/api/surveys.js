/* global axios */
import ApiClient from './ApiClient';

class SurveysAPI extends ApiClient {
  constructor() {
    super('surveys', { accountScoped: true });
  }

  getQuestions(surveyId) {
    return axios.get(`${this.url}/${surveyId}/survey_questions`);
  }

  createQuestion(surveyId, questionData) {
    return axios.post(`${this.url}/${surveyId}/survey_questions`, questionData);
  }

  updateQuestion(surveyId, questionId, questionData) {
    return axios.patch(
      `${this.url}/${surveyId}/survey_questions/${questionId}`,
      questionData
    );
  }

  deleteQuestion(surveyId, questionId) {
    return axios.delete(
      `${this.url}/${surveyId}/survey_questions/${questionId}`
    );
  }

  initiateSurveyCall({ contactId, surveyId }) {
    return axios.post(`${this.baseUrl()}/survey_calls`, {
      contact_id: contactId,
      survey_id: surveyId,
    });
  }
}

export default new SurveysAPI();
