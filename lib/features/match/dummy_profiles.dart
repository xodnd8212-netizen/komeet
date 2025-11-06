class ProfileCardData {
  final String name;
  final int age;
  final String city;
  final String bio;
  final String? imageUrl;
  final double lat;
  final double lng;
  const ProfileCardData({
    required this.name,
    required this.age,
    required this.city,
    required this.bio,
    this.imageUrl,
    required this.lat,
    required this.lng,
  });
}

const demoProfiles = <ProfileCardData>[
  ProfileCardData(
    name: 'Aiko',
    age: 27,
    city: 'Tokyo',
    bio: 'K-pop好き。韓国料理を一緒に食べに行きたい。',
    imageUrl: null,
    lat: 35.6762,
    lng: 139.6503,
  ),
  ProfileCardData(
    name: 'Haruka',
    age: 25,
    city: 'Yokohama',
    bio: '旅行と写真が趣味。言語交換しましょう。',
    imageUrl: null,
    lat: 35.4437,
    lng: 139.6380,
  ),
  ProfileCardData(
    name: 'Yui',
    age: 29,
    city: 'Osaka',
    bio: 'カフェ巡りと映画。落ち着いたデートが好き。',
    imageUrl: null,
    lat: 34.6937,
    lng: 135.5023,
  ),
];
