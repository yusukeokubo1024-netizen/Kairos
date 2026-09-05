/// ISO 3166-1 alpha-2 country codes with display names, used to scope the
/// weather location search (Open-Meteo's geocoder accepts `countryCode`) so
/// same-named places in different countries don't collide.
class Country {
  final String code;
  final String nameJa;
  final String nameEn;

  const Country({required this.code, required this.nameJa, required this.nameEn});
}

const List<Country> kCountries = [
  Country(code: 'JP', nameJa: '日本', nameEn: 'Japan'),
  Country(code: 'KR', nameJa: '韓国', nameEn: 'South Korea'),
  Country(code: 'CN', nameJa: '中国', nameEn: 'China'),
  Country(code: 'US', nameJa: 'アメリカ合衆国', nameEn: 'United States'),
];
