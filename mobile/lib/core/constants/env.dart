// API Base URL configuration
// Can be overridden via --dart-define=API_BASE_URL=http://your-ip:8000/api/v1
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.201.175.112:8000/api/v1', // Auto-detected IP from setup
);
