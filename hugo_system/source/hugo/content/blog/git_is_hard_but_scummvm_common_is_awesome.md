+++
banner = ""
categories = ["ScummVM"]
date = "2013-06-12T08:04:00-05:00"
description = ""
images = []
tags = []
title = "Git is hard, but ScummVM Common is Awesome"

+++

This week I started working on Z-engine proper... And immediately ran face-first into the complexity of git. Well, let me restate that. Git isn't hard, per-se, but has so many features and facets that it can very easily go over your head. Anybody with a brain can mindlessly commit and push things to a git repo. However, if you really want structured and concise commit flow, it takes not only knowing the tools, but actually sitting back and thinking about what changes should be put in what commits and which branches.

<br/>

So that said, I'll go over the things I really like about git or just distributed source control in general.

<br/>

Branchy development is absolutely a must. It's really really helpful to separate different parts of a project or even different parts of the same section of a project. It makes identifying and diff-ing changes really easy. Also, I found it's really helpful to have a local "work-in-progess" version of the branch I'm working on. That allows me to commit really often and not really have to worry about commit message formatting or general structure. Then when I'm ready to do a push to the repo, I rebase my commits in my WIP branch to fit all my needs, then rebase them to the main branch before pushing.

<br/>

On that note, rebase is AMAZING!!! It's like the "Jesus" answer in Sunday school, or "Hydrogen bonding" in chemistry class. However, "With great power comes great responsibility". So I try my hardest to only use rebase on my local repo.

<br/><br/>

On to details about Z-engine work!!

<br/>

My first milestone for Z-engine was to get a file manager fully working, seeing how pretty much every other part of the engine relies on files. When I was writing my proposal for GSoC, I thought I was going to have to write my own file manager, but Common::SearchManager to the rescue!

<br/>

By default, the SearchManager will register every file within the game's directory. So any calls to
<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:#216f85;">Common</span>::<span style="color:#216f85;">File</span>.open(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;filePath);</pre>

will search the game's directory for the filePath and open that file if found.

<br/>

Well that was easy. Done before lunch.... Well, not quite. Z-engine games store their script files in archive files. The format is really really simple, but I'll save that for a post of itself. Ideally, I wanted to be able to do:
<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:#216f85;">Common</span>::<span style="color:#216f85;">File</span>.open(<span style="color:#a31515;">&quot;fileInsideArchive.scr&quot;</span>);</pre>

<br/>

After some searching and asking about irc, I found that I can do exactly that by implementing <span style="font-family:Consolas;font-size:13;color:black;"><span style="color:#216f85;">Common</span>::<span style="color:#216f85;">Archive</span></span>:
<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">class</span>&nbsp;<span style="color:#216f85;">ZfsArchive</span>&nbsp;:&nbsp;<span style="color:blue;">public</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">Archive</span>&nbsp;{
<span style="color:blue;">public</span>:
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">ZfsArchive</span>(<span style="color:blue;">const</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;&amp;fileName);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">ZfsArchive</span>(<span style="color:blue;">const</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;&amp;fileName,&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">SeekableReadStream</span>&nbsp;\*stream);
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#850000;">~</span><span style="color:#850000;">ZfsArchive</span>();
&nbsp;&nbsp;&nbsp;&nbsp;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">/\*\*</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;Check&nbsp;if&nbsp;a&nbsp;member&nbsp;with&nbsp;the&nbsp;given&nbsp;name&nbsp;is&nbsp;present&nbsp;in&nbsp;the&nbsp;Archive.</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;Patterns&nbsp;are&nbsp;not&nbsp;allowed,&nbsp;as&nbsp;this&nbsp;is&nbsp;meant&nbsp;to&nbsp;be&nbsp;a&nbsp;quick&nbsp;File::exists()</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;replacement.</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*/</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">bool</span>&nbsp;<span style="color:#850000;">hasFile</span>(<span style="color:blue;">const</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;&amp;fileName)&nbsp;<span style="color:blue;">const</span>;
&nbsp;&nbsp;&nbsp;&nbsp;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">/\*\*</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;Add&nbsp;all&nbsp;members&nbsp;of&nbsp;the&nbsp;Archive&nbsp;to&nbsp;list.</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;Must&nbsp;only&nbsp;append&nbsp;to&nbsp;list,&nbsp;and&nbsp;not&nbsp;remove&nbsp;elements&nbsp;from&nbsp;it.</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;@return&nbsp;the&nbsp;number&nbsp;of&nbsp;names&nbsp;added&nbsp;to&nbsp;list</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*/</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">int</span>&nbsp;<span style="color:#850000;">listMembers</span>(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">ArchiveMemberList</span>&nbsp;&amp;list)&nbsp;<span style="color:blue;">const</span>;
&nbsp;&nbsp;&nbsp;&nbsp;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">/\*\*</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;Returns&nbsp;a&nbsp;ArchiveMember&nbsp;representation&nbsp;of&nbsp;the&nbsp;given&nbsp;file.</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*/</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:blue;">const</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">ArchiveMemberPtr</span>&nbsp;<span style="color:#850000;">getMember</span>(<span style="color:blue;">const</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;&amp;name)&nbsp;<span style="color:blue;">const</span>;
&nbsp;&nbsp;&nbsp;&nbsp;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">/\*\*</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;Create&nbsp;a&nbsp;stream&nbsp;bound&nbsp;to&nbsp;a&nbsp;member&nbsp;with&nbsp;the&nbsp;specified&nbsp;name&nbsp;in&nbsp;the</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;archive.&nbsp;If&nbsp;no&nbsp;member&nbsp;with&nbsp;this&nbsp;name&nbsp;exists,&nbsp;0&nbsp;is&nbsp;returned.</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*&nbsp;@return&nbsp;the&nbsp;newly&nbsp;created&nbsp;input&nbsp;stream</span>
<span style="color:green;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*/</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">SeekableReadStream</span>&nbsp;\*<span style="color:#850000;">createReadStreamForMember</span>(<span style="color:blue;">const</span>&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;&amp;name)&nbsp;<span style="color:blue;">const</span>;
}</pre>

and then registering each archive with the SearchManager like so:

<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:green;">//&nbsp;Search&nbsp;for&nbsp;.zfs&nbsp;archive&nbsp;files</span>
<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">ArchiveMemberList</span>&nbsp;list;
<span style="color:#6f008a;">SearchMan</span>.<span style="color:#850000;">listMatchingMembers</span>(list,&nbsp;<span style="color:#a31515;">&quot;*.zfs&quot;</span>);
 
<span style="color:green;">//&nbsp;Register&nbsp;the&nbsp;files&nbsp;within&nbsp;the&nbsp;zfs&nbsp;archive&nbsp;files&nbsp;with&nbsp;the&nbsp;SearchMan</span>
<span style="color:blue;">for</span>&nbsp;(<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">ArchiveMemberList</span>::<span style="color:#216f85;">iterator</span>&nbsp;iter&nbsp;=&nbsp;list.<span style="color:#850000;">begin</span>();&nbsp;iter&nbsp;<span style="color:teal;">!=</span>&nbsp;list.<span style="color:#850000;">end</span>();&nbsp;<span style="color:teal;">++</span>iter)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">Common</span>::<span style="color:#216f85;">String</span>&nbsp;name&nbsp;=&nbsp;(<span style="color:teal;">*</span>iter)<span style="color:teal;">-&gt;</span><span style="color:#850000;">getName</span>();
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">ZfsArchive</span>&nbsp;*archive&nbsp;=&nbsp;<span style="color:blue;">new</span>&nbsp;<span style="color:#216f85;">ZfsArchive</span>(name,&nbsp;(<span style="color:teal;">*</span>iter)<span style="color:teal;">-&gt;</span><span style="color:#850000;">createReadStream</span>());
 
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#6f008a;">SearchMan</span>.<span style="color:#850000;">add</span>(name,&nbsp;archive);
}</pre>

<br />

In summary, git can be complicated, but it has a wealth of potential and is extremely powereful. Also, the ScummVM Common classes are absolutely fantastic and make the lives of engine developers sooooo much easier. A toast to the wonderful people who developed them. Well, that's all for now.

<br />

Happy coding!&nbsp;&nbsp;&nbsp;:)