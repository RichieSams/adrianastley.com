+++
banner = ""
categories = ["ScummVM"]
date = "2013-06-12T10:59:00-05:00"
description = ""
images = []
tags = []
title = "ZFS File Format"

+++

Over the years I've reverse engineered quite a few file formats, but I've never really sat down and picked apart why a format was designed the way it was. With that said, I wanted to show the ZFS archive file format and highlight some of the peculiarities I saw and perhaps you guys can answer some of my questions.

<br/>

For some context, Z-engine was created around 1995 and was used on Macintosh, MS-DOS, and Windows 95.

## Format
The main file header is defined as:
<pre style="font-family:Consolas;font-size:13;color:black;"><span style="color:blue;">struct</span>&nbsp;<span style="color:#216f85;">ZfsHeader</span>&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;magic;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;unknown1;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;maxNameLength;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;filesPerBlock;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;fileCount;
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">byte</span>&nbsp;xorKey[4];
&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#216f85;">uint32</span>&nbsp;fileSectionOffset;
};</pre>

<br />

*   name is the file name right-padded with null characters
*   offset is the offset to the actual file data
*   id is a the numeric id of the file. The id's increment from 0 to fileCount
*   size is the length of the file
*   unknown is self explanatory

<pre>
[Main Header]
 
[uint32 offsetToPage2]
[Page 1 File Entry Headers]
[Page 1 File Data]
 
[uint32 offsetToPage3]
[Page 2 File Entry Headers]
[Page 2 File Data]
 
etc.
</pre>

## Questions and Observations
**maxNameLength**

Why have a fixed size name block vs. null terminated or [size][string]? Was that just the popular thing to do back then so the entire header to could be cast directly to a struct?

<br />

**filesPerBlock**

What is the benefit to pagination? The only explanation I can see atm is that it was some artifact of their asset compiler max memory. Maybe I'm missing something since I've never programmed for that type of hardware.

<br />

**fileSectionOffset**

I've seen things like this a lot in my reverse engineering; they give the offset to a section that's literally just after the header. Even if they were doing straight casting instead of incremental reading, a simple sizeof(mainHeader) would give them the offset to the next section. Again, if I'm missing something, please let me know.

<br />

Happy coding!&nbsp;&nbsp;&nbsp;:)