/// Type définissant une règle de validation métier.
///
/// Une règle prend en entrée les données du QR code et retourne :
/// - null si la validation réussit
/// - un message d'erreur (String) si la validation échoue
typedef ValidationRule = String? Function(Map<String, dynamic> data);

/// Collection de règles de validation couramment utilisées
class CommonValidationRules {
  /// Vérifie la présence d'un champ requis
  static ValidationRule required(String fieldName) {
    return (data) {
      if (!data.containsKey(fieldName) || data[fieldName] == null) {
        return 'Le champ $fieldName est requis';
      }
      return null;
    };
  }

  /// Vérifie qu'un champ numérique est dans un intervalle donné
  static ValidationRule numberInRange(String fieldName, num min, num max) {
    return (data) {
      final value = data[fieldName];
      if (value is! num) {
        return 'Le champ $fieldName doit être un nombre';
      }
      if (value < min || value > max) {
        return 'Le champ $fieldName doit être entre $min et $max';
      }
      return null;
    };
  }

  /// Vérifie qu'une date est dans le futur
  static ValidationRule dateMustBeFuture(String fieldName) {
    return (data) {
      final value = data[fieldName];
      if (value == null) return null; // Ignorer si le champ est absent

      DateTime? date;
      if (value is String) {
        date = DateTime.tryParse(value);
      } else if (value is int) {
        date = DateTime.fromMillisecondsSinceEpoch(value);
      }

      if (date == null) {
        return 'Le champ $fieldName doit être une date valide';
      }

      if (date.isBefore(DateTime.now())) {
        return 'Le champ $fieldName doit être dans le futur';
      }
      return null;
    };
  }

  /// Vérifie qu'une chaîne correspond à un format regex
  static ValidationRule matchesPattern(String fieldName, Pattern pattern) {
    return (data) {
      final value = data[fieldName];
      if (value == null) return null; // Ignorer si le champ est absent

      if (value is! String) {
        return 'Le champ $fieldName doit être une chaîne de caractères';
      }

      if (!RegExp(pattern.toString()).hasMatch(value)) {
        return 'Le champ $fieldName ne correspond pas au format attendu';
      }
      return null;
    };
  }

  /// Vérifie qu'une liste a une taille comprise dans un intervalle
  static ValidationRule listLength(String fieldName, {int? min, int? max}) {
    return (data) {
      final value = data[fieldName];
      if (value == null) return null;

      if (value is! List) {
        return 'Le champ $fieldName doit être une liste';
      }

      if (min != null && value.length < min) {
        return 'Le champ $fieldName doit contenir au moins $min éléments';
      }

      if (max != null && value.length > max) {
        return 'Le champ $fieldName doit contenir au plus $max éléments';
      }

      return null;
    };
  }

  /// Vérifie qu'un ensemble de champs sont mutuellement exclusifs
  static ValidationRule mutuallyExclusive(List<String> fieldNames) {
    return (data) {
      final presentFields = fieldNames.where((field) => data[field] != null);
      if (presentFields.length > 1) {
        return 'Les champs ${presentFields.join(", ")} sont mutuellement exclusifs';
      }
      return null;
    };
  }
}

/// Builder permettant de combiner plusieurs règles de validation
class ValidationRuleBuilder {
  final List<ValidationRule> _rules = [];

  /// Ajoute une règle à la liste
  ValidationRuleBuilder addRule(ValidationRule rule) {
    _rules.add(rule);
    return this;
  }

  /// Ajoute plusieurs règles à la liste
  ValidationRuleBuilder addRules(List<ValidationRule> rules) {
    _rules.addAll(rules);
    return this;
  }

  /// Crée une règle composite qui combine toutes les règles ajoutées
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