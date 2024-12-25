## Changelog

All notable changes to the Secure QR Validator will be documented in this file.


## 1.0.0 - 2024-12-25

## Added

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
