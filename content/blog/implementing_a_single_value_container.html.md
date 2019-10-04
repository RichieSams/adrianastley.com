+++
banner: ""
categories: ["ScummVM"]
date: 2013-06-26T22:19:00.005000-05:00
description: ""
images: []
tags: []
title: "Implementing a Generic Single Value Container in C++"
template: "blog.html.jinja"
+++

In my previous post I explained the format of the script system for ZEngine. Each Puzzle has a Results section which essentially stores function names and their arguments:

```text
results {
    action:assign(5985, 0)
    background:timer:7336(60)
    event:change_location(C,B,C0,1073)
    background:music:5252(1 a000h1tc.raw 1)
}
```

I wanted to be able to store each action inside a struct, and then have a linked list of all the structs. However, the problem is that both the number of arguments and the size of the arguments are variable. Marisa Chan's solution was to store all the arguments in a space delimited char array. IE:

```cpp
char arguments[25] = "1 a00h1tc.raw 1";
```

Simple, but not without it's problems.

1. The size is fixed, since the char array is in a struct. In order to make sure we never overflow, we have to allocate a fairly large array. That said, in this particular case, each 'large' array in this case would only be ~30 bytes per struct.
1. By storing everything as strings, we put off parsing till the action function is actually called. At first glace, this doesn't seem too bad, since the data will have to be parsed anyway. However, this method forces it to be parsed at every call to that action function.  

Another option was to have everything stored in a linked list of void pointers. However, I don't think I need to convince anyone that void pointers are just gross and using them would be just asking for problems.

What I really wanted was a typed way to store a variably typed (and sized) value. Therefore I created what I'm calling the "Object" class. (I'm up for suggestions for a better name)

The heart of the class is a union that stores a variety of pointers to different types and an enum that defines what type is being stored:

```cpp
class Object {
public:
    enum ObjectType : byte {
        BOOL,
        BYTE,
        INT16,
        UINT16,
        INT32,
        UINT32,
        FLOAT,
        DOUBLE,
        STRING,
    };

private:
    ObjectType _objectType;

    union {
        bool *boolVal;
        byte *byteVal;
        int16 *int16Val;
        uint16 *uint16Val;
        int32 *int32Val;
        uint32 *uint32Val;
        float *floatVal;
        double *doubleVal;
        Common::String *stringVal;
    } _value;
}
```

`_objectType` keeps track of what type of data the object is storing and `_value` points to the actual data. If `_value` were instead to hold the actual data value, the union would be forced to `sizeof(Common::String)`, which is quite large (~34 bytes), due to internal caching. Then we're back to the argument of storing things in containers much larger than what they need. By putting the data on the heap and only storing pointers to the data, we save the wasted space, but at the CPU cost of heap allocation.

Now that the data is stored, how do we get it back? My original idea was to have implicit cast operators:

```cpp
operator bool();
operator byte();
operator int16();
      .
      .
      .
```

However, LordHoto, one of the GSoC mentors and ScummVM developers, brought my attention to the problems that can arise when using implicit casting. For example, a user could try to cast the data to a type that wasn't stored in the Object and the cast would work, but the data would be completely corrupted. Also, from a user point of view, it wasn't intuitive.

Therefore, I removed the cast operators and created accessor methods:

```cpp
bool getBoolValue(bool *returnValue) const;
bool getByteValue(byte *returnValue) const;
bool getInt16Value(int16 *returnValue) const;
           .
           .
           .
```

```cpp
bool Object::getBoolValue(bool *returnValue) const {
    if (_objectType !=  BOOL) {
        warning("'Object' not of type bool.");
        return false;
    }

    *returnValue = *_value.boolVal;
    return true;
}
```

This adds a layer of type semi-protection to the class.

Lastly, I added assigment operators to the class, but rather than making this post even longer, I'll just link the full source [here](https://gist.github.com/RichieSams/5873413) and [here](https://gist.github.com/RichieSams/5873397).

##### Advantages of 'Object' class

* Can store relatively 'any' type of data. (Any type not currently supported could be trivially added)
* Only uses as much space as needed.
* Transforms dynamically typed data into a statically typed 'box' that can be stored in arrays, linked lists, hashmaps, etc. and can be iterated upon

##### Disadvantages of 'Object' class

* Adds a small memory overhead per object. ( 1 byte + sizeof(Operating System pointer) )
* Adds one heap memory allocation per object

So is it better than Marisa Chan's implementation? It really depends on what you define as better. While it does save memory, only requires data to be parsed once, and, in my opinion, adds a great deal of elegance to handling the Results arguments, it does so at the cost of heap storage. Not only the cost of the initial allocation, but the cost of potential defragmentation runs. But then again, is the cost of heap storage really that big, especially since the data should have a relatively long life? (On average, the time an end user spends in a room in the game) That I don't know, since it all depends on the memory allocator implementation.

In the end, I believe both methods perform well, and as such I choose the eloquence of using the 'Object' class. I am very much open to your thoughts on both the class as a whole or on your take of the problem. Also, if I misspoke about something please, please, please let me know.

Thanks for reading and happy coding! :)

##### *Edit

Upon further inspection I noticed that by using Common::String I'm not only negating any memory size benefits from using 'Object', but potentially even using more memory, since Common::String has such a huge size.

```cpp
Marisa Chan:
char arguments[25] = "1 a00h1tc.raw 1";
size = 25;

Object:
Object arg1 = 1;
Object arg2 = "a00h1tc.raw";
Object arg3 = 1;

size = (3 *sizeof(Object)) + sizeof(byte) + sizeof(Common::String) + sizeof(byte);
size = 15 + 1 + 34 + 1;
size = 51;
```
