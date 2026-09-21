'use strict';

class TransactionManager {
  constructor() {
    this.events = [];
  }

  async run(operation) {
    const transaction = { state: 'open' };
    try {
      const result = await operation(transaction);
      transaction.state = 'committed';
      this.events.push({ state: transaction.state });
      return result;
    } catch (error) {
      transaction.state = 'rolled_back';
      this.events.push({ state: transaction.state });
      throw error;
    }
  }

  history() {
    return this.events.map((event) => ({ ...event }));
  }
}

module.exports = { TransactionManager };
