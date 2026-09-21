'use strict';

class ConfigCache {
  constructor() {
    this.entries = new Map();
  }

  get(key) {
    return this.entries.get(key);
  }

  set(key, value) {
    const stored = Object.freeze({ ...value });
    this.entries.set(key, stored);
    return stored;
  }

  size() {
    return this.entries.size;
  }
}

module.exports = { ConfigCache };
