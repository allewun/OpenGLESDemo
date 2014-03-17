# OpenGL ES Demo
The `glReadPixels()` function seems to fail on only iOS 7 devices (it works as expected on iOS 6 simulator/device and the iOS 7 simulator). This is a small sample app to try to and narrow down the issue.

![Screenshot](https://raw.github.com/allewun/OpenGLESDemo/master/screenshot.png)


## Demonstrating the problem

The OpenGL ES v1.1 EAGLContext used in the app has two modes, it can either be layer-backed or data-backed. Change the macro `BACKING_TYPE_LAYERBACKED` at the top of GLView.m to toggle between modes.

### Layer-backed context

`glReadPixels()` appears to function correctly in this context mode on all configurations of iOS 6/7 and device/simulator.

When the app starts up, a default background color of gray will be set via OpenGL (`glClearColor()`) and displayed using `[self.context presentRenderbuffer:GL_RENDERBUFFER_OES]`.

Tapping the **glReadPixels()** button will cause the scene to be rendered again, and just before displaying it, `glReadPixels()` will be called to fetch the OpenGL scene contents. The first 20 bytes of data are shown in an alert.

Tapping **Random Color** simply changes the color and renders the scene again, to help verify that subsequent invocations of `glReadPixels()` work as expected.

### Data-backed context

In this situation, the behavior is summarized by the table below. Because the context is data-backed, the view won't change colors since OpenGL is rendering this off-screen.

Tapping the **glReadPixels()** button on iOS 7 devices shows null data being read, indicating a possible bug?

The table below shows the configurations where it works and doesn't work.

![Table](https://raw.github.com/allewun/OpenGLESDemo/master/table.png)


## Help?

Any help would be greatly appreciated! This problem was also posted to [Stack Overflow](https://stackoverflow.com/questions/22393687/glreadpixels-gives-a-black-image-only-on-ios-7-device).

***UPDATE:***
[Matic Oblak's response on Stack Overflow](http://stackoverflow.com/a/22449287/3418047) fixed the problem (still not sure why the original code only failed for iOS 7 though).