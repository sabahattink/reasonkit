'use strict';

const path = require('node:path');

function loadModules(packageRoot, mode) {
  const sourceRoot = mode === 'reference'
    ? path.join(packageRoot, 'evaluator-only', 'reference-fixed', 'src')
    : path.join(packageRoot, 'fixture-public', 'src');

  return {
    queue: require(path.join(sourceRoot, 'queue.js')),
    repository: require(path.join(sourceRoot, 'repository.js')),
    idempotency: require(path.join(sourceRoot, 'idempotency.js')),
    transaction: require(path.join(sourceRoot, 'transaction.js')),
    worker: require(path.join(sourceRoot, 'worker.js'))
  };
}

async function main() {
  const packageRoot = path.resolve(process.argv[2] || path.join(__dirname, '..'));
  const mode = process.argv[3] || 'public';
  const modules = loadModules(packageRoot, mode);
  const queue = new modules.queue.InMemoryQueue();
  const repository = new modules.repository.JobRepository({ applyDelayMs: 10 });
  const idempotency = new modules.idempotency.IdempotencyStore();
  const transaction = new modules.transaction.TransactionManager();
  const worker = modules.worker.createWorker({ queue, repository, idempotency, transaction });
  const baseJob = { dedupeKey: 'payment-held-out-1', type: 'charge', amount: 990 };

  await Promise.all([
    worker.deliver({ ...baseJob, id: 'delivery-held-out-a' }),
    worker.deliver({ ...baseJob, id: 'delivery-held-out-b' })
  ]);

  const effects = repository.listEffects().filter((effect) => effect.dedupeKey === baseJob.dedupeKey);
  if (effects.length !== 1) {
    throw new Error(`duplicate-effect regression: expected 1 effect, observed ${effects.length}`);
  }

  if (queue.acknowledgements().length !== 2) {
    throw new Error('duplicate-effect regression: both deliveries must be acknowledged');
  }

  process.stdout.write(JSON.stringify({ mode, status: 'PASS', effects: effects.length, acknowledgements: queue.acknowledgements().length }) + '\n');
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
