//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'me_response.g.dart';

/// MeResponse
///
/// Properties:
/// * [email] - User's email, if present on the token.
/// * [userId] - Supabase Auth user UUID (the JWT `sub` claim).
@BuiltValue()
abstract class MeResponse implements Built<MeResponse, MeResponseBuilder> {
  /// User's email, if present on the token.
  @BuiltValueField(wireName: r'email')
  String? get email;

  /// Supabase Auth user UUID (the JWT `sub` claim).
  @BuiltValueField(wireName: r'user_id')
  String get userId;

  MeResponse._();

  factory MeResponse([void updates(MeResponseBuilder b)]) = _$MeResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MeResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MeResponse> get serializer => _$MeResponseSerializer();
}

class _$MeResponseSerializer implements PrimitiveSerializer<MeResponse> {
  @override
  final Iterable<Type> types = const [MeResponse, _$MeResponse];

  @override
  final String wireName = r'MeResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MeResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MeResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MeResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.email = valueDes;
          break;
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MeResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MeResponseBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
