+++
banner = ""
categories = ["ScummVM"]
date = "2013-06-26T07:42:00-05:00"
description = ""
images = []
tags = []
title = "Scripting!!!!!!"

+++

I just realized that I forgot to do a post last week! I was being so productive, time just flew by.

<br />

Last week and the beginning of this week I've been working on the script management system for ZEngine. Well, before I get into that, let me go back a little further. According to my original timeline, the next milestone was creating a skeleton engine that could do basic rendering, sounds, and events. So, last Monday, I started by cleaning up the main game loop and splitting everything into separate methods and classes. With that, the run loop looks like this:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:#216f85;">Common</span>::<span style="color:#216f85;">Error</span>&nbsp;<span style="color:#216f85;">ZEngine</span>::<span style="color:#850000;">run</span>()&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">initialize</span>();
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Main&nbsp;loop</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;currentTime&nbsp;=&nbsp;_system-&gt;<span style="color:#850000;">getMillis</span>();
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;lastTime&nbsp;=&nbsp;currentTime;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">const</span>&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;desiredFrameTime&nbsp;=&nbsp;33;&nbsp;<span style="color:green;">//&nbsp;~30&nbsp;fps</span>
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">while</span>&nbsp;(!<span style="color:#850000;">shouldQuit</span>())&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">processEvents</span>();
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;currentTime&nbsp;=&nbsp;_system-&gt;<span style="color:#850000;">getMillis</span>();
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;deltaTime&nbsp;=&nbsp;currentTime&nbsp;-&nbsp;lastTime;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;lastTime&nbsp;=&nbsp;currentTime;
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">updateScripts</span>();
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">updateAnimations</span>(deltaTime);
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(_needsScreenUpdate)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_system-&gt;<span style="color:#850000;">updateScreen</span>();
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Calculate&nbsp;the&nbsp;frame&nbsp;delay&nbsp;based&nbsp;off&nbsp;a&nbsp;desired&nbsp;frame&nbsp;rate</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">int</span>&nbsp;delay&nbsp;=&nbsp;desiredFrameTime&nbsp;-&nbsp;(currentTime&nbsp;-&nbsp;_system-&gt;<span style="color:#850000;">getMillis</span>());
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Ensure&nbsp;non-negative</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;delay&nbsp;=&nbsp;delay&nbsp;&lt;&nbsp;0&nbsp;?&nbsp;0&nbsp;:&nbsp;delay;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_system-&gt;<span style="color:#850000;">delayMillis</span>(delay);
&nbsp;&nbsp;&nbsp;&nbsp;}
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">kNoError</span>;
}</pre>

No bad, if I do say so myself. :)

<br />

That done, I started implementing the various method shells, such as processEvents(). It was about that time that I realized the the structure of the scripting system had a huge impact on the structure of the engine as a whole. For example, should the event system call methods directly, or should it just register key presses, etc. and let the script system handle the calls? I had a basic understanding of how it _probably_ worked, knowing the history of adventure games, but it was clear I needed to understand the script system before I could go any further.

<br />

The .scr files themselves are rather simple; they're text-based if-then statements. Here's an example of a puzzle and a control:
<pre style="font-family:Consolas;font-size:13;color:black;">
puzzle:5251 {
    criteria { 
        [4188] = 1
        [4209] ! 5
        [7347] = 1
        [67] = 0
    }
    criteria { 
        [4209] > 1
        [7347] = 1
        [67] = 1
        [4188] = [6584]
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
</pre>

<br />

### Puzzles
 * Criteria are a set of comparisons. If ANY of the criteria are satisfied, the results are called.
 * The number in square brackets is the key in a 'global' variable hashmap. (The hashmap isn't actually global in my implementation but rather a member variable in the ScriptManager class)
 * Next is a simplified form of the standard comparison operators ( ==, !=, <, > ).
 * The last number can either be a constant or a key to another global variable.*   Results are what happens when one of the criteria is met. The first part defines a function, and the remaining parts are the arguments.
 * I haven't fully figured out flags, but from what I can see it's a bitwise OR of when results can be called. For example, only once per room.

<br />

For those of you that understand code better than words:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">bool</span>&nbsp;criteriaOne,&nbsp;criteriaTwo;
 
<span style="color:blue;">if</span>&nbsp;(criteriaOne&nbsp;||&nbsp;criteriaTwo)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">assign</span>(5985,&nbsp;0);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">timer</span>(7336,&nbsp;60);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">change_location</span>(<span style="color:#a31515;">&#39;C&#39;</span>,&nbsp;<span style="color:#a31515;">&#39;B&#39;</span>,&nbsp;<span style="color:#a31515;">&quot;C0&quot;</span>,&nbsp;1073);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">music</span>(5252,&nbsp;1,&nbsp;<span style="color:#a31515;">&quot;a000h1tc.raw&quot;</span>,&nbsp;1);
}</pre>

### Controls
 * I haven't done much work on controls yet, but from what I have done, they look to be similar to results and are just called whenever interacted with. For example, a lever being toggled.

### Implementation

The majority of the week was spent working on the best way to store this information so all the conditions could be readily tested and actions fired. The best way I've come up with so far, is to have a Criteria struct and a Results struct as follows:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:green;">/**&nbsp;Criteria&nbsp;for&nbsp;a&nbsp;Puzzle&nbsp;result&nbsp;to&nbsp;be&nbsp;fired&nbsp;*/</span>
<span style="color:blue;">struct</span>&nbsp;<span style="color:#216f85;">Criteria</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">/**&nbsp;The&nbsp;id&nbsp;of&nbsp;a&nbsp;global&nbsp;state&nbsp;*/</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;id;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">/**</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;*&nbsp;What&nbsp;we&#39;re&nbsp;comparing&nbsp;the&nbsp;value&nbsp;of&nbsp;the&nbsp;global&nbsp;state&nbsp;against</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;*&nbsp;This&nbsp;can&nbsp;either&nbsp;be&nbsp;a&nbsp;pure&nbsp;value&nbsp;or&nbsp;it&nbsp;can&nbsp;be&nbsp;the&nbsp;id&nbsp;of&nbsp;another&nbsp;global&nbsp;state</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;*/</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;argument;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">/**&nbsp;How&nbsp;to&nbsp;do&nbsp;the&nbsp;comparison&nbsp;*/</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">CriteriaOperator</span>&nbsp;criteriaOperator;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">/**&nbsp;Is&nbsp;&#39;argument&#39;&nbsp;the&nbsp;id&nbsp;of&nbsp;a&nbsp;global&nbsp;state&nbsp;or&nbsp;a&nbsp;pure&nbsp;value&nbsp;*/</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;argumentIsAnId;
};
 
<span style="color:green;">/**&nbsp;What&nbsp;happens&nbsp;when&nbsp;Puzzle&nbsp;criteria&nbsp;are&nbsp;met&nbsp;*/</span>
<span style="color:blue;">struct</span>&nbsp;<span style="color:#216f85;">Result</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">ResultAction</span>&nbsp;action;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">Object</span>&gt;&nbsp;arguments;
};</pre>

CriteriaOperator is an enum of the operators and ResultAction is an enum of all the possible actions. The other variables are pretty self explanatory.

<br />

Using the Criteria and Result structs, the Puzzle struct is:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">struct</span>&nbsp;<span style="color:#216f85;">Puzzle</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;id;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">Criteria</span>&gt;&nbsp;criteriaList;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">Result</span>&gt;&nbsp;resultList;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">byte</span>&nbsp;flags;
};</pre>

<br />

Thus, the process is: read a script file, parse the puzzles into structs and load the structs into a linked list representing all the currently active puzzles. Elegant and exceedingly fast to iterate for criteria comparison checking. Now, some of you may have noticed the 'Object' class and are probably thinking to yourselves, "I thought this was c++, not c# or &lt;insert terrible coffee-named language here&gt;." It is, but that is a whole post to itself, which I will be writing after this one.

<br />

So, a couple hundred words in, what have I said? Well, over this past week I discovered how the script system determines what events to fire. This has helped me not only to design the script system code, but also has given me insight into how to design the other systems in the engine. For example, I now know that mouse and keyboard events will just translate to setting global state variables.

### What I have left to do in the ScriptManager
*   Figure out what CriteriaFlags are used for
*   Create shell methods for all the Result 'actions'
*   Write the parser and storage for control and figure out how they are called


Well that's about it for this post, so until next time,

<br/>

Happy coding!&nbsp;&nbsp;&nbsp;:)
