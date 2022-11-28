const updateSurvey = ({ uuid, data }) => ({
  url: `/public/api/v1/csat_survey/${uuid}`,
  data,
});

const getSurvey = ({ uuid }) => ({
  url: `/public/api/v1/csat_survey/${uuid}`,
});

const getCsatMessage = ({ uuid }) => ({
  url: `/public/api/v1/csat_message/${uuid}`,
});


export default {
  getSurvey,
  updateSurvey,
  getCsatMessage
};
