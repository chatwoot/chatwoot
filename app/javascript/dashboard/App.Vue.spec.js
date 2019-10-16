import App from './App';
import '../../test-matchers';

describe(`App component`, () => {
  it(`should be a component`, () => {
    // Arrange
    // Act
    expect(App).toBeVueComponent('App');
    // Assert
  });
});
