# ChatGPT Adapter

This directory contains the first working copy/load adapter for a ChatGPT
host. Start with SKILL.md, then load the minimal or task-specific generated
bundle from dist/.

## Required interface

An implementation should load skill/SKILL.md, expose the available tools and
their risk classes, preserve the L0-L4 and token ceilings, and return the
ReasonKit result contract. Provider-specific behavior belongs here, not in
core/ or protocols/.

## Scope

This is a prompt-pack adapter, not an API client. No ChatGPT API, account,
model, pricing, or benchmark claim is made by this adapter.
