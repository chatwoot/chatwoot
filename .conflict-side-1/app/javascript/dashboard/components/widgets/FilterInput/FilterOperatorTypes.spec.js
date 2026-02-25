import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_2,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_4,
} from './FilterOperatorTypes';

describe('#filterOperators', () => {
  it('Matches the correct Operators', () => {
    expect(OPERATOR_TYPES_1).toMatchObject(OPERATOR_TYPES_1);
    expect(OPERATOR_TYPES_2).toMatchObject(OPERATOR_TYPES_2);
    expect(OPERATOR_TYPES_3).toMatchObject(OPERATOR_TYPES_3);
    expect(OPERATOR_TYPES_4).toMatchObject(OPERATOR_TYPES_4);
  });
});
