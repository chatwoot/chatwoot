import MessageFormatter from '../MessageFormatter';

describe('#MessageFormatter', () => {
  describe('content with links', () => {
    it('should format correctly', () => {
      const message =
        'Chatwoot is an opensource tool\nSee more at https://www.chatwoot.com';
      expect(new MessageFormatter(message).formattedMessage).toEqual(
        'Chatwoot is an opensource tool<br>See more at <a rel="noreferrer noopener nofollow" href="https://www.chatwoot.com" class="link" target="_blank">https://www.chatwoot.com</a>'
      );
    });
  });

  describe('tweets', () => {
    it('should return the same string if not tags or @mentions', () => {
      const message = 'Chatwoot is an opensource tool';
      expect(new MessageFormatter(message).formattedMessage).toEqual(message);
    });

    it('should add links to @mentions', () => {
      const message =
        '@chatwootapp is an opensource tool thanks @longnonexistenttwitterusername';
      expect(new MessageFormatter(message, true).formattedMessage).toEqual(
        '<a href="http://twitter.com/chatwootapp" target="_blank" rel="noreferrer nofollow noopener">@chatwootapp</a> is an opensource tool thanks @longnonexistenttwitterusername'
      );
    });

    it('should add links to #tags', () => {
      const message = '#chatwootapp is an opensource tool';
      expect(new MessageFormatter(message, true).formattedMessage).toEqual(
        '<a href="https://twitter.com/hashtag/chatwootapp" target="_blank" rel="noreferrer nofollow noopener">#chatwootapp</a> is an opensource tool'
      );
    });
  });
});
