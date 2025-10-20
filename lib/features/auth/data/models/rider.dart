class Rider {
  final String uid;
  final String name;
  final String surname;
  final String phone;
  final String email;

  Rider({
    required this.uid,
    this.name = "Not Set",
    this.surname = "Not Set",
    required this.phone,
    this.email = "Not Set",
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'surname': surname,
    'phone': phone,
    'email': email,
  };

  factory Rider.fromMap(Map<String, dynamic> map) => Rider(
    uid: map['uid'] as String,
    name: map['name'] as String,
    surname: map['surname'] as String,
    phone: map['phone'] as String,
    email: map['email'] as String,
  );
}
