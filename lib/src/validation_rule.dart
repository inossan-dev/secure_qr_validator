/// Type defining a business validation rule.
///
/// A rule takes QR code data as input and returns:
/// - null if validation succeeds
/// - an error message (String) if validation fails
typedef ValidationRule = String? Function(Map<String, dynamic> data);

/// Collection of commonly used validation rules
class CommonValidationRules {
  /// Checks for the presence of a required field
  static ValidationRule required(String fieldName) {
    return (data) {
      if (!data.containsKey(fieldName) || data[fieldName] == null) {
        return 'The field $fieldName is required';
      }
      return null;
    };
  }

  /// Checks if a numeric field is within a given range
  static ValidationRule numberInRange(String fieldName, num min, num max) {
    return (data) {
      final value = data[fieldName];
      if (value is! num) {
        return 'The field $fieldName must be a number';
      }
      if (value < min || value > max) {
        return 'The field $fieldName must be between $min and $max';
      }
      return null;
    };
  }

  /// Checks if a date is in the future
  static ValidationRule dateMustBeFuture(String fieldName) {
    return (data) {
      final value = data[fieldName];
      if (value == null) return null; // Ignore if field is absent

      DateTime? date;
      if (value is String) {
        date = DateTime.tryParse(value);
      } else if (value is int) {
        date = DateTime.fromMillisecondsSinceEpoch(value);
      }

      if (date == null) {
        return 'The field $fieldName must be a valid date';
      }

      if (date.isBefore(DateTime.now())) {
        return 'The field $fieldName must be in the future';
      }
      return null;
    };
  }

  /// Checks if a string matches a regex pattern
  static ValidationRule matchesPattern(String fieldName, Pattern pattern) {
    return (data) {
      final value = data[fieldName];
      if (value == null) return null; // Ignore if field is absent

      if (value is! String) {
        return 'The field $fieldName must be a string';
      }

      if (!RegExp(pattern.toString()).hasMatch(value)) {
        return 'The field $fieldName does not match the expected format';
      }
      return null;
    };
  }

  /// Checks if a list's length is within a given range
  static ValidationRule listLength(String fieldName, {int? min, int? max}) {
    return (data) {
      final value = data[fieldName];
      if (value == null) return null;

      if (value is! List) {
        return 'The field $fieldName must be a list';
      }

      if (min != null && value.length < min) {
        return 'The field $fieldName must contain at least $min elements';
      }

      if (max != null && value.length > max) {
        return 'The field $fieldName must contain at most $max elements';
      }

      return null;
    };
  }

  /// Checks that a set of fields are mutually exclusive
  static ValidationRule mutuallyExclusive(List<String> fieldNames) {
    return (data) {
      final presentFields = fieldNames.where((field) => data[field] != null);
      if (presentFields.length > 1) {
        return 'The fields ${presentFields.join(", ")} are mutually exclusive';
      }
      return null;
    };
  }
}

/// Builder allowing to combine multiple validation rules
class ValidationRuleBuilder {
  final List<ValidationRule> _rules = [];

  /// Adds a rule to the list
  ValidationRuleBuilder addRule(ValidationRule rule) {
    _rules.add(rule);
    return this;
  }

  /// Adds multiple rules to the list
  ValidationRuleBuilder addRules(List<ValidationRule> rules) {
    _rules.addAll(rules);
    return this;
  }

  /// Creates a composite rule that combines all added rules
  ValidationRule build() {
    return (data) {
      for (final rule in _rules) {
        final error = rule(data);
        if (error != null) return error;
      }
      return null;
    };
  }
}
