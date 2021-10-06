+++
banner: "/static/images/blog/one_pixel_at_a_time/wrapping_summary.png"
categories: ["ScummVM"]
date: 2013-08-30T02:51:00.002000-05:00
description: ""
images: []
tags: []
title: "One Pixel at a Time"
template: "blog.html.jinja"
+++

Over the course of this project, the way I've rendered images to the screen has rather drastically changed. Well, let me clarify. Everything is blitted to the screen in exactly the same way ( `OSystem::copyRectToScreen()` ), however, how I get/modify the pixels that I pass to `copyRectToScreen()` has changed. (Disclaimer: From past experiences, we know that panorama images are stored transposed. However, in this post, I'm not really going to talk about it, though you may see some snippets of that in code examples) So a brief history:

In my first iteration an image would be rendered to the screen as such:  

1. Load the image from file to a pixel buffer
1. Choose where to put the image.
1. Choose what portion of the image we want to render to the screen. We don't actually specify the height/width, just the (x,y) top-left corner
{{ image('/static/images/blog/one_pixel_at_a_time/wrapping_summary.png') }}
1. Call `renderSubRect(buffer, destinationPoint, Common::Point(200, 0))`
1. Create a subRect of the image by clipping the entire image width/height with the boundaries of the window and the boundaries of the image size
1. If we're in Panorama or Tilt RenderState, then warp the pixels of the subRect. (See post about the panorama system)
1. Render the final pixels to the screen using `OSytem::copyRectToScreen()`
1. If we're rendering a background image (boolean passed in the arguments), check if the dimensions of the subRect completely fill the window boundaries. If they don't them we need to wrap the image so it seems like it is continuous.
1. If we need to wrap, calculate a wrappedSubRect and a wrappedDestination point from the subRect dimensions and the window dimensions.
1. Call `renderSubRect(buffer, wrappedDestination, wrappedSubRect)`

At first glance, this seems like it would work well; however, it had some major flaws. The biggest problem stemmed from the [Z-Vision technology](http://richiesams.blogspot.com/2013/08/the-making-of-psychedelic-pictures-aka.html).

To understand why, let's review how pixel warping works:  

1. We use math to create a table of (x, y) offsets.
2. For each pixel in the subRect:
   1. Look up the offsets for the corresponding (x, y) position
   2. Add those offsets to the the actual coordinates
   3. Look up the pixel color at the new coordinates
   4. Write that pixel color to the destination buffer at the original coordinates

Let's give a specific example:  

1. We want to render a pixel located at (183, 91)
{{ image('/static/images/blog/one_pixel_at_a_time/example_pixel_to_render.png') }}
1. We go to the RenderTable and look up the offsets at location (183, 91)
{{ image('/static/images/blog/one_pixel_at_a_time/example_table.png') }}
1. Add (52, 13) to (183, 91) to get (235, 104)
1. Look up the pixel color at (235, 104). In this example, the color is FFFC00 (Yellow).
{{ image('/static/images/blog/one_pixel_at_a_time/example_pixel_offset.png') }}
1. Write to color FFFC00 to (183, 91) in the destination buffer

The problem occurs when you're at the edges of an image. Let's consider the same scenario, but the image is shifted to the left:  

{{ image('/static/images/blog/one_pixel_at_a_time/example_edge_case.png') }}

Let's skip to step 4:  

When we try to look up the pixel color at (235, 104) we have a problem. (235, 104) is outside the boundaries of the image.  

So, after discussing the problem with wjp, we thought that we could let the pixel warping function ( mutateImage() ) do the image wrapping, instead of doing it in renderSubRectToScreen. Therefore, in renderSubRectToScreen(), instead of clipping subRect to the boundaries of the image, I expand it to fill the entire window. Then inside of mutateImage, if the final pixel coordinates are larger or smaller than the actual image dimensions, I just keep adding or subtracting image widths/heights until the coordinates are in the correct range.

```cpp
void RenderTable::mutateImage(uint16 *sourceBuffer, uint16* destBuffer, int16 imageWidth, int16 imageHeight, int16 destinationX, int16 destinationY, const Common::Rect &subRect, bool wrap) {
    for (int16 y = subRect.top; y < subRect.bottom; y++) {
        int16 normalizedY = y - subRect.top;
        int32 internalColumnIndex = (normalizedY + destinationY) * _numColumns;
        int32 destColumnIndex = normalizedY * _numColumns;

        for (int16 x = subRect.left; x < subRect.right; x++) {
            int16 normalizedX = x - subRect.left;

            int32 index = internalColumnIndex + normalizedX + destinationX;

            // RenderTable only stores offsets from the original coordinates
            int16 sourceYIndex = y + _internalBuffer[index].y;
            int16 sourceXIndex = x + _internalBuffer[index].x;

            if (wrap) {
                // If the indicies are outside of the dimensions of the image, shift the indicies until they are in range
                while (sourceXIndex >= imageWidth) {
                    sourceXIndex -= imageWidth;
                }
                while (sourceXIndex < 0) {
                    sourceXIndex += imageWidth;
                }

                while (sourceYIndex >= imageHeight) {
                    sourceYIndex -= imageHeight;
                }
                while (sourceYIndex < 0) {
                    sourceYIndex += imageHeight;
                }
            } else {
                // Clamp the yIndex to the size of the image
                sourceYIndex = CLIP<int16>(sourceYIndex, 0, imageHeight - 1);

                // Clamp the xIndex to the size of the image
                sourceXIndex = CLIP<int16>(sourceXIndex, 0, imageWidth - 1);
            }

            destBuffer[destColumnIndex + normalizedX] = sourceBuffer[sourceYIndex * imageWidth + sourceXIndex];
        }
    }
}
```
  
With these changes, rendering worked well and wrapping/scrolling worked well. However, the way in which Zork games calculate background position forced me to slightly change the model.

Script files change location by calling `change_location(<world> <room> <nodeview> <location>)`. `location` refers to the initial position of the background image. Originally I thought this referred to distance from the top-left corner of the image. So for example, `location = 200` would create the following image:

{{ image('/static/images/blog/one_pixel_at_a_time/location_200_offset.png') }}

However, it turns out that this is not the case. `location` refers to distance the top-left corner is from the center line of the window:

{{ image('/static/images/blog/one_pixel_at_a_time/location_centerline.png') }}

Therefore, rather than worry about a subRect at all, I just pass in the destination coordinate, and then try to render the entire image (clipping it to window boundaries):

```cpp
void RenderManager::renderSubRectToScreen(Graphics::Surface &surface, int16 destinationX, int16 destinationY, bool wrap) {
    int16 subRectX = 0;
    int16 subRectY = 0;

    // Take care of negative destinations
    if (destinationX < 0) {
        subRectX = -destinationX;
        destinationX = 0;
    } else if (destinationX >= surface.w) {
        // Take care of extreme positive destinations
        destinationX -= surface.w;
    }

    // Take care of negative destinations
    if (destinationY < 0) {
        subRectY = -destinationY;
        destinationY = 0;
    } else if (destinationY >= surface.h) {
        // Take care of extreme positive destinations
        destinationY -= surface.h;
    }

    if (wrap) {
        _backgroundWidth = surface.w;
        _backgroundHeight = surface.h;

        if (destinationX > 0) {
            // Move destinationX to 0
            subRectX = surface.w - destinationX;
            destinationX = 0;
        }

        if (destinationY > 0) {
            // Move destinationY to 0
            subRectX = surface.w - destinationX;
            destinationY = 0;
        }
    }

    // Clip subRect to working window bounds
    Common::Rect subRect(subRectX, subRectY, subRectX + _workingWidth, subRectY + _workingHeight);

    if (!wrap) {
        // Clip to image bounds
        subRect.clip(surface.w, surface.h);
    }

    // Check destRect for validity
    if (!subRect.isValidRect() || subRect.isEmpty())
        return;

    if (_renderTable.getRenderState() == RenderTable::FLAT) {
        _system->copyRectToScreen(surface.getBasePtr(subRect.left, subRect.top), surface.pitch, destinationX + _workingWindow.left, destinationY + _workingWindow.top, subRect.width(), subRect.height());
    } else {
        _renderTable.mutateImage((uint16 *)surface.getPixels(), _workingWindowBuffer, surface.w, surface.h, destinationX, destinationY, subRect, wrap);

        _system->copyRectToScreen(_workingWindowBuffer, _workingWidth * sizeof(uint16), destinationX + _workingWindow.left, destinationY + _workingWindow.top, subRect.width(), subRect.height());
    }
}
```

So to walk through it:  

1. If destinationX/Y is less than 0, the image is off the screen to the left/top. Therefore get the top left corner of the subRect by subtracting destinationX/Y.
1. If destinationX/Y is greater than the image width/height respectively, the image is off the screen to the right/bottom. Therefore get the top left corner of the subRect by adding destinationX/Y.
1. If we're wrapping and destinationX/Y is still positive at this point, it means that the image will be rendered like this:
{{ image('/static/images/blog/one_pixel_at_a_time/wrapping_boundaries.png') }}
1. We want it to fully wrap, so we offset the image to the left one imageWidth, and then let mutateImage() take care of actually wrapping.

The last change to the render system was not due to a problem with the system, but due to a problem with the pixel format of the images. All images in Zork Nemesis and Zork Grand Inquisitor are encoded in RGB 555. However, a few of the ScummVM backends do not support RGB 555. Therefore, it was desirable to convert all images to RGB 565 on the fly. To do this, all image pixel data is first loaded into a Surface, then converted to RGB 565. After that, it is passed to `renderSubRectToSurface()`.

Since I was alreadly preloading the pixel data into a Surface for RGB conversion, I figured that was a good place to do 'un-transpose-ing', rather than having to do it within `mutateImage()`.

So, with all the changes, this is the current state of the render system:

1. Read image pixel data from file and dump it into a Surface buffer (see below). In the case of a background image, the surface buffer is stored so we only have to read the file once.
2. Use the ScriptManager to calculate the destination coordinates
3. Call `renderSubRectToScreen(surface, destinationX, destinationY, wrap)`    (see above)
   1. If destinationX/Y is less than 0, the image is off the screen to the left/top. Therefore get the top left corner of the subRect by subtracting destinationX/Y.
   2. If destinationX/Y is greater than the image width/height respectively, the image is off the screen to the right/bottom. Therefore get the top left corner of the subRect by adding destinationX/Y.
   3. If we're wrapping and destinationX/Y is still positive at this point, offset the image to the left one imageWidth
   4. If we're in `PANORAMA` or `TILT` state, call `mutateImage()`     (see above)
      1. Iterate over the pixels of the subRect
      2. At each pixel get the coordinate offsets from the RenderTable
      3. Add the offsets to the coordinates of the pixel.
      4. Use these new coordinates to get the location of the pixel color
      5. Store this color at the coordinates of the original pixel
   5. Blit the final result to the Screen using `OSystem::copyRectToScreen()`

```cpp
void RenderManager::readImageToSurface(const Common::String &fileName, Graphics::Surface &destination) {
    Common::File file;

    if (!file.open(fileName)) {
        warning("Could not open file %s", fileName.c_str());
        return;
    }

    // Read the magic number
    // Some files are true TGA, while others are TGZ
    uint32 fileType = file.readUint32BE();

    uint32 imageWidth;
    uint32 imageHeight;
    Graphics::TGADecoder tga;
    uint16 *buffer;
    bool isTransposed = _renderTable.getRenderState() == RenderTable::PANORAMA;
    // All ZEngine images are in RGB 555
    Graphics::PixelFormat pixelFormat555 = Graphics::PixelFormat(2, 5, 5, 5, 0, 10, 5, 0, 0);
    destination.format = pixelFormat555;

    bool isTGZ;

    // Check for TGZ files
    if (fileType == MKTAG('T', 'G', 'Z', '\0')) {
        isTGZ = true;

        // TGZ files have a header and then Bitmap data that is compressed with LZSS
        uint32 decompressedSize = file.readSint32LE();
        imageWidth = file.readSint32LE();
        imageHeight = file.readSint32LE();

        LzssReadStream lzssStream(&file);
        buffer = (uint16 *)(new uint16[decompressedSize]);
        lzssStream.read(buffer, decompressedSize);
    } else {
        isTGZ = false;

        // Reset the cursor
        file.seek(0);

        // Decode
        if (!tga.loadStream(file)) {
            warning("Error while reading TGA image");
            return;
        }

        Graphics::Surface tgaSurface = *(tga.getSurface());
        imageWidth = tgaSurface.w;
        imageHeight = tgaSurface.h;

        buffer = (uint16 *)tgaSurface.getPixels();
    }

    // Flip the width and height if transposed
    if (isTransposed) {
        uint16 temp = imageHeight;
        imageHeight = imageWidth;
        imageWidth = temp;
    }

    // If the destination internal buffer is the same size as what we're copying into it,
    // there is no need to free() and re-create
    if (imageWidth != destination.w || imageHeight != destination.h) {
        destination.create(imageWidth, imageHeight, pixelFormat555);
    }

    // If transposed, 'un-transpose' the data while copying it to the destination
    // Otherwise, just do a simple copy
    if (isTransposed) {
        uint16 *dest = (uint16 *)destination.getPixels();

        for (uint32 y = 0; y < imageHeight; y++) {
            uint32 columnIndex = y * imageWidth;

            for (uint32 x = 0; x < imageWidth; x++) {
                dest[columnIndex + x] = buffer[x * imageHeight + y];
            }
        }
    } else {
        memcpy(destination.getPixels(), buffer, imageWidth * imageHeight * _pixelFormat.bytesPerPixel);
    }

    // Cleanup
    if (isTGZ) {
        delete[] buffer;
    } else {
        tga.destroy();
    }

    // Convert in place to RGB 565 from RGB 555
    destination.convertToInPlace(_pixelFormat);
}
```

That's it! Thanks for reading. As always, feel free to ask questions or make comments.

Happy coding! :)
