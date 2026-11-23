# Ethiopic Primitives

[![conformance](https://github.com/Yaredt/ethiopic-primitives/actions/workflows/conformance.yml/badge.svg)](https://github.com/Yaredt/ethiopic-primitives/actions/workflows/conformance.yml)

Deterministic, model-free primitives for the Ethiopian calendar, fiscal periods,
Ge'ez numerals, and Ge'ez-script equivalence.

## Status

**Pre-1.0 — work in progress, not yet released.** Three Layer-0 modules are
implemented and cross-language-verified, but the conformance fixtures and a Tier-1
provenance source are still outstanding, so **nothing is published to npm or PyPI
yet** and no version is tagged (Principle II). The code is public to invite review
and — importantly — external authorship of the conformance vectors (Principle I
forbids the maintainers authoring them).

**Correctness core landed.** The calendar layer is implemented in both languages
and passes all 181 gating vectors plus the 1990–2035 sweep, both directions, with
zero mismatches — in JavaScript, in the Python wrapper, and across both together.

- `javascript/` — TypeScript calendar conversion (the primary deliverable; the
  maintained JS option surveyed is 48.9% wrong). Ships `dist/` + `.d.ts`.
- `python/` — thin wrapper over `py-ethiopian-date-converter` (Principle III),
  not a reimplementation.
- **Fiscal logic** (feature 002) is implemented in both languages — fiscal year,
  quarter, period (Pagumē = period 13), bounds, and aging across Pagumē. It builds
  purely on the calendar core and passes cross-language parity. Three conventions
  (label / period numbering / Pagumē's quarter) are informed defaults awaiting a
  Tier-1 source; acceptance is gated by an externally authored
  `tests/vectors/fiscal.json` that does not exist yet.
- **Ge'ez numerals** (feature 003) are implemented in both languages —
  bidirectional Arabic↔Ge'ez over 1–99,999,999, canonical rendering (leading-1
  omission), strict round-trip parse, and Arabic-default money, byte-identical
  across JS and Python. The closed domain is enforced: no zero, negative, or
  fraction (Principle VII). Acceptance is gated by an externally authored
  `tests/vectors/numerals.json` (not yet present) plus a package-measurement
  step (Principle III).
- The **Ge'ez-script equivalence engine** (folding) is **not yet built**.

Public release remains blocked by Principle II until a Tier-1 source is added
(see below).

## Why this exists

A prior-art survey found calendar conversion is implemented many times over, but:

| 
