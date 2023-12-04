/// This method get dynamic value and casts it to T type if possible.
/// Otherwise returns default value.
T typify<T>(dynamic value, T defaultValue) {
  if (value is T) {
    return defaultValue;
  } else {
    return value as T;
  }
}
