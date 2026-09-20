'use strict';

class IdempotencyStore {
  constructor() {
    this.records = new Map();
  }

  async lookup(key) {
    await Promise.resolve();
    return this.records.get(key) || null;
  }

  claim(key) {
    if (this.records.has(key)) {
      return { claimed: false, receipt: this.records.get(key) };
    }
    this.records.set(key, { state: 'in-flight' });
    return { claimed: true, receipt: null };
  }

  async save(key, receipt) {
    await Promise.resolve();
    this.records.set(key, receipt);
    return receipt;
  }

  snapshot() {
    return Object.fromEntries(this.records.entries());
  }
}

module.exports = { IdempotencyStore };
