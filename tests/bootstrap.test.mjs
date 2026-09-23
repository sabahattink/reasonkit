import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import {
  mkdtempSync,
  readFileSync,
  readdirSync,
  mkdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const REPOSITORY_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const CLI_PATH = path.join(REPOSITORY_ROOT, 'bin/reasonkit.mjs');
const CANDIDATE = JSON.parse(
  readFileSync(path.join(REPOSITORY_ROOT, 'dist/v0.2/candidate-manifest.json'), 'utf8'),
);
const EXPECTED_FILES = [
  'README.md',
  'adapter.md',
  'kernel.md',
  'protocol.md',
  'reasonkit.json',
].sort();

function sha256(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

function makeTempDirectory(t) {
  const directory = mkdtempSync(path.join(os.tmpdir(), 'reasonkit-bootstrap-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

function runInit(directory, host, profile, extraArgs = []) {
  return spawnSync(
    process.execPath,
    [CLI_PATH, 'init', '--host', host, '--profile', profile, ...extraArgs],
    { cwd: directory, encoding: 'utf8' },
  );
}

function assertSuccessfulInit(t, host, profile) {
  const directory = makeTempDirectory(t);
  const result = runInit(directory, host, profile);
  assert.equal(result.status, 0, result.stderr);

  const outputDirectory = path.join(directory, '.reasonkit');
  assert.deepEqual(readdirSync(outputDirectory).sort(), EXPECTED_FILES);

  const metadata = JSON.parse(
    readFileSync(path.join(outputDirectory, 'reasonkit.json'), 'utf8'),
  );
  assert.deepEqual(Object.keys(metadata).sort(), [
    'host',
    'profile',
    'reasonkitVersion',
    'sources',
  ]);
  assert.equal(metadata.reasonkitVersion, '0.2.0');
  assert.equal(metadata.host, host);
  assert.equal(metadata.profile, profile);

  const expectedSources = {
    'kernel.md': {
      destinationKey: 'kernel',
      sourcePath: 'dist/v0.2/reasonkit-kernel.md',
    },
    'adapter.md': {
      destinationKey: 'adapter',
      sourcePath: 'adapters/generic/SYSTEM.md',
    },
    'protocol.md': {
      destinationKey: 'protocol',
      sourcePath: 'protocols/' + profile + '.md',
    },
  };
  for (const [destinationName, sourceInfo] of Object.entries(expectedSources)) {
    const sourceBytes = readFileSync(path.join(REPOSITORY_ROOT, sourceInfo.sourcePath));
    const copiedBytes = readFileSync(path.join(outputDirectory, destinationName));
    const manifestEntry = CANDIDATE.covered_files.find(
      (entry) => entry.repository_relative_path === sourceInfo.sourcePath,
    );
    assert.ok(manifestEntry, sourceInfo.sourcePath + ' must be in frozen coverage');
    assert.deepEqual(copiedBytes, sourceBytes);
    assert.equal(sha256(copiedBytes), manifestEntry.sha256);
    assert.deepEqual(metadata.sources[sourceInfo.destinationKey], {
      path: sourceInfo.sourcePath,
      sha256: manifestEntry.sha256,
    });
  }

  assert.equal(result.stdout.includes('no uploads or telemetry'), true);
  assert.equal(result.stdout.includes('specialist'), false);
  assert.equal(readdirSync(outputDirectory).some((name) => name.includes('full')), false);
  return { directory, outputDirectory, result };
}

test('generic debugging init copies the frozen kernel, adapter, and protocol', (t) => {
  assertSuccessfulInit(t, 'generic', 'debugging');
});

test('generic research init selects the research protocol', (t) => {
  assertSuccessfulInit(t, 'generic', 'research');
});

test('codex coding init succeeds without host configuration side effects', (t) => {
  const { outputDirectory } = assertSuccessfulInit(t, 'codex', 'coding');
  const readme = readFileSync(path.join(outputDirectory, 'README.md'), 'utf8');
  assert.match(readme, /does not create or edit AGENTS\.md/);
});

test('claude architecture init succeeds without host configuration side effects', (t) => {
  const { outputDirectory } = assertSuccessfulInit(t, 'claude', 'architecture');
  const readme = readFileSync(path.join(outputDirectory, 'README.md'), 'utf8');
  assert.match(readme, /does not create or edit CLAUDE\.md/);
});

test('invalid host fails before creating .reasonkit', (t) => {
  const directory = makeTempDirectory(t);
  const result = runInit(directory, 'unknown', 'debugging');
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Unsupported host/);
  assert.equal(readdirSync(directory).includes('.reasonkit'), false);
});

test('invalid profile fails before creating .reasonkit', (t) => {
  const directory = makeTempDirectory(t);
  const result = runInit(directory, 'generic', 'design');
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Unsupported profile/);
  assert.equal(readdirSync(directory).includes('.reasonkit'), false);
});

test('existing .reasonkit content blocks overwrite and remains unchanged', (t) => {
  const directory = makeTempDirectory(t);
  const outputDirectory = path.join(directory, '.reasonkit');
  mkdirSync(outputDirectory);
  writeFileSync(path.join(outputDirectory, 'keep.txt'), 'user file\n');

  const result = runInit(directory, 'generic', 'debugging');
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Refusing to overwrite existing \.reasonkit/);
  assert.deepEqual(readdirSync(outputDirectory), ['keep.txt']);
  assert.equal(readFileSync(path.join(outputDirectory, 'keep.txt'), 'utf8'), 'user file\n');
});

test('--force is rejected because overwrite support is not implemented', (t) => {
  const directory = makeTempDirectory(t);
  const result = runInit(directory, 'generic', 'debugging', ['--force']);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Unknown option: --force/);
  assert.equal(readdirSync(directory).includes('.reasonkit'), false);
});
