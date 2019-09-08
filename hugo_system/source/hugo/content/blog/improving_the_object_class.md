+++
banner = ""
categories = ["ScummVM"]
date = "2013-07-01T05:03:00-05:00"
description = ""
images = []
tags = []
title = "Improving the 'Object' Class and Using Classes for ResultActions"

+++

Last week, I posted about using an 'Object' class to encapsulate the variable-typed arguments for ResultActions. You guys posted some awesome feedback[<sup>\[1\]</sup>](#reference1) and I used it to improve the class. First, I renamed the class to 'SingleValueContainer' so users have a better sense of what it is. Second, following {{< fancybox img="fuzzie_response.png" >}}Fuzzie's advice{{< /fancybox >}}, I put all the values except for String, directly in the union. It's the same or less memory cost and results in less heap allocations.

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">union</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;boolVal;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">byte</span>&nbsp;byteVal;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">int16</span>&nbsp;int16Val;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint16</span>&nbsp;uint16Val;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">int32</span>&nbsp;int32Val;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;uint32Val;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">float</span>&nbsp;floatVal;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">double</span>&nbsp;doubleVal;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">char</span>&nbsp;*stringVal;
}&nbsp;_value;</pre>

<br />

You'll notice that the stringVal isn't actually a Common::String object, but rather a pointer to a char array. This saves a bit of memory at the cost of a couple strlen(), memcpy(), and String object assigment.

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:#216f85;">SingleValueContainer</span>::<span style="color:#850000;">SingleValueContainer</span>(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;value)&nbsp;:&nbsp;_objectType(<span style="color:#216f85;">BYTE</span>)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;_value.stringVal&nbsp;=&nbsp;<span style="color:blue;">new</span>&nbsp;<span style="color:blue;">char</span>[value.<span style="color:#850000;">size</span>()&nbsp;+&nbsp;1];
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">memcpy</span>(_value.stringVal,&nbsp;value.<span style="color:#850000;">c_str</span>(),&nbsp;value.<span style="color:#850000;">size</span>()&nbsp;+&nbsp;1);
}
<span style="color:#216f85;">SingleValueContainer</span>&nbsp;&amp;<span style="color:#216f85;">SingleValueContainer</span>::<span style="color:teal;">operator</span><span style="color:teal;">=</span>(<span style="color:blue;">const</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;&amp;rhs)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(_objectType&nbsp;!=&nbsp;<span style="color:#216f85;">STRING</span>)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_objectType&nbsp;=&nbsp;<span style="color:#216f85;">STRING</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_value.stringVal&nbsp;=&nbsp;<span style="color:blue;">new</span>&nbsp;<span style="color:blue;">char</span>[rhs.<span style="color:#850000;">size</span>()&nbsp;+&nbsp;1];
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">memcpy</span>(_value.stringVal,&nbsp;rhs.<span style="color:#850000;">c_str</span>(),&nbsp;rhs.<span style="color:#850000;">size</span>()&nbsp;+&nbsp;1);
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;*<span style="color:blue;">this</span>;
&nbsp;&nbsp;&nbsp;&nbsp;}
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;length&nbsp;=&nbsp;<span style="color:#850000;">strlen</span>(_value.stringVal);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(length&nbsp;&lt;=&nbsp;rhs.<span style="color:#850000;">size</span>()&nbsp;+&nbsp;1)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">memcpy</span>(_value.stringVal,&nbsp;rhs.<span style="color:#850000;">c_str</span>(),&nbsp;rhs.<span style="color:#850000;">size</span>()&nbsp;+&nbsp;1);
&nbsp;&nbsp;&nbsp;&nbsp;}&nbsp;<span style="color:blue;">else</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">delete</span><span style="color:blue;">[]</span>&nbsp;_value.stringVal;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_value.stringVal&nbsp;=&nbsp;<span style="color:blue;">new</span>&nbsp;<span style="color:blue;">char</span>[rhs.<span style="color:#850000;">size</span>()&nbsp;+&nbsp;1];
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">memcpy</span>(_value.stringVal,&nbsp;rhs.<span style="color:#850000;">c_str</span>(),&nbsp;rhs.<span style="color:#850000;">size</span>()&nbsp;+&nbsp;1);
&nbsp;&nbsp;&nbsp;&nbsp;}
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;*<span style="color:blue;">this</span>;
}
<span style="color:blue;">bool</span>&nbsp;<span style="color:#216f85;">SingleValueContainer</span>::<span style="color:#850000;">getStringValue</span>(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;*returnValue)&nbsp;<span style="color:blue;">const</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(_objectType&nbsp;!=&nbsp;&nbsp;<span style="color:#216f85;">STRING</span>)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">warning</span>(<span style="color:#a31515;">&quot;&#39;Object&#39;&nbsp;is&nbsp;not&nbsp;storing&nbsp;a&nbsp;Common::String.&quot;</span>);
 
&nbsp;&nbsp;&nbsp;&nbsp;*returnValue&nbsp;<span style="color:teal;">=</span>&nbsp;_value.stringVal;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;<span style="color:blue;">true</span>;
}</pre>

<br />

  
With those changes the class seems quite solid. (The full source can be found [here](https://github.com/RichieSams/scummvm/blob/20f8e05cc3d1661ed5d5af9c9e1420cce36b6893/engines/zvision/utility/single_value_container.h) and [here](https://github.com/RichieSams/scummvm/blob/20f8e05cc3d1661ed5d5af9c9e1420cce36b6893/engines/zvision/utility/single_value_container.cpp)). However, after seeing {{< fancybox img="zidane_sama_response.png" >}}Zidane Sama's comment{{< /fancybox >}}, I realized that there was a better way to tackle the problem than variant objects. Instead of trying to generalize the action types and arguments and storing them in structs, a better approach is to create a class for each action type with a common, "execute()" method that will be called by the scriptManager when the Criteria are met for an ResultAction.

<br />

I first created an interface base class that all the different types would inherit from:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">class</span>&nbsp;<span style="color:#216f85;">ResultAction</span>&nbsp;{
<span style="color:blue;">public</span>:
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">virtual</span>&nbsp;<span style="color:#850000;">~</span><span style="color:#850000;">ResultAction</span>()&nbsp;{}
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">virtual</span>&nbsp;<span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">execute</span>(<span style="color:#216f85;">ZEngine</span>&nbsp;*zEngine)&nbsp;=&nbsp;0;
};</pre>

<br />

Next, I created the individual classes for each type of ResultAction:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">class</span>&nbsp;<span style="color:#216f85;">ActionAdd</span>&nbsp;:&nbsp;<span style="color:blue;">public</span>&nbsp;<span style="color:#216f85;">ResultAction</span>&nbsp;{
<span style="color:blue;">public</span>:
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">ActionAdd</span>(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;line);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">execute</span>(<span style="color:#216f85;">ZEngine</span>&nbsp;*zEngine);
 
<span style="color:blue;">private</span>:
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;_key;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">byte</span>&nbsp;_value;
};</pre>

<br />

The individual classes parse out any arguments in their constructor and store them in member variables. In execute(), they execute the logic pertaining to their action. A pointer to ZEngine is passed in order to give the method access to all the necessary tools (modifying graphics, scriptManager states, sounds, etc.)

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:#216f85;">ActionAdd</span>::<span style="color:#850000;">ActionAdd</span>(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;line)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">sscanf</span>(line.<span style="color:#850000;">c_str</span>(),&nbsp;<span style="color:#a31515;">&quot;:add(%u,%hhu)&quot;</span>,&nbsp;&amp;_key,&nbsp;&amp;_value);
}
 
<span style="color:blue;">bool</span>&nbsp;<span style="color:#216f85;">ActionAdd</span>::<span style="color:#850000;">execute</span>(<span style="color:#216f85;">ZEngine</span>&nbsp;*zEngine)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;zEngine-&gt;<span style="color:#850000;">getScriptManager</span>()-&gt;<span style="color:#850000;">addToStateValue</span>(_key,&nbsp;_value);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;<span style="color:blue;">true</span>;
}</pre>

<br />

Thus, in the script file parser I can just look for the action type and then pass create an action type, passing the constructor the whole line:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">while</span>&nbsp;(!line.<span style="color:#850000;">contains</span>(<span style="color:#a31515;">&#39;}&#39;</span>))&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Parse&nbsp;for&nbsp;the&nbsp;action&nbsp;type</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(line.<span style="color:#850000;">matchString</span>(<span style="color:#a31515;">&quot;*:add*&quot;</span>,&nbsp;<span style="color:blue;">true</span>))&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;actionList.<span style="color:#850000;">push_back</span>(<span style="color:#216f85;">ActionAdd</span>(line));
&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">else</span>&nbsp;<span style="color:blue;">if</span>&nbsp;(line.<span style="color:#850000;">matchString</span>(<span style="color:#a31515;">&quot;*:animplay*&quot;</span>,&nbsp;<span style="color:blue;">true</span>))&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;actionList.<span style="color:#850000;">push_back</span>(<span style="color:#216f85;">ActionAnimPlay</span>(line));
&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">else</span>&nbsp;<span style="color:blue;">if</span>&nbsp;(.....)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
}</pre>

<br />

While this means I have to create 20+ classes for all the different types of actions, I think this method nicely encapsulates and abstracts both the parsing and the action of the result. I'm a bit sad that I'm not going to be using the 'SingleValueContainer' class, but if nothing else, I learned quite a bit while creating it. Plus, I won't be getting rid of it, so it might have a use somewhere else.

<br />

This coming week I need to finish creating all the classes and then try to finish the rest of the engine skeleton. As always, feel free to comment / ask questions.

<br />

Happy coding!&nbsp;&nbsp;&nbsp;:)

<br /><br />

**\[1\]**: <a name="reference1"></a>My original blog was on Blogger. I have since migrated all the content here, except the comments. You'll just have to take my word for it that the comments were useful. :P