+++
banner: ""
categories: ["ScummVM"]
date: 2013-06-12T20:04:00.005000-05:00
description: ""
images: []
tags: []
title: "Git is hard, but ScummVM Common is Awesome"
template: "blog.html.jinja"
+++

This week I started working on Z-engine proper... And immediately ran face-first into the complexity of git. Well, let me restate that. Git isn't hard, per-se, but has so many features and facets that it can very easily go over your head. Anybody with a brain can mindlessly commit and push things to a git repo. However, if you really want structured and concise commit flow, it takes not only knowing the tools, but actually sitting back and thinking about what changes should be put in what commits and which branches.

So that said, I'll go over the things I really like about git or just distributed source control in general.

Branchy development is absolutely a must. It's really really helpful to separate different parts of a project or even different parts of the same section of a project. It makes identifying and diff-ing changes really easy. Also, I found it's really helpful to have a local "work-in-progess" version of the branch I'm working on. That allows me to commit really often and not really have to worry about commit message formatting or general structure. Then when I'm ready to do a push to the repo, I rebase my commits in my WIP branch to fit all my needs, then rebase them to the main branch before pushing.

On that note, rebase is AMAZING!!! It's like the "Jesus" answer in Sunday school, or "Hydrogen bonding" in chemistry class. However, "With great power comes great responsibility". So I try my hardest to only use rebase on my local repo.

On to details about Z-engine work!!

My first milestone for Z-engine was to get a file manager fully working, seeing how pretty much every other part of the engine relies on files. When I was writing my proposal for GSoC, I thought I was going to have to write my own file manager, but Common::SearchManager to the rescue!

By default, the SearchManager will register every file within the game's directory. So any calls to

```cpp
Common::File.open(Common::String filePath);
```

will search the game's directory for the filePath and open that file if found.

Well that was easy. Done before lunch.... Well, not quite. Z-engine games store their script files in archive files. The format is really really simple, but I'll save that for a post of itself. Ideally, I wanted to be able to do:

```cpp
Common::File.open("fileInsideArchive.scr");
```

After some searching and asking about irc, I found that I can do exactly that by implementing Common::Archive :

```cpp
class ZfsArchive : public Common::Archive {
public:
    ZfsArchive(const Common::String &fileName);
    ZfsArchive(const Common::String &fileName, Common::SeekableReadStream *stream);
    ~ZfsArchive();

    /**
     * Check if a member with the given name is present in the Archive.
     * Patterns are not allowed, as this is meant to be a quick File::exists()
     * replacement.
     */
    bool hasFile(const Common::String &fileName) const;

    /**
     * Add all members of the Archive to list.
     * Must only append to list, and not remove elements from it.
     *
     * @return the number of names added to list
     */
    int listMembers(Common::ArchiveMemberList &list) const;

    /**
     * Returns a ArchiveMember representation of the given file.
     */
    const Common::ArchiveMemberPtr getMember(const Common::String &name) const;

    /**
     * Create a stream bound to a member with the specified name in the
     * archive. If no member with this name exists, 0 is returned.
     * @return the newly created input stream
     */
    Common::SeekableReadStream *createReadStreamForMember(const Common::String &name) const;
}
```

and then registering each archive with the SearchManager like so:

```cpp
// Search for .zfs archive files
Common::ArchiveMemberList list;
SearchMan.listMatchingMembers(list, "*.zfs");
  
// Register the files within the zfs archive files with the SearchMan
for (Common::ArchiveMemberList::iterator iter = list.begin(); iter != list.end(); ++iter) {
    Common::String name = (*iter)->getName();
    ZfsArchive *archive = new ZfsArchive(name, (*iter)->createReadStream());

    SearchMan.add(name, archive);
}
```

In summary, git can be complicated, but it has a wealth of potential and is extremely powereful. Also, the ScummVM Common classes are absolutely fantastic and make the lives of engine developers sooooo much easier. A toast to the wonderful people who developed them. Well, that's all for now.

Happy coding! :)
