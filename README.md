# LiveCameraView

[![CI Status](http://img.shields.io/travis/Mike Kavouras/LiveCameraView.svg?style=flat)](https://travis-ci.org/Mike Kavouras/LiveCameraView)
[![Version](https://img.shields.io/cocoapods/v/LiveCameraView.svg?style=flat)](http://cocoapods.org/pods/LiveCameraView)
[![License](https://img.shields.io/cocoapods/l/LiveCameraView.svg?style=flat)](http://cocoapods.org/pods/LiveCameraView)
[![Platform](https://img.shields.io/cocoapods/p/LiveCameraView.svg?style=flat)](http://cocoapods.org/pods/LiveCameraView)


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

![https://github.com/mikekavouras/LiveCameraView/blob/master/assets/example.gif](https://github.com/mikekavouras/LiveCameraView/blob/master/assets/example.gif)

## Installation

LiveCameraView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "LiveCameraView"
```

## Usage

Just drop a `UIView` in your storyboard and change the class to `LiveCameraView`. All done.



```swift
// Capture a still image
cameraView.captureStill(completion: (image: UIImage?) -> Void) {
  // do something
}
```

## Author

Mike Kavouras, kavourasm@gmail.com

## License

LiveCameraView is available under the MIT license. See the LICENSE file for more info.
