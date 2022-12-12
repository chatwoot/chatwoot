// @ts-ignore - this package has no typings, so we wrap it and add typings that way, because we expose it
import Cache from 'file-system-cache';
export class FileSystemCache {
  constructor(options) {
    this.internal = void 0;
    this.internal = Cache(options);
  }

  path(key) {
    return this.internal.path(key);
  }

  fileExists(key) {
    return this.internal.fileExists(key);
  }

  ensureBasePath() {
    return this.internal.ensureBasePath();
  }

  get(key, defaultValue) {
    return this.internal.get(key, defaultValue);
  }

  getSync(key, defaultValue) {
    return this.internal.getSync(key, defaultValue);
  }

  set(key, value) {
    return this.internal.set(key, value);
  }

  setSync(key, value) {
    this.internal.setSync(key, value);
    return this;
  }

  remove(key) {
    return this.internal.remove(key);
  }

  clear() {
    return this.internal.clear();
  }

  save() {
    return this.internal.save();
  }

  load() {
    return this.internal.load();
  }

}
export function createFileSystemCache(options) {
  return new FileSystemCache(options);
}