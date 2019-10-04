+++
banner: ""
categories: ["ScummVM"]
date: 2013-07-11T01:27:00.005000-05:00
description: ""
images: []
tags: []
title: "The Engine Skeleton Gains Some Tendons - Part 1"
template: "blog.html.jinja"
+++

Being a little tired of the script system, I started last week by adding image handling, video handling and a text debug console to the engine. With that done, I tried piecing together how the script system worked as a whole. After a long talk with Fuzzie, we figured out the majority of the system worked and I've spent the beginning of this week putting it into code.

I'll start with the script system since it's fresh in my mind. Rather than try to explain what I learned, I'll just explain my current understanding of the system and it's behavior.

The system is governed by five main containers:

```cpp
Common::HashMap<uint32, byte> _globalState;
Common::List<ActionNode *> _activeNodes;
Common::HashMap<uint32, Common::Array<Puzzle *>> _referenceTable;
Common::Stack<Puzzle *> _puzzlesToCheck;
Common::List<Puzzle> _activePuzzles;
Common::List<Control> _activeControls;
```

`_globalState` holds the state of the entire game. Each key is a hash that can represent anything from a timer to whether a certain puzzle has been solved. The value depends on the what the key is, however, the vast majority are boolean states (0 or 1).

`_activeNodes` holds... wait for it... the active ActionNodes. Imagine that! Nodes are anything that needs to be processed over time. For example, a timer, an animation, etc. I'll explain further later in the post.

`_referenceTable` stores references to the Puzzles that certain globalState keys have. This can be thought of as a reverse of the Puzzle struct. A Puzzle stores a list of globalState keys to be checked. `_referenceTable` stores which Puzzles reference certain globalState keys. Why would we want to do this? It means that any puzzles loaded into the `_reference_ table` only have to be checked once, instead of every frame. When a value in `_globalState` is changed, it adds the referenced Puzzle to `_puzzlesToCheck`

`_puzzlesToCheck` holds the Puzzles whose Criteria we want to check against `_globalState`. This stack is exhausted every frame. It is filled either by `_referenceTable` or when we enter a new room.

`_activePuzzles` is where the room's Puzzles are stored. The Puzzle pointers in `_referenceTable` and `_puzzlesToCheck` point to here.

I realize that the descriptions are still a bit vague, so I figured I would go through an example of sorts and how the containers behave.

#### Every time we change rooms

1. Clear `_referenceTable`, `_puzzlesToCheck`, and `_activePuzzles`
1. Open and parse the corresponding .scr file into Puzzle structs and store them in `_activePuzzles`. (See last three blog posts)
1. Iterate through all the Puzzles and their Criteria and create references from a `_globalState` key to the Puzzle. (See createReferenceTable below)
1. Add all Puzzles to `_puzzlesToCheck`

```cpp
void ScriptManager::createReferenceTable() {
    // Iterate through each Puzzle
    for (Common::List<Puzzle>::iterator activePuzzleIter = _activePuzzles.begin(); activePuzzleIter != _activePuzzles.end(); activePuzzleIter++) {
        Puzzle *puzzlePtr = &(*activePuzzleIter);

        // Iterate through each Criteria and add a reference from the criteria key to the Puzzle
        for (Common::List<Criteria>::iterator criteriaIter = activePuzzleIter->criteriaList.begin(); criteriaIter != (*activePuzzleIter).criteriaList.end(); criteriaIter++) {
            _referenceTable[criteriaIter->key].push_back(puzzlePtr);

            // If the argument is a key, add a reference to it as well
            if (criteriaIter->argument)
                _referenceTable[criteriaIter->argument].push_back(puzzlePtr);
        }
    }

    // Remove duplicate entries
    for (Common::HashMap<uint32, Common::Array<Puzzle *>>::iterator referenceTableIter; referenceTableIter != _referenceTable.end(); referenceTableIter++) {
        removeDuplicateEntries(&(referenceTableIter->_value));
    }
}
```

#### Every frame

1. Iterate through each ActionNode in `_activeNodes` and call `process()` on them
1. If `process()` returns true, remove and delete the ActionNode
1. While `_puzzlesToCheck` is not empty, pop a Puzzle off the stack and check its Criteria against `_globalState`
1. If any of the Criteria pass, call `execute()` on the corresponding ResultAction.
    * Some ResultAction's might create ActionNode's and add them to `_activeNodes`. IE ActionTimer

```cpp
void ScriptManager::updateNodes(uint32 deltaTimeMillis) {
    // If process() returns true, it means the node can be deleted
    for (Common::List<ActionNode *>::iterator iter = _activeNodes.begin(); iter != _activeNodes.end();) {
        if ((*iter)->process(_engine, deltaTimeMillis)) {
            // Remove the node from _activeNodes, then delete it
            ActionNode *node = *iter;
            iter = _activeNodes.erase(iter);
            delete node;
        } else {
            iter++;
        }
    }
}

bool NodeTimer::process(ZEngine *engine, uint32 deltaTimeInMillis) {
    _timeLeft -= deltaTimeInMillis;

    if (_timeLeft <= 0) {
        engine->getScriptManager()->setStateValue(_key, 0);
        return true;
    }

    return false;
}

void ScriptManager::checkPuzzleCriteria() {
    while (!_puzzlesToCheck.empty()) {
        Puzzle *puzzle = _puzzlesToCheck.pop();
        // Check each Criteria
        for (Common::List<Criteria>::iterator iter = puzzle->criteriaList.begin(); iter != puzzle->criteriaList.end(); iter++) {
            bool criteriaMet = false;

            // Get the value to compare against
            byte argumentValue;
            if ((*iter).argument)
                argumentValue = getStateValue(iter->argument);
            else
                argumentValue = iter->argument;

            // Do the comparison
            switch ((*iter).criteriaOperator) {
            case EQUAL_TO:
                criteriaMet = getStateValue(iter->key) == argumentValue;
                break;
            case NOT_EQUAL_TO:
                criteriaMet = getStateValue(iter->key) != argumentValue;
                break;
            case GREATER_THAN:
                criteriaMet = getStateValue(iter->key) > argumentValue;
                break;
            case LESS_THAN:
                criteriaMet = getStateValue(iter->key) < argumentValue;
                break;
            }

            // TODO: Add logic for the different Flags (aka, ONCE_PER_INST)
            if (criteriaMet) {
                for (Common::List<ResultAction *>::iterator resultIter = puzzle->resultActions.begin(); resultIter != puzzle->resultActions.end(); resultIter++) {
                    (*resultIter)->execute(_engine);
                }
            }
        }
    }
}

bool ActionTimer::execute(ZEngine *zEngine) {
    zEngine->getScriptManager()->addActionNode(new NodeTimer(_key, _time));
    return true;
}
```

So that's the script system. I've tried to explain it in the best way possible, but if you guys have any questions or suggestions for my implementation, as always, feel free to comment.

Details on the image handling, video handling and the text debug console will be in Part 2, which should be up some time tomorrow. As always, thanks for reading.

Happy coding! :)
