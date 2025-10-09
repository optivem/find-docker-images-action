# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2024-10-09

### Added
- Initial release of the Inspect Docker Image action
- Support for extracting Docker image digests from GitHub Container Registry
- PowerShell-based implementation for cross-platform compatibility
- Comprehensive error handling and logging
- Support for public and private repositories (with proper authentication)

### Features
- Extract exact SHA256 digest from Docker images
- Works with GitHub Container Registry (ghcr.io)
- Composite action for easy integration
- Detailed logging with emojis for better visibility
- Robust error handling with meaningful error messages

[Unreleased]: https://github.com/optivem/inspect-docker-action/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/optivem/inspect-docker-action/releases/tag/v1.0.0