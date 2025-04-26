class AppConfig {
  static const String devHost = 'http://127.0.0.1:8000';
  static const String prodHost =
      'https://expense-manager-api-s5zz.onrender.com';

  static String getHost(String environment) {
    switch (environment) {
      case 'prod':
        return prodHost;
      case 'dev':
      default:
        return devHost;
    }
  }
}
