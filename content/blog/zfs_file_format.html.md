+++
banner: ""
categories: ["ScummVM"]
date: 2013-06-12T22:59:00.001000-05:00
description: ""
images: []
tags: []
title: "ZFS File Format"
template: "blog.html.jinja"
+++

Over the years I've reverse engineered quite a few file formats, but I've never really sat down and picked apart why a format was designed the way it was. With that said, I wanted to show the ZFS archive file format and highlight some of the peculiarities I saw and perhaps you guys can answer some of my questions.

For some context, Z-engine was created around 1995 and was used on Macintosh, MS-DOS, and Windows 95.

#### Format

The main file header is defined as:

```cpp
struct ZfsHeader {
    uint32 magic;
    uint32 unknown1;
    uint32 maxNameLength;
    uint32 filesPerBlock;
    uint32 fileCount;
    byte xorKey[4];
    uint32 fileSectionOffset;
};
```

* `magic` and `unknown1` are self explanatory
* `maxNameLength` refers to the length of the block that stores a file's name. Any extra spaces are null.
* The archive is split into 'pages' or 'blocks'. Each 'page' contains, at max, `filesPerBlock` files
* `fileCount` is total number of files the archive contains
* `xorKey` is the XOR cipher used for encryption of the files
* `fileSectionOffset` is the offset of the main data section, aka fileLength - mainHeaderLength

The file entry header is defined as:

```cpp
struct ZfsEntryHeader {
    char name[16];
    uint32 offset;
    uint32 id;
    uint32 size;
    uint32 time;
    uint32 unknown;
};
```

* `name` is the file name right-padded with null characters
* `offset` is the offset to the actual file data
* `id` is a the numeric id of the file. The id's increment from 0 to `fileCount`
* `size` is the length of the file
* `unknown` is self explanatory

Therefore, the entire file structure is as follows:

```text
[Main Header]
  
[uint32 offsetToPage2]
[Page 1 File Entry Headers]
[Page 1 File Data]
  
[uint32 offsetToPage3]
[Page 2 File Entry Headers]
[Page 2 File Data]
  
etc.
```

#### Questions and Observations

###### **maxNameLength**

Why have a fixed size name block vs. null terminated or [size][string]? Was that just the popular thing to do back then so the entire header to could be cast directly to a struct?

###### **filesPerBlock**

What is the benefit to pagination? The only explanation I can see atm is that it was some artifact of their asset compiler max memory. Maybe I'm missing something since I've never programmed for that type of hardware.

###### **fileSectionOffset**

I've seen things like this a lot in my reverse engineering; they give the offset to a section that's literally just after the header. Even if they were doing straight casting instead of incremental reading, a simple sizeof(mainHeader) would give them the offset to the next section. Again, if I'm missing something, please let me know.

Happy coding! :)
