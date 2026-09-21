'use strict';

function createWorker({ queue, repository, idempotency, transaction, logger = () => {} }) {
  async function process(job, context = {}) {
    const key = job.dedupeKey || job.id;
    const attempt = context.attempt || 1;
    logger({ event: 'lookup_start', deliveryId: job.id, key, attempt });
    const previous = await idempotency.lookup(key);
    if (previous && previous.state !== 'in-flight') {
      logger({ event: 'duplicate_seen', deliveryId: job.id, key, attempt });
      return { status: 'duplicate', receipt: previous };
    }

    const claim = idempotency.claim(key);
    if (!claim.claimed) {
      logger({ event: 'duplicate_claim', deliveryId: job.id, key, attempt });
      return { status: 'duplicate', receipt: claim.receipt };
    }

    logger({ event: 'lookup_miss', deliveryId: job.id, key, attempt });
    const receipt = await transaction.run(async () => {
      logger({ event: 'effect_start', deliveryId: job.id, key, attempt });
      return repository.apply(job);
    });
    await idempotency.save(key, receipt);
    logger({ event: 'record_saved', deliveryId: job.id, key, attempt });
    return { status: 'processed', receipt };
  }

  async function deliver(job, options) {
    return queue.deliver(job, (item, context) => process(item, context), options);
  }

  return { process, deliver };
}

module.exports = { createWorker };
