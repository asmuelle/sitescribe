# Security Policy

## Supported Versions

`sitescribe` is under active pre-1.0 development. Security fixes are applied only to
the latest `main` branch (and the most recent tagged release, when one exists).
Older commits and tags do not receive backported fixes.

| Version            | Supported          |
| ------------------ | ------------------ |
| `main` (latest)    | :white_check_mark: |
| Older commits/tags | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues,
pull requests, or discussions.**

Instead, report privately through GitHub's coordinated-disclosure flow:

1. Open the [**Security** tab](https://github.com/asmuelle/sitescribe/security) of this repository.
2. Click **Report a vulnerability** to open a private advisory
   ([direct link](https://github.com/asmuelle/sitescribe/security/advisories/new)).

Please include as much of the following as you can:

- A description of the issue and its potential impact.
- Steps to reproduce — a proof-of-concept, affected inputs/endpoints, or a failing test.
- The affected version or commit, and your environment.
- Any suggested remediation, if you have one.

## Response Expectations

This is a personal, experimental project maintained on a best-effort basis:

- **Acknowledgement:** within 5 business days.
- **Triage and severity assessment:** within 10 business days.
- **Fix and disclosure:** timeline depends on severity and complexity. You will be
  kept informed, and credited in the published advisory unless you ask otherwise.

## Disclosure Policy

This project follows **coordinated disclosure**. Please give a reasonable window to
ship a fix before any public disclosure. When a fix is available, a GitHub Security
Advisory will be published describing the issue and its resolution.

## Automated Security Measures

This repository is continuously protected by:

- **Dependabot** — automated dependency and GitHub Actions security/version updates.
- **Secret scanning** with **push protection** — blocks committed credentials.
- **Private vulnerability reporting** — enabled for confidential disclosure.

These measures reduce, but do not eliminate, risk. Well-intentioned reports of
anything they miss are genuinely appreciated.
