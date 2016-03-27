Changelog

### unreleased
+ Remove Evaluator struct from NSURLSession
+ Added a block parameter when mocking to use matching components in the URL in the response body
+ Allow block parameter to return networking failures as well as server responses
+ Single mocks now have priority over permanent mocks

### 0.6.1
+ Tweak to return values of RequestEvaluator to be explicit about intent
+ Automatically start mocking when the requestEvaluator is set

## 0.6
+ Move state setting in task to after delegate callback
+ Add ability to block unmocked requests

## 0.5
+ Remove NSURLConnection mocking ability
+ Add format specifier to Logging

## 0.4
+ Add mock response (status and headers), thanks @kerrmarin

## 0.3
+ Internal tweaks from peer review

## 0.2.1
+ Fix for logging in NSURLSession when mocking my URL instead of request

## 0.2
+ Added log level to NSURLSession
+ Added consistent logging pattern 

## 0.1
+ Mock single requests to NSURLConnection
+ Add delay to mocked responses on NSURLConnection
+ Mock NSURLSession simple init methods
