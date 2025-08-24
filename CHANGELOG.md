# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Use `PATCH` not `POST` when enabling or disabling proxies when Toxiproxy supports `PATCH`.
  ([#186](https://github.com/Shopify/toxiproxy-ruby/pull/186), @brendo)
- Set HTTP timeout of 5s when communicating with Toxiproxy server.
  ([#85](https://github.com/Shopify/toxiproxy-ruby/pull/85), @casperisfine)

## [2.0.2] - 2022-09-02
### Fixed
- Fix uninitialized instance variable warning.
  ([#50](https://github.com/Shopify/toxiproxy-ruby/pull/50), @casperisfine)

### Added
- Create a RELEASE.md with release instructions.
  ([#44](https://github.com/Shopify/toxiproxy-ruby/pull/44), @miry)
- Introduce github actions to validate git tags and yaml.
  ([#45](https://github.com/Shopify/toxiproxy-ruby/pull/45), @miry)
- Introduce CHANGELOG.md.
  ([#47](https://github.com/Shopify/toxiproxy-ruby/pull/47), @miry)

### Changed
- Update release pipeline to trigger only if a new tag appeared.
  ([#46](https://github.com/Shopify/toxiproxy-ruby/pull/46), @miry)
- Add gem metafields `source_code_uri` and `changelog_uri`.
  ([#47](https://github.com/Shopify/toxiproxy-ruby/pull/47), @miry)

## [2.0.1] - 2022-03-15
### Changed
- Test against v3.0 and v3.1 ruby. Drop support of v2.5 ruby.
  ([#42](https://github.com/Shopify/toxiproxy-ruby/pull/42), @miry)
- Reset http client on host changes. ([#43](https://github.com/Shopify/toxiproxy-ruby/pull/43), @miry)

[Unreleased]: https://github.com/Shopify/toxiproxy-ruby/compare/v2.0.2...HEAD
[2.0.2]: https://github.com/Shopify/toxiproxy-ruby/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/Shopify/toxiproxy-ruby/compare/v2.0.0...v2.0.1
