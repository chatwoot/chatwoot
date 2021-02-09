import { generateBotMessageContent } from '../botMessageContentHelper';

describe('#generateBotMessageContent', () => {
  it('return correct input_select content', () => {
    expect(
      generateBotMessageContent('input_select', {
        submitted_values: [{ value: 'salad', title: 'Salad' }],
      })
    ).toEqual('<strong>Salad</strong>');
  });

  it('return correct input_email content', () => {
    expect(
      generateBotMessageContent('input_email', {
        submitted_email: 'hello@chatwoot.com',
      })
    ).toEqual('<strong>hello@chatwoot.com</strong>');
  });

  it('return correct form content', () => {
    expect(
      generateBotMessageContent('form', {
        items: [
          {
            name: 'large_text',
            label: 'This a large text',
          },
          {
            name: 'email',
            label: 'Email',
          },
        ],
        submitted_values: [{ name: 'large_text', value: 'Large Text Content' }],
      })
    ).toEqual(
      '<div>This a large text</div><strong>Large Text Content</strong><br/><br/><div>Email</div><strong>No response</strong><br/><br/>'
    );
  });
});
