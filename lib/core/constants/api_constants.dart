class ApiConstants {
  static const String baseUrlUS =
      'https://share2.dexcom.com/ShareWebServices/Services/';
  static const String baseUrlOUS =
      'https://shareous1.dexcom.com/ShareWebServices/Services/';
  static const String baseUrlJP =
      'https://share.dexcom.jp/ShareWebServices/Services/';

  static const String authenticateEndpoint =
      'General/AuthenticatePublisherAccount';
  static const String loginEndpoint = 'General/LoginPublisherAccountById';
  static const String latestGlucoseEndpoint =
      'Publisher/ReadPublisherLatestGlucoseValues';

  static const String applicationId = 'd89443d2-327c-4a6f-89e5-496bbb0317db';
}
