'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { InMemoryQueue } = require('../src/queue');
const { JobRepository } = require('../src/repository');
const { IdempotencyStore } = require('../src/idempotency');
const { TransactionManager } = require('../src/transaction');
const { createWorker } = require('../src/worker');

function makeWorker(options = {}) {
  const queue = new InMemoryQueue(options.queue);
  const repository = new JobRepository(options.repository);
  const idempotency = new IdempotencyStore();
  const transaction = new TransactionManager();
  const worker = createWorker({ queue, repository, idempotency, transaction });
  return { queue, repository, idempotency, transaction, worker };
}

test('processes one delivery into one durable effect', async () => {
  const { worker, repository, queue } = makeWorker();
  const result = await worker.deliver({ id: 'delivery-1', dedupeKey: 'job-1', amount: 1250 });

  assert.equal(result.status, 'processed');
  assert.equal(repository.listEffects().length, 1);
  assert.deepEqual(queue.acknowledgements().map((entry) => entry.status), ['acked']);
});
