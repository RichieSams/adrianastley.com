+++
banner: ""
categories: ["ScummVM"]
date: 2013-07-01T17:03:00.003000-05:00
description: ""
images: []
tags: []
title: "Improving the 'Object' Class and Using Classes for ResultActions"
template: "blog.html.jinja"
+++

Last week, I posted about using an 'Object' class to encapsulate the variable-typed arguments for ResultActions. You guys posted some awesome feedback[^1] and I used it to improve the class. First, I renamed the class to 'SingleValueContainer' so users have a better sense of what it is. Second, following {{ fancybox_link("/static/images/fuzzie_response.png", "Fuzzie's advice") }}, I put all the values except for String, directly in the union. It's the same or less memory cost and results in less heap allocations.

```cpp
union {
    bool boolVal;
    byte byteVal;
    int16 int16Val;
    uint16 uint16Val;
    int32 int32Val;
    uint32 uint32Val;
    float floatVal;
    double doubleVal;
    char *stringVal;
} _value;
```

You'll notice that the stringVal isn't actually a Common::String object, but rather a pointer to a char array. This saves a bit of memory at the cost of a couple strlen(), memcpy(), and String object assigment.

```cpp
SingleValueContainer::SingleValueContainer(Common::String value) : _objectType(BYTE) {
    _value.stringVal = new char[value.size() + 1];
    memcpy(_value.stringVal, value.c_str(), value.size() + 1);
}

SingleValueContainer &SingleValueContainer::operator=(const Common::String &rhs) {
    if (_objectType != STRING) {
        _objectType = STRING;
        _value.stringVal = new char[rhs.size() + 1];
        memcpy(_value.stringVal, rhs.c_str(), rhs.size() + 1);

        return *this;
    }

    uint32 length = strlen(_value.stringVal);
    if (length <= rhs.size() + 1) {
        memcpy(_value.stringVal, rhs.c_str(), rhs.size() + 1);
    } else {
        delete[] _value.stringVal;
        _value.stringVal = new char[rhs.size() + 1];
        memcpy(_value.stringVal, rhs.c_str(), rhs.size() + 1);
    }

    return *this;
}

bool SingleValueContainer::getStringValue(Common::String *returnValue) const {
    if (_objectType !=  STRING)
        warning("'Object' is not storing a Common::String.");

    *returnValue = _value.stringVal;
    return true;
}
```

With those changes the class seems quite solid. (The full source can be found [here](https://github.com/RichieSams/scummvm/blob/20f8e05cc3d1661ed5d5af9c9e1420cce36b6893/engines/zvision/utility/single_value_container.h) and [here](https://github.com/RichieSams/scummvm/blob/20f8e05cc3d1661ed5d5af9c9e1420cce36b6893/engines/zvision/utility/single_value_container.cpp)). However, after seeing {{ fancybox_link("/static/images/zidane_sama_response.png", "Zidane Sama's comment") }}, I realized that there was a better way to tackle the problem than variant objects. Instead of trying to generalize the action types and arguments and storing them in structs, a better approach is to create a class for each action type with a common, "execute()" method that will be called by the scriptManager when the Criteria are met for an ResultAction.

I first created an interface base class that all the different types would inherit from:

```cpp
class ResultAction {
public:
    virtual ~ResultAction() {}
    virtual bool execute(ZEngine *zEngine) = 0;
};
```

Next, I created the individual classes for each type of ResultAction:

```cpp
class ActionAdd : public ResultAction {
public:
    ActionAdd(Common::String line);
    bool execute(ZEngine *zEngine);

private:
    uint32 _key;
    byte _value;
};
```

The individual classes parse out any arguments in their constructor and store them in member variables. In execute(), they execute the logic pertaining to their action. A pointer to ZEngine is passed in order to give the method access to all the necessary tools (modifying graphics, scriptManager states, sounds, etc.)

```cpp
class ResultAction {
ActionAdd::ActionAdd(Common::String line) {
    sscanf(line.c_str(), ":add(%u,%hhu)", &_key, &_value);
}

bool ActionAdd::execute(ZEngine *zEngine) {
    zEngine->getScriptManager()->addToStateValue(_key, _value);
    return true;
}
```

Thus, in the script file parser I can just look for the action type and then pass create an action type, passing the constructor the whole line:

```cpp
while (!line.contains('}')) {
    // Parse for the action type
    if (line.matchString("*:add*", true)) {
        actionList.push_back(ActionAdd(line));
    } else if (line.matchString("*:animplay*", true)) {
        actionList.push_back(ActionAnimPlay(line));
    } else if (.....)
         .
         .
         .
}
```

While this means I have to create 20+ classes for all the different types of actions, I think this method nicely encapsulates and abstracts both the parsing and the action of the result. I'm a bit sad that I'm not going to be using the 'SingleValueContainer' class, but if nothing else, I learned quite a bit while creating it. Plus, I won't be getting rid of it, so it might have a use somewhere else.

This coming week I need to finish creating all the classes and then try to finish the rest of the engine skeleton. As always, feel free to comment / ask questions.

Happy coding! :)

[^1]: My original blog was on Blogger. I have since migrated all the content here, except the comments. You'll just have to take my word for it that the comments were useful. :P
