#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { lstatSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const REPOSITORY_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const EXPECTED_CANDIDATE_MANIFEST_FILE_SHA256 =
  'd92130b16185e4f21af3223e51a8ea38269d3fd76b5e4462f7d33d8d53ee1621';
const EXPECTED_CANDIDATE_MANIFEST_SHA256 =
  '17f66740655adf279b217c6288b521212c579fc631dbc1fd44646cebd8cb1948';
const SUPPORTED_HOSTS = ['generic', 'codex', 'claude'];
const SUPPORTED_PROFILES = ['debugging', 'coding', 'architecture', 'research'];
const OUTPUT_FILES = [
  'README.md',
  'adapter.md',
  'kernel.md',
  'protocol.md',
  'reasonkit.json',
];
const USAGE = [
  'Usage:',
  '  node ./bin/reasonkit.mjs init --host <generic|codex|claude> --profile <debugging|coding|architecture|research>',
  '',
  'Creates .reasonkit/ in the current working directory.',
  'Existing .reasonkit/ paths are never overwritten.',
].join('\n');

function sha256(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

function parseArgs(args) {
  if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    return { help: true };
  }
  if (args[0] !== 'init') {
    throw new Error('Only the init command is supported.\n\n' + USAGE);
  }

  const values = {};
  for (let index = 1; index < args.length; index += 1) {
    const option = args[index];
    if (option !== '--host' && option !== '--profile') {
      throw new Error('Unknown option: ' + option + '\n\n' + USAGE);
    }
    if (Object.hasOwn(values, option)) {
      throw new Error('Option supplied more than once: ' + option);
    }
    const value = args[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error('Missing value for ' + option + '\n\n' + USAGE);
    }
    values[option] = value;
    index += 1;
  }

  if (!SUPPORTED_HOSTS.includes(values['--host'])) {
    throw new Error(
      'Unsupported host: ' + String(values['--host']) +
      '. Choose one of: ' + SUPPORTED_HOSTS.join(', ') + '.',
    );
  }
  if (!SUPPORTED_PROFILES.includes(values['--profile'])) {
    throw new Error(
      'Unsupported profile: ' + String(values['--profile']) +
      '. Choose one of: ' + SUPPORTED_PROFILES.join(', ') + '.',
    );
  }

  return {
    host: values['--host'],
    profile: values['--profile'],
  };
}

function loadFrozenCandidate() {
  const manifestPath = path.join(REPOSITORY_ROOT, 'dist/v0.2/candidate-manifest.json');
  const manifestBytes = readFileSync(manifestPath);
  if (sha256(manifestBytes) !== EXPECTED_CANDIDATE_MANIFEST_FILE_SHA256) {
    throw new Error('The frozen v0.2 candidate manifest bytes do not match the expected release.');
  }

  const manifest = JSON.parse(manifestBytes.toString('utf8'));
  if (
    manifest.candidate_id !== 'rk2-0.2.0' ||
    manifest.candidate_version !== '0.2.0' ||
    manifest.candidate_manifest_sha256 !== EXPECTED_CANDIDATE_MANIFEST_SHA256
  ) {
    throw new Error('The v0.2 candidate manifest identity is unexpected.');
  }
  return manifest;
}

function readFrozenSource(manifest, relativePath, expectedRole) {
  const entry = manifest.covered_files.find(
    (item) => item.repository_relative_path === relativePath,
  );
  if (!entry) {
    throw new Error('Required file is not covered by the frozen candidate: ' + relativePath);
  }
  if (expectedRole && entry.role !== expectedRole) {
    throw new Error('Unexpected frozen candidate role for ' + relativePath);
  }

  const bytes = readFileSync(path.join(REPOSITORY_ROOT, relativePath));
  const actualHash = sha256(bytes);
  if (actualHash !== entry.sha256 || bytes.length !== entry.bytes) {
    throw new Error('Frozen source integrity check failed: ' + relativePath);
  }
  return {
    bytes,
    source: {
      path: relativePath,
      sha256: actualHash,
    },
  };
}

function hostInstructions(host) {
  if (host === 'codex') {
    return [
      'For this task, ask Codex to read the three files listed above before it starts.',
      'Codex project instructions can live in AGENTS.md. To make these references persistent, review and add an instruction there yourself; this bootstrap does not create or edit AGENTS.md.',
    ];
  }
  if (host === 'claude') {
    return [
      'For this task, ask Claude Code to read the three files listed above before it starts.',
      'Claude Code project instructions can live in CLAUDE.md. For persistent loading, review and add references such as @.reasonkit/kernel.md yourself; this bootstrap does not create or edit CLAUDE.md or .claude settings.',
    ];
  }
  return [
    'Load the three files listed above as system or instruction context for this task.',
    'If your host cannot read local files directly, paste their contents into its instruction context.',
  ];
}

function renderReadme(host, profile) {
  const lines = [
    '# ReasonKit task context',
    '',
    'This folder contains the compact v0.2 instruction context prepared for one task.',
    '',
    'Selected host: ' + host,
    'Selected profile: ' + profile,
    '',
    'Before the task, load:',
    '- .reasonkit/kernel.md',
    '- .reasonkit/adapter.md',
    '- .reasonkit/protocol.md',
    '',
    ...hostInstructions(host),
    '',
    'ReasonKit is an instruction and orchestration layer, not a hosted runtime. This bootstrap only prepares local files; the selected host performs model calls, tool use, and execution.',
    '',
    'The bootstrap does not start specialists, upload files, make provider calls, or collect telemetry.',
  ];
  return lines.join('\n') + '\n';
}

function assertDestinationAbsent(destination) {
  try {
    lstatSync(destination);
  } catch (error) {
    if (error && error.code === 'ENOENT') {
      return;
    }
    throw error;
  }
  throw new Error('Refusing to overwrite existing .reasonkit. Move or review it before retrying.');
}

function initialize({ host, profile }) {
  const manifest = loadFrozenCandidate();
  const sources = {
    kernel: readFrozenSource(
      manifest,
      'dist/v0.2/reasonkit-kernel.md',
      'generated_artifact',
    ),
    adapter: readFrozenSource(
      manifest,
      'adapters/generic/SYSTEM.md',
      'adapter',
    ),
    protocol: readFrozenSource(
      manifest,
      'protocols/' + profile + '.md',
    ),
  };

  const metadata = {
    reasonkitVersion: manifest.candidate_version,
    host,
    profile,
    sources: {
      kernel: sources.kernel.source,
      adapter: sources.adapter.source,
      protocol: sources.protocol.source,
    },
  };
  const output = new Map([
    ['kernel.md', sources.kernel.bytes],
    ['adapter.md', sources.adapter.bytes],
    ['protocol.md', sources.protocol.bytes],
    ['reasonkit.json', JSON.stringify(metadata, null, 2) + '\n'],
    ['README.md', renderReadme(host, profile)],
  ]);

  const destination = path.join(process.cwd(), '.reasonkit');
  assertDestinationAbsent(destination);
  try {
    mkdirSync(destination);
  } catch (error) {
    if (error && error.code === 'EEXIST') {
      throw new Error('Refusing to overwrite existing .reasonkit. Move or review it before retrying.');
    }
    throw error;
  }

  try {
    for (const [filename, contents] of output) {
      writeFileSync(path.join(destination, filename), contents, { flag: 'wx' });
    }
  } catch (error) {
    throw new Error(
      'Could not finish writing .reasonkit. Inspect the new directory before retrying. ' +
      String(error.message || error),
    );
  }
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    process.stdout.write(USAGE + '\n');
    return;
  }

  initialize(options);
  process.stdout.write(
    'ReasonKit initialized for ' + options.host + ' (' + options.profile + ').\n' +
    'Created .reasonkit/ with ' + OUTPUT_FILES.join(', ') + '.\n' +
    'Load .reasonkit/kernel.md, .reasonkit/adapter.md, and .reasonkit/protocol.md before your task.\n' +
    'The host performs execution; no uploads or telemetry were made.\n',
  );
}

try {
  main();
} catch (error) {
  process.stderr.write('reasonkit: ' + String(error.message || error) + '\n');
  process.exitCode = 1;
}
