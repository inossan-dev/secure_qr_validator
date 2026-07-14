## Changelog

All notable changes to the Secure QR Validator will be documented in this file.

## 1.2.0 - 2026-07-14

### Added

* **Automatic backward-compatible validation**: `validateQRPayload` now transparently detects and decodes both the new compact format (CBOR + Base45, emitted by `secure_qr_generator` ≥ 1.1.0 with `payloadFormat: compact`) and the legacy format (JSON + Base64) — based on the payload's character set, with no configuration change required
* Automatic fallback: if the detected format fails at a purely structural stage (encoding, decryption, or parsing), the validator retries with the other format before reporting failure, as a safety net against misdetection
* Support for the compact format's encrypt-then-MAC signature ordering, allowing forged or corrupted QR codes to be rejected before decryption is attempted (the legacy format's sign-then-encrypt ordering is still supported for older QR codes)

### Changed

* Internal decode pipeline split into two format-specific paths sharing common expiration checking and business rule application, so both formats benefit from the same `enableExpirationCheck` / business rules behavior

### Migration notes

* **No breaking changes.** `validateQRPayload`'s signature and `ValidatorConfig` are unchanged — existing integrations continue to work as-is.
* **Upgrade this package first, across all readers**, before switching any generator to `payloadFormat: compact`. A validator on 1.1.x or earlier only understands the legacy format and will fail to read compact-format QR codes.
* New dependencies pulled in by this package: `cbor` and `base45`.

## 1.1.1 - 2026-06-26

### Changed
Use of Flutter 3.38.6

## 1.1.0 - 2025-04-11

### Added
* Added support for accessing data from expired QR codes with new constructor `ValidationResult.expiredWithData`
* Modified `ValidationResult` to allow data access even when QR code is not valid
* Added new option `enableExpirationCheck` in `ValidatorConfig` to control whether expiration validation is enforced
* Updated documentation with examples for handling expired QR codes

### Changed
* Modified data access methods to work with both valid and invalid QR codes that contain data
* Improved error handling for different types of validation issues
* Enhanced the validator to preserve data for inspection even when QR code is expired

## 1.0.3 - 2024-12-25

### Added
* Add example directory for using library

## 1.0.2 - 2024-12-25

### Added
* Update readme

## 1.0.1 - 2024-12-25

### Added
* Reviews class comments

## 1.0.0 - 2024-12-25

### Added
* Initial release of the Secure QR Validator package
* Core QR code validation features:
  * Configurable encryption support using AES
  * Digital signature verification
  * Temporal validation with expiration handling
  * Customizable business rule validation
* Common validation rules library:
  * Required field validation
  * Numeric range validation
  * Future date validation
  * Pattern matching validation
  * List length validation
  * Mutually exclusive fields validation
* Flutter widget for validation status display:
  * Customizable colors and styling
  * Responsive design
  * Clear status indication with icons
* Extensive validation result handling:
  * Detailed error reporting
  * Type-safe data access
  * Convenient extension methods
* Comprehensive test coverage
* Full documentation with examples

## Security

* Implements AES encryption for secure data protection
* HMAC-SHA256 for digital signatures
* Secure key length validation
* Protection against common security issues:
  * Data tampering through signature verification
  * Unauthorized access through encryption
