+++
banner = ""
categories = ["ScummVM"]
date = "2013-06-26T10:19:00-05:00"
description = ""
images = []
tags = []
title = "Implementing a Generic Single Value Container in C++"

+++

In my previous post I explained the format of the script system for ZEngine. Each Puzzle has a Results section which essentially stores function names and their arguments:

<pre style="font-family:Consolas;font-size:13;color:black;">
results {
    action:assign(5985, 0)
    background:timer:7336(60)
    event:change_location(C,B,C0,1073)
    background:music:5252(1 a000h1tc.raw 1)    
}
</pre>

I wanted to be able to store each action inside a struct, and then have a linked list of all the structs. However, the problem is that both the number of arguments and the size of the arguments are variable. Marisa Chan's solution was to store all the arguments in a space delimited char array. IE:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">char</span>&nbsp;arguments[25]&nbsp;=&nbsp;<span style="color:#a31515;">&quot;1&nbsp;a00h1tc.raw&nbsp;1&quot;</span>;
</pre>

<br />

Simple, but not without it's problems.

1.  The size is fixed, since the char array is in a struct. In order to make sure we never overflow, we have to allocate a fairly large array. That said, in this particular case, each 'large' array in this case would only be ~30 bytes per struct.
2.  By storing everything as strings, we put off parsing till the action function is actually called. At first glace, this doesn't seem too bad, since the data will have to be parsed anyway. However, this method forces it to be parsed at every call to that action function.

<br />

Another option was to have everything stored in a linked list of void pointers. However, I don't think I need to convince anyone that void pointers are just gross and using them would be just asking for problems.

<br />

What I really wanted was a typed way to store a variably typed (and sized) value. Therefore I created what I'm calling the "Object" class. (I'm up for suggestions for a better name)

<br />

The heart of the class is a union that stores a variety of pointers to different types and an enum that defines what type is being stored:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">class</span>&nbsp;<span style="color:#216f85;">Object</span>&nbsp;{
<span style="color:blue;">public</span>:
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">enum</span>&nbsp;<span style="color:#216f85;">ObjectType</span>&nbsp;:&nbsp;<span style="color:#216f85;">byte</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">BOOL</span>,
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">BYTE</span>,
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">INT16</span>,
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">UINT16</span>,
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">INT32</span>,
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">UINT32</span>,
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">FLOAT</span>,
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">DOUBLE</span>,
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">STRING</span>,
&nbsp;&nbsp;&nbsp;&nbsp;};
 
<span style="color:blue;">private</span>:
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">ObjectType</span>&nbsp;_objectType;
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">union</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;*boolVal;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">byte</span>&nbsp;*byteVal;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">int16</span>&nbsp;*int16Val;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint16</span>&nbsp;*uint16Val;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">int32</span>&nbsp;*int32Val;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;*uint32Val;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">float</span>&nbsp;*floatVal;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">double</span>&nbsp;*doubleVal;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;*stringVal;
&nbsp;&nbsp;&nbsp;&nbsp;}&nbsp;_value;
};</pre>

<br />

__objectType_ keeps track of what type of data the object is storing and __value_ points to the actual data. If __value_ were instead to hold the actual data value, the union would be forced to sizeof(Common::String), which is quite large (~34 bytes), due to internal caching. Then we're back to the argument of storing things in containers much larger than what they need. By putting the data on the heap and only storing pointers to the data, we save the wasted space, but at the CPU cost of heap allocation.

Now that the data is stored, how do we get it back? My original idea was to have implicit cast operators:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">operator</span>&nbsp;<span style="color:blue;">bool</span>();
<span style="color:blue;">operator</span>&nbsp;<span style="color:#216f85;">byte</span>();
<span style="color:blue;">operator</span>&nbsp;<span style="color:#216f85;">int16</span>();
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.</pre>

However, LordHoto, one of the GSoC mentors and ScummVM developers, brought my attention to the problems that can arise when using implicit casting. For example, a user could try to cast the data to a type that wasn't stored in the Object and the cast would work, but the data would be completely corrupted. Also, from a user point of view, it wasn't intuitive.

<br />

Therefore, I removed the cast operators and created accessor methods:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">getBoolValue</span>(<span style="color:blue;">bool</span>&nbsp;*returnValue)&nbsp;<span style="color:blue;">const</span>;
<span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">getByteValue</span>(<span style="color:#216f85;">byte</span>&nbsp;*returnValue)&nbsp;<span style="color:blue;">const</span>;
<span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">getInt16Value</span>(<span style="color:#216f85;">int16</span>&nbsp;*returnValue)&nbsp;<span style="color:blue;">const</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
 
<span style="color:blue;">bool</span>&nbsp;Object::getBoolValue(<span style="color:blue;">bool</span>&nbsp;*returnValue)&nbsp;<span style="color:blue;">const</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(_objectType&nbsp;!=&nbsp;&nbsp;BOOL)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;warning(<span style="color:#a31515;">&quot;&#39;Object&#39;&nbsp;not&nbsp;of&nbsp;type&nbsp;bool.&quot;</span>);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;<span style="color:blue;">false</span>;
&nbsp;&nbsp;&nbsp;&nbsp;}
 
&nbsp;&nbsp;&nbsp;&nbsp;*returnValue&nbsp;=&nbsp;*_value.boolVal;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;<span style="color:blue;">true</span>;
}</pre>

<br />

This adds a layer of type semi-protection to the class.

<br />

Lastly, I added assigment operators to the class, but rather than making this post even longer, I'll just link the full source [here](https://gist.github.com/RichieSams/5873413) and [here](https://gist.github.com/RichieSams/5873397).

Advantages of 'Object' class

*   Can store relatively 'any' type of data. (Any type not currently supported could be trivially added)
*   Only uses as much space as needed.
*   Transforms dynamically typed data into a statically typed 'box' that can be stored in arrays, linked lists, hashmaps, etc. and can be iterated upon

Disadvantages of 'Object' class

*   Adds a small memory overhead per object. ( 1 byte + sizeof(Operating System pointer) )
*   Adds one heap memory allocation per object

<br />

So is it better than Marisa Chan's implementation? It really depends on what you define as better. While it does save memory, only requires data to be parsed once, and, in my opinion, adds a great deal of elegance to handling the Results arguments, it does so at the cost of heap storage. Not only the cost of the initial allocation, but the cost of potential defragmentation runs. But then again, is the cost of heap storage really that big, especially since the data should have a relatively long life? (On average, the time an end user spends in a room in the game) That I don't know, since it all depends on the memory allocator implementation.

<br />

In the end, I believe both methods perform well, and as such I choose the eloquence of using the 'Object' class. I am very much open to your thoughts on both the class as a whole or on your take of the problem. Also, if I misspoke about something please, please, please let me know.

<br />

Thanks for reading and happy coding!&nbsp;&nbsp;&nbsp;:)

<br /><br />

#### *Edit

Upon further inspection I noticed that by using Common::String I'm not only negating any memory size benefits from using 'Object', but potentially even using more memory, since Common::String has such a huge size.

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:green;">//&nbsp;Marisa&nbsp;Chan</span>
<span style="color:blue;">char</span>&nbsp;arguments[25]&nbsp;=&nbsp;<span style="color:#a31515;">&quot;1&nbsp;a00h1tc.raw&nbsp;1&quot;</span>;
<span style="color:green;">//&nbsp;size&nbsp;=&nbsp;25;</span>
 
<span style="color:green;">//&nbsp;Object:</span>
<span style="color:#216f85;">Object</span>&nbsp;arg1&nbsp;=&nbsp;1;
<span style="color:#216f85;">Object</span>&nbsp;arg2&nbsp;=&nbsp;<span style="color:#a31515;">&quot;a00h1tc.raw&quot;</span>;
<span style="color:#216f85;">Object</span>&nbsp;arg3&nbsp;=&nbsp;1;
 
<span style="color:green;">//&nbsp;size&nbsp;=&nbsp;(3&nbsp;*sizeof(Object))&nbsp;+&nbsp;sizeof(byte)&nbsp;+&nbsp;sizeof(Common::String)&nbsp;+&nbsp;sizeof(byte);</span>
<span style="color:green;">//&nbsp;size&nbsp;=&nbsp;15&nbsp;+&nbsp;1&nbsp;+&nbsp;34&nbsp;+&nbsp;1;</span>
<span style="color:green;">//&nbsp;size&nbsp;=&nbsp;51;</span></pre>








