// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserProfile extends UserProfile {
  @override
  final String? bio;
  @override
  final DateTime createdAt;
  @override
  final String? email;
  @override
  final String id;
  @override
  final String? profilePhotoUrl;
  @override
  final DateTime updatedAt;
  @override
  final String username;

  factory _$UserProfile([void Function(UserProfileBuilder)? updates]) =>
      (UserProfileBuilder()..update(updates))._build();

  _$UserProfile._(
      {this.bio,
      required this.createdAt,
      this.email,
      required this.id,
      this.profilePhotoUrl,
      required this.updatedAt,
      required this.username})
      : super._();
  @override
  UserProfile rebuild(void Function(UserProfileBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserProfileBuilder toBuilder() => UserProfileBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserProfile &&
        bio == other.bio &&
        createdAt == other.createdAt &&
        email == other.email &&
        id == other.id &&
        profilePhotoUrl == other.profilePhotoUrl &&
        updatedAt == other.updatedAt &&
        username == other.username;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, bio.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, profilePhotoUrl.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserProfile')
          ..add('bio', bio)
          ..add('createdAt', createdAt)
          ..add('email', email)
          ..add('id', id)
          ..add('profilePhotoUrl', profilePhotoUrl)
          ..add('updatedAt', updatedAt)
          ..add('username', username))
        .toString();
  }
}

class UserProfileBuilder implements Builder<UserProfile, UserProfileBuilder> {
  _$UserProfile? _$v;

  String? _bio;
  String? get bio => _$this._bio;
  set bio(String? bio) => _$this._bio = bio;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _profilePhotoUrl;
  String? get profilePhotoUrl => _$this._profilePhotoUrl;
  set profilePhotoUrl(String? profilePhotoUrl) =>
      _$this._profilePhotoUrl = profilePhotoUrl;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  UserProfileBuilder() {
    UserProfile._defaults(this);
  }

  UserProfileBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _bio = $v.bio;
      _createdAt = $v.createdAt;
      _email = $v.email;
      _id = $v.id;
      _profilePhotoUrl = $v.profilePhotoUrl;
      _updatedAt = $v.updatedAt;
      _username = $v.username;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserProfile other) {
    _$v = other as _$UserProfile;
  }

  @override
  void update(void Function(UserProfileBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserProfile build() => _build();

  _$UserProfile _build() {
    final _$result = _$v ??
        _$UserProfile._(
          bio: bio,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'UserProfile', 'createdAt'),
          email: email,
          id: BuiltValueNullFieldError.checkNotNull(id, r'UserProfile', 'id'),
          profilePhotoUrl: profilePhotoUrl,
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'UserProfile', 'updatedAt'),
          username: BuiltValueNullFieldError.checkNotNull(
              username, r'UserProfile', 'username'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
