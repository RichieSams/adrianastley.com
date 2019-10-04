+++
banner: ""
categories: ["ScummVM"]
date: 2013-08-18T20:15:00.002000-05:00
description: ""
images: []
tags: []
title: "Moving Through Time"
template: "blog.html.jinja"
+++

Before I start, I know it's been a long time since my last post. Over the next couple days I'm going to write a series of posts about what I've been working on these last two weeks. So without further ado, here is the first one:

While I was coding in the last couple of weeks, I noticed that every time I came back to the main game from a debug window, the whole window hung for a good 6 seconds. After looking at my `run()` loop for a bit, I realized what the problem was. When I returned from the debug window, the next frame would have a massive deltaTime, which in turn caused a huge frame delay. This was partially a problem with how I had structured my frame delay calculation, but in the end, I needed a way to know when the game was paused, and to modify my deltaTime value accordingly.

To solve the problem, I came up with a pretty simple Clock class that tracks time, allows pausing, (and if you really wanted scaling/reversing):

```cpp
/* Class for handling frame to frame deltaTime while keeping track of time pauses/un-pauses */
class Clock {
public:
    Clock(OSystem *system);

private:
    OSystem *_system;
    uint32 _lastTime;
    int32 _deltaTime;
    uint32 _pausedTime;
    bool _paused;

public:
    /**
     * Updates _deltaTime with the difference between the current time and
     * when the last update() was called.
     */
    void update();
    /**
     * Get the delta time since the last frame. (The time between update() calls)
     *
     * @return    Delta time since the last frame (in milliseconds)
     */
    uint32 getDeltaTime() const { return _deltaTime; }
    /**
     * Get the time from the program starting to the last update() call
     *
     * @return Time from program start to last update() call (in milliseconds)
     */
    uint32 getLastMeasuredTime() { return _lastTime; }

    /**
     * Pause the clock. Any future delta times will take this pause into account.
     * Has no effect if the clock is already paused.
     */
    void start();
    /**
     * Un-pause the clock.
     * Has no effect if the clock is already un-paused.
     */
    void stop();
};

```

I'll cover the guts of the functions in a bit, but first, here is their use in the main run() loop:  

```cpp
Common::Error ZEngine::run() {
    initialize();

    // Main loop
    while (!shouldQuit()) {
        _clock.update();
        uint32 currentTime = _clock.getLastMeasuredTime();
        uint32 deltaTime = _clock.getDeltaTime();

        processEvents();

        _scriptManager->update(deltaTime);
        _renderManager->update(deltaTime);

        // Update the screen
        _system->updateScreen();

        // Calculate the frame delay based off a desired frame time
        int delay = _desiredFrameTime - int32(_system->getMillis() - currentTime);
        // Ensure non-negative
        delay = delay < 0 ? 0 : delay;
        _system->delayMillis(delay);
    }

    return Common::kNoError;
}
```

And lastly, whenever the engine is paused (by a debug console, by the Global Main Menu, by a phone call, etc.), ScummVM core calls pauseEngineIntern(bool pause), which can be overridden to implement any engine internal pausing. In my case, I can call Clock::start()/stop()

```cpp
void ZEngine::pauseEngineIntern(bool pause) {
    _mixer->pauseAll(pause);

    if (pause) {
        _clock.stop();
    } else {
        _clock.start();
    }
}
```

All the work of the class is done by update(). update() gets the current time using getMillis() and subtracts the last recorded time from it to get `_deltaTime`. If the clock is currently paused, it subtracts off the amount of time that the clock has been paused. Lastly, it clamps the value to positive values.

```cpp
void Clock::update() {
    uint32 currentTime = _system->getMillis();

    _deltaTime = (currentTime - _lastTime);
    if (_paused) {
        _deltaTime -= (currentTime - _pausedTime);
    }

    if (_deltaTime < 0) {
        _deltaTime = 0;
    }

    _lastTime = currentTime;
}
```
  
If you wanted to slow down or speed up time, it would be a simple matter to scale _deltaTime. You could even make it negative to make time go backwards. The full source code can be found  [here](https://github.com/RichieSams/scummvm/blob/zengine/engines/zengine/clock.cpp) and [here](https://github.com/RichieSams/scummvm/blob/zengine/engines/zengine/clock.h).  

Well that's it for this post. Next up is a post about the rendering system. Until then, happy coding! :)
