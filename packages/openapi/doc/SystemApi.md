# openapi.api.SystemApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**health**](SystemApi.md#health) | **GET** /health | 


# **health**
> HealthResponse health()



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getSystemApi();

try {
    final response = api.health();
    print(response);
} on DioException catch (e) {
    print('Exception when calling SystemApi->health: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthResponse**](HealthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

