import { getters } from '../../attributes';
import attributesList from './fixtures';

describe('#getters', () => {
  it('getAttributes', () => {
    const state = { records: attributesList };
    expect(getters.getAttributes(state)).toEqual([
      {
        attribute_display_name: 'Language',
        attribute_display_type: 1,
        attribute_description: 'The conversation language',
        attribute_key: 'language',
        attribute_model: 0,
      },
      {
        attribute_display_name: 'Language one',
        attribute_display_type: 2,
        attribute_description: 'The conversation language one',
        attribute_key: 'language_one',
        attribute_model: 1,
      },
    ]);
  });

  it('getAttributesByModel', () => {
    const state = { records: attributesList };
    expect(getters.getAttributesByModel(state)(1)).toEqual([
      {
        attribute_display_name: 'Language one',
        attribute_display_type: 2,
        attribute_description: 'The conversation language one',
        attribute_key: 'language_one',
        attribute_model: 1,
      },
    ]);
  });

  it('getAttributesByModel sorts records without a position to the end', () => {
    const state = {
      records: [
        { attribute_key: 'no_position', attribute_model: 1, position: null },
        { attribute_key: 'second', attribute_model: 1, position: 20 },
        { attribute_key: 'first', attribute_model: 1, position: 10 },
      ],
    };
    expect(
      getters
        .getAttributesByModel(state)(1)
        .map(r => r.attribute_key)
    ).toEqual(['first', 'second', 'no_position']);
  });

  it('getCompanyAttributes', () => {
    const state = {
      records: [
        {
          attribute_display_name: 'Industry',
          attribute_display_type: 0,
          attribute_description: 'Company industry',
          attribute_key: 'industry',
          attribute_model: 'company_attribute',
        },
        {
          attribute_display_name: 'Language',
          attribute_display_type: 1,
          attribute_description: 'Conversation language',
          attribute_key: 'language',
          attribute_model: 'conversation_attribute',
        },
      ],
    };
    expect(getters.getCompanyAttributes(state)).toEqual([
      {
        attributeDisplayName: 'Industry',
        attributeDisplayType: 0,
        attributeDescription: 'Company industry',
        attributeKey: 'industry',
        attributeModel: 'company_attribute',
      },
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
    });
  });
});
