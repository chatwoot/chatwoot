export default class VideoPlugin {
  constructor(name, version) {
    this.pluginName = name;
  }

  track(event, properties) {
    window.analytics.track(event, properties, {
      integration: {
        name: this.pluginName
      }
    });
  }
}
