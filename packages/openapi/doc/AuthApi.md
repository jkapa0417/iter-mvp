# openapi.api.AuthApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**meHandler**](AuthApi.md#mehandler) | **GET** /me | 


# **meHandler**
> MeResponse meHandler()



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();

try {
    final response = api.meHandler();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->meHandler: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MeResponse**](MeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

