+++
banner: ""
categories: ["ScummVM"]
date: 2013-07-17T16:21:00.002000-05:00
description: ""
images: []
tags: []
title: "The Engine Skeleton Gains Some Tendons - Part 2"
template: "blog.html.jinja"
+++

Part 2!! As a recap from last post, I started out last week by implementing image handling, video handling, and a text debug console.

I started with the console as it allows me to to map typed commands to functions. (IE. 'loadimage zassets/castle/cae4d311.tga' calls loadImageToScreen() on that file) This is extremely useful in that I can load an image multiple times or I can load different images all without having to re-run the engine or recompile.

Creating the text console was actually extremely easy because it was already written. I just to inherit from the base class:

```cpp
class Console : public GUI::Debugger {
public:
    Console(ZEngine *engine);
    virtual ~Console() {}

private:
    ZEngine *_engine;

    bool cmdLoadImage(int argc, const char **argv);
    bool cmdLoadVideo(int argc, const char **argv);
    bool cmdLoadSound(int argc, const char **argv);
};
```

In the constructor, I just registered the various commands:

```cpp
Console::Console(ZEngine *engine) : GUI::Debugger(), _engine(engine) {
    DCmd_Register("loadimage", WRAP_METHOD(Console, cmdLoadImage));
    DCmd_Register("loadvideo", WRAP_METHOD(Console, cmdLoadVideo));
    DCmd_Register("loadsound", WRAP_METHOD(Console, cmdLoadSound));
}
```

And then, in ZEngine::initialize() I created an instance of my custom class:

```cpp
void ZEngine::initialize() {
        .
        .
        .

    _console = new Console(this);
}
```

And lastly, I registered a key press combination to bring up the debug console:

```cpp
void ZEngine::processEvents() {
    while (_eventMan->pollEvent(_event)) {
        switch (_event.type) {
        case Common::EVENT_KEYDOWN:
            switch (_event.kbd.keycode) {
            case Common::KEYCODE_d:
                if (_event.kbd.hasFlags(Common::KBD_CTRL)) {
                    // Start the debugger
                    _console->attach();
                    _console->onFrame();
                }
                break;
            }
            break;
        }
    }
}
```

With that done, I can press ctrl+d, and this is what pops up:

{{ fancybox_image('/static/images/zengine_console.png', 500) }}

Awesome! With that done, I could move on to images. All the images in ZNem and ZGI are .tga files, but don't be fooled; the vast majority of them aren't actually TGA. They're actually TGZ, a custom image format. The format itself isn't too difficult, and I give all the credit to [Mr. Mouse on Xentax](http://forum.xentax.com/viewtopic.php?f=18&amp;t=3511&amp;sid=af21b2ecfc2990f4cdec70a1585df31a).

```text
Byte[4] "TGZ\0"
uint32 Original size of bitmap data
uint32 Width of image
uint32 Heigth of image
Byte[n] Bitmap data (LZSS compressed)
```

I could have created a class for decoding TGZ, but with it being that simple, I just chose to integrate the decoding in the renderImageToScreen method:

```cpp
void ZEngine::renderImageToScreen(const Common::String &fileName, uint32 x, uint32 y) {
    Common::File file;

    if (!file.open(fileName)) {
        error("Could not open file %s", fileName.c_str());
        return;
    }

    // Read the magic number
    // Some files are true TGA, while others are TGZ
    char fileType[4];
    file.read(fileType, 4);

    // Check for TGZ files
    if (fileType[0] == 'T' && fileType[1] == 'G' && fileType[2] == 'Z' && fileType[3] == '\0') {
        // TGZ files have a header and then Bitmap data that is compressed with LZSS
        uint32 decompressedSize = file.readSint32LE();
        uint32 width = file.readSint32LE();
        uint32 height = file.readSint32LE();

        LzssReadStream stream(&file);
        byte *buffer = new byte[decompressedSize];
        stream.read(buffer, decompressedSize);

        _system->copyRectToScreen(buffer, width * 2, x, y, width, height);
    } else {
        // Reset the cursor
        file.seek(0);

        // Decode
        Graphics::TGADecoder tga;
        if (!tga.loadStream(file)) {
            error("Error while reading TGA image");
            return;
        }

        const Graphics::Surface *tgaSurface = tga.getSurface();
        _system->copyRectToScreen(tgaSurface->pixels, tgaSurface->pitch, x, y, tgaSurface->w, tgaSurface->h);

        tga.destroy();
    }

    _needsScreenUpdate = true;
}
```

So after using the loadimage command in the console, we get a wonderful picture on the screen:

{{ fancybox_image('/static/images/adding_tgz_to_zengine.png', 500) }}

Video!! Implementing the image aspect of video was rather trivial, as ZEngine uses a standard AVI format. The only 'wrinkle' was that the videos used a different PixelFormat. Every other part of the engine uses RGB 555, but videos use RGB 565. However, when a video is playing, it's only thing going on. So, I can reinitialize the graphics to RGB 565 before playing a video, and reset it back to RGB 555 when the video finishes:

```cpp
void ZEngine::startVideo(Video::VideoDecoder *videoDecoder) {
    if (!videoDecoder)
        return;

    _currentVideo = videoDecoder;

    Common::List formats;
    formats.push_back(videoDecoder->getPixelFormat());
    initGraphics(_width, _height, true, formats);
           .
           .
           .
}
void ZEngine::continueVideo() {
           .
           .
           .

    if (!_currentVideo->endOfVideo()) {
        // Code to render the current frame
    } else {
        initGraphics(_width, _height, true, &_pixelFormat);
        delete _currentVideo;
        _currentVideo = 0;
        delete _scaledVideoFrameBuffer;
        _scaledVideoFrameBuffer = 0;
    }
}
```

Where `_pixelFormat` is a const PixelFormat member variable of the ZEngine class.

One other slight wrinkle is that the video is at a resolution of 256 x 160, which is quite small if I do say so myself. To fix that, I used a linear 2x scaler that [md5] wrote and scaled every frame. Using the opening cinematic as an example, we get this:

{{ fancybox_image('/static/images/znemesis_opening_cinematic.png', 500) }}

However, the sound in video is messed up, and it's actually been what I've been working on this week, but I'll save that for another post.

I'm now two steps closer to getting all the parts of the engine implemented and somewhat tied together. As always, if you have an suggestions or comments, feel free to comment below.

Happy coding! :)
