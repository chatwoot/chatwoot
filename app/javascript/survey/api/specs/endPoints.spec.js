import endPoints from '../endPoints';
const uuid = '98c5d7f3-8873-4262-b101-d56425ff7ee1';

describe('#getSurvey', () => {
  it('should returns correct payload', () => {
    expect(
      endPoints.getSurvey({
        uuid,
      })
    ).toEqual({
      url: `/public/api/v1/csat_survey/98c5d7f3-8873-4262-b101-d56425ff7ee1`,
    });
  });
});

describe('#updateSurvey', () => {
  it('should returns correct payload', () => {
    const data = {
      message: {
        submitted_values: {
          csat_survey_response: {
            rating: 4,
            feedback_message: 'amazing',
          },
        },
      },
    };
    expect(
      endPoints.updateSurvey({
        uuid,
        data,
      })
    ).toEqual({
      url: `/public/api/v1/csat_survey/98c5d7f3-8873-4262-b101-d56425ff7ee1`,
      data,
    });
  });
});
