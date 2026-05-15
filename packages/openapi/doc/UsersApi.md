# openapi.api.UsersApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getOrBootstrapMe**](UsersApi.md#getorbootstrapme) | **GET** /users/me | 


# **getOrBootstrapMe**
> UserProfile getOrBootstrapMe()



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();

try {
    final response = api.getOrBootstrapMe();
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->getOrBootstrapMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserProfile**](UserProfile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

