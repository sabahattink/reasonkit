'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { InMemoryQueue } = require('../src/queue');
const { JobRepository } = require('../src/repository');
const { IdempotencyStore } = require('../src/idempotency');
const { TransactionManager } = require('../src/transaction');
const { createWorker } = require('../src/worker');

test('acknowledgement retry does not repeat the durable effect', async () => {
  const queue = new InMemoryQueue({ ackFailures: 1 });
  const repository = new JobRepository();
  const idempotency = new IdempotencyStore();
  const transaction = new TransactionManager();
  const worker = createWorker({ queue, repository, idempotency, transaction });

  const result = await worker.deliver(
    { id: 'delivery-retry-1', dedupeKey: 'job-retry-1', amount: 640 },
    { maxAttempts: 2 }
  );

  assert.equal(result.status, 'duplicate');
  assert.equal(repository.listEffects().length, 1);
  assert.deepEqual(queue.acknowledgements().map((entry) => entry.status), ['failed', 'acked']);
});
