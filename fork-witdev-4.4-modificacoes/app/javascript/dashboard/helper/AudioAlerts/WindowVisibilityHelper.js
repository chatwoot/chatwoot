export class WindowVisibilityHelper {
  constructor() {
    this.isVisible = true;
    this.initializeEvent();
  }

  initializeEvent = () => {
    window.addEventListener('blur', () => {
      this.isVisible = false;
    });
    window.addEventListener('focus', () => {
      this.isVisible = true;
    });
  };

  isWindowVisible() {
    return !document.hidden && this.isVisible;
  }
}

export default new WindowVisibilityHelper();
