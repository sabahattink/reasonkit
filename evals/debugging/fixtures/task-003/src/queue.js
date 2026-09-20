'use strict';

function wait(ms) {
  return ms > 0 ? new Promise((resolve) => setTimeout(resolve, ms)) : Promise.resolve();
}

class InMemoryQueue {
  constructor({ ackFailures = 0, ackDelayMs = 0 } = {}) {
    this.remainingAckFailures = ackFailures;
    this.ackDelayMs = ackDelayMs;
    this.ackLog = [];
  }

  async deliver(job, handler, { maxAttempts = 1 } = {}) {
    let lastError;

    for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        const result = await handler(job, { attempt });
        await this.ack(job, attempt);
        return { ...result, attempts: attempt };
      } catch (error) {
        lastError = error;
        if (attempt === maxAttempts) throw error;
      }
    }

    throw lastError;
  }

  async ack(job, attempt) {
    await wait(this.ackDelayMs);
    const record = { deliveryId: job.id, attempt, status: 'pending' };
    this.ackLog.push(record);

    if (this.remainingAckFailures > 0) {
      this.remainingAckFailures -= 1;
      record.status = 'failed';
      throw new Error('ack timeout');
    }

    record.status = 'acked';
  }

  acknowledgements() {
    return this.ackLog.map((record) => ({ ...record }));
  }
}

module.exports = { InMemoryQueue };
