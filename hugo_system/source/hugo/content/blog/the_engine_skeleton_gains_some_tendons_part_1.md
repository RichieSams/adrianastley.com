+++
banner = ""
categories = ["ScummVM"]
date = "2013-07-11T01:27:00-05:00"
description = ""
images = []
tags = []
title = "The Engine Skeleton Gains Some Tendons - Part 1"

+++

Being a little tired of the script system, I started last week by adding image handling, video handling and a text debug console to the engine. With that done, I tried piecing together how the script system worked as a whole. After a long talk with Fuzzie, we figured out the majority of the system worked and I've spent the beginning of this week putting it into code.

<br />

I'll start with the script system since it's fresh in my mind. Rather than try to explain what I learned, I'll just explain my current understanding of the system and it's behavior.

<br />

The system is governed by five main containers:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:#216f85;">Common</span>::<span style="color:#216f85;">HashMap</span>&lt;<span style="color:#216f85;">uint32</span>,&nbsp;<span style="color:#216f85;">byte</span>&gt;&nbsp;_globalState;
<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">ActionNode</span>&nbsp;*&gt;&nbsp;_activeNodes;
<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">HashMap</span>&lt;<span style="color:#216f85;">uint32</span>,&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">Array</span>&lt;<span style="color:#216f85;">Puzzle</span>&nbsp;*&gt;&gt;&nbsp;_referenceTable;
<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">Stack</span>&lt;<span style="color:#216f85;">Puzzle</span>&nbsp;*&gt;&nbsp;_puzzlesToCheck;
<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">Puzzle</span>&gt;&nbsp;_activePuzzles;
<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">Control</span>&gt;&nbsp;_activeControls;</pre>

<br />


__globalState_ holds the state of the entire game. Each key is a hash that can represent anything from a timer to whether a certain puzzle has been solved. The value depends on the what the key is, however, the vast majority are boolean states (0 or 1).

<br />

__activeNodes_ holds... wait for it... the active ActionNodes. Imagine that! Nodes are anything that needs to be processed over time. For example, a timer, an animation, etc. I'll explain further later in the post.

<br />

__referenceTable_ stores references to the Puzzles that certain globalState keys have. This can be thought of as a reverse of the Puzzle struct. A Puzzle stores a list of globalState keys to be checked. _referenceTable stores which Puzzles reference certain globalState keys. Why would we want to do this? It means that any puzzles loaded into the __reference_ table only have to be checked once, instead of every frame. When a value in __globalState_ is changed, it adds the referenced Puzzle to __puzzlesToCheck_

<br />

__puzzlesToCheck_ holds the Puzzles whose Criteria we want to check against __globalState_. This stack is exhausted every frame. It is filled either by _referenceTable or when we enter a new room.

<br />

__activePuzzles_ is where the room's Puzzles are stored. The Puzzle pointers in __referenceTable_ and __puzzlesToCheck_ point to here.

<br />

I realize that the descriptions are still a bit vague, so I figured I would go through an example of sorts and how the containers behave.

<br />

### Every time we change rooms

1.  Clear __referenceTable_, __puzzlesToCheck_, and __activePuzzles_
2.  Open and parse the corresponding .scr file into Puzzle structs and store them in __activePuzzles_. (See last three blog posts)
3.  Iterate through all the Puzzles and their Criteria and create references from a globalState key to the Puzzle. (See createReferenceTable below)
4.  Add all Puzzles to __puzzlesToCheck_

<br />

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">void</span>&nbsp;<span style="color:#216f85;">ScriptManager</span>::<span style="color:#850000;">createReferenceTable</span>()&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Iterate&nbsp;through&nbsp;each&nbsp;Puzzle</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">for</span>&nbsp;(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">Puzzle</span>&gt;::<span style="color:#216f85;">iterator</span>&nbsp;activePuzzleIter&nbsp;=&nbsp;_activePuzzles.<span style="color:#850000;">begin</span>();&nbsp;activePuzzleIter&nbsp;<span style="color:teal;">!=</span>&nbsp;_activePuzzles.<span style="color:#850000;">end</span>();&nbsp;activePuzzleIter<span style="color:teal;">++</span>)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">Puzzle</span>&nbsp;*puzzlePtr&nbsp;=&nbsp;&amp;(<span style="color:teal;">*</span>activePuzzleIter);
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Iterate&nbsp;through&nbsp;each&nbsp;Criteria&nbsp;and&nbsp;add&nbsp;a&nbsp;reference&nbsp;from&nbsp;the&nbsp;criteria&nbsp;key&nbsp;to&nbsp;the&nbsp;Puzzle</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">for</span>&nbsp;(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">Criteria</span>&gt;::<span style="color:#216f85;">iterator</span>&nbsp;criteriaIter&nbsp;=&nbsp;activePuzzleIter<span style="color:teal;">-&gt;</span>criteriaList.<span style="color:#850000;">begin</span>();&nbsp;criteriaIter&nbsp;!=&nbsp;(<span style="color:teal;">*</span>activePuzzleIter).criteriaList.<span style="color:#850000;">end</span>();&nbsp;criteriaIter<span style="color:teal;">++</span>)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_referenceTable<span style="color:teal;">[</span>criteriaIter<span style="color:teal;">-&gt;</span>key<span style="color:teal;">]</span>.push_back(puzzlePtr);
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;If&nbsp;the&nbsp;argument&nbsp;is&nbsp;a&nbsp;key,&nbsp;add&nbsp;a&nbsp;reference&nbsp;to&nbsp;it&nbsp;as&nbsp;well</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(criteriaIter<span style="color:teal;">-&gt;</span>argument)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_referenceTable<span style="color:teal;">[</span>criteriaIter<span style="color:teal;">-&gt;</span>argument<span style="color:teal;">]</span>.push_back(puzzlePtr);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;}
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Remove&nbsp;duplicate&nbsp;entries</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">for</span>&nbsp;(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">HashMap</span>&lt;<span style="color:#216f85;">uint32</span>,&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">Array</span>&lt;<span style="color:#216f85;">Puzzle</span>&nbsp;*&gt;&gt;::<span style="color:#216f85;">iterator</span>&nbsp;referenceTableIter;&nbsp;referenceTableIter&nbsp;!=&nbsp;_referenceTable.<span style="color:#850000;">end</span>();&nbsp;referenceTableIter<span style="color:teal;">++</span>)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">removeDuplicateEntries</span>(&amp;(referenceTableIter<span style="color:teal;">-&gt;</span>_value));
&nbsp;&nbsp;&nbsp;&nbsp;}
}</pre>

<br />

### Every frame

[comment]: # (Markdown hates restarting lists, so we have to manually implement it)

<ol>
<li>Iterate through each ActionNode in __activeNodes_ and call _process()_ on them</li>
<li>If _process()_ returns true, remove and delete the ActionNode
<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">void</span>&nbsp;<span style="color:#216f85;">ScriptManager</span>::<span style="color:#850000;">updateNodes</span>(<span style="color:#216f85;">uint32</span>&nbsp;deltaTimeMillis)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;If&nbsp;process()&nbsp;returns&nbsp;true,&nbsp;it&nbsp;means&nbsp;the&nbsp;node&nbsp;can&nbsp;be&nbsp;deleted</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">for</span>&nbsp;(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">ActionNode</span>&nbsp;*&gt;::<span style="color:#216f85;">iterator</span>&nbsp;iter&nbsp;=&nbsp;_activeNodes.<span style="color:#850000;">begin</span>();&nbsp;iter&nbsp;<span style="color:teal;">!=</span>&nbsp;_activeNodes.<span style="color:#850000;">end</span>();)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;((<span style="color:teal;">*</span>iter)-&gt;<span style="color:#850000;">process</span>(_engine,&nbsp;deltaTimeMillis))&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Remove&nbsp;the&nbsp;node&nbsp;from&nbsp;_activeNodes,&nbsp;then&nbsp;delete&nbsp;it</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">ActionNode</span>&nbsp;*node&nbsp;=&nbsp;<span style="color:teal;">*</span>iter;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;iter&nbsp;<span style="color:teal;">=</span>&nbsp;_activeNodes.<span style="color:#850000;">erase</span>(iter);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">delete</span>&nbsp;node;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}&nbsp;<span style="color:blue;">else</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;iter<span style="color:teal;">++</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;}
}
<span style="color:blue;">bool</span>&nbsp;<span style="color:#216f85;">NodeTimer</span>::<span style="color:#850000;">process</span>(<span style="color:#216f85;">ZEngine</span>&nbsp;*engine,&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;deltaTimeInMillis)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;_timeLeft&nbsp;-=&nbsp;deltaTimeInMillis;
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(_timeLeft&nbsp;&lt;=&nbsp;0)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;engine-&gt;<span style="color:#850000;">getScriptManager</span>()-&gt;<span style="color:#850000;">setStateValue</span>(_key,&nbsp;0);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;<span style="color:blue;">true</span>;
&nbsp;&nbsp;&nbsp;&nbsp;}
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;<span style="color:blue;">false</span>;
}</pre>

<br />
</li>
<li>While __puzzlesToCheck_ is not empty, pop a Puzzle off the stack and check its Criteria against __globalState_</li>
<li>If any of the Criteria pass, call _execute()_ on the corresponding ResultAction.
    <ul><li>Some ResultAction's might create ActionNode's and add them to __activeNodes_. IE ActionTimer</li></ul>
</ol>

<br />

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">void</span>&nbsp;<span style="color:#216f85;">ScriptManager</span>::<span style="color:#850000;">checkPuzzleCriteria</span>()&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">while</span>&nbsp;(!_puzzlesToCheck.<span style="color:#850000;">empty</span>())&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">Puzzle</span>&nbsp;*puzzle&nbsp;=&nbsp;_puzzlesToCheck.<span style="color:#850000;">pop</span>();
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Check&nbsp;each&nbsp;Criteria</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">for</span>&nbsp;(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">Criteria</span>&gt;::<span style="color:#216f85;">iterator</span>&nbsp;iter&nbsp;=&nbsp;puzzle-&gt;criteriaList.<span style="color:#850000;">begin</span>();&nbsp;iter&nbsp;!=&nbsp;puzzle-&gt;criteriaList.<span style="color:#850000;">end</span>();&nbsp;iter<span style="color:teal;">++</span>)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;criteriaMet&nbsp;=&nbsp;<span style="color:blue;">false</span>;
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Get&nbsp;the&nbsp;value&nbsp;to&nbsp;compare&nbsp;against</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">byte</span>&nbsp;argumentValue;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;((<span style="color:teal;">*</span>iter).argument)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;argumentValue&nbsp;=&nbsp;<span style="color:#850000;">getStateValue</span>(iter<span style="color:teal;">-&gt;</span>argument);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">else</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;argumentValue&nbsp;=&nbsp;iter<span style="color:teal;">-&gt;</span>argument;
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Do&nbsp;the&nbsp;comparison</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">switch</span>&nbsp;((<span style="color:teal;">*</span>iter).criteriaOperator)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">case</span>&nbsp;<span style="color:#216f85;">EQUAL_TO</span>:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;criteriaMet&nbsp;=&nbsp;<span style="color:#850000;">getStateValue</span>(iter<span style="color:teal;">-&gt;</span>key)&nbsp;==&nbsp;argumentValue;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">break</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">case</span>&nbsp;<span style="color:#216f85;">NOT_EQUAL_TO</span>:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;criteriaMet&nbsp;=&nbsp;<span style="color:#850000;">getStateValue</span>(iter<span style="color:teal;">-&gt;</span>key)&nbsp;!=&nbsp;argumentValue;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">break</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">case</span>&nbsp;<span style="color:#216f85;">GREATER_THAN</span>:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;criteriaMet&nbsp;=&nbsp;<span style="color:#850000;">getStateValue</span>(iter<span style="color:teal;">-&gt;</span>key)&nbsp;&gt;&nbsp;argumentValue;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">break</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">case</span>&nbsp;<span style="color:#216f85;">LESS_THAN</span>:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;criteriaMet&nbsp;=&nbsp;<span style="color:#850000;">getStateValue</span>(iter<span style="color:teal;">-&gt;</span>key)&nbsp;&lt;&nbsp;argumentValue;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">break</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;TODO:&nbsp;Add&nbsp;logic&nbsp;for&nbsp;the&nbsp;different&nbsp;Flags&nbsp;(aka,&nbsp;ONCE_PER_INST)</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(criteriaMet)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">for</span>&nbsp;(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">List</span>&lt;<span style="color:#216f85;">ResultAction</span>&nbsp;*&gt;::<span style="color:#216f85;">iterator</span>&nbsp;resultIter&nbsp;=&nbsp;puzzle-&gt;resultActions.<span style="color:#850000;">begin</span>();&nbsp;resultIter&nbsp;<span style="color:teal;">!=</span>&nbsp;puzzle-&gt;resultActions.<span style="color:#850000;">end</span>();&nbsp;resultIter<span style="color:teal;">++</span>)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(<span style="color:teal;">*</span>resultIter)-&gt;<span style="color:#850000;">execute</span>(_engine);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;}
}
<span style="color:blue;">bool</span>&nbsp;<span style="color:#216f85;">ActionTimer</span>::<span style="color:#850000;">execute</span>(<span style="color:#216f85;">ZEngine</span>&nbsp;*zEngine)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;zEngine-&gt;<span style="color:#850000;">getScriptManager</span>()-&gt;<span style="color:#850000;">addActionNode</span>(<span style="color:blue;">new</span>&nbsp;<span style="color:#216f85;">NodeTimer</span>(_key,&nbsp;_time));
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">return</span>&nbsp;<span style="color:blue;">true</span>;
}</pre>

<br />

So that's the script system. I've tried to explain it in the best way possible, but if you guys have any questions or suggestions for my implementation, as always, feel free to comment.

<br />

Details on the image handling, video handling and the text debug console will be in Part 2, which should be up some time tomorrow. As always, thanks for reading.

<br />

Happy coding!&nbsp;&nbsp;&nbsp;:)
