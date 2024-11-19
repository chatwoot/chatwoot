const updateSurvey = ({ uuid, data }) => ({
  url: `/public/api/v1/csat_survey/${uuid}`,
  data,
});

const getSurvey = ({ uuid }) => ({
  url: `/public/api/v1/csat_survey/${uuid}`,
});

export default {
  getSurvey,
  updateSurvey,
};
