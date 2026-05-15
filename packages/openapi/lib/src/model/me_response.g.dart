// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MeResponse extends MeResponse {
  @override
  final String? email;
  @override
  final String userId;

  factory _$MeResponse([void Function(MeResponseBuilder)? updates]) =>
      (MeResponseBuilder()..update(updates))._build();

  _$MeResponse._({this.email, required this.userId}) : super._();
  @override
  MeResponse rebuild(void Function(MeResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MeResponseBuilder toBuilder() => MeResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MeResponse &&
        email == other.email &&
        userId == other.userId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MeResponse')
          ..add('email', email)
          ..add('userId', userId))
        .toString();
  }
}

class MeResponseBuilder implements Builder<MeResponse, MeResponseBuilder> {
  _$MeResponse? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  MeResponseBuilder() {
    MeResponse._defaults(this);
  }

  MeResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MeResponse other) {
    _$v = other as _$MeResponse;
  }

  @override
  void update(void Function(MeResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MeResponse build() => _build();

  _$MeResponse _build() {
    final _$result = _$v ??
        _$MeResponse._(
          email: email,
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'MeResponse', 'userId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
