+++
banner: ""
categories: ["ScummVM"]
date: 2013-06-26T19:42:00.001000-05:00
description: ""
images: []
tags: []
title: "Scripting!!!!!!"
template: "blog.html.jinja"
+++

I just realized that I forgot to do a post last week! I was being so productive, time just flew by.

Last week and the beginning of this week I've been working on the script management system for ZEngine. Well, before I get into that, let me go back a little further. According to my original timeline, the next milestone was creating a skeleton engine that could do basic rendering, sounds, and events. So, last Monday, I started by cleaning up the main game loop and splitting everything into separate methods and classes. With that, the run loop looks like this:

```cpp
Common::Error ZEngine::run() {
    initialize();

    // Main loop
    uint32 currentTime = _system->getMillis();
    uint32 lastTime = currentTime;
    const uint32 desiredFrameTime = 33; // ~30 fps

    while (!shouldQuit()) {
        processEvents();

        currentTime = _system->getMillis();
        uint32 deltaTime = currentTime - lastTime;
        lastTime = currentTime;

        updateScripts();
        updateAnimations(deltaTime);

        if (_needsScreenUpdate)
        {
            _system->updateScreen();
        }

        // Calculate the frame delay based off a desired frame rate
        int delay = desiredFrameTime - (currentTime - _system->getMillis());
        // Ensure non-negative
        delay = delay < 0 ? 0 : delay;
        _system->delayMillis(delay);
    }

    return Common::kNoError;
}
```

No bad, if I do say so myself. :)

That done, I started implementing the various method shells, such as processEvents(). It was about that time that I realized the the structure of the scripting system had a huge impact on the structure of the engine as a whole. For example, should the event system call methods directly, or should it just register key presses, etc. and let the script system handle the calls? I had a basic understanding of how it _probably_ worked, knowing the history of adventure games, but it was clear I needed to understand the script system before I could go any further.

The .scr files themselves are rather simple; they're text-based if-then statements. Here's an example of a puzzle and a control:

```text
puzzle:5251 {
    criteria {
        [4188]: 1
        [4209] ! 5
        [7347]: 1
        [67]: 0
    }
    criteria {
        [4209] > 1
        [7347]: 1
        [67]: 1
        [4188]: [6584]
    }
    results {
        action:assign(5985, 0)
        background:timer:7336(60)
        event:change_location(C,B,C0,1073)
        background:music:5252(1 a000h1tc.raw 1)
    }
    flags {
        ONCE_PER_INST
    }
}

control:8454 push_toggle {
    flat_hotspot(0,265,511,54)
    cursor(backward)
}
```

#### Puzzles

* Criteria are a set of comparisons. If ANY of the criteria are satisfied, the results are called.
* The number in square brackets is the key in a 'global' variable hashmap. (The hashmap isn't actually global in my implementation but rather a member variable in the ScriptManager class)
* Next is a simplified form of the standard comparison operators ( ==, !=, <, > ).
* The last number can either be a constant or a key to another global variable.*   Results are what happens when one of the criteria is met. The first part defines a function, and the remaining parts are the arguments.
* I haven't fully figured out flags, but from what I can see it's a bitwise OR of when results can be called. For example, only once per room.

For those of you that understand code better than words:

```cpp
bool criteriaOne, criteriaTwo;

if (criteriaOne || criteriaTwo) {
    assign(5985, 0);
    timer(7336, 60);
    change_location('C', 'B', "C0", 1073);
    music(5252, 1, "a000h1tc.raw", 1);
}
```

#### Controls

* I haven't done much work on controls yet, but from what I have done, they look to be similar to results and are just called whenever interacted with. For example, a lever being toggled.

#### Implementation

The majority of the week was spent working on the best way to store this information so all the conditions could be readily tested and actions fired. The best way I've come up with so far, is to have a Criteria struct and a Results struct as follows:

```cpp
/** Criteria for a Puzzle result to be fired */
struct Criteria {
    /** The id of a global state */
    uint32 id;
    /**
    * What we're comparing the value of the global state against
    * This can either be a pure value or it can be the id of another global state
    */
    uint32 argument;
    /** How to do the comparison */
    CriteriaOperator criteriaOperator;
    /** Is 'argument' the id of a global state or a pure value */
    bool argumentIsAnId;
};

/** What happens when Puzzle criteria are met */
struct Result {
    ResultAction action;
    Common::List<Object> arguments;
};
```

CriteriaOperator is an enum of the operators and ResultAction is an enum of all the possible actions. The other variables are pretty self explanatory.

Using the Criteria and Result structs, the Puzzle struct is:

```cpp
struct Puzzle {
    uint32 id;
    Common::List<Criteria> criteriaList;
    Common::List<Result> resultList;
    byte flags;
};
```

Thus, the process is: read a script file, parse the puzzles into structs and load the structs into a linked list representing all the currently active puzzles. Elegant and exceedingly fast to iterate for criteria comparison checking. Now, some of you may have noticed the 'Object' class and are probably thinking to yourselves, "I thought this was c++, not c#, or \<insert terrible coffee-named language here\>" It is, but that is a whole post to itself, which I will be writing after this one.

So, a couple hundred words in, what have I said? Well, over this past week I discovered how the script system determines what events to fire. This has helped me not only to design the script system code, but also has given me insight into how to design the other systems in the engine. For example, I now know that mouse and keyboard events will just translate to setting global state variables.

#### What I have left to do in the ScriptManager

* Figure out what CriteriaFlags are used for
* Create shell methods for all the Result 'actions'
* Write the parser and storage for control and figure out how they are called

Well that's about it for this post, so until next time, happy coding! :)
