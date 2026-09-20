'use strict';

function wait(ms) {
  return ms > 0 ? new Promise((resolve) => setTimeout(resolve, ms)) : Promise.resolve();
}

class JobRepository {
  constructor({ applyDelayMs = 0 } = {}) {
    this.applyDelayMs = applyDelayMs;
    this.effects = [];
  }

  async apply(job) {
    await wait(this.applyDelayMs);
    const effect = {
      effectId: `effect-${this.effects.length + 1}`,
      jobId: job.id,
      dedupeKey: job.dedupeKey || job.id,
      type: job.type || 'charge',
      amount: job.amount
    };
    this.effects.push(effect);
    return { receiptId: effect.effectId, dedupeKey: effect.dedupeKey, amount: effect.amount };
  }

  listEffects() {
    return this.effects.map((effect) => ({ ...effect }));
  }
}

module.exports = { JobRepository };
