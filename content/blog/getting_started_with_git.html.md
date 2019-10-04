+++
banner: ""
categories: ["General"]
date: 2014-01-22T22:01:00.002000-06:00
description: ""
images: []
tags: []
title: "Getting Started with Git"
template: "blog.html.jinja"
+++

We're using Git in my Elements of Databases class this semester, so I though I would put together a crash course for Git. So here goes!  

#### What is Git?

[TL;DR](http://en.wikipedia.org/wiki/Wikipedia:Too_long;_didn't_read) explanation of what Git is:  

Git was designed to allow multiple users to work on the same project as the same time.\
It also serves as a way to save and display your work history.  

#### First things first

There are various ways you can use git (command line, SourceTree, GitHub client, TortoiseGit, or some combination). My personal preference is SourceTree for mostly everything, TortoiseGit for merge conflicts, and command line only when necessary.

So the first step is to download and install the software that you would like to use. I am going to be showing SourceTree, but it should be a similar process for other programs.

Go to this link: <http://www.sourcetreeapp.com/download/>\
The download should start within a couple seconds.

Run the exe and follow the directions.  

{{ image('/static/images/blog/getting_started_with_git/install_sourcetree.png') }}

### Setting up SourceTree

1. When you first start SourceTree, it will ask you where git is installed.
{{ image('/static/images/blog/getting_started_with_git/sourcetree_where_is_git.png') }}
1. If it's not installed, then it can do it for you if you click "Download an embedded version of Git"
1. Next it will ask you about Mercurial. You can just say "I don't want to use Mercurial"
1. You will then be presented with this:
{{ image('/static/images/blog/getting_started_with_git/sourcetree_user_info.png') }}
1. Fill out your name and email. This is the information that will show up when you commit.
1. Leave the two checkboxes checked.
    * The first allows SourceTree to automatically update git configurations when you change options within SourceTree.
    * The second makes sure all your line endings are the same, so there are no conflicts if you move from Windows to Mac, Linux to Windows, etc.
1. Accept SourceTree's Licence Agreement and Click "Next"
{{ image('/static/images/blog/getting_started_with_git/sourcetree_user_info_completed.png') }}
1. This next dialog box is for if you use SSH. This can be set up later if you choose to use it. In the meantime, just press "Next" and then "No"
1. The last dialog box gives you the opportunity to sign into any repository sites you use. This makes cloning repositories much easier and faster.
{{ image('/static/images/blog/getting_started_with_git/sourcetree_login.png') }}
1. Click "Finish" and you should be in SourceTree proper:
{{ fancybox_image('/static/images/blog/getting_started_with_git/sourcetree_home.png', 500) }}

#### Creating a Repository

So now you have everything installed, let's actually get into usage. The first thing you'll want to do is create a repository.  You can think of this as a giant box to hold all your code and changes. So let's head over to GitHub. Once you've logged in, you should see something similar to this:

{{ fancybox_image('/static/images/blog/getting_started_with_git/github_home.png', 500) }}

1. Click the green, "New repository" button on the right-hand side of the web page. The page should look something like this:
{{ fancybox_image('/static/images/blog/getting_started_with_git/github_create_repo.png', 500) }}
1. Name the repository and, if you would like, add a description.
1. Click the radio button next to "Private", since all our class repos need to be private
1. Click on the combobox labelled "Add git ignore" and select Python. Github will then automatically create a .gitignore files for us.
    * A '.gitignore' file tells git what type of files or directories we ***don't*** want to store in our repository.
1. Finally, click "Create repository"

### Cloning a Repository

Now that we've created the repository, we want a copy of it on our local machine.  

1. Open up SourceTree
1. Click the button in the top left corner of the program called "Clone/New"
{{ image('/static/images/blog/getting_started_with_git/sourcetree_clone_button.png') }}
1. You should get something that looks like this:
{{ fancybox_image('/static/images/blog/getting_started_with_git/sourcetree_clone_dialog.png', 600) }}
1. If you logged in with your GitHub account earlier, you can press the Globe-looking button to list all your repositories.
   * Just select the one you want to clone and press OK.
{{ fancybox_image('/static/images/blog/getting_started_with_git/sourcetree_clone_globe.png', 800) }}
1. Otherwise, go to the repository on GitHub and copy the url labelled "HTTPS clone url"
{{ fancybox_image('/static/images/blog/getting_started_with_git/github_clone_url.png', 350) }}
    * (You can use SSH if you want, but that's beyond the scope of this tutorial)
1. Paste the url into SourceTree
{{ fancybox_image('/static/images/blog/getting_started_with_git/sourcetree_clone_dialog_complete.png', 500) }}
1. Click on the ellipses button next to "Destination path" and select an ***EMPTY*** folder where you want your local copy to reside.
1. Click "Clone"
{{ fancybox_image('/static/images/blog/getting_started_with_git/sourcetree_clone_dialog_clone.png', 500) }}

#### Basic Git Usage

Now let's get into the basic usage of git  

Let's add a python file with some basic code. So browse to the folder that you just created and create a file called hello.py. Open it with your favorite editor and write a basic Hello World.

{{ image('/static/images/blog/getting_started_with_git/create_file.png') }}

Ok now that we've created this file, let's add it to our repository. So let's go over to SourceTree.

1. Make sure you're in the "File Status" tab
    * This tab lists all the changes that you've done since your last commit with a preview window on the right
{{ fancybox_image('/static/images/blog/getting_started_with_git/file_status.png', 400, '', 'center', true) }}
1. Click on hello.py
1. Add the file to the "Stage" by clicking "Stage file" or by using the arrows in the left column.
{{ image('/static/images/blog/getting_started_with_git/stage1.png') }}\
{{ image('/static/images/blog/getting_started_with_git/stage2.png') }}
Just what is the stage? Think of it as a temporary storage area where you prepare a set of changes before committing. Only the items that are on the stage will be committed. This comes in handy when you want to break changes into multiple commits. We'll see an example of that later.
1. Press the "Commit" button in the top left of SourceTree.
{{ image('/static/images/blog/getting_started_with_git/commit_button.png') }}
You should get something like this:
{{ fancybox_image('/static/images/blog/getting_started_with_git/commit_dialog.png', 600) }}
1. Add a message to your commit and click the "Commit" button at the bottom right-hand corner. I'll explain message formatting later.
{{ image('/static/images/blog/getting_started_with_git/commit_dialog_done.png', 600) }}
1. Now if you go to the "Log/History" tab, you will see your new commit:
{{ image('/static/images/blog/getting_started_with_git/log_history1.png', -1, '', 'center', true) }}\
{{ image('/static/images/blog/getting_started_with_git/log_history2.png') }}

You might notice that SourceTree tells you that "master is 1 ahead". What does this mean?  

When you commit, everything is local. Nothing is transmitted to GitHub. Therefore, SourceTree is telling you that your Master branch is 1 commit ahead of GitHub.

So let's fix that!

1. Click the "Push" button.
{{ image('/static/images/blog/getting_started_with_git/push_button.png', 500) }}
1. And press "Ok"

***Now*** everything is synced to GitHub.

#### Commit Style and Commit Message Formatting

Before I go any further I want to make a few comments on commit style and commit message formatting.

Commits should be treated as small logical changes. A stranger should be able to look at your history and know roughly what your thought process was. Also, they should be able to look at each commit and know exactly what you changed. Some examples would be "Fixed a typo on the output message" or "Added an iteration counter for debug purposes"

With that in mind, Git has a standard commit message format:

```text
<SYSTEM_NAME_IN_ALL_CAPS>: <Commit message>

[Commit body / Any additional information]
```

So an example would be:  

```text
COLLATZ: Add an iteration counter for debug purposes

I wanted to know how many times the function was being called
in each loop.
```

`SYSTEM_NAME` refers to whatever part of the project the commit affects. IE. SOUND_SYSTEM, GRAPHICS_MANAGER, CORE. For our class projects, we probably won't have subsystems, so we can just use the project name, ie. for this first project COLLATZ.\
The commit message should be short and to the point. Any details should be put in the body of the commit.\
If you have a commit body, there should be a blank line between it and the commit message.

#### More Git Usage Examples

Let's do another example commit  

1. Modify your hello.py file to add these lines:
{{ image('/static/images/blog/getting_started_with_git/modify_py_file.png') }}
1. Save

Now, let's commit  

1. Go back to the "File Status" tab in SourceTree
{{ image('/static/images/blog/getting_started_with_git/file_status_tab.png') }}
1. If you look at the preview pane, you'll see the lines we added highlighted in green
{{ image('/static/images/blog/getting_started_with_git/file_status_added_lines.png') }}

However, it would make sense to split the changes into two commits. How do we do that?  

1. Click on the first line you would like to add to the Stage. Holding down shift, click on the last line you want to add to the stage.
{{ image('/static/images/blog/getting_started_with_git/highlight_added_lines.png') }}
1. Now click, "Stage Selected Lines"
{{ image('/static/images/blog/getting_started_with_git/stage_selected_lines_button.png') }}
1. The changes moved to the Stage!
{{ fancybox_image('/static/images/blog/getting_started_with_git/change_added_to_stage.png', 600) }}
1. Commit the changes using the same instructions as before
{{ fancybox_image('/static/images/blog/getting_started_with_git/commit_change1.png', 600) }}
1. Now let's stage and commit the remaining changes. You can once again select the lines you want and use "Stage Selected Lines", or you can stage the entire chunk.
    * A chunk is just a group of changes that happen to be near each other.
{{ fancybox_image('/static/images/blog/getting_started_with_git/stage_change2.png', 600) }}
1. Now there's an extra space that I accidentally added.
{{ fancybox_image('/static/images/blog/getting_started_with_git/extra_space.png', 600) }}
1. Rather than going to my editor to delete it, I can let git do the work.
1. Select the lines you want to discard and press "Discard Selected lines"

{{ admonition('danger') }}
**DANGER:** Once you discard changes, they are gone ***forever***. As in, no getting them back. So be VERY VERY careful using discard.
{{ end_admonition() }}

#### Pulling



So far, we've been the only ones on our repository. However, the whole

point of using a repository is so that multiple people can work at the

same time.  

  

This is a portion of the commit history for an open source project I'm

part of called ScummVM:  



[![](../images/thumbnails/2014-01-22-getting-started-with-git-34-MjAH5aL.png)](../images/2014-01-22-getting-started-with-git-34-MjAH5aL.png)



As you can see, there are many changes going on all the same time.  



#### Let's imagine a scenario:



You and your partner Joe are working on some code at the same time. You

make some changes and commit them. However, in the meantime, Joe also

made some changes, commited them, and pushed them to the repository. If

you try and push, git will complain, and rightfully so. You don't have

the most up-to-date version of the repository. Therefore, in order to

push your changes to the repository, you first need to pull Joe's

changes and merge any conflicts.  

  

How do you pull?  

Just click the "Pull" button in SourceTree. Click ok and wait for git to

do its work. Once it finishes, you'll notice Joe's new commit have shown

up in your history. \*Now\* you can push.  

  

Therefore, it's common practice to always pull before you push. Nothing

will go wrong if you don't, since git will catch the error, but it's a

good habit to get in.  

  



### Tips and Tricks



#### Stashing



So say you have a group of changes that you're working on, but you want

to try a different way to fix the problem. One way to approach that is

by "Stashing". Stashing stores all your current changes and then reverts

your code back to your last commit. Then at a later time you can restore

the stash back onto your code.  

  

  



1.  To stash changes, just press the stash button in SourceTree 

    [![](../images/thumbnails/2014-01-22-getting-started-with-git-35-n3xPm21.png)](../images/2014-01-22-getting-started-with-git-35-n3xPm21.png)



2.  To bring your changes back, right click on the stash you want and

    click "Apply" 

    [![](../images/thumbnails/2014-01-22-getting-started-with-git-36-XJiY0UZ.png)](../images/2014-01-22-getting-started-with-git-36-XJiY0UZ.png)



3.  It will bring up a dialog box like this: 

    [![](../images/thumbnails/2014-01-22-getting-started-with-git-37-kpilHjc.png)](../images/2014-01-22-getting-started-with-git-37-kpilHjc.png)



4.  If you leave the "Delete after applying" checkbox unchecked, the

    stash will stay, even after it's been restored. I usually delete a

    stash after applying, but it can be useful to keep it if you want to

    apply it somewhere else.



  

Stashing can also be done on the command line with:  

  



-   git stash

-   git stash pop



  

The first command stashes changes and the second restores the last stash

and then deletes it  

  



#### Going back in history



Say you want to go back to a certain state in your history, perhaps

because that was the last time your code worked, or maybe to see if a

certain stage also had a certain bug.  

  



1.  First, stash or commit all your current changes. If you don't, you

    could lose some or all of your work.

2.  Then, in the Log/History tab of SourceTree, double click on the

    commit you would like to move to. You should get a dialog box like

    this: 

    [![](../images/thumbnails/2014-01-22-getting-started-with-git-38-02w3nki.png)](../images/2014-01-22-getting-started-with-git-38-02w3nki.png)



3.  That's to confirm that you want to move. Click yes.

4.  Now your code should have changed to reflect the state of the commit

    you clicked.

5.  If you want to make any changes here, first create a branch. That's

    covered in the next section.

6.  To move back to the end, just double click the last commit you were

    on.



  

  



#### Branching



Consider that you and Joe are both trying to come up with a solution to

a bug. Rather than both working in 'master' and potentially messing up

each other's code, it would make more sense if you each had a separate

instance of the code. This can be solved with branching.  

  

So for example, you could work in a branch called, 'solution1' and Joe

could work in a branch called 'solution2'. Then when everything is

finished, you choose the branch you like best and use git to merge that

branch back into 'master'.  

  

So to start, let's create a branch.  

  



1.  Easy enough. Just click the "Branch" button

    http://i.imgur.com/BAmPmg2.png

2.  Name the branch and press "Create Branch". Branch names can not

    contain spaces and are case sensitive

3.  You should now be in your new branch. Any commits you do will commit

    to this branch.



  

To move to another branch, or "checkout" a branch, simply double click

the branch in your commit history or double click the branch in the

branch list in the left column  



[![](../images/thumbnails/2014-01-22-getting-started-with-git-39-ikvsVti.png)](../images/2014-01-22-getting-started-with-git-39-ikvsVti.png)



  

Now that you've committed some changes to another branch, let's merge it

back into master  

  



1.  Double click on master to check it out

2.  Right click on the last commit of the branch you would like to merge

    in and select "Merge..."

3.  Click "Ok"

4.  If there are no conflicts, the merge will be successful and master

    will contain all the changes from the other branch

5.  Remember to push!



  



  



Well, that's pretty much all the basics. There are *many many many* more

things you can do with Git, but you can worry about that when you the

situation arises. 



  



You are more than welcome to leave a comment if you have any questions

or if you have any suggestions for improving what I've written or the

structure of how it's organized. Also, please let me know if you find

any errors.



  



Have fun coding!



-<span style="color: #dd7700;">RichieSams</span>

