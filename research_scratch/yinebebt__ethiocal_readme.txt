<p align="center">
<img src="logo.svg" alt="logo" width="110" height="110">
</p>
<h1 align="center"><a href="https://pkg.go.dev/github.com/yinebebt/ethiocal">Ethiocal — Ethiopian Calendar (ባሕረ-ሐሳብ)</a></h1>

[![Go Reference](https://pkg.go.dev/badge/github.com/yinebebt/ethiocal.svg)](https://pkg.go.dev/github.com/yinebebt/ethiocal)
[![ci-badge](https://github.com/yinebebt/ethiocal/actions/workflows/ci.yml/badge.svg)](https://github.com/yinebebt/ethiocal/actions/workflows/ci.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/yinebebt/ethiocal)](https://goreportcard.com/report/github.com/yinebebt/ethiocal)

## Description

Ethiocal is an Ethiopian calendar (ባሕረ-ሐሳብ) tool for retrieving fasting and holiday dates based on the
[EOTC](https://www.ethiopianorthodox.org/) calendar, and converting between Ethiopian and
Gregorian dates. Ethiopia follows its own calendar with 13 months (twelve 30-day months
plus a 5- or 6-day 13th month).

### Features

* **GUI app** — graphical interface for desktop (macOS/Linux/Windows) and Android.
* **CLI** — `ethiocal-cli` subcommands for scripting and terminal use.
* Get Ethiopian fasting and religious festival dates for a specific year.
* Convert Ethiopian dates to Gregorian dates and vice versa.

## Installation

### Download a binary (no Go required)

Pre-built binaries are available on the [Releases](https://github.com/yinebebt/ethiocal/releases) page. Pick your platform:

| Platform | Download |
| --- | --- |
| macOS (Apple Silicon) | `curl -Lo ethiocal.zip https://github.com/yinebebt/ethiocal/releases/latest/download/ethiocal-macos-arm64.app.zip && unzip ethiocal.zip` |
| macOS (Intel) | `curl -Lo ethiocal.zip https://github.com/yinebebt/ethiocal/releases/latest/download/ethiocal-macos-amd64.app.zip && unzip ethiocal.zip` |
| Linux (x86_64) | `curl -Lo ethiocal.tar.xz https://github.com/yinebebt/ethiocal/releases/latest/download/ethiocal-linux-amd64.tar.xz && tar xJf ethiocal.tar.xz` |
| Windows (x86_64) | `curl -Lo ethiocal.zip https://github.com/yinebebt/ethiocal/releases/latest/download/ethiocal-windows-amd64.exe.zip && unzip ethiocal.zip` |
| Android (arm64) | [`ethiocal-android.apk`](https://github.com/yinebebt/ethiocal/releases/latest) — sideload on a 64-bit device |

The CLI tool ships per platform too, as `ethiocal-cli-<os>-<arch>` on the same Releases page.

### Install with Go

```bash
go install github.com/yinebebt/ethiocal@latest
```

### Build from source

```bash
git clone https://github.com/y
