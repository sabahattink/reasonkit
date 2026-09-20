'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { InMemoryQueue } = require('../src/queue');
const { JobRepository } = require('../src/repository');
const { IdempotencyStore } = require('../src/idempotency');
const { TransactionManager } = require('../src/transaction');
const { createWorker } = require('../src/worker');

test('processes different logical jobs concurrently', async () => {
  const queue = new InMemoryQueue();
  const repository = new JobRepository({ applyDelayMs: 5 });
  const idempotency = new IdempotencyStore();
  const transaction = new TransactionManager();
  const worker = createWorker({ queue, repository, idempotency, transaction });

  await Promise.all([
    worker.deliver({ id: 'delivery-a', dedupeKey: 'job-a', amount: 10 }),
    worker.deliver({ id: 'delivery-b', dedupeKey: 'job-b', amount: 20 })
  ]);

  assert.equal(repository.listEffects().length, 2);
  assert.deepEqual(
    repository.listEffects().map((effect) => effect.dedupeKey).sort(),
    ['job-a', 'job-b']
  );
});
