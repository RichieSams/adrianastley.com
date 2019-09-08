+++
banner = ""
categories = ["ScummVM"]
date = "2013-07-17T16:21:00-05:00"
description = ""
images = []
tags = []
title = "The Engine Skeleton Gains Some Tendons - Part 2"

+++

Part 2!! As a recap from last post, I started out last week by implementing image handling, video handling, and a text debug console.

<br />

I started with the console as it allows me to to map typed commands to functions. (IE. 'loadimage zassets/castle/cae4d311.tga' calls loadImageToScreen() on that file) This is extremely useful in that I can load an image multiple times or I can load different images all without having to re-run the engine or recompile.

<br />

Creating the text console was actually extremely easy because it was already written. I just to inherit from the base class:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">class</span>&nbsp;<span style="color:#216f85;">Console</span>&nbsp;:&nbsp;<span style="color:blue;">public</span>&nbsp;<span style="color:#216f85;">GUI</span>::<span style="color:#216f85;">Debugger</span>&nbsp;{
<span style="color:blue;">public</span>:
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">Console</span>(<span style="color:#216f85;">ZEngine</span>&nbsp;*engine);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">virtual</span>&nbsp;<span style="color:#850000;">~</span><span style="color:#850000;">Console</span>()&nbsp;{}
 
<span style="color:blue;">private</span>:
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">ZEngine</span>&nbsp;*_engine;
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">cmdLoadImage</span>(<span style="color:blue;">int</span>&nbsp;argc,&nbsp;<span style="color:blue;">const</span>&nbsp;<span style="color:blue;">char</span>&nbsp;**argv);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">cmdLoadVideo</span>(<span style="color:blue;">int</span>&nbsp;argc,&nbsp;<span style="color:blue;">const</span>&nbsp;<span style="color:blue;">char</span>&nbsp;**argv);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">cmdLoadSound</span>(<span style="color:blue;">int</span>&nbsp;argc,&nbsp;<span style="color:blue;">const</span>&nbsp;<span style="color:blue;">char</span>&nbsp;**argv);
};</pre>

<br />

In the constructor, I just registered the various commands:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:#216f85;">Console</span>::<span style="color:#850000;">Console</span>(<span style="color:#216f85;">ZEngine</span>&nbsp;*engine)&nbsp;:&nbsp;<span style="color:#216f85;">GUI</span><span style="color:#216f85;">::</span><span style="color:#216f85;">Deb</span>ugger(),&nbsp;_engine(engine)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">registerCmd</span>(<span style="color:#a31515;">&quot;loadimage&quot;</span>,&nbsp;<span style="color:#6f008a;">WRAP_METHOD</span>(<span style="color:#216f85;">Console</span>,&nbsp;<span style="color:#850000;">cmdLoadImage</span>));
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">registerCmd</span>(<span style="color:#a31515;">&quot;loadvideo&quot;</span>,&nbsp;<span style="color:#6f008a;">WRAP_METHOD</span>(<span style="color:#216f85;">Console</span>,&nbsp;<span style="color:#850000;">cmdLoadVideo</span>));
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">registerCmd</span>(<span style="color:#a31515;">&quot;loadsound&quot;</span>,&nbsp;<span style="color:#6f008a;">WRAP_METHOD</span>(<span style="color:#216f85;">Console</span>,&nbsp;<span style="color:#850000;">cmdLoadSound</span>));
}</pre>

<br />

And then, in ZEngine::initialize() I created an instance of my custom class:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">void</span>&nbsp;<span style="color:#216f85;">ZEngine</span>::<span style="color:#850000;">initialize</span>()&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
 
&nbsp;&nbsp;&nbsp;&nbsp;_console&nbsp;=&nbsp;<span style="color:blue;">new</span>&nbsp;<span style="color:#216f85;">Console</span>(<span style="color:blue;">this</span>);
}</pre>

<br />

And lastly, I registered a key press combination to bring up the debug console:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">void</span>&nbsp;<span style="color:#216f85;">ZEngine</span>::<span style="color:#850000;">processEvents</span>()&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">while</span>&nbsp;(_eventMan-&gt;<span style="color:#850000;">pollEvent</span>(_event))&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">switch</span>&nbsp;(_event.type)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">case</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">EVENT_KEYDOWN</span>:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">switch</span>&nbsp;(_event.kbd.keycode)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">case</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">KEYCODE_d</span>:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">if</span>&nbsp;(_event.kbd.<span style="color:#850000;">hasFlags</span>(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">KBD_CTRL</span>))&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">//&nbsp;Start&nbsp;the&nbsp;debugger</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_console-&gt;<span style="color:#850000;">attach</span>();
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_console-&gt;<span style="color:#850000;">onFrame</span>();
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">break</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">break</span>;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;}
}</pre>

<br />

With that done, I can press ctrl+d, and this is what pops up:

{{% fancybox img="console.png" size="medium" %}}![Console]({{< blog_image_path "console.png" >}}){{% /fancybox %}}

<br />

asdf


















