" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
autoload/rcomplete.vim	[[[1
57
" Vim completion script
" Language:    R
" Maintainer:  Jakson Alves de Aquino <jalvesaq@gmail.com>
"

fun! rcomplete#CompleteR(findstart, base)
  if &filetype == "rnoweb" && RnwIsInRCode(0) == 0 && exists("*LatexBox_Complete")
      let texbegin = LatexBox_Complete(a:findstart, a:base)
      return texbegin
  endif
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && (line[start - 1] =~ '\w' || line[start - 1] =~ '\.' || line[start - 1] =~ '\$')
      let start -= 1
    endwhile
    return start
  else
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
      call BuildROmniList()
    endif
    let res = []
    if strlen(a:base) == 0
      return res
    endif

    if len(g:rplugin_liblist) == 0
        call add(res, {'word': a:base, 'menu': " [ List is empty. Run  :RUpdateObjList ]"})
    endif

    let flines = g:rplugin_liblist + g:rplugin_globalenvlines
    " The char '$' at the end of 'a:base' is treated as end of line, and
    " the pattern is never found in 'line'.
    let newbase = '^' . substitute(a:base, "\\$$", "", "")
    for line in flines
      if line =~ newbase
        " Skip cols of data frames unless the user is really looking for them.
        if a:base !~ '\$' && line =~ '\$'
            continue
        endif
        let tmp1 = split(line, "\x06", 1)
        if g:vimrplugin_show_args
            let info = tmp1[4]
            let info = substitute(info, "\t", ", ", "g")
            let info = substitute(info, "\x07", " = ", "g")
            let tmp2 = {'word': tmp1[0], 'menu': tmp1[1] . ' ' . tmp1[3], 'info': info}
        else
            let tmp2 = {'word': tmp1[0], 'menu': tmp1[1] . ' ' . tmp1[3]}
        endif
	call add(res, tmp2)
      endif
    endfor

    return res
  endif
endfun

doc/r-plugin.txt	[[[1
2741
*r-plugin.txt*                                                      *vim-r-plugin*
				 Vim-R-plugin~
			     Plugin to work with R~

Authors: Jakson A. Aquino   <jalvesaq@gmail.com>
         Jose Claudio Faria <joseclaudio.faria@gmail.com>

Version: 0.9.9.9
For Vim version 7.4

 1. Overview                                    |r-plugin-overview|
 2. Main features                               |r-plugin-features|
 3. Installation                                |r-plugin-installation|
 4. Use                                         |r-plugin-use|
 5. Known bugs and workarounds                  |r-plugin-known-bugs|
 6. Options                                     |r-plugin-options|
 7. Custom key bindings                         |r-plugin-key-bindings|
 8. Files                                       |r-plugin-files|
 9. FAQ and tips                                |r-plugin-tips|
10. News                                        |r-plugin-news|


==============================================================================
							   *r-plugin-overview*
1. Overview~

This plugin improves Vim's support for editing R code and makes it possible to
integrate Vim with R.

It uses some ideas and code from Johannes Ranke's (vim-r-plugin), Eric Van
Dewoestine's (screen.vim plugin), Vincent Nijs (R.vim for Mac OS X) and some
ideas from the Tinn-R (Windows only) project.

The latest stable version of this plugin is available at:

    http://www.vim.org/scripts/script.php?script_id=2628

Feedback is welcomed. Please submit bug reports to the developers. Do not like
a feature? Tell us and we may add an option to disable it. If you have any
comments or questions, please post them at:

    https://groups.google.com/forum/#!forum/vim-r-plugin

The plugin should emit useful warnings if you do things it was not programmed
to deal with. Cryptic error message are bugs... Please report them at:

    https://github.com/jcfaria/Vim-R-plugin/issues

We do not plan to take the initiative of writing code for new features, but
patches and git pull requests are welcome. If you want a feature that only few
people might be interested in, you can write a script to be sourced by the
Vim-R-plugin (see |vimrplugin_source|).


==============================================================================
							   *r-plugin-features*
2. Main features~

  * Syntax highlighting for R code, including:
      - Special characters in strings.
      - Functions of loaded packages.
      - Special highlighting for R output (.Rout files).
      - Spell check only strings and comments.
      - Fold code when foldmethod=syntax.
  * Syntax highlighting for RHelp, RMarkdown and RreStructuredText.
  * Smart indentation for R, RHelp, Rnoweb, RMarkdown and RreStructuredText.
  * Integrated communication with R:
      - Start/Close R.
      - Send lines, selection, paragraphs, functions, blocks, entire file.
      - Send commands with the object under cursor as argument: help, args,
        plot, print, str, summary, example, names.
      - Send to R the Sweave, knit and pdflatex commands.
  * Omni completion (auto-completion) for R objects (.GlobalEnv and loaded
    packages).
  * Auto-completion of function arguments.
  * Auto-completion of knitr chunk options.
  * Ability to see R's documentation in a Vim's buffer:
      - Automatic calculation of the best layout of the R documentation buffer
        (split the window either horizontally or vertically according to the
        available room).
      - Automatic formatting of the text to fit the panel width.
      - Send code and commands to R (useful to run examples).
      - Jump to another R documentation.
      - Syntax highlighting of R documentation.
  * Object Browser (.GlobalEnv and loaded packages):
      - Send commands with the object under cursor as argument.
      - Call R's `help()` with the object under cursor as argument.
      - Syntax highlighting of the Object Browser.
  * Most of the plugin's behavior is customizable.

For screenshots see: http://www.lepem.ufc.br/jaa/vim-r-plugin.html

==============================================================================
						       *r-plugin-installation*
3. Installation~

The installation instructions are split in four sections:

   1. Instructions specific for Unix/Linux/OSX
   2. Instructions specific for Windows
   3. Troubleshooting
   4. Optional steps

3.1. Instructions for Unix (Linux, OS X, etc.)~

If you are using Windows, jump to section 3.2.

If you are an unexperienced Vim user, start a terminal emulator and type in
it: `vimtutor`<Enter>

Before installing the plugin, you should install its dependencies:

   Depends:~

   Vim >= 7.4: http://www.vim.org/download.php
               In addition to the most commonly used features, the plugin
               requires: |+python| or |+python3|, |+clientserver| and |+conceal|. 

   R >= 3.0.0: http://www.r-project.org/

   vimcom.plus = 0.9-93: http://www.lepem.ufc.br/jaa/vimcom.plus.html

   Tmux >= 1.5:   http://tmux.sourceforge.net
                  Tmux is necessary to send commands from Vim to R Console.

   Suggests:~

   colorout:      http://www.lepem.ufc.br/jaa/colorout.html
                  Colorizes the R output.

   setwidth:      An R package that can be installed with the command
                  `install.packages("setwidth")`.
                  The library setwidth adjusts the value of `options("width")`
                  whenever the terminal is resized.

   ncurses-term:  http://invisible-island.net/ncurses
                  Might be useful if you want support for 256 colors at the
                  terminal emulator.

   latexmk:       Automate the compilation of LaTeX documents.
                  See examples in |vimrplugin_latexcmd|.

   Note: Vim, R, Tmux, ncurses-term and latexmk are already packaged for most
   GNU/Linux distributions and other Unix variants. Unfortunately their
   installation instructions vary widely and are beyond the scope of this
   documentation.
   
You need to activate plugins and indentation according to 'filetype'. You
should have at least the following options in your |vimrc|:
>
   set nocompatible
   syntax enable
   filetype plugin on
   filetype indent on
<
Download the latest version of the plugin from:

    http://www.vim.org/scripts/script.php?script_id=2628

Start a terminal emulator, go to the directory where you have downloaded the
plugin and type:
>
   vim Vim-R-plugin.vmb
<
Then, in Vim, type:
>
   :so %
<
Press <Enter> and the plugin will be installed (because the plugin has many
files, you have to press the space bar a few times to finish the
installation). You should, then, quit Vim.

Note: If you need too install the plugin in a non default directory, do
`:UseVimball` `[path]`. Then, create a symbolic link to `path/ftdetect/r.vim`
into `~/.vim/ftdetect/r.vim`.

Start Vim again and edit an R script. Type <LocalLeader>rf to start R and run
the command below to get help configuring ~/.Rprofile, ~/.vimrc, ~/.tmux.conf,
and ~/.bashrc (the <LocalLeader> is `\` by default):
>
   :RpluginConfig
<
The above command will guide you through the final configuration steps, but
if you prefer to configure everything by yourself, please, read the section
|r-plugin-quick-setup|.

If you start either GVim or Vim in a terminal emulator the plugin will start R
in a external terminal emulator. If you start Vim inside of a Tmux session,
the plugin will split the Tmux window in two and start R in the other pane.

The recommended way of running the plugin on Linux is running Vim inside a
Tmux session. If you do not use Tmux frequently, it is recommended that you
create a custom Bash function as explained in the section |r-plugin-tmux|,
especially the tip |r-plugin-tvim| (the above command :RpluginConfig should do
this for you).

Note: On Mac OS X, in both Vim and GVim, the plugin will use AppleScript to
send commands to the R Console application unless |vimrplugin_applescript| = 0.
Some users have reported more luck with iTerm than with the default Mac OS X
terminal emulator.

If you want to uninstall the plugin, do
>
   :RmVimball Vim-R-plugin
<

3.2. Instructions for Windows ~

Before installing the plugin, you should install several external
dependencies:

    * R's version must be >= 3.0.0: http://www.r-project.org/

    * vimcom.plus = 0.9-93: http://www.lepem.ufc.br/jaa/vimcom.plus.html
      
      Note: If you cannot build vimcom.plus yourself, you will want to
      download and install the zip file.

    * Vim's version must be >= 7.4: http://www.vim.org/download.php

    * Python 2.7.6 (32 bit):
      http://www.python.org/ftp/python/2.7.6/python-2.7.6.msi
      Do not choose the X86-64 version because it will not work. 

    * pywin32:
      http://sourceforge.net/projects/pywin32/files/pywin32/Build%20218/pywin32-218.win32-py2.7.exe/download
			     
      Note: The above versions of Python and pywin32 are known to work with
      the official GVim 7.4 binary. The default download may not match the
      Python version Vim was linked against: then you have to "View all files"
      on the download page to find the file that matches exactly the above
      versions. Please, read |r-plugin-python| if you need to use different
      versions.

Now, download the latest version of `Vim-R-plugin.vmb` from

    http://www.vim.org/scripts/script.php?script_id=2628
    
and open the directory where you have downloaded it, right click on it and
choose "Edit with Vim".
>
Then, in Vim, type:
>
   :so %
<
Press <Enter> and the plugin will be installed (because the plugin has many
files, you have to press the space bar a few times to finish the
installation). You should, then, quit Vim.

Note: If you need too install the plugin in a non default directory, do
`:UseVimball` `[path]`. Then, create a symbolic link to `path/ftdetect/r.vim`
into `~/vimfiles/ftdetect/r.vim`.

Start GVim again and edit an R script. You can right click a .R file and
choose "Edit with Vim" or create a new one with the Normal mode command:
>
   :e example.R
<
To finish the installation, you have to start R to run a configuration script.
Please, click on the menu bar
>
   R
   Start/Close
   Start R (default)
<
and, finally, click on the menu bar
>
   R
   Configure (Vim-R)
<
The above command will guide you through the final configuration steps.

You may have to adjust the value of |vimrplugin_sleeptime|.

If you want to uninstall the plugin, do
>
   :RmVimball Vim-R-plugin
<

3.3. Troubleshooting (if the plugin doesn't work)~

Note: The <LocalLeader> is '\' by default.

The plugin is a |file-type| plugin. It will be active only if you are editing
a .R, .Rnw, .Rd, Rmd, or Rrst file. The menu items will not be visible and the
key bindings will not be active while editing either unnamed files or files
with name extensions other than the mentioned above. If the plugin is active,
pressing <LocalLeader>rf should start R.

Did you see warning messages but they disappeared before you have had time to
read them? Type the command |:messages| in Normal mode to see them again.

Are you using Debian, Ubuntu or other Debian based Linux distribution? If yes,
you may prefer to install the Debian package available at:

   http://www.lepem.ufc.br/jaa/vim-r-plugin.html

Did you see the message "VimCom port not found"? This means that R is not
running, the vimcom.plus (or vimcom) package is not installed (or is installed
but is not loaded), or R was not started by Vim.


3.4. Optional steps~

3.4.1 Customize the plugin~

Please, read the section |r-plugin-options|. Emacs/ESS users should read the
section Indenting setup (|r-plugin-indenting|) of this document.


3.4.2 Install additional plugins~

You may be interested in installing additional general plugins to get
functionality not provided by this file type plugin. ShowMarks and snipMate
are particularly interesting. Please read |r-plugin-tips| for details. If you
edit Rnoweb files, you may want to try LaTeX-Box for omnicompletion of LaTeX
code (see |r-plugin-latex-box| for details).


3.4.3 Add buttons to GVim~

Please read |r-plugin-toolbar| if you want to add R buttons to GVim's tool
bar.


==============================================================================
								*r-plugin-use*
4. Use~

4.1. Key bindings~

Note: The <LocalLeader> is '\' by default.

Note: It is recommended the use of different keys for <Leader> and
<LocalLeader> to avoid clashes between filetype plugins and general plugins
key binds. See |filetype-plugins|, |maplocalleader| and |r-plugin-localleader|.

To use the plugin, open a .R or .Rnw or .Rd file with Vim and type
<LocalLeader>rf. Then, you will be able to use the plugin key bindings to send
commands to R.

This plugin has many key bindings, which correspond with menu entries. In the
list below, the backslash represents the <LocalLeader>. Not all menu items and
key bindings are enabled in all filetypes supported by the plugin (r, rnoweb,
rhelp, rrst, rmd).

Menu entry                                Default shortcut~
Start/Close
  . Start R (default)                                  \rf
  . Start R --vanilla                                  \rv
  . Start R (custom)                                   \rc
  --------------------------------------------------------
  . Close R (no save)                                  \rq
-----------------------------------------------------------

Send
  . File                                               \aa
  . File (echo)                                        \ae
  . File (open .Rout)                                  \ao
  --------------------------------------------------------
  . Block (cur)                                        \bb
  . Block (cur, echo)                                  \be
  . Block (cur, down)                                  \bd
  . Block (cur, echo and down)                         \ba
  --------------------------------------------------------
  . Chunk (cur)                                        \cc
  . Chunk (cur, echo)                                  \ce
  . Chunk (cur, down)                                  \cd
  . Chunk (cur, echo and down)                         \ca
  . Chunk (from first to here)                         \ch
  --------------------------------------------------------
  . Function (cur)                                     \ff
  . Function (cur, echo)                               \fe
  . Function (cur and down)                            \fd
  . Function (cur, echo and down)                      \fa
  --------------------------------------------------------
  . Selection                                          \ss
  . Selection (echo)                                   \se
  . Selection (and down)                               \sd
  . Selection (echo and down)                          \sa
  --------------------------------------------------------
  . Paragraph                                          \pp
  . Paragraph (echo)                                   \pe
  . Paragraph (and down)                               \pd
  . Paragraph (echo and down)                          \pa
  --------------------------------------------------------
  . Line                                                \l
  . Line (and down)                                     \d
  . Line (and new one)                                  \q
  . Left part of line (cur)                       \r<Left>
  . Right part of line (cur)                     \r<Right>
-----------------------------------------------------------

Command
  . List space                                         \rl
  . Clear console                                      \rr
  . Clear all                                          \rm
  --------------------------------------------------------
  . Print (cur)                                        \rp
  . Names (cur)                                        \rn
  . Structure (cur)                                    \rt
  --------------------------------------------------------
  . Arguments (cur)                                    \ra
  . Example (cur)                                      \re
  . Help (cur)                                         \rh
  --------------------------------------------------------
  . Summary (cur)                                      \rs
  . Plot (cur)                                         \rg
  . Plot and summary (cur)                             \rb
  --------------------------------------------------------
  . Set working directory (cur file path)              \rd
  --------------------------------------------------------
  . Sweave (cur file)                                  \sw
  . Sweave and PDF (cur file)                          \sp
  . Sweave and PDF (cur file, verbose) (Windows)       \sv
  . Sweave, BibTeX and PDF (cur file) (Linux/Unix)     \sb
  --------------------------------------------------------
  . Knit (cur file)                                    \kn
  . Knit and PDF (cur file)                            \kp
  . Knit, BibTeX and PDF (cur file) (Linux/Unix)       \kb
  . Knit and Beamer PDF (cur file) (only .Rmd)         \kl
  . Knit and HTML (cur file, verbose) (only .Rmd)      \kh
  . Knit and PDF (cur file, verbose) (Windows)         \kv
  . Spin (cur file) (only .R)                          \ks
  . Slidify (cur file) (only .Rmd)                     \sl
  --------------------------------------------------------
  . Open PDF (cur file)                                \op
  --------------------------------------------------------
  . Build tags file (cur dir)                  :RBuildTags
-----------------------------------------------------------

Edit
  . Insert "<-"                                          _
  . Complete object name                              ^X^O
  . Complete function arguments                       ^X^A
  --------------------------------------------------------
  . Indent (line)                                       ==
  . Indent (selected lines)                              =
  . Indent (whole buffer)                             gg=G
  --------------------------------------------------------
  . Toggle comment (line, sel)                         \xx
  . Comment (line, sel)                                \xc
  . Uncomment (line, sel)                              \xu
  . Add/Align right comment (line, sel)                 \;
  --------------------------------------------------------
  . Go (next R chunk)                                   gn
  . Go (previous R chunk)                               gN
-----------------------------------------------------------

Object Browser
  . Show/Update                                        \ro
  . Expand (all lists)                                 \r=
  . Collapse (all lists)                               \r-
  . Toggle (cur)                                     Enter
-----------------------------------------------------------

Help (plugin)
Help (R)                                            :Rhelp
Configure (Vim-R)                           :RpluginConfig
-----------------------------------------------------------

Please see |r-plugin-key-bindings| to learn how to customize the key bindings
without editing the plugin directly.

The plugin commands that send code to R Console are the most commonly used. If
the code to be sent to R has a single line it is sent directly to R Console,
but if it has more than one line (a selection of lines, a block of lines
between two marks, a paragraph etc) the lines are written to a file and the
plugin sends to R the command to source the file. You should type quickly
<LocalLeader>d to send to R Console the line currently under the cursor. If
you want to see what lines are being sourced when sending a selection of
lines, you should do either <LocalLeader>se or <LocalLeader>sa instead of
<LocalLeader>ss.

After the commands that send, sweave or knit the current buffer, Vim will save
the current buffer if it has any pending changes before performing the tasks.
After <LocalLeader>ao, Vim will run "R CMD BATCH --no-restore --no-save" on
the current file and show the resulting .Rout file in a new tab. Please see
|vimrplugin_routnotab| if you prefer that the file is open in a new split
window. Note: The command <LocalLeader>ao, silently writes the current buffer
to its file if it was modified and deletes the .Rout file if it exists.

R syntax uses " <- " to assign values to variables which is inconvenient to
type. In insert mode, typing a single underscore, "_", will write " <- ",
unless you are typing inside a string. The replacement will always happen if
syntax highlighting is off (see |:syn-on| and |:syn-off|). If necessary, it is
possible to insert an actual underscore into your file by typing a second
underscore. This behavior is similar to the EMACS ESS mode some users may be
familiar with and is enabled by default. You have to change the value of
|vimrplugin_assign| to disable underscore replacement.

When you press <LocalLeader>rh, the plugin shows the help for the function
under the cursor. The plugin also checks the class of the object passed as
argument to the function to try to figure out whether the function is a
generic one and whether it is more appropriate to show a specific method. The
same procedure is followed with <LocalLeader>rp, that is, while printing an
object. For example, if you run the code below and, then, press
<LocalLeader>rh and <LocalLeader>rp over the two occurrences of `summary`, the
plugin will show different help documents and print different function methods
in each case:
>
   y <- rnorm(100)
   x <- rnorm(100)
   m <- lm(y ~ x)
   summary(x)
   summary(m)
<
When completing object names (CTRL-X CTRL-O) and function arguments (CTRL-X
CTRL-A) you have to press CTRL-N to go foward in the list and CTRL-P to go
backward (see |popupmenu-completion|). Note: if using Vim in a terminal
emulator, Tmux will capture the CTRL-A command. You have to do CTRL-A twice to
pass a single CTRL-A to Vim. For rnoweb, rmd and rrst file types, CTRL-X
CTRL-A can also be used to complete knitr chunk options if the cursor is
inside the chunk header.

If R is not running or if it is running but is busy the completion will be
based on information from the packages listed by |vimrplugin_permanent_libs|
(provided that the libraries were loaded at least once during a session of
Vim-R-plugin usage). Otherwise, the pop up menu for completion of function
arguments will include an additional line with the name of the library where
the function is (if the function name can be found in more than one library)
and the function method (if what is being shown are the arguments of a method
and not of the function itself).

To get help on an R topic, type in Vim (Normal mode):
>
   :Rhelp topic
<
The command may be abbreviated to  :Rh  and you can either press <Tab> to
trigger the autocompletion of R objects names or hit CTRL-D to list the
possible completions (see |cmdline-completion| for details on the various ways
of getting command-line completion). The list of objects used for
completion is the same available for omnicompletion (see
|vimrplugin_permanent_libs|).

You can source all .R files in a directory with the Normal mode command
:RSourceDir, which accepts an optional argument (the directory to be sourced).
								    *:Rinsert*
The command  :Rinsert <cmd>  inserts one or more lines with the output of the
R command sent to R. By using this command we can avoid the need of copying
and pasting the output R from its console to Vim. For example, to insert the
output of `dput(levels(var))`, where `var` is a factor vector, we could do in
Vim:
>
   :Rinsert dput(levels(var))
<
The output inserted by  :Rinsert  is limited to 5012 characters.

The command  :Rformat  calls the function `tidy.source()` of formatR package
to format either the entire buffer or the selected lines. The value of the
`width.cutoff` argument is set to the buffer's 'textwidth' if it is not
outside the range 20-180. Se R help on `tidy.source` for details on how to
control the function behavior.


4.2. Edition of rnoweb files~

In Rnoweb files (.Rnw), when the cursor is over the `@` character, which
finishes an R chunk, the sending of all commands to R is suspended and the
shortcut to send the current line makes the cursor to jump to the next chunk.
While editing rnoweb files, the following commands are available in Normal
mode:

   [count]gn : go to the next chunk of R code
   [count]gN : go to the previous chunk of R code

The commands <LocalLeader>cc, ce, cd and ca send the current chunk of R code
to R Console. The command <LocalLeader>ch sends the R code from the first
chunk up to the current line.


4.3. Omni completion and the highlighting of functions~

The plugin adds some features to the default syntax highlight of R code. One
such feature is the highlight of R functions. However, functions are
highlighted only if their libraries are loaded by R (but see
|vimrplugin_permanent_libs|).

Note: If you have too many loaded packages Vim may be unable to load the list
of functions for syntax highlight.


4.4. Omni completion~

Vim can automatically complete the names of R objects when CTRL-X CTRL-O is
pressed in insert mode (see |omni-completion| for details). Omni completion
shows in a pop up menu the name of the object, its class and its environment
(most frequently, its package name). If the object is a function, its
arguments are shown in a separate window (see 'completeopt' if you want to
disable the preview window).

If a data.frame is found, while building the list of objects, the columns in
the data.frame are added to the list. When you try to use omni completion to
complete the name of a data.frame, the columns are not shown. But when the
data.frame name is already complete, and you have inserted the '$' symbol,
omni completion will show the column names.

Vim uses one file to store the names of .GlobalEnv objects and a list of files
for all other objects. The .GlobalEnv list is stored in the
/tmp/r-plugin-yourlogin directory and is deleted when you quits Vim. The other
files are stored in ~/.vim/r-plugin/objlist/ and remain available until you
manually delete them.


4.5. The Object Browser~

You have to do <LocalLeader>ro to either start or updated the Object Browser.
The Object Browser has two views: .GlobalEnv and Libraries. If you either
press <Enter> or double click (GVim or Vim with 'mouse' set to "a") on the
first line of the Object Browser it will toggle the view between the objects
in .GlobalEnv and the currently loaded libraries. The Object Browser requires
the |+clientserver| feature to be automatically updated and the |+conceal|
feature to correctly align list items.

Note: On Linux you may find Vim binaries without the |clientserver| feature if
you install packages such as vim-nox on Debian/Ubuntu or vim-enhanced on
Fedora/Red Hat. If you want to use Vim in a terminal emulator in Fedora/Red
Hat, you may want to create a symbolic link to "gvim" named "vim". You still
have to explicitly start the server with the argument |--servername|.  To
avoid having to type this argument every time that you start Vim, please look
at the example in |r-plugin-bash-setup|.

Note: On Mac OS X the Object Browser will not be automatically updated if you
are using MacVim because the R package vimcom.plus has support only for
Windows and X11 interprocess communication systems while MacVim is a Cocoa
application.

In the .GlobalEnv view, if an object has the attribute "label", it will also
be displayed. Please, see the R help for package vimcom.plus (or vimcom) for
some options to control the Object Browser behavior. In the Object Browser
window, while in Normal mode, you can either press <Enter> or double click
(GVim only) over a data.frame or list to show/hide its elements (not if
viewing the content of loaded libraries). If you are running R in an
environment where the string UTF-8 is part of either LC_MESSAGES or LC_ALL
variables, unicode line drawing characters will be used to draw lines in the
Object Browser. This is the case of most Linux distributions.

In the Libraries view, you can either double click or press <Enter> over a
library to see its objects. In the Object Browser, the libraries have the
color defined by the PreProc highlighting group, and the other objects have
their colors defined by the return value of some R functions. Each line in the
table below shows a highlighting group and the corresponding R function (if
any) used to classify the objects:

	 PreProc	libraries
	 Number		is.numeric()
	 String		is.character()
	 Special	is.factor()
	 Boolean	is.logical()
	 Type		is.list()
	 Function	is.function()
	 Statement	isS4()

One limitation is that objects made available by the command `data()` may not
have their classes recognized in the GlobalEnv view.


4.6. Commenting and uncommenting lines~

You can toggle the state of a line as either commented or uncommented by
typing <LocalLeader>xx. The string used to comment the line will be "# ",
"## " or "### ", depending on the values of |vimrplugin_indent_commented| and
|r_indent_ess_comments|.

You can also add the string "# " to the beginning of a line by typing
<LocalLeader>xc and remove it with <LocalLeader>xu. In this case, you can set
the value of vimrplugin_rcomment_string to control what string will be added
to the begining of the line. Example:
>
   let vimrplugin_rcomment_string = "# "
<
Finally, you can also add comments to the right of a line with the
<LocalLeader>; shortcut. By default, the comment starts at the 40th column,
which can be changed by setting the value of r_indent_comment_column, as
below:
>
   let r_indent_comment_column = 20
<
If the line is longer than 38 characters, the comment will start two columns
after the last character in the line. If you are running <LocalLeader>; over a
selection of lines, the comments will be aligned according to the longest
line.

Note: While typing comments the leader comment string is automatically added
to new lines when you reach 'textwidth' but not when you press <Enter>.
Please, read the Vim help about 'formatoptions' and |fo-table|. For example,
you can add the following line to your |vimrc| if you want the comment string
being added after <Enter>:
>
   autocmd FileType r setlocal formatoptions-=t formatoptions+=croql
<
Tip: You can use Vim substitution command `:%s/#.*//` to delete all comments
in a buffer (see |:s| and |pattern-overview|).


4.7. Build a tags file to jump to function definitions~
								 *:RBuildTags*
Vim can jump to functions defined in other files if you press CTRL-] over the
name of a function, but it needs a tags file to be able to find the function
definition (see |tags-and-searches|). The command  :RBuildTags  calls the R
function `rtags()` to build the tags file for the R scripts in the current
directory. Please read |r-plugin-tagsfile| to learn how to create a tags file
referencing source code located in other directories, including the entire R
source code.


4.8. Tmux usage~
							       *r-plugin-tmux*
When running either GVim or Vim in a terminal emulator (Linux/Unix only), the
Vim-R-plugin will use Tmux to start R in a separate terminal emulator. R will
be running inside a Tmux session, but you will hardly notice any difference
from R running directly in the terminal emulator. The remaining of this
section refers to the case of starting R when Vim already is in a Tmux
session, that is, if you do:
>
   tmux
   vim --servername VIM filename.R
   exit
<
In this case, the terminal window is split in two regions: one for Vim and the
other for Tmux. Then, it's useful (but not required) to know some Tmux
commands. After you finished editing the file, you have to type `exit` to quit
the Tmux session.


4.8.1 tvim~
							       *r-plugin-tvim*
If, as recommended, you always prefer to run Tmux before running Vim you could
create a Bash function called `tvim` (please, see the ~/.bashrc example at
|r-plugin-quick-setup|). Then you will be able to start a Tmux session running
Vim by typing:
>
   tvim filename.R
<
Using the `tvim` function, the Tmux session is finished when you quits Vim.
That is, the main advantage of using `tvim` is that you do not have to type
`tmux` before and `exit` after the edition of the file. Moreover, the
`tvim` command also pass the |--servername| argument to Vim, which is required
update of the Object Browser and functions highlight.

If you are going to run Vim inside Tmux, than you should create your
~/.tmux.conf if it does not exist yet. You may put the lines below in your
~/.tmux.conf as a starting point to your own configuration file:
>
    set-option -g prefix C-a
    unbind-key C-b
    bind-key C-a send-prefix
    set-window-option -g mode-keys vi
    set -g terminal-overrides 'xterm*:smcup@:rmcup@'
    set -g mode-mouse on
    set -g mouse-select-pane on
    set -g mouse-resize-pane on
<

4.8.2 Key bindings and mouse support~

The Tmux configuration file suggested above configures Tmux to use vi key
bindings. It also configures Tmux to react to mouse clicks. You should be able
to switch the active pane by clicking on an inactive pane, to resize the panes
by clicking on the border line and dragging it, and to scroll the R Console
with the mouse wheel. When you use the mouse wheel, Tmux enters in its
copy/scroll back mode (see below).

The configuration script also sets <C-a> as the Tmux escape character (the
default is <C-b>), that is, you have to type <C-a> before typing a Tmux
command. Below are the most useful key bindings to use Tmux with the above
tmux.conf:

    <C-a>arrow keys : Move the cursor to the Tmux panel above, below, at the
                      right or at the left of the current one.

    <C-a><C-Up>     : Move the panel division upward one line, that is, resize
                      the panels. Repeat <C-Up> to move more. <C-Down> will
                      move the division downward one line. If you are using
                      the vertical split, you should use <C-Left> and
                      <C-Right> to resize the panels.

    <C-a>[          : Enter the copy/scroll back mode. You can use <PgUp>,
                      <PgDown> and vi key bindings to move the cursor around
                      the panel. Press q to quit copy mode.

    <C-a>]          : Paste the content of Tmux paste buffer.

    <C-a>z          : Hide/show all panes except the current one.
		      Note: If you mistakenly press <C-a><C-z>, you have to
		      type `fg` to get Tmux back to the foreground.

While in the copy and scroll back mode, the following key bindings are very
useful:

    q               : Quit the copy and scroll mode.
    <Space>         : Start text selection.
    v<Space>        : Start rectangular text selection.
    <Enter>         : Copy the selection to Tmux paste buffer.

Please, read the manual page of Tmux if you want to change the Tmux
configuration and learn more commands. To read the Tmux manual, type in the
terminal emulator:
>
  man tmux
<
Note: Because <C-a> was configured as the Tmux escape character, it will not
be passed to applications running under Tmux. To send <C-a> to either R or Vim
you have to type <C-a>a.


4.8.3 Copying and pasting~

You do not need to copy code from Vim to R because you can use the plugin's
shortcuts to send the code. For pasting the output of R commands into Vim's
buffer, you can use the command |:Rinsert|. If you want to copy text from an
application running inside the Tmux to another application also running in
Tmux, as explained in the previous subsection, you can enter in Tmux
copy/scroll mode, select the text, copy it, switch to the other application
pane and, then, paste.

However, if you want to copy something from either Vim or R to another
application not running inside Tmux, Tmux may prevent the X server from
capturing the text selected by the mouse. The solution is to disable mouse
support in Tmux. You will be able to toggle mouse support on and off by typing
<C-a>m if you add the following line to your ~/.tmux.conf:
>
   bind m run-shell '( if [ "mode-mouse on" = "$(tmux show-window-option | grep mode-mouse)" ]; then toggle=off; else toggle=on; fi; tmux display-message "mouse $toggle"; tmux set-option -w mode-mouse $toggle ; for cmd in mouse-select-pane mouse-resize-pane mouse-select-window; do tmux set-option -g $cmd $toggle ; done;) > /dev/null 2>&1'
<

4.8.2 Remote access~

With Tmux, you can detach the Vim-R session and reattach it latter. This is
useful if you plan to begin the use the Vim-R-plugin in a machine and latter
move to another computer and access remotely your previous Vim-R session.
Below is the step-by-step procedure to run the Vim-R remotely:

  - Start Tmux:
      tmux

  - Start Vim:
      vim the_script.R

  - Use Vim to start an R session:
      <LocalLeader>rf

  - Send code from Vim to R, and, then, detach Vim and R with <C-a>d
    The command will be <C-b>d if you have not set <C-a> as the escape
    character in your ~/.tmux.conf.

  - Some time latter (even if accessing the machine remotely) reattach the
    Tmux session:
      tmux attach


==============================================================================
							 *r-plugin-known-bugs*
5. Known bugs and workarounds~

The bugs that are known to exist but that will not be fixed are listed in this
section. Some of them can not be fixed because they depend on either R or Vim
missing features; others would be very time consuming to fix without breaking
anything.


5.1. R's source() issues~

The R's `source()` function of base package prints an extra new line between
commands if the option echo = TRUE, and error and warning messages are printed
only after the entire code is sourced, which makes it more difficult to find
errors in the code sent to R. Details:

   https://stat.ethz.ch/pipermail/r-devel/2012-December/065352.html


5.2. The clipboard's content is lost (Windows only)~

On Windows, the plugin copies the command that will be sent to R into the
clipboard. Thus, if you have anything in the clipboard it will be lost while
using the plugin.


5.3. The menu may not reflect some of your custom key bindings~

If you have created a custom key binding for the Vim-R-plugin, the menu in
GVim will not always reflect the correct key binding if it is not the same for
Normal, Visual and Insert modes.


5.4. Syntactically correct code may be wrongly indented~

If the Vim-R-plugin indents your code wrongly you may get the correct
indentation by adding braces and line breaks to it. For example, try to
indent the code below:
>
    # This code will be wrongly indented:

    levels(x) <- ## nl == nL or 1
        if (nl == nL) as.character(labels)
        else paste(labels, seq_along(levels), sep = "")
    class(x) <- c(if(ordered) "ordered", "factor")


    # But this one will be correctly indented:

    levels(x) <- ## nl == nL or 1
        if (nl == nL)
            as.character(labels)
        else
            paste(labels, seq_along(levels), sep = "")
    class(x) <- c(if(ordered) "ordered", "factor")
<

5.5. Wrong message that "R is busy" (Windows only)~

On Windows, when code is sent from Vim to R Console, the vimcom (or
vimcom.plus) library sets the value of the internal variable `r_is_busy` to 1.
The value is set back to 0 when any code is successfully evaluated. If you
send invalid code to R, there will be no successful evaluation of code and,
thus, the value of `r_is_busy` will remain set to 1. Then, if you try to
update the object browser, see the R documentation for any function, or do
other tasks that require the hidden evaluation of code by R, the vimcom
library will refuse to do the tasks to avoid any risk of corrupting R's
memory. It will tell Vim that "R is busy" and Vim will display this message.
Everything should work as expected again after any valid code is executed in
the R Console.


5.6. R must be started by Vim~

The communication between Vim and R will work only if R was started by Vim
through the <LocalLeader>rf command because the plugin was designed to connect
each Vim instance with its own R instance. If you start R before Vim, it will
not inherit from Vim the environment variables VIMRPLUGIN_TMPDIR,
VIMRPLUGIN_HOME, VIMEDITOR_SVRNM and VIMINSTANCEID. The first one is the path
used by the R package vimcom to save temporary files used by the Vim-R-plugin
to: perform omnicompletion, show R documentation in a Vim buffer, and update
the Object Browser. The latter is used by the Vim-R-plugin to know that it is
not connecting to an R instance initiated by another Vim instance. If you use
Vim to start R, but then closes Vim, the VIMINSTANCEID variable in R will
become outdated. Additionally, the Vim-R-plugin sets the value of its internal
variable SendCmdToR from SendCmdToR_fake to the appropriate value when R is
successfully started. It is possible to set the values of all these variables
manually, but, as you can see below, it is not practical to do so. If you have
either started R before Vim or closed Vim and opened it again and really want
full communication between Vim and R, you can try the following (not all
procedures are necessary for all cases):

   In Normal mode Vim do:
>
   :echo $VIMRPLUGIN_TMPDIR
   :echo $VIMINSTANCEID
   :echo $VIMEDITOR_SVRNM
   :echo $VIMRPLUGIN_HOME
<
   In R do:
>
   detach("package:vimcom.plus", unload = TRUE) # or vimcom
   Sys.setenv(VIMRPLUGIN_TMPDIR="T") # where "T" is what Vim has echoed
   library(vimcom.plus)              # or vimcom
   Sys.setenv(VIMINSTANCEID="I")     # where "I" is what Vim has echoed
   Sys.setenv(VIMEDITOR_SVRNM"="S")  # where "S" is what Vim has echoed
   Sys.setenv(VIMRPLUGIN_HOME"="H")  # where "H" is what Vim has echoed
<
If you are running R in a terminal emulator (Linux/Unix) Vim still needs to
know the name of Tmux session and Tmux pane where R is running.

So, in R do:
>
   Sys.getenv("TMUX_PANE")
<
   and the following Tmux command:
>
   <Ctrl-A>:display-message -p '#S'<Enter><Enter>
<
And in Normal mode Vim do:
>
   :let rplugin_rconsole_pane = "X"
   :let rplugin_tmuxsname = "Y"
<
Finally, do one of the commands below in Normal mode Vim, according to how R
is running:
>
   let SendCmdToR = function('SendCmdToR_TmuxSplit')
   let SendCmdToR = function('SendCmdToR_Term')
   let SendCmdToR = function('SendCmdToR_OSX')
   let SendCmdToR = function('SendCmdToR_Windows')
<

==============================================================================
							    *r-plugin-options*
6. Options~

|vimrplugin_term|              External terminal to be used
|vimrplugin_term_cmd|          Complete command to open an external terminal
|vimrplugin_Rterm|             On Windows, use Rterm.exe
|vimrplugin_assign|            Convert '_' into ' <- '
|vimrplugin_assign_map|        Choose what to convert into ' <- '
|vimrplugin_rnowebchunk|       Convert '<' into '<<>>=\n@' in Rnoweb files
|vimrplugin_objbr_place|       Placement of Object Browser
|vimrplugin_objbr_w|           Initial width of Object Browser window
|vimrplugin_external_ob|       Run Object Browser on external terminal
|vimrplugin_vimpager|          Use Vim to see R documentation
|vimrplugin_editor_w|          Minimum width of R script buffer
|vimrplugin_help_w|            Desired width of R documentation buffer
|vimrplugin_i386|              Use 32 bit version of R
|vimrplugin_r_path|            Directory where R is
|vimrplugin_r_args|            Arguments to pass to R
|vimrplugin_permanent_libs|    Objects for omnicompletion and syntax highlight
|vimrplugin_routmorecolors|    More syntax highlighting in R output
|vimrplugin_routnotab|         Show output of R CMD BATCH in new window
|vimrplugin_indent_commented|  Indent lines commented with the \xx command
|vimrplugin_sleeptime|         Delay while sending commands in MS Windows
|vimrplugin_rconsole_height|   The number of lines of R Console (Tmux split)
|vimrplugin_vsplit|            Make Tmux split the window vertically
|vimrplugin_rconsole_width|    The number of columns of R Console (Tmux split)
|vimrplugin_applescript|       Use osascript in Mac OS X
|vimrplugin_listmethods|       Do `vim.list.args()` instead of `args()`
|vimrplugin_specialplot|       Do `vim.plot()` instead of `plot()`
|vimrplugin_maxdeparse|        Argument to R `source()` function
|vimrplugin_latexcmd|          Command to run on .tex files
|vimrplugin_sweaveargs|        Arguments do `Sweave()`
|vimrplugin_never_unmake_menu| Do not unmake the menu when switching buffers
|vimrplugin_map_r|             Use 'r' to send lines and selected text
|vimrplugin_ca_ck|             Add ^A^K to the beginning of commands
|vimrplugin_openpdf|           Open PDF after processing rnoweb file
|vimrplugin_openpdf_quietly|   Open PDF quietly
|vimrplugin_openhtml|          Open PDF quietly
|vimrplugin_strict_rst|        Code style for generated rst files
|vimrplugin_insert_mode_cmds|  Allow R commands in insert mode
|vimrplugin_allnames|          Show names which begin with a dot
|vimrplugin_rmhidden|          Remove hidden objects from R workspace
|vimrplugin_source|            Source additional scripts
|vimrplugin_restart|           Restart R if it is already running
|vimrplugin_show_args|         Show extra information during omnicompletion


6.1. Terminal emulator (Linux/Unix only)~
							     *vimrplugin_term*
The plugin uses the first terminal emulator that it finds in the following
list:
    1. gnome-terminal,
    2. konsole,
    3. xfce4-terminal,
    4. iterm,
    5. Eterm,
    6. rxvt,
    7. aterm,
    8. roxterm,
    9. terminator,
   10. xterm.

If Vim does not select your favorite terminal emulator, you may define it in
your |vimrc| by setting the variable vimrplugin_term, as shown below:
>
   let vimrplugin_term = "xterm"
   let vimrplugin_term = "/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal"
<
							 *vimrplugin_term_cmd*
If your terminal emulator is not listed above, or if you are not satisfied
with the way your terminal emulator is called by the plugin, you may define in
your |vimrc| the variable vimrplugin_term_cmd, as in the examples below:
>
   let vimrplugin_term_cmd = "gnome-terminal --title R -e"
   let vimrplugin_term_cmd = "terminator --title R -x"
   let vimrplugin_term_cmd = "/Applications/Utilities/iTerm.app/Contents/MacOS/iTerm -t R"
<
Please, look at the manual of your terminal emulator to know how to call it.
The last argument must be the one which precedes the command to be executed.


6.2. Use Rterm.exe on Windows~
							      *vimrplugin_Rterm*
If you rather prefer to use Rterm.exe than Rgui.exe, you have to set both the
"Quick Edit Mode" and the "Insert mode" on either the Windows 7 PowerShell or
the Windows XP Command Prompt (click on the title bar and choose
"properties"). Then, you should put in your |vimrc|:
>
   let vimrplugin_Rterm = 1
<
Technical details: The plugin copies the code to be sent to R to the Windows
clipboard and, then, sends the key strokes CTRL-V to R Console window.
However, neither the Windows 7 PowerShell nor the Windows XP Command Prompt
has a keyboard shortcut to "paste". The solution is to set the "Quick Edit
Mode" on either PowerShell or Command Prompt and to send a "Right click" to
it.


6.3. Assignment operator and Rnoweb completion of code block~
						      *vimrplugin_rnowebchunk*
						       *vimrplugin_assign_map*
							   *vimrplugin_assign*
In Rnoweb files, a '<' is replaced with '<<>>=\n@'. To disable this feature,
put in your |vimrc|:
>
   let vimrplugin_rnowebchunk = 0
<
While editing R code, '_' is replaced with ' <- '. If want to bind other keys
to be replaced by ' <- ', set the value of |vimrplugin_assign_map| in your
|vimrc|, as in the example below which emulates RStudio behavior (may only
works on GVim):
>
   let vimrplugin_assign_map = "<M-->"
<
Note: If you are using Vim in a terminal emulator, you have to put in your
|vimrc|:
>
   set <M-->=^[-
   let vimrplugin_assign_map = "<M-->"
<
where `^[` is obtained by pressing CTRL-V CTRL-[ in Insert mode.

Note: You can't map <C-=>, as StatET does because only alphabetic letters can
be mapped in combination with the CTRL key.

To completely disable this feature, put in your |vimrc|:
>
   let vimrplugin_assign = 0
<

6.4. Object Browser options~
						      *vimrplugin_objbr_place*
							  *vimrplugin_objbr_w*
						      *vimrplugin_external_ob*
By default, the object browser will be created with 40 columns. The minimum
width of the Object Browser window is 9 columns. You can change the object
browser's default width by setting the value of |vimrplugin_objbr_w| in your
|vimrc|, as below:
>
   let vimrplugin_objbr_w = 30
<
The Object Browser will always be created by splitting the Vim script window
if you are running either GVim or Vim not inside a Tmux session. However, if
running Vim in a terminal emulator inside a Tmux session, the Object Browser
will be created in a independent Vim instance in a Tmux panel beside the R
Console. Valid values for the Object Browser placement are "script" or
"console" and "right" or "left" separated by a comma. Examples:
>
   let vimrplugin_objbr_place = "script,right"
   let vimrplugin_objbr_place = "console,left"
<
If vimrplugin_external_ob = 1 and R is running in an external terminal
emulator, the Object Browser will be placed besides the R Console in the
external terminal emulator. In this case, the command <LocalLeader>rh will not
work on the Object Browser (you will see the message "Cmd not available").


6.5. Vim as pager for R help~
							 *vimrplugin_vimpager*
							 *vimrplugin_editor_w*
							   *vimrplugin_help_w*
6.5.1. Quick setup~

If you do not want to see R documentation in a Vim's buffer, put in your
|vimrc|:
>
   let vimrplugin_vimpager = "no"
<
If you want to use Vim to see R documentation even when looking for help in
the R console, you have to create a shell script in your path that will call
Vim in the right way. You can, for example, create a file named
`~/bin/vimrpager` to do that (see |r-plugin-quick-setup|).


6.5.2. Details and other options:~

The plugin key bindings will remain active in the documentation buffer, and,
thus, you will be able to send commands to R as you do while editing an R
script. You can, for example, use <LocalLeader>rh to jump to another R help
document.

The valid values of vimrplugin_vimpager are:

   "tab"       : Show the help document in a new tab. If there is already a
                 tab with an R help document, use it.
                 This is the default.
   "vertical"  : Split the window vertically if the editor width is large
                 enough; otherwise, split the window horizontally and attempt
                 to set the window height to at least 20 lines.
   "horizontal": Split the window horizontally.
   "tabnew"    : Show the help document in a new tab.
   "no"        : Do not show R documentation in Vim.

The window will be considered large enough if it has more columns than
vimrplugin_editor_w + vimrplugin_help_w. These variables control the minimum
width of the editor window and the help window, and their default values are,
respectively, 66 and 46. Thus, if you want to have more control over Vim's
behavior while opening R's documentations, you will want to set different
values to some variables in your |vimrc|, as in the example:
>
   let vimrplugin_editor_w = 80
   let vimrplugin_editor_h = 60
<

6.6. Use 32 bit version of R (Windows and Mac OS X only)~
							     *vimrplugin_i386*
If you are using a 64 bit Windows or a 64 bit Mac OS X, but prefer to run the
32 bit version of R, put in your |vimrc|:
>
   let vimrplugin_i386 = 1
<

6.7. R path~
							   *vimrplugin_r_path*
Vim will run the first R executable in the path. You can set an alternative R
path in your |vimrc| as in the examples:
>
   let vimrplugin_r_path = "/path/to/my/preferred/R/version/bin"
   let vimrplugin_r_path = "C:\\Program Files\\R\\R-3.0.1\\bin\\i386"
<
On Windows, Vim will try to find the R install path in the Windows Registry.

You can set a different R version for specific R scripts in your |vimrc|.
Example:
>
   autocmd BufReadPre ~/old* let vimrplugin_r_path='~/app/R-2.8.1/bin'
<

6.8. Arguments to R~
							   *vimrplugin_r_args*
Set this option in your |vimrc| if you want to pass command line arguments to
R at the startup. Example:
>
   let vimrplugin_r_args = "--sdi --no-save --quiet"
<
On Linux, there is no default value for |vimrplugin_r_args|. On Windows, the
default value is "--sdi", but you may change it to "--mdi" if you do not like
the SDI style of the graphical user interface.


6.9. Omnicompletion and syntax highlight of R functions~
						   *vimrplugin_permanent_libs*
The list of functions to be highlighted and the list of objects for
omnicompletion are built dynamically as the libraries are loaded by R.
However, you can set the value of vimrplugin_permanent_libs if you want that
the functions and objects of specific packages are respectively highlighted
and available for omnicompletion even if R is not running. By default, only
the functions of vanilla R are always highlighted. Below is the default value
of vimrplugin_permanent_libs:
>
   let vimrplugin_permanent_libs = "base,stats,graphics,grDevices,utils,datasets,methods"
<

6.10. More colorful syntax highlight of .Rout files~
						   *vimrplugin_routmorecolors*
By default, the R commands in .Rout files are highlighted with the color of
comments, and only the output of commands has some of its elements highlighted
(numbers, strings, index of vectors, warnings and errors).

If you prefer that R commands in the R output are highlighted as they are in R
scripts, put the following in your |vimrc|:
>
   let vimrplugin_routmorecolors = 1
<

6.11. How to automatically open the .Rout file~
							*vimrplugin_routnotab*
After the command <LocalLeader>ao, Vim will save the current buffer if it has
any pending changes, run `R CMD BATCH --no-restore --no-save` on the current
file and show the resulting .Rout file in a new tab. If you prefer that the
file is open in a new split window, put in your |vimrc|:
>
   let vimrplugin_routnotab = 1
<

6.12. Indent commented lines~
						 *vimrplugin_indent_commented*
						       *r_indent_ess_comments*
You can type <LocalLeader>xx to comment out a line or selected lines. If the
line already starts with a comment string, it will be removed. After adding
the comment string, the line will be reindented by default. To turn off the
automatic indentation, put in your |vimrc|:
>
   let vimrplugin_indent_commented = 0
<
What string will be added to the beginning of the line depends on the values
of vimrplugin_indent_commented and r_indent_ess_comments according to the
table below (see |r-plugin-indenting|):
>
   vimrplugin_indent_commented   r_indent_ess_comments   string
                 1                        0                #
                 0                        0                #
                 1                        1                ##
                 0                        1                ###
<

6.13. Sleep time (Windows only)~
							*vimrplugin_sleeptime*
The plugin gives to R a small amount of time to process the paste command. The
default value is 0.2 second, but you should experiment different values. The
example show how to adjust the value of sleeptime in your |vimrc|:
>
   let vimrplugin_sleeptime = 0.1
<

6.14. Tmux configuration (Linux/Unix only)~
						       *vimrplugin_notmuxconf*

GVim (or Vim running R in an external terminal emulator) runs Tmux with a
specially built configuration file. If you want to use your own ~/.tmux.conf,
put in your |vimrc|:
>
   let vimrplugin_notmuxconf = 1
<
If you opted for using your own configuration file, the plugin will write a
minimum configuration which will set the value of two environment variables
required for the communication with R and then source your own configuration
file (~/.tmux.conf).


6.15. Integration with Tmux (Linux/Unix only)~
						  *vimrplugin_rconsole_height*
							   *vimrplugin_vsplit*
						   *vimrplugin_rconsole_width*
These three options are valid only when Vim is started inside a Tmux session.
In this case, when you type <LocalLeader>rf, the terminal will be split in two
regions and R will run in one of them. By default, the Vim-R-plugin will tell
Tmux to split the terminal window horizontally and you can set in your
|vimrc| the initial number of lines of the Tmux pane running R as in the
example below:
>
   let vimrplugin_rconsole_height = 15
<
If you prefer to split it vertically:
>
   let vimrplugin_vsplit = 1
<
In this case, you can choose the initial number of columns of R Console:
>
   let vimrplugin_rconsole_width = 15
<

6.16. Integration with AppleScript (OS X only)~
							*vimrplugin_applescript*
In Mac OS X, the plugin will try to send commands to R gui using AppleScript.
If you prefer either to run R and Vim in the same terminal emulator split in
two regions (Vim and R) or to run R in an external terminal emulator, put in
your |vimrc|:
>
   let vimrplugin_applescript = 0
<
If Vim is running inside Tmux, the terminal will be split in two regions.
Otherwise, R will start in an external terminal emulator.


6.17. Special R functions~
						      *vimrplugin_listmethods*
						      *vimrplugin_specialplot*
The R function `args()` lists the arguments of a function, but not the arguments
of its methods. If you want that the plugin calls the function
`vim.list.args()` after <LocalLeader>ra, you have to add to your |vimrc|:
>
   let vimrplugin_listmethods = 1
<
By default, R makes a scatterplot of numeric vectors. The function `vim.plot()`
do both a histogram and a boxplot. The function can be called by the plugin
after <LocalLeader>rg if you put the following line in your |vimrc|:
>
   let vimrplugin_specialplot = 1
<

6.18. maxdeparse~
						       *vimrplugin_maxdeparse*
You can set the argument maxdeparse to be passed to R's `source()` function.
Example:
>
   let vimrplugin_maxdeparse = 300
<

6.19. LaTeX command~
							 *vimrplugin_latexcmd*
						       *vimrplugin_sweaveargs*
On Windows, the plugin calls `tools::texi2pdf()` to build the pdf from the
generated .tex file. On Linux/Unix, by default, Vim calls `latexmk` `-pdf` to
produce a pdf document from the .tex file produced by either `Sweave()` or
`knit()` command. If `latexmk` is not installed, it calls `pdflatex`. You can
use the option vimrplugin_latexcmd to change this behavior. Example:
>
   let vimrplugin_latexcmd = "latex"
<
If you want to pass arguments do the `Sweave()` function, set the value of the
vimrplugin_sweaveargs variable.


6.20. Never unmake the R menu~
						*vimrplugin_never_unmake_menu*
Use this option if you want that the menu item R is not deleted when you
change from one buffer to another, for example, when going from an .R file to
a .txt one:
>
   let vimrplugin_never_unmake_menu = 1
<
When this option is enabled all menu items are created regardless of the file
type. If you have added R related tool bar buttons (see |r-plugin-toolbar|)
the buttons also are created at the plugin startup and kept while you go to
different file type buffers.


6.21. Map 'r'~
							    *vimrplugin_map_r*
If the variable |vimrplugin_map_r| exists, the plugin will map the letter 'r'
to send lines to R when there are visually selected lines, for compatibility
with the original plugin. To activate this option, insert the following into
|vimrc|:
>
   let vimrplugin_map_r = 1
<
You may want to add the following three lines to your |vimrc| which were in
Johannes Ranke's plugin and will increase compatibility with code edited with
Emacs:
>
   set expandtab
   set shiftwidth=4
   set tabstop=8
<

6.22. Add ^A^K to the beginning of commands~
							    *vimrplugin_ca_ck*
When one types <C-a> in the R Console the cursor goes to the beginning of the
line and one types <C-k> the characters to the right of the cursor are
deleted. This is useful to avoid characters left on the R Console being mixed
with commands sent by Vim. However, sending <C-a> may be problematic if using
Tmux. The Vim-R-plugin will add <C-a><C-k> to every command if you put
in your |vimrc|:
>
   let vimrplugin_ca_ck = 1
<

6.23. Open PDF after processing rnoweb, rmd or rrst files~
							  *vimrplugin_openpdf*
						  *vimrplugin_openpdf_quietly*
							 *vimrplugin_openhtml*
The plugin will try to open automatically the pdf file generated by pdflatex,
after either `Sweave()` or `knit()`, if you put in your |vimrc|:
>
   let vimrplugin_openpdf = 1
<
If you use Linux or other Unix and eventually use the system console (without
the X server) you may want to put in your |vimrc|:
>
   if $DISPLAY != ""
       let vimrplugin_openpdf = 1
   endif
<
Note: If the pdf is already open, some pdf readers will automatically update
the pdf; others will lock the pdf file and prevent R from successfully
compiling it again.

The application used to open the pdf may not be the same when the pdf is open
by R (when vimrplugin_openpdf = 1) and when you open it manually with
<LocalLeader>op key binding. If you are using Linux/Unix, you can change the
pdf reader by setting the value of the environment variable $R_PDFVIEWER. This
will affect both Vim and R.

On Linux/Unix, when vimrplugin_openpdf = 1, the application used to open the
pdf may be quite verbose, printing many lines of useless diagnostic messages
in the R Console. Put the following in your |vimrc| to inhibit these messages
(and all useful error messages):
>
   let vimrplugin_openpdf_quietly = 1
<
If editing an Rmd file, you can produce the html result with <LocalLeader>kh.
The html file will be automatically opened if you put the following in your
|vimrc|:
>
   let vimrplugin_openhtml = 1
<

6.24. Support to RreStructuredText file~
						       *vimrplugin_strict_rst*
						      *vimrplugin_rst2pdfpath*
						      *vimrplugin_rst2pdfargs*
						     *vimrplugin_rrstcompiler*
By default, the Vim-R-plugin sends the command `render_rst(strict=TRUE)` to R
before using R's `knit()` function to convert an Rrst file into an rst one. If
you prefer the non strict rst code, put the following in your |vimrc|:
>
   let vimrplugin_strict_rst = 0
<
You can also set the value of vimrplugin_rst2pdfpath (the path to rst2pdf
application), vimrplugin_rrstcompiler (the compiler argument to be passed to R
function knit2pdf), and vimrplugin_rst2pdfargs (further arguments to be passed
to R function knit2pdf).


6.25. Allow R commands in insert mode~
						 *vimrplugin_insert_mode_cmds*
Vim-R commands are designed to work in insert mode as well as normal mode.
However, depending on your <LocalLeader>, this can make it very difficult to
write R packages or Sweave files.  For example, if <LocalLeader> is set to the
`\` character, typing `\dQuote` in a .Rd file tries to send the command!

The option vimrplugin_insert_mode_cmds disables commands in insert mode.  To
use it, add the following to your |vimrc|:
>
   let g:vimrplugin_insert_mode_cmds = 0
<
The default value is 1, for consistency with earlier versions.

See also: |r-plugin-localleader|.


6.26. Show/remove hidden objects~
							 *vimrplugin_allnames*
							 *vimrplugin_rmhidden*
Hidden objects are not included in the list of objects for omni completion. If
you prefer to include them, put in your |vimrc|:
>
   let g:vimrplugin_allnames = 1
<
Hidden objects are removed from R workspace when you do <LocalLeader>rm. If
you prefer to remove only visible objects, put in your |vimrc|:
>
   let g:vimrplugin_rmhidden = 0
<

6.27. Source additional scripts~
							   *vimrplugin_source*
This variable should contain a comma separated list of Vim scripts to be
sourced by the Vim-R-plugin. These scripts may provide additional
functionality and/or change the behavior of the Vim-R-plugin. If you have such
scripts, put in your |vimrc|:
>
   let vimrplugin_source = "~/path/to/MyScript.vim,/path/to/AnotherScript.vim"
<
Currently, there are only two scripts known to extend the Vim-R-plugin
features:

   Support to the devtools R package~
   https://github.com/mllg/vim-devtools-plugin

   Basic integration with GNU screen~
   https://github.com/jalvesaq/screenR


6.28. Restart R if it is already running (Linux/Unix only)~
							  *vimrplugin_restart*
When R is already running and you type one of the commands to start R before
you have done <LocalLeader>rq, the Vim-R-plugin does one of the following:
(a) If R is in an external terminal emulator, the terminal is closed, a new
one is opened with the same R session running in it. (b) If both Vim and R are
running in different Tmux regions of the same terminal emulator, the plugin
warns that R is already running.

If instead of the default behavior, you prefer to quit and restart R when you
do <LocalLeader>rf, <LocalLeader>rv or <LocalLeader>rc, then, put in your
|vimrc|:
>
   let vimrplugin_restart = 1
<

6.29. Show extra information during omnicompletion~
							*vimrplugin_show_args*
If you want that Vim shows a preview window with the function arguments as you
do omnicompletion, put in your |vimrc|:
>
   let vimrplugin_show_args = 1
<
The preview window is not shown by default because it is more convenient to
run <Ctrl-X><Ctrl-A> to complete the function arguments. The preview window
will be shown only if "preview" is included in your 'completeopt'.


==============================================================================
						       *r-plugin-key-bindings*
7. Custom key bindings~

When creating custom key bindings for the Vim-R-plugin, it is necessary to
create three maps for most functions because the way the function is called is
different in each Vim mode. Thus, key bindings must be made for Normal mode,
Insert mode, and Visual mode.

To customize a key binding you should put in your |vimrc| something like:
>
   nmap <LocalLeader>sr <Plug>RStart
   imap <LocalLeader>sr <Plug>RStart
   vmap <LocalLeader>sr <Plug>RStart
<
The above example shows how to change key binding used to start R from
<LocalLeader>rf to <LocalLeader>sr.

Only the custom key bindings for Normal mode are shown in Vim's menu, but you
can type |:map| to see the complete list of current mappings, and below is the
list of the names for custom key bindings (the prefix RE means "echo";
RD, "cursor down"; RED, both "echo" and "down"):

   Star/Close R~
   RStart
   RVanillaStart
   RCustomStart
   RClose
   RSaveClose

   Clear R console~
   RClearAll
   RClearConsole

   Edit R code~
   RSimpleComment
   RSimpleUnComment
   RToggleComment
   RRightComment
   RCompleteArgs
   RIndent

   Send line or part of it to R~
   RSendLine
   RDSendLine
   RSendLAndOpenNewOne
   RNLeftPart
   RNRightPart
   RILeftPart
   RIRightPart

   Send code to R console~
   RSendSelection
   RESendSelection
   RDSendSelection
   REDSendSelection
   RSendMBlock
   RESendMBlock
   RDSendMBlock
   REDSendMBlock
   RSendParagraph
   RESendParagraph
   RDSendParagraph
   REDSendParagraph
   RSendFunction
   RESendFunction
   RDSendFunction
   REDSendFunction
   RSendFile
   RESendFile

   Send command to R~
   RHelp
   RPlot
   RSPlot
   RShowArgs
   RShowEx
   RShowRout
   RObjectNames
   RObjectPr
   RObjectStr
   RSetwd
   RSummary
   RListSpace

   Support to Sweave and knitr~
   RSendChunk
   RDSendChunk
   RESendChunk
   REDSendChunk
   RSendChunkFH (from the first chunk to here)
   RBibTeX    (Sweave)
   RBibTeXK   (Knitr)
   RSweave
   RKnit
   RMakeHTML
   RMakeODT
   RMakePDF   (Sweave)
   RMakePDFK  (Knitr)
   RMakePDFKb (.Rmd, beamer)
   ROpenPDF
   RSpinFile
   RMakeSlides (Slidify)

   Object browser~
   RUpdateObjBrowser
   ROpenLists
   RCloseLists

The completion of function arguments only happens in Insert mode. To customize
its keybind you should put in your |vimrc| something as in the example:
>
   imap <C-A> <Plug>RCompleteArgs
<
The plugin also contains a function called RAction which allows you to build
ad-hoc commands to R. This function takes the name of an R function such as
"levels" or "table" and the word under the cursor, and passes them to R as a
command.

For example, if your cursor is sitting on top of the object called gender and
you call the RAction function, with an argument such as levels, Vim will pass
the command `levels(gender)` to R, which will show you the levels of the object
gender.

To make it even easier to use this function, you could write a custom key
binding that would allow you to rapidly get the levels of the object under
your cursor. Add the following to your |vimrc| to have an easy way to pass R
the levels command:
>
   map <silent> <LocalLeader>rk :call RAction("levels")<CR>
   map <silent> <LocalLeader>t :call RAction("tail")<CR>
   map <silent> <LocalLeader>h :call RAction("head")<CR>
<
Then if you type <LocalLeader>rk R will receive the command
>
   levels(myObject)
<
You should replace <LocalLeader>rk with the key binding that you want to use
and "levels" with the R function that you want to call.

If the command that you want to send does not require an R object as argument,
you can create a shortcut to it by following the example:
>
   map <silent> <LocalLeader>s :call g:SendCmdToR("search()")
<
See also: |vimrplugin_source|.


==============================================================================
							      *r-plugin-files*
8. Files~

The following files are part of the plugin and should be in your ~/.vim
directory after the installation:


   ftdetect/r.vim
   indent/r.vim
   indent/rmd.vim
   indent/rrst.vim
   indent/rnoweb.vim
   indent/rhelp.vim
   autoload/rcomplete.vim
   ftplugin/r.vim
   ftplugin/rbrowser.vim
   ftplugin/rdoc.vim
   ftplugin/rhelp.vim
   ftplugin/rmd.vim
   ftplugin/rrst.vim
   ftplugin/rnoweb.vim
   syntax/rout.vim
   syntax/r.vim
   syntax/rhelp.vim
   syntax/rmd.vim
   syntax/rrst.vim
   syntax/rdoc.vim
   syntax/rbrowser.vim
   doc/r-plugin.txt
   r-plugin/vimcom.py
   r-plugin/global_r_plugin.vim
   r-plugin/windows.py
   r-plugin/objlist/README
   r-plugin/tex_indent.vim
   r-plugin/r.snippets
   r-plugin/common_buffer.vim
   r-plugin/common_global.vim
   r-plugin/vimrconfig.vim


==============================================================================
							       *r-plugin-tips*
9. FAQ and tips~

9.1. Is it possible to stop R from within Vim?~

Sorry, it is not possible. The plugin can only send the `quit()` command. If you
want to stop R, you have to press ^C into R's terminal emulator.


9.2. Html help and custom pager~

If you prefer to see help pages in an html browser, put in your ~/.Rprofile:
>
   options(help_type = "html")
<
and in your |vimrc| (see |vimrplugin_vimpager|):
>
   let vimrplugin_vimpager = "no"
<

9.3. How do marked blocks work?~
							  *r-plugin-showmarks*
Vim allows you to put several marks (bookmarks) in buffers. The most commonly
used marks are the lowercase alphabet letters. If the cursor is between any
two marks, the plugin will send the lines between them to R. If the cursor is
above the first mark, the plugin will send from the beginning of the file to
the mark. If the cursor is below the last mark, the plugin will send from the
mark to the end of the file. The mark above the cursor is included and the
mark below is excluded from the block to be sent to R. To create a mark, press
m<letter> in Normal mode.

We recommended the use of ShowMarks plugin which show what lines have marks
defined. The plugin is available at:

   http://www.vim.org/scripts/script.php?script_id=152

This plugin makes it possible to visually manage your marks. You may want to
add the following two lines to your |vimrc| to customize ShowMarks behavior:
>
   let marksCloseWhenSelected = 0
   let showmarks_include = "abcdefghijklmnopqrstuvwxyz"
<

9.4. Use snipMate~
							   *r-plugin-snippets*
You probably will want to use the snipMate plugin to insert snippets of code
in your R script. The plugin may be downloaded from:

   http://www.vim.org/scripts/script.php?script_id=2540

The snipMate plugin does not come with snippets for R, but you can copy the
files r.snippets and rmd.snippets that ship with the Vim-R-plugin (look at the
r-plugin directory) to the snippets directory. The files have only a few
snippets, but they will help you to get started. If you usually edit rnoweb
files, you may also want to create an rnoweb.snippets by concatenating both
tex.snippets and r.snippets. If you edit R documentation, you may want to
create an rhelp.snippets


9.5. Easier key bindings for most used commands~
							   *r-plugin-bindings*
The most used commands from Vim-R-plugin probably are "Send line" and "Send
selection". You may find it a good idea to map them to the space bar in your
|vimrc| (suggestion made by Iago Mosqueira):
>
   vmap <Space> <Plug>RDSendSelection
   nmap <Space> <Plug>RDSendLine
<
You may also want to remap <C-x><C-o>:

   http://stackoverflow.com/questions/2269005/how-can-i-change-the-keybinding-used-to-autocomplete-in-vim


9.6. Remap the <LocalLeader>~
							*r-plugin-localleader*
People writing Rnoweb documents may find it better to use a comma or other key
as the <LocalLeader> instead of the default backslash (see |maplocalleader|).
For example, to change the <LocalLeader> to a comma, put at the beginning of
your |vimrc| (before any mapping command):
>
   let maplocalleader = ","
<

9.7. Use a tags file to jump to function definitions~
							   *r-plugin-tagsfile*
Vim can jump to a function definition if it finds a "tags" file with the
information about the place where the function is defined. To generate the
tags file, use the R function `rtags()`, which will build an Emacs tags file.
If Vim was compiled with the feature |emacs_tags|, it will be able to read the
tags file. Otherwise, you can use the function `etags2ctags()` from the script
located at ~/.vim/r-plugin/etags2ctags.R to convert the Emacs tags file into a
Vim's one. To jump to a function definition, put the cursor over the function
name and hit CTRL-]. Please, read |tagsrch.txt| for details on how to use tags
files, specially the section |tags-option|.

You could, for example, download and unpack R's source code, start R inside
the ~/.vim directory and do the following command:
>
   rtags(path = "/path/to/R/source/code", recursive = TRUE, ofile = "RTAGS")
<
Then, you would quit R and do the following command in the terminal emulator:
>
   ctags --languages=C,Fortran,Java,Tcl -R -f RsrcTags /path/to/R/source/code
<
Finally, you would put the following in your |vimrc|, inside an |autocmd-group|:
>
   autocmd FileType r set tags+=~/.vim/RTAGS,~/.vim/RsrcTags
   autocmd FileType rnoweb set tags+=~/.vim/RTAGS,~/.vim/RsrcTags
<
Note: While defining the autocmd, the RTAGS path must be put before RsrcTags.

Example on how to test whether your setup is ok:

   1. Type `mapply()` in an R script and save the buffer.
   2. Press CTRL-] over "mapply" (Vim should jump to "mapply.R").
   3. Locate the string "do_mapply", which is the name of a C function.
   4. Press CTRL-] over "do_mapply" (Vim sould jump to "mapply.c").


9.8. Indenting setup~
							  *r-plugin-indenting*
Note: In Normal mode, type |==| to indent the current line and gg=G to format
the entire buffer (see |gg|, |=| and |G| for details). These are Vim commands;
they are not specific to R code.

The Vim-R-plugin includes a script to automatically indent R files. By
default, the script aligns function arguments if they span for multiple lines.
If you prefer do not have the arguments of functions aligned, put in your
|vimrc|:
>
   let r_indent_align_args = 0
<
By default, all lines beginning with a comment character, `#`, get the same
indentation level of the normal R code. Users of Emacs/ESS may be used to have
lines beginning with a single `#` indented in the 40th column, `##` indented as R
code, and `###` not indented. If you prefer that lines beginning with comment
characters are aligned as they are by Emacs/ESS, put in your |vimrc|:
>
   let r_indent_ess_comments = 1
<
If you prefer that lines beginning with a single # are aligned at a column
different from the 40th one, you should set a new value to the variable
r_indent_comment_column, as in the example below:
>
   let r_indent_comment_column = 30
<
By default any code after a line that ends with "<-" is indented. Emacs/ESS
does not indent the code if it is a top level function. If you prefer that the
Vim-R-plugin behaves like Emacs/ESS in this regard, put in your |vimrc|:
>
   let r_indent_ess_compatible = 1
<
Below is an example of indentation with and without this option enabled:
>
   ### r_indent_ess_compatible = 1           ### r_indent_ess_compatible = 0
   foo <-                                    foo <-
       function(x)                               function(x)
   {                                             {
       paste(x)                                      paste(x)
   }                                             }
<
Notes: (1) Not all code indented by Emacs/ESS will be indented by the
           Vim-R-plugin in the same way, and, in some circumstances it may be
           necessary to make changes in the code to get it properly indented
           by Vim (you may have to either put or remove braces and line
           breaks).
       (2) Indenting is not a file type plugin option. It is a feature defined
           in indent/r.vim. That is why it is documented in this section.


9.9. Folding setup~
							    *r-plugin-folding*
Vim has several methods of folding text (see |fold-methods| and
|fold-commands|). To enable the syntax method of folding for R files, put in
your |vimrc|:
>
   let r_syntax_folding = 1
<
With the above option, Vim will load R files with all folds closed. If you
prefer to start editing files with all folds open, put in your |vimrc|:
>
   set nofoldenable
<
Notes: (1) Enabling folding may slow down Vim. (2) Folding is not a file type
plugin option. It is a feature defined in syntax/r.vim.

Note: Indentation of R code is very slow because the indentation algorithm
sometimes goes backwards looking for an opening parenthesis or brace or for
the beginning of a `for`, `if` or `while` statement. This is necessary because
the indentation level of a given line depends on the indentation level of the
previous line, but the previous line is not always the line above. It's the
line where the statement immediately above started. Of course someone may
develop a better algorithm in the future.


9.10. Highlight chunk header as R code~

By default, Vim will highlight chunk headers of RMarkdown and
RreStructuredText with a single color. When the code is processed by knitr,
chunk headers should contain valid R code and, thus, you may want to highlight
them as such. You can do this by putting in your |vimrc|:
>
   let rrst_syn_hl_chunk = 1
   let rmd_syn_hl_chunk = 1
<

9.11. Automatically close parenthesis~

Some people want Vim automatically inserting a closing parenthesis, bracket or
brace when an open one has being typed. The page below explains how to achieve
this goal:

   http://vim.wikia.com/wiki/Automatically_append_closing_characters


9.12. Automatic line breaks~

By default, Vim breaks lines when you are typing if you reach the column
defined by the 'textwidth' option. If you prefer that Vim does not break the R
code automatically, breaking only comment lines, put in your |vimrc|:
>
   autocmd FileType r setlocal formatoptions=cq
<

9.13. Vim with 256 colors in a terminal emulator (Linux/Unix only)~

If you want 256 colors support in Vim, install the package ncurses-term. Then
put in your ~/.bashrc the lines suggested at |r-plugin-bash-setup|.
Finally, put in your |vimrc|:
>
   if &term =~ "xterm" || &term =~ "256" || $DISPLAY != ""
       set t_Co=256
   endif
   colorscheme your_preferred_color_scheme
<
You have to search the internet for color schemes supporting 256 colors,
download and copy them to ~/.vim/colors. You may use the command
|:colorscheme| to try them one by one before setting your preference in your
|vimrc|.


9.14. Run your Makefile from within R~

Do you have many Rnoweb files included in a master tex or Rnoweb file and use
a Makefile to build the pdf? You may consider it useful to put the following
line in your |vimrc|:
>
   nmap <LocalLeader>sm :update<CR>:call g:SendCmdToR('system("make")')<CR>
<

9.15. Edit your ~/.Rprofile~
							   *r-plugin-Rprofile*
You may want to edit your ~/.Rprofile in addition to considering the
suggestions of |r-plugin-R-setup| you may also want to put the following
lines in your .Rprofile if you are using Linux:
>
   grDevices::X11.options(width = 4.5, height = 4, ypos = 0,
                          xpos = 1000, pointsize = 10)
<
The `X11.options()` is used to choose the position and dimensions of the X11
graphical device. You can also install the application wmctrl and create
shortcuts in your desktop environment to the commands
>
   wmctrl -r "R Graphics" -b add,above
   wmctrl -r "R Graphics" -b remove,above
<
which will toggle the "always on top" state of the X11 device window.
Alternatively, you can right click on the X11 device window title bar and
choose "Always on top". This is useful to emulate a feature present in R IDEs
which can display R plots in a separate panel. Although we can not embed an R
graphical device in Vim, we can at least make it always visible over the
terminal emulator or the GVim window.


9.16. Debugging R functions~

The Vim-R-Plugin does not have debugging facilities, but you may want to use
the R package "debug":
>
   install.packages("debug")
   library(debug)
   mtrace(function_name)
<
Once the library is installed and loaded, you should use `mtrace(function_name)`
to enable the debugging of a function. Then, the next time that the function
is called it will enter in debugging mode. Once debugging a function, you can
hit <Enter> to evaluate the current line, `go(n)` to go to line `n` in the
function and `qqq()` to quit the function (See debug's help for details). A
useful tip is to click on the title bar of the debug window and choose "Always
on top" or a similar option provided by your desktop manager.


9.17. Turn the R-plugin into a global plugin~
							     *r-plugin-global*
The Vim-R-plugin is a file type plugin. If you want its functionality
available for all file types, then go to your ~/.vim/plugin directory and
create a symbolic link to ~/.vim/r-plugin/global_r_plugin.vim. That is, type
the following in a terminal emulator:
>
   cd ~/.vim/plugin/
   ln -s ../r-plugin/global_r_plugin.vim
<
On Windows, you probably will have to make a copy of the file to the
~/vimfiles/plugin directory.


9.18. Disable syntax highlight of R functions~

If you want to disable the syntax highlight of R functions put in your
|vimrc|:
>
   autocmd Syntax * syntax clear rFunction
<

9.19. Tips for knitr users~
							      *r-plugin-knitr*
If you are using knitr with option cache=TRUE, you may want from time to time
to delete all objects in R workspace and all files in the cache directory. If
you want to use <LocalLeader>kr in Normal mode for this, put in your |vimrc|:
>
   nmap <LocalLeader>kr :call g:SendCmdToR('rm(list=ls(all.names=TRUE)); unlink("cache/*")')<CR>
<
When generating pdfs out of Rmd-files, you can send options to pandoc. State
them in your vimrc. For example

   let vimrplugin_pandoc_args = "--toc -V lang=german"

will produce a german document with a table of contents.


9.20. Integration with LaTeX-Box~
							  *r-plugin-latex-box*
LaTeX-Box does not automatically recognize Rnoweb files as a valid LaTeX file.
You have to tell LaTeX-BoX that the .tex file compiled by either `knitr()` or
`Sweave()` is the main LaTeX file. You can do this in two ways. Suppose that
your Rnoweb file is called report.Rnw... You can:

    (1) Create an empty file called "report.tex.latexmain".

    or

    (2) Put in the first 5 lines of report.Rnw:

        % For LaTeX-Box: root = report.tex

Of course you must run either `knitr()` or `Sweave()` before trying LaTeX-Box
omnicompletion. Please, read LaTeX-Box documentation for more information.

See also: |vimrplugin_latexcmd|.


9.21. Quick setup for the Vim-R-plugin on Linux/Unix environment~
							*r-plugin-quick-setup*
Please, look at section |r-plugin-options| if you want information about the
Vim-r-plugin customization.

Here are some suggestions of configuration of Vim, Bash, Tmux and R. To
understand what you are doing, and change the configuration to your taste,
please read this document from the beginning.

   ~/.vimrc~
>
   " Minimum required configuration:
   set nocompatible
   syntax on
   filetype plugin on
   filetype indent on
   " Change Leader and LocalLeader keys:
   let maplocalleader = ","
   let mapleader = ";"
   " Use Ctrl+Space to do omnicompletion:
   if has("gui_running")
       inoremap <C-Space> <C-x><C-o>
   else
       inoremap <Nul> <C-x><C-o>
   endif
   " Press the space bar to send lines and selection to R:
   vmap <Space> <Plug>RDSendSelection
   nmap <Space> <Plug>RDSendLine
   " The lines below are suggestions for Vim in general and are not
   " specific to the improvement of the Vim-R-plugin.
   " Highlight the last searched pattern:
   set hlsearch
   " Show where the next pattern is as you type it:
   set incsearch
   " By default, Vim indents code by 8 spaces. Most people prefer 4
   " spaces:
   set sw=4
   " Search "Vim colorscheme 256" in the internet and download color
   " schemes that supports 256 colors in the terminal emulator. Then,
   " uncomment the code below to set you color scheme:
   "colorscheme not_defined
   " Use 256 colors even if in a terminal emulator:
   if &term =~ "xterm" || &term =~ "256" || $DISPLAY != ""
       set t_Co=256
   endif
<
							 *r-plugin-bash-setup*
   ~/.bashrc:~
>
   # Change the TERM environment variable (to get 256 colors) and make Vim
   # connecting to X Server even if running in a terminal emulator (to get
   # dynamic update of syntax highlight and Object Browser):
   if [ "x$DISPLAY" != "x" ]
   then
       if [ "screen" = "$TERM" ]
       then
           export TERM=screen-256color
       else
           export TERM=xterm-256color
       fi
       alias vim='vim --servername VIM'
       if [ "x$TERM" == "xxterm" ] || [ "x$TERM" == "xxterm-256color" ]
       then
           function tvim(){ tmux -2 new-session "TERM=screen-256color vim --servername VIM $@" ; }
       else
           function tvim(){ tmux new-session "vim --servername VIM $@" ; }
       fi
   else
       if [ "x$TERM" == "xxterm" ] || [ "x$TERM" == "xxterm-256color" ]
       then
           function tvim(){ tmux -2 new-session "TERM=screen-256color vim $@" ; }
       else
           function tvim(){ tmux new-session "vim $@" ; }
       fi
   fi
<

							 *r-plugin-tmux-setup*
   ~/.tmux.conf:~
>
   set-option -g prefix C-a
   unbind-key C-b
   bind-key C-a send-prefix
   set -g status off
   set-window-option -g mode-keys vi
   set -g terminal-overrides 'xterm*:smcup@:rmcup@'
   set -g mode-mouse on
   set -g mouse-select-pane on
   set -g mouse-resize-pane on
<

							    *r-plugin-R-setup*
   ~/.Rprofile~
>
   if(interactive()){
       # Get startup messages of three packages and set Vim as R pager:
       options(setwidth.verbose = 1,
               colorout.verbose = 1,
               vimcom.verbose = 1,
               pager = "vimrpager")
       # Use the text based web browser w3m to navigate through R docs:
       if(Sys.getenv("TMUX") != "")
           options(browser="~/bin/vimrw3mbrowser",
                   help_type = "html")
       # Use either Vim or GVim as text editor for R:
       if(nchar(Sys.getenv("DISPLAY")) > 1)
           options(editor = 'gvim -f -c "set ft=r"')
       else
           options(editor = 'vim -c "set ft=r"')
       # Load the colorout library:
       library(colorout)
       if(Sys.getenv("TERM") != "linux" && Sys.getenv("TERM") != ""){
           # Choose the colors for R output among 256 options.
           # You should run show256Colors() and help(setOutputColors256) to
           # know how to change the colors according to your taste:
           setOutputColors256(verbose = FALSE)
       }
       # Load the setwidth library:
       library(setwidth)
       # Load the vimcom.plus library only if R was started by Vim:
       if(Sys.getenv("VIMRPLUGIN_TMPDIR") != ""){
           library(vimcom.plus)
           # If you can't install the vimcom.plus package, do:
           # library(vimcom)
           # See R documentation on Vim buffer even if asking for help in R Console:
           if(Sys.getenv("VIM_PANE") != "")
               options(help_type = "text", pager = vim.pager)
       }
   }
<

   ~/bin/vimrpager~
>
   #!/bin/sh
   # I don't know the reason, but we can't pipe the output directly to Vim.
   # So we need this script to use 'cat' as intermediary.
   cat | vim -c 'set ft=rdoc' -
<

   ~/bin/vimrw3mbrowser~
>
   #!/bin/sh
   NCOLS=$(tput cols)
   if [ "$NCOLS" -gt "140" ]
   then
       if [ "x$VIM_PANE" = "x" ]
       then
           tmux split-window -h "w3m $1 && exit"
       else
           tmux split-window -h -t $VIM_PANE "w3m $1 && exit"
       fi
   else
       tmux new-window "w3m $1 && exit"
   fi
<

NOTES: 1. The `~/bin` diretory must be in your PATH.
       2. To use the `vimrw3mbrower` script the web browser w3m must be
          installed.
       3. You have to change `~/bin/vimrpager` and `~/bin/vimrw3mbrowser`
          permissions to make them executable:
>
   chmod +x ~/bin/vimrpager
   chmod +x ~/bin/vimrw3mbrowser
<

Finally, if you want to use vi key bindings in Bash:

   ~/.inputrc~
>
   set editing-mode vi
   set keymap vi
<

9.22. Python versions~
							     *r-plugin-python*
Are you using Windows and need to use a specific version of either Python or
pywin32? The official Vim is 32 bit and, thus, Python must be 32 bit too.
However, Vim and R run as independent processes, that is, you may have 32 bit
Vim sending commands to 64 bit R. Be careful to download the correct Python
version because Vim needs a specific version of Python DLL. For example, the
official Vim 7.4 for Windows needs either Python 2.7 or 3.2. If Python was not
installed or was not found, the Vim-R-plugin will output information about
what Python version Vim was compiled against. Do the following if you want to
discover this information manually:

   1. Type  :version  in Vim (normal mode).

   2. Look for a string like -DDYNAMIC_PYTHON_DLL="python27.dll".

   3. Install the Python version which corresponds to the version which Vim
   was linked against. In the example of step 2 (python27.dll) the required
   Python version is 2.7.x.

    * pywin32: http://sourceforge.net/projects/pywin32/


9.23. Add tool bar icons and hide unused buttons~
							    *r-plugin-toolbar*
If you want to add some R buttons to GVim tool bar download the zip file
http://www.lepem.ufc.br/jaa/bitmaps.zip and unpack it at either ~/.vim
(Unix/Linux/Mac OS X) or ~/vimfiles (Windows). You may not see the buttons
because GVim has too many buttons by default. Then, you may want to edit
GVim's toolbar and remove the buttons that you never use. Please see the page
below to know how to hide buttons on the toolbar:

   http://vim.wikia.com/wiki/Hide_toolbar_or_menus_to_see_more_text


9.24. Integration with GNU Screen, screen plugin, Conque Shell or VimShell~

The plugin used to be able to use GNU Screen (through screen plugin), Conque
Shell or VimShell to send commands to R. This integration was removed on
August 20, 2013. People wanting this integration back into the plugin may want
to use the old Vim-R-plugin code as a starting point to create scripts to be
sourced by the Vim-R-plugin. Please look at |vimrplugin_source| for details.


==============================================================================
							       *r-plugin-news*
10. News~

0.9.9.9 (2014-02-01)

 * Minor bug fixes.
 
 * Delete temporary files on VimLeave event.

 * Support to R package slidify (thanks to Michael Lerch).

 * New option: vimrplugin_rcomment_string.

0.9.9.8 (2013-11-30)

 * The list of objects for omnicompletion and the list of functions for syntax
   highlight now are built dynamically. Deprecated commands and options:
   :RUpdateObjList, :RAddLibToList, vimrplugin_buildwait. New option:
   vimrplugin_permanent_libs.

 * New options: vimrplugin_show_args.

 * New command \ch: send to R Console all R code from the first chunk up to
   this line.

 * Remove toolbar icons (they still may be added back manually by interested
   users).

 * If latexmk is installed, use it by default to compile the pdf.

0.9.9.7 (2013-11-06)

 * Minor bug fixes.

0.9.9.6 (2013-10-31)

 * Minor bug fixes.

0.9.9.5 (2013-10-12)

 * Minor bug fixes.

0.9.9.4 (2013-09-24)

 * Minor bug fixes.
 * The package now depends on vimcom.plus.
 * The support to GNU Screen, VimShell and Conque Shell was dropped. The
   screen plugin no longer is used.
 * The delete command was removed from the Object Browser.
 * New options: vimrplugin_vsplit, vimrplugin_rconsole_height and
   vimrplugin_rconsole_width.
 * New option: vimrplugin_restart.
 * Show elements of S4 objects in the Object Browser.

0.9.9.3 (2013-04-11)

 * Minor bug fixes.
 * New option: vimrplugin_source.

0.9.9.2 (2013-02-01)

 * Update vimcom version requirement to 0.9-7 (fix incompatibility with tcltk
   package on Unix).
 * Change the default value of vimrplugin_rmhidden to 0.
 * New option for Windows: vimrplugin_Rterm.
 * New simpler un/comment commands: <LocalLeader>xc and <LocalLeader>xu.
 * Remove options vimrplugin_nosingler and vimrplugin_by_vim_instance.

0.9.9.1 (2012-12-11)

 * Enable mouse on Tmux again.

0.9.9 (2012-12-03)

 * New commands:  :Rinsert  and  :Rformat.
 * Automatically update the Object Browser in GVim.
 * On MS Windows, don't raise the R Console before sending CTRL-V to it.
 * Search for vimcom in both IPv4 and IPv6 ports (thanks to Zé Loff for
   writing the patch).

0.9.8 (2012-10-13)

 * Open PDF automatically after processing Rnoweb file if
   vimrplugin_openpdf = 1 (thanks to Tomaz Ficko for suggesting the feature).
   Open it quietly if vimrplugin_openpdf_quietly = 1.
   Open it manually with \op.
 * Open HTML automatically after processing either Rmd or Rrst file if
   vimrplugin_openhtml = 1. Generate strict rst code if
   vimrplugin_strict_rst = 1.
 * Remove option vimrplugin_knitargs.
 * Start last R if there is more than one installed on Windows (thanks to Alex
   Zvoleff for reporting the bug and writing the patch).
 * Alex Zvoleff added support to Rrst file type.
 * michelk added support to Rmd file type.
 * For Rnoweb, Rmd and Rrst file types, CTRL-X CTRL-A completes knitr chunk
   options if the cursor is inside the chunk header.
 * New option: vimrplugin_rmhidden.
 * New option: vimrplugin_insert_mode_cmds (thanks to Charles R. Hogg III).
 * New command  :RAddLibToList  to add the objects of specific libraries to
   omnicompletion.
 * Thanks to genrich and NagatoPain for other bug fixes and code improvements.
 * New option: vimrplugin_assign_map. The option vimrplugin_underscore was
   renamed to vimrplugin_assign

0.9.7 (2012-05-04)

 * Use the R package vimcom:
     - Automatic update of the Object Browser when running R in a Tmux
       session.
     - The following options are now set on the vimcom R package and no longer
       in the Vim-R-plugin: allnames, open_df, and open_list.
     - New command in normal and visual modes when on the Object Browser: "d"
       deletes objects and detach libraries. New option: vimrplugin_ob_sleep.
 * New option, vimrplugin_external_ob, to open the Object Browser in a Tmux
   pane in the external terminal running R.
 * New command  :Rhelp (thanks for Nir Atias for suggesting the new feature).
 * Remove the command  :RUpdateObjListAll  because Vim may not load the
   syntax file if it is too big.
 * Add support to knitr package.
 * New command  :RSourceDir.
 * New key bindings \r<Left> and \r<Right>.
 * Correctly send selected blocks.

0.9.6 (2011-12-13)

 * Fix path to R source() command on Windows.
 * New default value of vimrplugin_vimpager = "tab".
 * New default value of vimrplugin_objbr_place = "editor,right"
 * Autocompletion of function arguments with <C-X><C-A>.

0.9.5 (2011-12-07)

 * Changed the way that blocks are sent to R.
 * Added "terminal" to the list of known terminal emulators (thanks for "i5m"
   for the patch).
 * Use Tmux to start the Object Browser beside the R console if
   vimrplugin_objbr_place =~ "console".
 * The file r-plugin/omniList was renamed to r-plugin/omnils because its
   field separator changed.

111114 (2011-11-14)
 * Changed key binding for commenting/uncommenting code from \cc to \xx.
 * Added function SendChunkToR() and its corresponding key bindings:
   \cc, \ce, \cd and \ca (thanks to Xavier Fernández i Marín for suggesting
   the feature).
 * New option (vimrplugin_ca_ck) was created to fix bug reported by Xavier
   Fernández i Marín: spurious ^A^K being added to lines sent to R.
 * Don't blink the menu and toolbar buttons when doing omni completion.
 * Use Tmux to run R in an external terminal emulator.

111014 (2011-10-14)
 * Fixed spell check bug in R documentation files (.Rd).
 * Fixed beep bug when sending commands to R.
 * New option: vimrplugin_notmuxconf.
 * Fixed bug when starting tmux before vim: the environment variable
   VIMRPLUGIN_TMPDIR was not being set. Thanks to Michel Lang for reporting
   the bug and helping to track its source, and thanks to Eric Dewoestine for
   explaining how to fix the bug.
 * Fixed bug in code indentation after unbalanced brackets and parenthesis
   when r_indent_align_args = 0 (thanks to Chris Neff and Peng Yu for
   reporting the bugs).
 * Really make the use of AppleScript the default on OS X (thanks for Jason
   for reporting the bug).

110805 (2011-08-05)
 * New option: vimrplugin_tmux.
 * Set Tmux as the default instead of either GNU Screen or Conque Shell.
 * Document Tmux as the preferred way of running the plugin on Linux.
 * Vim-LaTeX-suite plugin can be used with Rnoweb files without any additional
   configuration. The necessary code was added to the ftplugin/rnoweb.vim.
 * Added count argument to normal mode commands gn and gN (thanks to Ivan
   Bezerra for the suggestion).

110614 (2011-06-14)
 * When doing the command \rh, the plugin tries to show the help for the
   method corresponding to the class of the object passed as argument to the
   function. The same with \rp (thanks to Thomas Scheike for suggesting the
   feature).
 * Removed script rpager.sh.
 * Added script global_r_plugin.vim to allow the use of the plugin with any
   file type.

110222 (2011-02-22)
 * Added syntax/rhelp.vim.
 * New command for rnoweb files: BibTeX current file (\sb).
 * New commands for the object browser: open visible lists (\r=) and close
   visible lists (\r-).
 * Reorganization of the GUI menu.

110208 (2011-02-08)
 * Fixed bug in "else if" constructions (thanks to Dan Kelley for reporting
   the bug).
 * Support for commenting/uncommenting lines.

110203 (2011-02-03)
 * Fixed bug in  :RUpdateObjList  when the function arguments included S4
   objects (thanks to Gerhard Schoefl for reporting the bug).
 * Improvements in indentation of R code (thanks to Dan Kelley for finding and
   reporting indentation bugs and testing many versions of indent/r.vim).
 * New indentation options: r_indent_align_args, r_indent_ess_comments,
   r_indent_comment_column, and r_indent_ess_compatible.
 * New file: indent/rhelp.vim.

110117 (2011-01-17)
 * Fixed indentation bug in Rnoweb files (thanks to Dan Kelley for reporting
   the bug).

101217 (2010-12-17)
 * Renamed the function SendCmdToScreen to SendCmdToR.
 * Clear the current line in the R console before sending a new line.
 * Always starts R on the script's directory.
 * Don't send "^@$" as part of a paragraph in rnoweb files (thanks to Fabio
   Correa for reporting the bug).
 * More useful warning message when PyWin32 isn't installed.
 * Initial support to AppleScript on Mac OS X (thanks to Vincent Nijs for
   writing and testing the code).

101121 (2010-11-21)
 * Fix for when whoami returns domain name on Windows (thanks to "Si" for
   fixing the bug).

101118 (2010-11-18)
 * New command:  :RUpdateObjListAll.
 * New option: vimrplugin_allnames.
 * Allow the use of Python 3.1 on Windows.
 * Minor improvements in indentation of R code.
 * The file r-plugin/omni_list was renamed to r-plugin/omniList because its
   field separator changed to ";".
 * Fixed bug that was causing ^H to be exhibited in the R documentation in
   some systems. (Thanks to Helge Liebert for reporting the problem).

101107 (2010-11-07)
 * New feature: complete chunk block when '<' is pressed in rnoweb files.
 * New option: vimrplugin_rnowebchunk.
 * New key bindings in Normal mode for Rnoweb files: gn (go to next R code
   chunk) and gN (go to previous R code chunk).
 * New command:  :RBuildTags.
 * Added fold capability to syntax/r.vim.
 * Improved indentation of rnoweb files: thanks to Johannes Tanzler for
   writing the tex.vim indent script and for permitting its inclusion in the
   Vim-R-plugin.
 * R CMD BATCH now is called with --no-restore --no-save (key binding \ro).
 * The file r-plugin/omnilist now has an additional field and was renamed as
   omni_list.
 * Use 64 bit version of R by default on Windows if the directory bin/x64
   exists.
 * New Windows only option: vimrplugin_i386.

101025 (2010-10-25)
 * New option: vimrplugin_routmorecolors.
 * Fixed bug in the Object Browser when a data.frame or list had just one
   element (thanks to Jan Larres for reporting the bug).
 * Do not copy omnilist and functions.vim to ~/.vim/r-plugin if the directory
   where the plugin is installed is writable (thanks to Jan Larres for the
   suggestion).

101023 (2010-10-23)
 * New options: vimrplugin_objbr_place and vimrplugin_objbr_w.
 * New default value: vimrplugin_vimpager = "vertical"
 * The R help can now be seen in a Vim buffer on MS Windows.
 * Fix width of help text when R version >= 2.12.0.
 * Implemented actions in the Object Browser: summary, print, etc...
 * Browse libraries objects in Object Browser.

101016 (2010-10-16)
 * Minor bug fixes in the Object Browser.

101015 (2010-10-15)
 * New feature: Object Browser.
 * Conque Shell will be used if installed unless explicitly told otherwise in
   the vimrc.
 * New valid value for vimrplugin_vimpager: "tabnew"

100923 (2010-09-23)
 * New option: vimrplugin_vimpager.
 * Do not let Vim translate "File" in R menu.
 * Fixed bug when the option vimrplugin_r_path was used (thanks to Asis Hallab
   for reporting the bug),
 * Fixed bug (E687) when user created custom key binding (thanks to Philippe
   Glaziou for reporting the bug).

100917 (2010-09-17)
 * Changed the use of vimrplugin_r_path: now the option includes only the
   directory part of the path.
 * Initial support to Conque Shell plugin. Thanks to "il_principe orange" for
   suggesting the use of Conque Shell, "ZyX-I" for writing the initial code to
   use Conque Shell, and Nico Raffo for writing the plugin and additional code
   to integrate both plugins.
 * New options: vimrplugin_conqueplugin and vimrplugin_conquevsplit.
 * New option: vimrplugin_r_args.
 * Fixed bug when the plugin was installed in a directory other than ~/.vim
   (thanks to Tom Link).
 * Initial support for Vim-R communication on Windows using Python.

100825 (2010-08-25)
 * Minor improvements in syntax highlighting.
 * New option: vimrplugin_buildwait.
 * New option: vimrplugin_r_path (thanks to Asis Hallab).

100803 (2010-08-03)
 * Fixed bug in .Rsource name making in some systems.

100801 (2010-08-01)
 * Dropped options vimrplugin_hstart and vimrplugin_browser_time.
 * If ~/.vim/r-plugin/functions.vim is not found, try to copy it from
   /usr/share/vim/addons/r-plugin/functions.vim.
 * Minor bug fixes.

100730 (2010-07-30)
 * Added menu item and key binding for run "R CMD BATCH" and open the
   resulting ".Rout" file.
 * Fixed bug when more than one Vim instance used the same file to send
   multiple lines of code to R (thanks to Bart for reporting the bug).

100728 (2010-07-28)
 * Adapted the plugin to allow the creation of a Debian package.

100719 (2010-07-19)
 * Added options vimrplugin_listmethods and vimrplugin_specialplot.
 * Improved syntax highlight of R batch output (.Rout files).
 * No longer uses the external programs grep, awk and sed to build the
   additional syntax file containing the list of functions.

100710 (2010-07-10)
 * Fixed :RUpdateObjList bug when list had length 0.

100707 (2010-07-07)
 * Fixed 'E329: No menu "R"' when more than one file were loaded simultaneously
   by calling vim with either -p or -o parameters. Thanks to Peng Yu for
   reporting the bug.
 * Correctly recognize a newly created file with extension ".R" as an R script
   file.

100521 (2010-05-12)
 * Replaced "-t" with "--title" to make xfce4-terminal work again.

100512 (2010-05-12)
 * Thanks to Tortonesi Mauro who wrote a patch to make the plugin work with
   pathogen.vim.
 * Added simple syntax highlight for .Rout files.
 * Increased the time limit of RUpdateObjList to two minutes.
 * Improvement in the syntax highlight based on code written by Zhuojun Chen.
 * Thanks to Scott Kostyshak who helped to improve the documentation.
 * Iago Mosqueira suggested that the plugin should be able to run one R process
   for each Vim instance, and his suggestion was implemented with the option
   vimrplugin_by_vim_instance.

091223 (2009-12-23)
 * Syntax highlight for R functions.
 * Added "info" field to omni completion (thanks to Ben Kujala for writing the
   original code).

091016 (2009-10-16)
 * The plugin now can run together with screen.vim, thanks to Eric Van
   Dewoestine, the author of screen.vim, who added script integration to
   screen.vim.
 * Andy Choens has made many improvements on the documentation.
 * Added the possibility of custom key binding creation to call any R function
   with the word under cursor as argument.
 * The key bindings related with Sweave are activated even if the file type is
   not rnoweb.
 * Replaced <Leader> with <LocalLeader> in the key bindings.
 * Added "Send Paragraph" commands.

091004 (2009-10-04)
 * Jose Claudio Faria has begun to work in the project as co-author.
 * Some ideas from Tinn-R project were ported to the plugin.
 * The main menu has new items and the toolbar new icons.
 * Documentation improvements.

090828 (2009-08-28)
 * Faster startup.
 * Better support for Rnoweb files: the cursor goes to '^<<' if the sent line
   is '^@$'.

090811 (2009-08-12)
 * Now use screen instead of funnel.pl. The bugs and limitations related with
   funnel.pl are solved.
 * Deleted key binding for R-devel.
 * Automatically detect available terminal emulators and choose one of them.
 * By default, no longer calls help.start() the first time that CTRL-H is
   pressed.

090810 (2009-08-10)
 * Added R icons for some terminal emulators.
 * Removed the script open-gvim-here. You may use Vim's option autochdir.
 * Added option vimrplugin_term.
 * Improved indentation script.
 * Changed key binding from Shift-Enter, which doesn't work in any terminal, to
   Alt-Enter, which at least works in xterm.

090610 (2009-06-11)
 * The options expandtab, shiftwidth and tabstop are no longer set by the plugin.
 * Better word detection before calling R's help().
 * Fixed bug in underscore replacement.
 * Fixed small bug in code indentation.
 * Added script rpager.sh.
 * Added two new plugin options: no underscore replacement and fixed name for
   the pipe file instead of random one.

090523 (2009-05-23)
 * Key bindings now are customizable.
 * Default key binding for calling R's args() changed to Shift-F1.
 * New R script rargs.R gives better results for generic functions than R's
   args() called directly.

090519 (2009-05-20)
 * Don't send large blocks of code to R to avoid xterm freezing.
 * Automatically call help.start() after CTRL-H is pressed for the first time,
   and wait 4 seconds for the browser start before calling R's help(). These
   features are customizable.
 * Fixed tags file script.

090516 (2009-05-16)
 * Added documentation.
 * Added ability to send function to R, revert the automatic conversion of "_"
   into "<-" and call R's help().
 * Added archive with some files to ease desktop integration, if desired.

090507 (2009-05-08)
 * Initial upload

vim:tw=78:ts=8:ft=help:norl
ftdetect/r.vim	[[[1
21

if exists("disable_r_ftplugin")
  finish
endif

autocmd BufNewFile,BufRead *.Rprofile set ft=r
autocmd BufRead *.Rhistory set ft=r
autocmd BufNewFile,BufRead *.r set ft=r
autocmd BufNewFile,BufRead *.R set ft=r
autocmd BufNewFile,BufRead *.s set ft=r
autocmd BufNewFile,BufRead *.S set ft=r

autocmd BufNewFile,BufRead *.Rout set ft=rout
autocmd BufNewFile,BufRead *.Rout.save set ft=rout
autocmd BufNewFile,BufRead *.Rout.fail set ft=rout

autocmd BufNewFile,BufRead *.Rrst set ft=rrst
autocmd BufNewFile,BufRead *.rrst set ft=rrst

autocmd BufNewFile,BufRead *.Rmd set ft=rmd
autocmd BufNewFile,BufRead *.rmd set ft=rmd
ftplugin/r.vim	[[[1
140
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for R files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          
"          Based on previous work by Johannes Ranke
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_r_ftplugin") || exists("disable_r_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_r_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Don't do this if called by ../r-plugin/common_global.vim
if &filetype == "r"
    setlocal commentstring=#%s
    setlocal comments=b:#,b:##,b:###,b:#'
endif

" Source scripts common to R, Rnoweb, Rhelp, Rmd, Rrst and rdoc files:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rnoweb, Rhelp, Rmd, Rrst and rdoc files
" need be defined after the global ones:
runtime r-plugin/common_buffer.vim

setlocal iskeyword=@,48-57,_,.

" Run R CMD BATCH on current file and load the resulting .Rout in a split
" window
function! ShowRout()
    let routfile = expand("%:r") . ".Rout"
    if bufloaded(routfile)
        exe "bunload " . routfile
        call delete(routfile)
    endif

    " if not silent, the user will have to type <Enter>
    silent update
    if has("win32") || has("win64")
        let rcmd = 'Rcmd.exe BATCH --no-restore --no-save "' . expand("%") . '" "' . routfile . '"'
    else
        let rcmd = b:rplugin_R . " CMD BATCH --no-restore --no-save '" . expand("%") . "' '" . routfile . "'"
    endif
    echo "Please wait for: " . rcmd
    let rlog = system(rcmd)
    if v:shell_error && rlog != ""
        call RWarningMsg('Error: "' . rlog . '"')
        sleep 1
    endif

    if filereadable(routfile)
        if g:vimrplugin_routnotab == 1
            exe "split " . routfile
        else
            exe "tabnew " . routfile
        endif
        set filetype=rout
    else
        call RWarningMsg("The file '" . routfile . "' is not readable.")
    endif
endfunction

" Convert R script into Rmd, md and, then, html.
function! RSpin()
    update
    call RSetWD()
    call g:SendCmdToR('require(knitr); spin("' . expand("%:t") . '")')
endfunction

" Default IsInRCode function when the plugin is used as a global plugin
function! DefaultIsInRCode(vrb)
    return 1
endfunction

"==========================================================================
" Key bindings and menu items

let b:IsInRCode = function("DefaultIsInRCode")

call RCreateStartMaps()
call RCreateEditMaps()

" Only .R files are sent to R
call RCreateMaps("ni", '<Plug>RSendFile',     'aa', ':call SendFileToR("silent")')
call RCreateMaps("ni", '<Plug>RESendFile',    'ae', ':call SendFileToR("echo")')
call RCreateMaps("ni", '<Plug>RShowRout',     'ao', ':call ShowRout()')

" Knitr::spin
" -------------------------------------
call RCreateMaps("ni", '<Plug>RSpinFile',     'ks', ':call RSpin()')

call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Sweave (cur file)
"-------------------------------------
if &filetype == "rnoweb"
    call RCreateMaps("nvi", '<Plug>RSweave',      'sw', ':call RSweave()')
    call RCreateMaps("nvi", '<Plug>RMakePDF',     'sp', ':call RMakePDF("nobib")')
    call RCreateMaps("nvi", '<Plug>RIndent',      'si', ':call RnwToggleIndentSty()')
endif


" Menu R
if has("gui_running")
    call MakeRMenu()
endif

call RSourceOtherScripts()

let &cpo = s:cpo_save
unlet s:cpo_save

ftplugin/rbrowser.vim	[[[1
387
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for RBrowser files (created by the Vim-R-plugin)
"
" Author: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_ftplugin")
    finish
endif

let g:rplugin_upobcnt = 0

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Source scripts common to R, Rnoweb, Rhelp and rdoc files:
runtime r-plugin/common_global.vim

" Some buffer variables common to R, Rnoweb, Rhelp and rdoc file need be
" defined after the global ones:
runtime r-plugin/common_buffer.vim

setlocal noswapfile
setlocal buftype=nofile
setlocal nowrap
setlocal iskeyword=@,48-57,_,.

if !exists("g:rplugin_hasmenu")
    let g:rplugin_hasmenu = 0
endif

" Popup menu
if !exists("g:rplugin_hasbrowsermenu")
    let g:rplugin_hasbrowsermenu = 0
endif

" Current view of the object browser: .GlobalEnv X loaded libraries
let g:rplugin_curview = "GlobalEnv"


function! UpdateOB(what)
    if a:what == "both"
        let wht = g:rplugin_curview
    else
        let wht = a:what
    endif
    if g:rplugin_curview != wht
        return "curview != what"
    endif
    if g:rplugin_upobcnt
        echoerr "OB called twice"
        return "OB called twice"
    endif
    let g:rplugin_upobcnt = 1

    let g:rplugin_switchedbuf = 0
    if $TMUX_PANE == ""
        redir => s:bufl
        silent buffers
        redir END
        if s:bufl !~ "Object_Browser"
            let g:rplugin_upobcnt = 0
            return "Object_Browser not listed"
        endif
        if exists("g:rplugin_curbuf") && g:rplugin_curbuf != "Object_Browser"
            let savesb = &switchbuf
            set switchbuf=useopen,usetab
            sil noautocmd sb Object_Browser
            let g:rplugin_switchedbuf = 1
        endif
    endif

    setlocal modifiable
    let curline = line(".")
    let curcol = col(".")
    if !exists("curline")
        let curline = 3
    endif
    if !exists("curcol")
        let curcol = 1
    endif
    let save_unnamed_reg = @@
    sil normal! ggdG
    let @@ = save_unnamed_reg 
    if wht == "GlobalEnv"
        let fcntt = readfile($VIMRPLUGIN_TMPDIR . "/globenv_" . $VIMINSTANCEID)
    else
        let fcntt = readfile($VIMRPLUGIN_TMPDIR . "/liblist_" . $VIMINSTANCEID)
    endif
    call setline(1, fcntt)
    call cursor(curline, curcol)
    if bufname("%") =~ "Object_Browser" || b:rplugin_extern_ob
        setlocal nomodifiable
    endif
    redraw
    if g:rplugin_switchedbuf
        exe "sil noautocmd sb " . g:rplugin_curbuf
        exe "set switchbuf=" . savesb
    endif
    let g:rplugin_upobcnt = 0
    return "End of UpdateOB()"
endfunction

function! RBrowserDoubleClick()
    " Toggle view: Objects in the workspace X List of libraries
    if line(".") == 1
        if g:rplugin_curview == "libraries"
            let g:rplugin_curview = "GlobalEnv"
            call UpdateOB("GlobalEnv")
        else
            let g:rplugin_curview = "libraries"
            call UpdateOB("libraries")
        endif
        return
    endif

    " Toggle state of list or data.frame: open X closed
    let key = RBrowserGetName(0, 1)
    if g:rplugin_curview == "GlobalEnv"
        exe 'Py SendToVimCom("' . "\005" . key . '")'
        if g:rplugin_lastrpl == "R is busy."
            call RWarningMsg("R is busy.")
        endif
    else
        let key = substitute(key, '`', '', "g") 
        if key !~ "^package:"
            let key = "package:" . RBGetPkgName() . '-' . key
        endif
        exe 'Py SendToVimCom("' . "\005" . key . '")'
        if g:rplugin_lastrpl == "R is busy."
            call RWarningMsg("R is busy.")
        endif
    endif
    if v:servername == "" || has("win32") || has("win64")
        sleep 50m " R needs some time to write the file.
        call UpdateOB("both")
    endif
endfunction

function! RBrowserRightClick()
    if line(".") == 1
        return
    endif

    let key = RBrowserGetName(1, 0)
    if key == ""
        return
    endif

    let line = getline(".")
    if line =~ "^   ##"
        return
    endif
    let isfunction = 0
    if line =~ "(#.*\t"
        let isfunction = 1
    endif

    if g:rplugin_hasbrowsermenu == 1
        aunmenu ]RBrowser
    endif
    let key = substitute(key, '\.', '\\.', "g")
    let key = substitute(key, ' ', '\\ ', "g")

    exe 'amenu ]RBrowser.summary('. key . ') :call RAction("summary")<CR>'
    exe 'amenu ]RBrowser.str('. key . ') :call RAction("str")<CR>'
    exe 'amenu ]RBrowser.names('. key . ') :call RAction("names")<CR>'
    exe 'amenu ]RBrowser.plot('. key . ') :call RAction("plot")<CR>'
    exe 'amenu ]RBrowser.print(' . key . ') :call RAction("print")<CR>'
    amenu ]RBrowser.-sep01- <nul>
    exe 'amenu ]RBrowser.example('. key . ') :call RAction("example")<CR>'
    exe 'amenu ]RBrowser.help('. key . ') :call RAction("help")<CR>'
    if isfunction
        exe 'amenu ]RBrowser.args('. key . ') :call RAction("args")<CR>'
    endif
    popup ]RBrowser
    let g:rplugin_hasbrowsermenu = 1
endfunction

function! RBGetPkgName()
    let lnum = line(".")
    while lnum > 0
        let line = getline(lnum)
        if line =~ '.*##[0-9a-zA-Z\.]*\t'
            let line = substitute(line, '.*##\(.*\)\t', '\1', "")
            return line
        endif
        let lnum -= 1
    endwhile
    return ""
endfunction

function! RBrowserFindParent(word, curline, curpos)
    let curline = a:curline
    let curpos = a:curpos
    while curline > 1 && curpos >= a:curpos
        let curline -= 1
        let line = substitute(getline(curline), "	.*", "", "")
        let curpos = stridx(line, '[#')
        if curpos == -1
            let curpos = stridx(line, '<#')
            if curpos == -1
                let curpos = a:curpos
            endif
        endif
    endwhile

    if g:rplugin_curview == "GlobalEnv"
        let spacelimit = 3
    else
        if s:isutf8
            let spacelimit = 10
        else
            let spacelimit = 6
        endif
    endif
    if curline > 1
        let line = substitute(line, '^.\{-}\(.\)#', '\1#', "")
        let line = substitute(line, '^ *', '', "")
        if line =~ " " || line =~ '^.#[0-9]'
            let line = substitute(line, '\(.\)#\(.*\)$', '\1#`\2`', "")
        endif
        if line =~ '<#'
            let word = substitute(line, '.*<#', "", "") . '@' . a:word
        else
            let word = substitute(line, '.*\[#', "", "") . '$' . a:word
        endif
        if curpos != spacelimit
            let word = RBrowserFindParent(word, line("."), curpos)
        endif
        return word
    else
        " Didn't find the parent: should never happen.
        let msg = "R-plugin Error: " . a:word . ":" . curline
        echoerr msg
    endif
    return ""
endfunction

function! RBrowserCleanTailTick(word, cleantail, cleantick)
    let nword = a:word
    if a:cleantick
        let nword = substitute(nword, "`", "", "g")
    endif
    if a:cleantail
        let nword = substitute(nword, '[\$@]$', '', '')
        let nword = substitute(nword, '[\$@]`$', '`', '')
    endif
    return nword
endfunction

function! RBrowserGetName(cleantail, cleantick)
    let line = getline(".")
    if line =~ "^$"
        return ""
    endif

    let curpos = stridx(line, "#")
    let word = substitute(line, '.\{-}\(.#\)\(.\{-}\)\t.*', '\2\1', '')
    let word = substitute(word, '\[#$', '$', '')
    let word = substitute(word, '<#$', '@', '')
    let word = substitute(word, '.#$', '', '')

    if word =~ ' ' || word =~ '^[0-9]'
        let word = '`' . word . '`'
    endif

    if (g:rplugin_curview == "GlobalEnv" && curpos == 4) || (g:rplugin_curview == "libraries" && curpos == 3)
        " top level object
        let word = substitute(word, '\$\[\[', '[[', "g")
        let word = RBrowserCleanTailTick(word, a:cleantail, a:cleantick)
        if g:rplugin_curview == "libraries"
            return "package:" . substitute(word, "#", "", "")
        else
            return word
        endif
    else
        if g:rplugin_curview == "libraries"
            if s:isutf8
                if curpos == 11
                    let word = RBrowserCleanTailTick(word, a:cleantail, a:cleantick)
                    let word = substitute(word, '\$\[\[', '[[', "g")
                    return word
                endif
            elseif curpos == 7
                let word = RBrowserCleanTailTick(word, a:cleantail, a:cleantick)
                let word = substitute(word, '\$\[\[', '[[', "g")
                return word
            endif
        endif
        if curpos > 4
            " Find the parent data.frame or list
            let word = RBrowserFindParent(word, line("."), curpos - 1)
            let word = RBrowserCleanTailTick(word, a:cleantail, a:cleantick)
            let word = substitute(word, '\$\[\[', '[[', "g")
            return word
        else
            " Wrong object name delimiter: should never happen.
            let msg = "R-plugin Error: (curpos = " . curpos . ") " . word
            echoerr msg
            return ""
        endif
    endif
endfunction

function! MakeRBrowserMenu()
    let g:rplugin_curbuf = bufname("%")
    if g:rplugin_hasmenu == 1
        return
    endif
    menutranslate clear
    call RControlMenu()
    call RBrowserMenu()
endfunction

function! ObBrBufUnload()
    if exists("g:rplugin_editor_sname")
        call system("tmux select-pane -t " . g:rplugin_vim_pane)
    endif
endfunction

function! SourceObjBrLines()
    exe "source " . g:rplugin_esc_tmpdir . "/objbrowserInit"
endfunction

nmap <buffer><silent> <CR> :call RBrowserDoubleClick()<CR>
nmap <buffer><silent> <2-LeftMouse> :call RBrowserDoubleClick()<CR>
nmap <buffer><silent> <RightMouse> :call RBrowserRightClick()<CR>

call RControlMaps()

setlocal winfixwidth
setlocal bufhidden=wipe

if has("gui_running")
    call RControlMenu()
    call RBrowserMenu()
endif

au BufEnter <buffer> stopinsert

if $TMUX_PANE == ""
    au BufUnload <buffer> Py SendToVimCom("\x08Stop updating info [OB BufUnload].")
else
    au BufUnload <buffer> call ObBrBufUnload()
    " Fix problems caused by some plugins
    if exists("g:loaded_surround")
        nunmap ds
    endif
    if exists("g:loaded_showmarks ")
        autocmd! ShowMarks
    endif
endif

let s:envstring = tolower($LC_MESSAGES . $LC_ALL . $LANG)
if s:envstring =~ "utf-8" || s:envstring =~ "utf8"
    let s:isutf8 = 1
else
    let s:isutf8 = 0
endif
unlet s:envstring

call setline(1, ".GlobalEnv | Libraries")

call RSourceOtherScripts()

let &cpo = s:cpo_save
unlet s:cpo_save

ftplugin/rdoc.vim	[[[1
105
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for R files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          
"          Based on previous work by Johannes Ranke
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_rdoc_ftplugin") || exists("disable_r_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_rdoc_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Source scripts common to R, Rnoweb, Rhelp and rdoc files:
runtime r-plugin/common_global.vim

" Some buffer variables common to R, Rnoweb, Rhelp and rdoc file need be
" defined after the global ones:
runtime r-plugin/common_buffer.vim

setlocal iskeyword=@,48-57,_,.

" Prepare R documentation output to be displayed by Vim
function! FixRdoc()
    let lnr = line("$")
    for i in range(1, lnr)
        call setline(i, substitute(getline(i), "_\010", "", "g"))
        " A space after 'Arguments:' is necessary for correct syntax highlight
        " of the first argument
        call setline(i, substitute(getline(i), "^Arguments:", "Arguments: ", ""))
    endfor
    let has_ex = search("^Examples:$")
    if has_ex
        let lnr = line("$") + 1
        call setline(lnr, '###')
    endif
    normal! gg

    " Clear undo history
    let old_undolevels = &undolevels
    set undolevels=-1
    exe "normal a \<BS>\<Esc>"
    let &undolevels = old_undolevels
    unlet old_undolevels
endfunction

function! RdocIsInRCode(vrb)
    let exline = search("^Examples:$", "bncW")
    if exline > 0 && line(".") > exline
        return 1
    else
        if a:vrb
            call RWarningMsg('Not in the "Examples" section.')
        endif
        return 0
    endif
endfunction

"==========================================================================
" Key bindings and menu items

let b:IsInRCode = function("RdocIsInRCode")

call RCreateSendMaps()
call RControlMaps()

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

call RSourceOtherScripts()

setlocal bufhidden=wipe
setlocal noswapfile
set buftype=nofile
autocmd VimResized <buffer> let g:vimrplugin_newsize = 1
call FixRdoc()
autocmd FileType rdoc call FixRdoc()

let &cpo = s:cpo_save
unlet s:cpo_save

ftplugin/rhelp.vim	[[[1
81
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for R files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          
"          Based on previous work by Johannes Ranke
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_rhelp_ftplugin") || exists("disable_r_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_rhelp_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Source scripts common to R, Rnoweb, Rhelp and rdoc files:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rnoweb, Rhelp and rdoc file need be
" defined after the global ones:
runtime r-plugin/common_buffer.vim

setlocal iskeyword=@,48-57,_,.

function! RhelpIsInRCode(vrb)
    let lastsec = search('^\\[a-z][a-z]*{', "bncW")
    let secname = getline(lastsec)
    if line(".") > lastsec && (secname =~ '^\\usage{' || secname =~ '^\\examples{' || secname =~ '^\\dontshow{' || secname =~ '^\\dontrun{' || secname =~ '^\\donttest{' || secname =~ '^\\testonly{')
        return 1
    else
        if a:vrb
            call RWarningMsg("Not inside an R section.")
        endif
        return 0
    endif
endfunction

"==========================================================================
" Key bindings and menu items

let b:IsInRCode = function("RhelpIsInRCode")

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

call RSourceOtherScripts()

let &cpo = s:cpo_save
unlet s:cpo_save

ftplugin/rmd.vim	[[[1
241
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for Rmd files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          Alex Zvoleff (adjusting for rmd by Michel Kuhlmann)
"
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_rmd_ftplugin") || exists("disable_r_ftplugin") || exists("b:did_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_rmd_ftplugin = 1

runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
unlet! b:did_ftplugin

setlocal comments=fb:*,fb:-,fb:+,n:> commentstring=>\ %s
setlocal formatoptions+=tcqln
setlocal formatlistpat=^\\s*\\d\\+\\.\\s\\+\\\|^\\s*[-*+]\\s\\+
setlocal iskeyword=@,48-57,_,.

let s:cpo_save = &cpo
set cpo&vim

" Enables pandoc if it is installed
runtime ftplugin/pandoc.vim

" Source scripts common to R, Rrst, Rnoweb, Rhelp and Rdoc:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rmd, Rrst, Rnoweb, Rhelp and Rdoc need to
" be defined after the global ones:
runtime r-plugin/common_buffer.vim

function! RmdIsInRCode(vrb)
    let chunkline = search("^[ \t]*```[ ]*{r", "bncW")
    let docline = search("^[ \t]*```$", "bncW")
    if chunkline > docline && chunkline != line(".")
        return 1
    else
        if a:vrb
            call RWarningMsg("Not inside an R code chunk.")
        endif
        return 0
    endif
endfunction

function! RmdPreviousChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let curline = line(".")
        if RmdIsInRCode(0)
            let i = search("^[ \t]*```[ ]*{r", "bnW")
            if i != 0
                call cursor(i-1, 1)
            endif
        endif
        let i = search("^[ \t]*```[ ]*{r", "bnW")
        if i == 0
            call cursor(curline, 1)
            call RWarningMsg("There is no previous R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RmdNextChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let i = search("^[ \t]*```[ ]*{r", "nW")
        if i == 0
            call RWarningMsg("There is no next R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RMakeHTMLrmd(t)
    call RSetWD()
    update
    let rcmd = 'require(knitr); knit2html("' . expand("%:t") . '")'
    if a:t == "odt"
        if g:rplugin_has_soffice == 0
            if has("win32") || has("win64")
                let soffbin = "soffice.exe"
            else
                let soffbin = "soffice"
            endif
            if executable(soffbin)
                let g:rplugin_has_soffice = 1
            else
                call RWarningMsg("Is Libre Office installed? Cannot convert into ODT: '" . soffbin . "' not found.")
            endif
        endif
        let rcmd = rcmd . '; system("' . soffbin . ' --invisible --convert-to odt ' . expand("%:r:t") . '.html")'
    endif
    if g:vimrplugin_openhtml && a:t == "html"
        let rcmd = rcmd . '; browseURL("' . expand("%:r:t") . '.html")'
    endif
    call g:SendCmdToR(rcmd)
endfunction

function! RMakeSlidesrmd()
    call RSetWD()
    update
    let rcmd = 'require(slidify); slidify("' . expand("%:t") . '")'
    if g:vimrplugin_openhtml
        let rcmd = rcmd . '; browseURL("' . expand("%:r:t") . '.html")'
    endif
    call g:SendCmdToR(rcmd)
endfunction


function! RMakePDFrmd(t)
    if g:rplugin_vimcomport == 0
        exe "Py DiscoverVimComPort()"
        if g:rplugin_vimcomport == 0
            call RWarningMsg("The vimcom package is required to make and open the PDF.")
        endif
    endif
    if g:rplugin_has_pandoc == 0
        if executable("pandoc")
            let g:rplugin_has_pandoc = 1
        else
            call RWarningMsg("Cannot convert into PDF: 'pandoc' not found.")
            return
        endif
    endif
    call RSetWD()
    update
    let pdfcmd = "vim.interlace.rmd('" . expand("%:t") . "'"
    let pdfcmd = pdfcmd . ", pdfout = '" . a:t  . "'"
    if exists("g:vimrplugin_rmdcompiler")
        let pdfcmd = pdfcmd . ", compiler='" . g:vimrplugin_rmdcompiler . "'"
    endif
    if exists("g:vimrplugin_knitargs")
        let pdfcmd = pdfcmd . ", " . g:vimrplugin_knitargs
    endif
    if exists("g:vimrplugin_rmd2pdfpath")
        pdfcmd = pdfcmd . ", rmd2pdfpath='" . g:vimrplugin_rmd2pdf_path . "'"
    endif
    if exists("g:vimrplugin_pandoc_args")
        let pdfcmd = pdfcmd . ", pandoc_args = '" . g:vimrplugin_pandoc_args . "'"
    endif
    let pdfcmd = pdfcmd . ")"
    call g:SendCmdToR(pdfcmd)
endfunction  

" Send Rmd chunk to R
function! SendRmdChunkToR(e, m)
    if RmdIsInRCode(0) == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    let chunkline = search("^[ \t]*```[ ]*{r", "bncW") + 1
    let docline = search("^[ \t]*```", "ncW") - 1
    let lines = getline(chunkline, docline)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down"
        call RmdNextChunk()
    endif  
endfunction

let b:IsInRCode = function("RmdIsInRCode")
let b:PreviousRChunk = function("RmdPreviousChunk")
let b:NextRChunk = function("RmdNextChunk")
let b:SendChunkToR = function("SendRmdChunkToR")

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Only .Rmd files use these functions:
call RCreateMaps("nvi", '<Plug>RKnit',        'kn', ':call RKnit()')
call RCreateMaps("nvi", '<Plug>RMakePDFK',    'kp', ':call RMakePDFrmd("latex")')
call RCreateMaps("nvi", '<Plug>RMakePDFKb',   'kl', ':call RMakePDFrmd("beamer")')
call RCreateMaps("nvi", '<Plug>RMakeHTML',    'kh', ':call RMakeHTMLrmd("html")')
call RCreateMaps("nvi", '<Plug>RMakeSlides',  'sl', ':call RMakeSlidesrmd()')
call RCreateMaps("nvi", '<Plug>RMakeODT',     'ko', ':call RMakeHTMLrmd("odt")')
call RCreateMaps("ni",  '<Plug>RSendChunk',   'cc', ':call b:SendChunkToR("silent", "stay")')
call RCreateMaps("ni",  '<Plug>RESendChunk',  'ce', ':call b:SendChunkToR("echo", "stay")')
call RCreateMaps("ni",  '<Plug>RDSendChunk',  'cd', ':call b:SendChunkToR("silent", "down")')
call RCreateMaps("ni",  '<Plug>REDSendChunk', 'ca', ':call b:SendChunkToR("echo", "down")')
nmap <buffer><silent> gn :call b:NextRChunk()<CR>
nmap <buffer><silent> gN :call b:PreviousRChunk()<CR>

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

let g:rplugin_has_pandoc = 0
let g:rplugin_has_soffice = 0

call RSourceOtherScripts()

let &cpo = s:cpo_save
unlet s:cpo_save

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= "|setl cms< com< fo< flp<"
else
  let b:undo_ftplugin = "setl cms< com< fo< flp<"
endif

ftplugin/rnoweb.vim	[[[1
280
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for R files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_rnoweb_ftplugin") || exists("disable_r_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_rnoweb_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Enables Vim-Latex-Suite, LaTeX-Box if installed
runtime ftplugin/tex_latexSuite.vim
runtime ftplugin/tex_LatexBox.vim
setlocal iskeyword=@,48-57,_,.

" Source scripts common to R, Rnoweb, Rhelp and Rdoc:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rnoweb, Rhelp and Rdoc need to be defined
" after the global ones:
runtime r-plugin/common_buffer.vim

setlocal iskeyword=@,48-57,_,.

function! RWriteChunk()
    if getline(".") =~ "^\\s*$" && RnwIsInRCode(0) == 0
        call setline(line("."), "<<>>=")
        exe "normal! o@"
        exe "normal! 0kl"
    else
        exe "normal! a<"
    endif
endfunction

function! RnwIsInRCode(vrb)
    let chunkline = search("^<<", "bncW")
    let docline = search("^@", "bncW")
    if chunkline > docline && chunkline != line(".")
        return 1
    else
        if a:vrb
            call RWarningMsg("Not inside an R code chunk.")
        endif
        return 0
    endif
endfunction

function! RnwPreviousChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let curline = line(".")
        if RnwIsInRCode(0)
            let i = search("^<<.*$", "bnW")
            if i != 0
                call cursor(i-1, 1)
            endif
        endif
        let i = search("^<<.*$", "bnW")
        if i == 0
            call cursor(curline, 1)
            call RWarningMsg("There is no previous R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RnwNextChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let i = search("^<<.*$", "nW")
        if i == 0
            call RWarningMsg("There is no next R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

" Sweave and compile the current buffer content
function! RMakePDF(bibtex, knit)
    if g:rplugin_vimcomport == 0
        exe "Py DiscoverVimComPort()"
        if g:rplugin_vimcomport == 0
            call RWarningMsg("The vimcom package is required to make and open the PDF.")
        endif
    endif
    update
    call RSetWD()
    let pdfcmd = "vim.interlace.rnoweb('" . expand("%:t") . "'"

    if a:knit
        let pdfcmd = pdfcmd . ', knit = TRUE'
    endif

    if g:vimrplugin_latexcmd != "pdflatex"
        let pdfcmd = pdfcmd . ", latexcmd = '" . g:vimrplugin_latexcmd . "'"
    endif

    if a:bibtex == "bibtex"
        let pdfcmd = pdfcmd . ", bibtex = TRUE"
    endif

    if a:bibtex == "verbose"
        let pdfcmd = pdfcmd . ", quiet = FALSE"
    endif

    if g:vimrplugin_openpdf == 0
        let pdfcmd = pdfcmd . ", view = FALSE"
    endif

    if g:vimrplugin_openpdf_quietly
        let pdfcmd = pdfcmd . ", pdfquiet = TRUE"
    endif

    if a:knit == 0 && exists("g:vimrplugin_sweaveargs")
        let pdfcmd = pdfcmd . ", " . g:vimrplugin_sweaveargs
    endif

    let pdfcmd = pdfcmd . ")"
    let ok = g:SendCmdToR(pdfcmd)
    if ok == 0
        return
    endif
endfunction  

" Send Sweave chunk to R
function! RnwSendChunkToR(e, m)
    if RnwIsInRCode(0) == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    let chunkline = search("^<<", "bncW") + 1
    let docline = search("^@", "ncW") - 1
    let lines = getline(chunkline, docline)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down"
        call RnwNextChunk()
    endif  
endfunction

" Sweave the current buffer content
function! RSweave()
    update
    call RSetWD()
    if exists("g:vimrplugin_sweaveargs")
        call g:SendCmdToR('Sweave("' . expand("%:t") . '", ' . g:vimrplugin_sweaveargs . ')')
    else
        call g:SendCmdToR('Sweave("' . expand("%:t") . '")')
    endif
endfunction

function! ROpenPDF()
    if has("win32") || has("win64")
        exe 'Py OpenPDF("' . expand("%:t:r") . '.pdf")'
        return
    endif

    if !exists("g:rplugin_pdfviewer")
        let g:rplugin_pdfviewer = "none"
        if has("gui_macvim") || has("gui_mac") || has("mac") || has("macunix")
            if $R_PDFVIEWER == ""
                let pdfvl = ["open"]
            else
                let pdfvl = [$R_PDFVIEWER, "open"]
            endif
        else
            if $R_PDFVIEWER == ""
                let pdfvl = ["xdg-open"]
            else
                let pdfvl = [$R_PDFVIEWER, "xdg-open"]
            endif
        endif
        " List from R configure script:
        let pdfvl += ["evince", "okular", "xpdf", "gv", "gnome-gv", "ggv", "kpdf", "gpdf", "kghostview,", "acroread", "acroread4"]
        for prog in pdfvl
            if executable(prog)
                let g:rplugin_pdfviewer = prog
                break
            endif
        endfor
    endif

    if g:rplugin_pdfviewer == "none"
        if g:vimrplugin_openpdf_quietly
            call g:SendCmdToR('vim.openpdf("' . expand("%:p:r") . ".pdf" . '", TRUE)')
        else
            call g:SendCmdToR('vim.openpdf("' . expand("%:p:r") . ".pdf" . '")')
        endif
    else
        let openlog = system(g:rplugin_pdfviewer . " '" . expand("%:p:r") . ".pdf" . "'")
        if v:shell_error
            let rlog = substitute(openlog, "\n", " ", "g")
            let rlog = substitute(openlog, "\r", " ", "g")
            call RWarningMsg(openlog)
        endif
    endif
endfunction

if g:vimrplugin_rnowebchunk == 1
    " Write code chunk in rnoweb files
    imap <buffer><silent> < <Esc>:call RWriteChunk()<CR>a
endif

" Pointers to functions whose purposes are the same in rnoweb, rrst, rmd,
" rhelp and rdoc and which are called at common_global.vim
let b:IsInRCode = function("RnwIsInRCode")
let b:PreviousRChunk = function("RnwPreviousChunk")
let b:NextRChunk = function("RnwNextChunk")
let b:SendChunkToR = function("RnwSendChunkToR")

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Only .Rnw files use these functions:
call RCreateMaps("nvi", '<Plug>RSweave',      'sw', ':call RSweave()')
call RCreateMaps("nvi", '<Plug>RMakePDF',     'sp', ':call RMakePDF("nobib", 0)')
call RCreateMaps("nvi", '<Plug>RBibTeX',      'sb', ':call RMakePDF("bibtex", 0)')
call RCreateMaps("nvi", '<Plug>RKnit',        'kn', ':call RKnit()')
call RCreateMaps("nvi", '<Plug>RMakePDFK',    'kp', ':call RMakePDF("nobib", 1)')
call RCreateMaps("nvi", '<Plug>RBibTeXK',     'kb', ':call RMakePDF("bibtex", 1)')
call RCreateMaps("nvi", '<Plug>ROpenPDF',     'op', ':call ROpenPDF()')
call RCreateMaps("nvi", '<Plug>RIndent',      'si', ':call RnwToggleIndentSty()')
call RCreateMaps("ni",  '<Plug>RSendChunk',   'cc', ':call b:SendChunkToR("silent", "stay")')
call RCreateMaps("ni",  '<Plug>RESendChunk',  'ce', ':call b:SendChunkToR("echo", "stay")')
call RCreateMaps("ni",  '<Plug>RDSendChunk',  'cd', ':call b:SendChunkToR("silent", "down")')
call RCreateMaps("ni",  '<Plug>REDSendChunk', 'ca', ':call b:SendChunkToR("echo", "down")')
nmap <buffer><silent> gn :call RnwNextChunk()<CR>
nmap <buffer><silent> gN :call RnwPreviousChunk()<CR>

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

call RSourceOtherScripts()

let &cpo = s:cpo_save
unlet s:cpo_save

ftplugin/rrst.vim	[[[1
225
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for Rrst files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          Alex Zvoleff
"
"==========================================================================

" Only do this when not yet done for this buffer
if exists("b:did_rrst_ftplugin") || exists("disable_r_ftplugin")
    finish
endif

" Don't load another plugin for this buffer
let b:did_rrst_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Source scripts common to R, Rrst, Rnoweb, Rhelp and Rdoc:
runtime r-plugin/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

setlocal comments=fb:*,fb:-,fb:+,n:> commentstring=>\ %s
setlocal formatoptions+=tcqln
setlocal formatlistpat=^\\s*\\d\\+\\.\\s\\+\\\|^\\s*[-*+]\\s\\+
setlocal iskeyword=@,48-57,_,.

" Some buffer variables common to R, Rrst, Rnoweb, Rhelp and Rdoc need to be 
" defined after the global ones:
runtime r-plugin/common_buffer.vim

function! RrstIsInRCode(vrb)
    let chunkline = search("^\\.\\. {r", "bncW")
    let docline = search("^\\.\\. \\.\\.", "bncW")
    if chunkline > docline && chunkline != line(".")
        return 1
    else
        if a:vrb
            call RWarningMsg("Not inside an R code chunk.")
        endif
        return 0
    endif
endfunction

function! RrstPreviousChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let curline = line(".")
        if RrstIsInRCode(0)
            let i = search("^\\.\\. {r", "bnW")
            if i != 0
                call cursor(i-1, 1)
            endif
        endif
        let i = search("^\\.\\. {r", "bnW")
        if i == 0
            call cursor(curline, 1)
            call RWarningMsg("There is no previous R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RrstNextChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let i = search("^\\.\\. {r", "nW")
        if i == 0
            call RWarningMsg("There is no next R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RMakeHTMLrrst(t)
    call RSetWD()
    update
    if g:rplugin_has_rst2pdf == 0
        if executable("rst2pdf")
            let g:rplugin_has_rst2pdf = 1
        else
            call RWarningMsg("Is 'rst2pdf' application installed? Cannot convert into HTML/ODT: 'rst2pdf' executable not found.")
            return
        endif
    endif

    let rcmd = 'require(knitr)'
    if g:vimrplugin_strict_rst
        let rcmd = rcmd . '; render_rst(strict=TRUE)'
    endif
    let rcmd = rcmd . '; knit("' . expand("%:t") . '")'
    
    if a:t == "odt"
        let rcmd = rcmd . '; system("rst2odt ' . expand("%:r:t") . ".rst " . expand("%:r:t") . '.odt")'
    else
        let rcmd = rcmd . '; system("rst2html ' . expand("%:r:t") . ".rst " . expand("%:r:t") . '.html")'
    endif

    if g:vimrplugin_openhtml && a:t == "html"
        let rcmd = rcmd . '; browseURL("' . expand("%:r:t") . '.html")'
    endif
    call g:SendCmdToR(rcmd)
endfunction

function! RMakePDFrrst()
    if g:rplugin_vimcomport == 0
        exe "Py DiscoverVimComPort()"
        if g:rplugin_vimcomport == 0
            call RWarningMsg("The vimcom package is required to make and open the PDF.")
        endif
    endif
    update
    call RSetWD()
    if g:rplugin_has_rst2pdf == 0
        if exists("g:vimrplugin_rst2pdfpath") && executable(g:vimrplugin_rst2pdfpath)
            let g:rplugin_has_rst2pdf = 1
        elseif executable("rst2pdf")
            let g:rplugin_has_rst2pdf = 1
        else
            call RWarningMsg("Is 'rst2pdf' application installed? Cannot convert into PDF: 'rst2pdf' executable not found.")
            return
        endif
    endif

    let pdfcmd = "vim.interlace.rrst('" . expand("%:t") . "'"
    if exists("g:vimrplugin_rrstcompiler")
        let pdfcmd = pdfcmd . ", compiler='" . g:vimrplugin_rrstcompiler . "'"
    endif
    if exists("g:vimrplugin_knitargs")
        let pdfcmd = pdfcmd . ", " . g:vimrplugin_knitargs
    endif
    if exists("g:vimrplugin_rst2pdfpath")
        let pdfcmd = pdfcmd . ", rst2pdfpath='" . g:vimrplugin_rst2pdfpath . "'"
    endif
    if exists("g:vimrplugin_rst2pdfargs")
        let pdfcmd = pdfcmd . ", " . g:vimrplugin_rst2pdfargs
    endif
    let pdfcmd = pdfcmd . ")"
    let ok = g:SendCmdToR(pdfcmd)
    if ok == 0
        return
    endif
endfunction  

" Send Rrst chunk to R
function! SendRrstChunkToR(e, m)
    if RrstIsInRCode(0) == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    let chunkline = search("^\\.\\. {r", "bncW") + 1
    let docline = search("^\\.\\. \\.\\.", "ncW") - 1
    let lines = getline(chunkline, docline)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down"
        call RrstNextChunk()
    endif  
endfunction

let b:IsInRCode = function("RrstIsInRCode")
let b:PreviousRChunk = function("RrstPreviousChunk")
let b:NextRChunk = function("RrstNextChunk")
let b:SendChunkToR = function("SendRrstChunkToR")

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Only .Rrst files use these functions:
call RCreateMaps("nvi", '<Plug>RKnit',        'kn', ':call RKnit()')
call RCreateMaps("nvi", '<Plug>RMakePDFK',    'kp', ':call RMakePDFrrst()')
call RCreateMaps("nvi", '<Plug>RMakeHTML',    'kh', ':call RMakeHTMLrrst("html")')
call RCreateMaps("nvi", '<Plug>RMakeODT',     'ko', ':call RMakeHTMLrrst("odt")')
call RCreateMaps("nvi", '<Plug>RIndent',      'si', ':call RrstToggleIndentSty()')
call RCreateMaps("ni",  '<Plug>RSendChunk',   'cc', ':call b:SendChunkToR("silent", "stay")')
call RCreateMaps("ni",  '<Plug>RESendChunk',  'ce', ':call b:SendChunkToR("echo", "stay")')
call RCreateMaps("ni",  '<Plug>RDSendChunk',  'cd', ':call b:SendChunkToR("silent", "down")')
call RCreateMaps("ni",  '<Plug>REDSendChunk', 'ca', ':call b:SendChunkToR("echo", "down")')
nmap <buffer><silent> gn :call b:NextRChunk()<CR>
nmap <buffer><silent> gN :call b:PreviousRChunk()<CR>

" Menu R
if has("gui_running")
    call MakeRMenu()
endif

let g:rplugin_has_rst2pdf = 0

call RSourceOtherScripts()

let &cpo = s:cpo_save
unlet s:cpo_save
indent/r.vim	[[[1
493
" Vim indent file
" Language:	R
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Fri Feb 15, 2013  08:06PM


" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentkeys=0{,0},:,!^F,o,O,e
setlocal indentexpr=GetRIndent()

" Only define the function once.
if exists("*GetRIndent")
    finish
endif

" Options to make the indentation more similar to Emacs/ESS:
if !exists("g:r_indent_align_args")
    let g:r_indent_align_args = 1
endif
if !exists("g:r_indent_ess_comments")
    let g:r_indent_ess_comments = 0
endif
if !exists("g:r_indent_comment_column")
    let g:r_indent_comment_column = 40
endif
if ! exists("g:r_indent_ess_compatible")
    let g:r_indent_ess_compatible = 0
endif

function s:RDelete_quotes(line)
    let i = 0
    let j = 0
    let line1 = ""
    let llen = strlen(a:line)
    while i < llen
        if a:line[i] == '"'
            let i += 1
            let line1 = line1 . 's'
            while !(a:line[i] == '"' && ((i > 1 && a:line[i-1] == '\' && a:line[i-2] == '\') || a:line[i-1] != '\')) && i < llen
                let i += 1
            endwhile
            if a:line[i] == '"'
                let i += 1
            endif
        else
            if a:line[i] == "'"
                let i += 1
                let line1 = line1 . 's'
                while !(a:line[i] == "'" && ((i > 1 && a:line[i-1] == '\' && a:line[i-2] == '\') || a:line[i-1] != '\')) && i < llen
                    let i += 1
                endwhile
                if a:line[i] == "'"
                    let i += 1
                endif
            else
                if a:line[i] == "`"
                    let i += 1
                    let line1 = line1 . 's'
                    while a:line[i] != "`" && i < llen
                        let i += 1
                    endwhile
                    if a:line[i] == "`"
                        let i += 1
                    endif
                endif
            endif
        endif
        if i == llen
            break
        endif
        let line1 = line1 . a:line[i]
        let j += 1
        let i += 1
    endwhile
    return line1
endfunction

" Convert foo(bar()) int foo()
function s:RDelete_parens(line)
    if s:Get_paren_balance(a:line, "(", ")") != 0
        return a:line
    endif
    let i = 0
    let j = 0
    let line1 = ""
    let llen = strlen(a:line)
    while i < llen
        let line1 = line1 . a:line[i]
        if a:line[i] == '('
            let nop = 1
            while nop > 0 && i < llen
                let i += 1
                if a:line[i] == ')'
                    let nop -= 1
                else
                    if a:line[i] == '('
                        let nop += 1 
                    endif
                endif
            endwhile
            let line1 = line1 . a:line[i]
        endif
        let i += 1
    endwhile
    return line1
endfunction

function! s:Get_paren_balance(line, o, c)
    let line2 = substitute(a:line, a:o, "", "g")
    let openp = strlen(a:line) - strlen(line2)
    let line3 = substitute(line2, a:c, "", "g")
    let closep = strlen(line2) - strlen(line3)
    return openp - closep
endfunction

function! s:Get_matching_brace(linenr, o, c, delbrace)
    let line = SanitizeRLine(getline(a:linenr))
    if a:delbrace == 1
        let line = substitute(line, '{$', "", "")
    endif
    let pb = s:Get_paren_balance(line, a:o, a:c)
    let i = a:linenr
    while pb != 0 && i > 1
        let i -= 1
        let pb += s:Get_paren_balance(SanitizeRLine(getline(i)), a:o, a:c)
    endwhile
    return i
endfunction

" This function is buggy because there 'if's without 'else'
" It must be rewritten relying more on indentation
function! s:Get_matching_if(linenr, delif)
"    let filenm = expand("%")
"    call writefile([filenm], "/tmp/matching_if_" . a:linenr)
    let line = SanitizeRLine(getline(a:linenr))
    if a:delif
        let line = substitute(line, "if", "", "g")
    endif
    let elsenr = 0
    let i = a:linenr
    let ifhere = 0
    while i > 0
        let line2 = substitute(line, '\<else\>', "xxx", "g")
        let elsenr += strlen(line) - strlen(line2)
        if line =~ '.*\s*if\s*()' || line =~ '.*\s*if\s*()'
            let elsenr -= 1
            if elsenr == 0
                let ifhere = i
                break
            endif
        endif
        let i -= 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if ifhere
        return ifhere
    else
        return a:linenr
    endif
endfunction

function! s:Get_last_paren_idx(line, o, c, pb)
    let blc = a:pb
    let line = substitute(a:line, '\t', s:curtabstop, "g")
    let theidx = -1
    let llen = strlen(line)
    let idx = 0
    while idx < llen
        if line[idx] == a:o
            let blc -= 1
            if blc == 0
                let theidx = idx
            endif
        else
            if line[idx] == a:c
                let blc += 1
            endif
        endif
        let idx += 1
    endwhile
    return theidx + 1
endfunction

" Get previous relevant line. Search back until getting a line that isn't
" comment or blank
function s:Get_prev_line(lineno)
    let lnum = a:lineno - 1
    let data = getline( lnum )
    while lnum > 0 && (data =~ '^\s*#' || data =~ '^\s*$')
        let lnum = lnum - 1
        let data = getline( lnum )
    endwhile
    return lnum
endfunction

" This function is also used by r-plugin/common_global.vim
" Delete from '#' to the end of the line, unless the '#' is inside a string.
function SanitizeRLine(line)
    let newline = s:RDelete_quotes(a:line)
    let newline = s:RDelete_parens(newline)
    let newline = substitute(newline, '#.*', "", "")
    let newline = substitute(newline, '\s*$', "", "")
    return newline
endfunction

function GetRIndent()

    let clnum = line(".")    " current line

    let cline = getline(clnum)
    if cline =~ '^\s*#'
        if g:r_indent_ess_comments == 1
            if cline =~ '^\s*###'
                return 0
            endif
            if cline !~ '^\s*##'
                return g:r_indent_comment_column
            endif
        endif
    endif

    let cline = SanitizeRLine(cline)

    if cline =~ '^\s*}' || cline =~ '^\s*}\s*)$'
        let indline = s:Get_matching_brace(clnum, '{', '}', 1)
        if indline > 0 && indline != clnum
            let iline = SanitizeRLine(getline(indline))
            if s:Get_paren_balance(iline, "(", ")") == 0 || iline =~ '(\s*{$'
                return indent(indline)
            else
                let indline = s:Get_matching_brace(indline, '(', ')', 1)
                return indent(indline)
            endif
        endif
    endif

    " Find the first non blank line above the current line
    let lnum = s:Get_prev_line(clnum)
    " Hit the start of the file, use zero indent.
    if lnum == 0
        return 0
    endif

    let line = SanitizeRLine(getline(lnum))

    if &filetype == "rhelp"
        if cline =~ '^\\dontshow{' || cline =~ '^\\dontrun{' || cline =~ '^\\donttest{' || cline =~ '^\\testonly{'
            return 0
        endif
        if line =~ '^\\examples{' || line =~ '^\\usage{' || line =~ '^\\dontshow{' || line =~ '^\\dontrun{' || line =~ '^\\donttest{' || line =~ '^\\testonly{'
            return 0
        endif
        if line =~ '^\\method{.*}{.*}(.*'
            let line = substitute(line, '^\\method{\(.*\)}{.*}', '\1', "")
        endif
    endif

    if cline =~ '^\s*{'
        if g:r_indent_ess_compatible && line =~ ')$'
            let nlnum = lnum
            let nline = line
            while s:Get_paren_balance(nline, '(', ')') < 0
                let nlnum = s:Get_prev_line(nlnum)
                let nline = SanitizeRLine(getline(nlnum)) . nline
            endwhile
            if nline =~ '^\s*function\s*(' && indent(nlnum) == &sw
                return 0
            endif
        endif
        if s:Get_paren_balance(line, "(", ")") == 0
            return indent(lnum)
        endif
    endif

    " line is an incomplete command:
    if line =~ '\<\(if\|while\|for\|function\)\s*()$' || line =~ '\<else$' || line =~ '<-$'
        return indent(lnum) + &sw
    endif

    " Deal with () and []

    let pb = s:Get_paren_balance(line, '(', ')')

    if line =~ '^\s*{$' || line =~ '(\s*{' || (pb == 0 && (line =~ '{$' || line =~ '(\s*{$'))
        return indent(lnum) + &sw
    endif

    let bb = s:Get_paren_balance(line, '[', ']')

    let s:curtabstop = repeat(' ', &tabstop)
    if g:r_indent_align_args == 1

        if pb == 0 && bb == 0 && (line =~ '.*[,&|\-\*+<>]$' || cline =~ '^\s*[,&|\-\*+<>]')
            return indent(lnum)
        endif

        if pb > 0
            if &filetype == "rhelp"
                let ind = s:Get_last_paren_idx(line, '(', ')', pb)
            else
                let ind = s:Get_last_paren_idx(getline(lnum), '(', ')', pb)
            endif
            return ind
        endif

        if pb < 0 && line =~ '.*[,&|\-\*+<>]$'
            let lnum = s:Get_prev_line(lnum)
            while pb < 1 && lnum > 0
                let line = SanitizeRLine(getline(lnum))
                let line = substitute(line, '\t', s:curtabstop, "g")
                let ind = strlen(line)
                while ind > 0
                    if line[ind] == ')'
                        let pb -= 1
                    else
                        if line[ind] == '('
                            let pb += 1
                        endif
                    endif
                    if pb == 1
                        return ind + 1
                    endif
                    let ind -= 1
                endwhile
                let lnum -= 1
            endwhile
            return 0
        endif

        if bb > 0
            let ind = s:Get_last_paren_idx(getline(lnum), '[', ']', bb)
            return ind
        endif
    endif

    let post_block = 0
    if line =~ '}$'
        let lnum = s:Get_matching_brace(lnum, '{', '}', 0)
        let line = SanitizeRLine(getline(lnum))
        if lnum > 0 && line =~ '^\s*{'
            let lnum = s:Get_prev_line(lnum)
            let line = SanitizeRLine(getline(lnum))
        endif
        let pb = s:Get_paren_balance(line, '(', ')')
        let post_block = 1
    endif

    let post_fun = 0
    if pb < 0 && line !~ ')\s*[,&|\-\*+<>]$'
        let post_fun = 1
        while pb < 0 && lnum > 0
            let lnum -= 1
            let linepiece = SanitizeRLine(getline(lnum))
            let pb += s:Get_paren_balance(linepiece, "(", ")")
            let line = linepiece . line
        endwhile
        if line =~ '{$' && post_block == 0
            return indent(lnum) + &sw
        endif

        " Now we can do some tests again
        if cline =~ '^\s*{'
            return indent(lnum)
        endif
        if post_block == 0
            let newl = SanitizeRLine(line)
            if newl =~ '\<\(if\|while\|for\|function\)\s*()$' || newl =~ '\<else$' || newl =~ '<-$'
                return indent(lnum) + &sw
            endif
        endif
    endif

    if cline =~ '^\s*else'
        if line =~ '<-\s*if\s*()'
            return indent(lnum) + &sw
        else
            if line =~ '\<if\s*()'
                return indent(lnum)
            else
                return indent(lnum) - &sw
            endif
        endif
    endif

    if bb < 0 && line =~ '.*]'
        while bb < 0 && lnum > 0
            let lnum -= 1
            let linepiece = SanitizeRLine(getline(lnum))
            let bb += s:Get_paren_balance(linepiece, "[", "]")
            let line = linepiece . line
        endwhile
        let line = s:RDelete_parens(line)
    endif

    let plnum = s:Get_prev_line(lnum)
    let ppost_else = 0
    if plnum > 0
        let pline = SanitizeRLine(getline(plnum))
        let ppost_block = 0
        if pline =~ '}$'
            let ppost_block = 1
            let plnum = s:Get_matching_brace(plnum, '{', '}', 0)
            let pline = SanitizeRLine(getline(plnum))
            if pline =~ '^\s*{$' && plnum > 0
                let plnum = s:Get_prev_line(plnum)
                let pline = SanitizeRLine(getline(plnum))
            endif
        endif

        if pline =~ 'else$'
            let ppost_else = 1
            let plnum = s:Get_matching_if(plnum, 0)
            let pline = SanitizeRLine(getline(plnum))
        endif

        if pline =~ '^\s*else\s*if\s*('
            let pplnum = s:Get_prev_line(plnum)
            let ppline = SanitizeRLine(getline(pplnum))
            while ppline =~ '^\s*else\s*if\s*(' || ppline =~ '^\s*if\s*()\s*\S$'
                let plnum = pplnum
                let pline = ppline
                let pplnum = s:Get_prev_line(plnum)
                let ppline = SanitizeRLine(getline(pplnum))
            endwhile
            while ppline =~ '\<\(if\|while\|for\|function\)\s*()$' || ppline =~ '\<else$' || ppline =~ '<-$'
                let plnum = pplnum
                let pline = ppline
                let pplnum = s:Get_prev_line(plnum)
                let ppline = SanitizeRLine(getline(pplnum))
            endwhile
        endif

        let ppb = s:Get_paren_balance(pline, '(', ')')
        if ppb < 0 && (pline =~ ')\s*{$' || pline =~ ')$')
            while ppb < 0 && plnum > 0
                let plnum -= 1
                let linepiece = SanitizeRLine(getline(plnum))
                let ppb += s:Get_paren_balance(linepiece, "(", ")")
                let pline = linepiece . pline
            endwhile
            let pline = s:RDelete_parens(pline)
        endif
    endif

    let ind = indent(lnum)
    let pind = indent(plnum)

    if g:r_indent_align_args == 0 && pb != 0
        let ind += pb * &sw
        return ind
    endif

    if g:r_indent_align_args == 0 && bb != 0
        let ind += bb * &sw
        return ind
    endif

    if ind == pind || (ind == (pind  + &sw) && pline =~ '{$' && ppost_else == 0)
        return ind
    endif

    let pline = getline(plnum)
    let pbb = s:Get_paren_balance(pline, '[', ']')

    while pind < ind && plnum > 0 && ppb == 0 && pbb == 0
        let ind = pind
        let plnum = s:Get_prev_line(plnum)
        let pline = getline(plnum)
        let ppb = s:Get_paren_balance(pline, '(', ')')
        let pbb = s:Get_paren_balance(pline, '[', ']')
        while pline =~ '^\s*else'
            let plnum = s:Get_matching_if(plnum, 1)
            let pline = getline(plnum)
            let ppb = s:Get_paren_balance(pline, '(', ')')
            let pbb = s:Get_paren_balance(pline, '[', ']')
        endwhile
        let pind = indent(plnum)
        if ind == (pind  + &sw) && pline =~ '{$'
            return ind
        endif
    endwhile

    return ind

endfunction

" vim: sw=4
indent/rhelp.vim	[[[1
111
" Vim indent file
" Language:	R Documentation (Help), *.Rd
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Fri Feb 15, 2013  09:46PM


" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif
runtime indent/r.vim
let b:did_indent = 1

setlocal indentkeys=0{,0},:,!^F,o,O,e
setlocal indentexpr=GetRHelpIndent()

" Only define the function once.
if exists("*GetRHelpIndent")
    finish
endif

setlocal noautoindent
setlocal nocindent
setlocal nosmartindent
setlocal nolisp

setlocal indentkeys=0{,0},:,!^F,o,O,e
setlocal indentexpr=GetCorrectRHelpIndent()

function s:SanitizeRHelpLine(line)
    let newline = substitute(a:line, '\\\\', "x", "g")
    let newline = substitute(newline, '\\{', "x", "g")
    let newline = substitute(newline, '\\}', "x", "g")
    let newline = substitute(newline, '\\%', "x", "g")
    let newline = substitute(newline, '%.*', "", "")
    let newline = substitute(newline, '\s*$', "", "")
    return newline
endfunction

function GetRHelpIndent()

    let clnum = line(".")    " current line
    if clnum == 1
        return 0
    endif
    let cline = getline(clnum)

    if cline =~ '^\s*}\s*$'
        let i = clnum
        let bb = -1
        while bb != 0 && i > 1
            let i -= 1
            let line = s:SanitizeRHelpLine(getline(i))
            let line2 = substitute(line, "{", "", "g")
            let openb = strlen(line) - strlen(line2)
            let line3 = substitute(line2, "}", "", "g")
            let closeb = strlen(line2) - strlen(line3)
            let bb += openb - closeb
        endwhile
        return indent(i)
    endif

    if cline =~ '^\s*#ifdef\>' || cline =~ '^\s*#endif\>'
        return 0
    endif

    let lnum = clnum - 1
    let line = getline(lnum)
    if line =~ '^\s*#ifdef\>' || line =~ '^\s*#endif\>'
        let lnum -= 1
        let line = getline(lnum)
    endif
    while lnum > 1 && (line =~ '^\s*$' || line =~ '^#ifdef' || line =~ '^#endif')
        let lnum -= 1
        let line = getline(lnum)
    endwhile
    if lnum == 1
        return 0
    endif
    let line = s:SanitizeRHelpLine(line)
    let line2 = substitute(line, "{", "", "g")
    let openb = strlen(line) - strlen(line2)
    let line3 = substitute(line2, "}", "", "g")
    let closeb = strlen(line2) - strlen(line3)
    let bb = openb - closeb

    let ind = indent(lnum) + (bb * &sw)

    if line =~ '^\s*}\s*$'
        let ind = indent(lnum)
    endif

    if ind < 0
        return 0
    endif

    return ind
endfunction

function GetCorrectRHelpIndent()
    let lastsection = search('^\\[a-z]*{', "bncW")
    let secname = getline(lastsection)
    if secname =~ '^\\usage{' || secname =~ '^\\examples{' || secname =~ '^\\dontshow{' || secname =~ '^\\dontrun{' || secname =~ '^\\donttest{' || secname =~ '^\\testonly{' || secname =~ '^\\method{.*}{.*}('
        return GetRIndent()
    else
        return GetRHelpIndent()
    endif
endfunction

" vim: sw=4
indent/rmd.vim	[[[1
45
" Vim indent file
" Language:	Rmd
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Fri Feb 15, 2013  09:46PM


" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
runtime indent/r.vim
let b:did_indent = 1

setlocal indentkeys=0{,0},:,!^F,o,O,e
setlocal indentexpr=GetRmdIndent()

if exists("*GetRmdIndent")
  finish
endif

function GetMdIndent()
    let pline = getline(v:lnum - 1)
    let cline = getline(v:lnum)
    if prevnonblank(v:lnum - 1) < v:lnum - 1 || cline =~ '^\s*[-\+\*]\s' || cline =~ '^\s*\d\+\.\s\+'
        return indent(v:lnum)
    elseif pline =~ '^\s*[-\+\*]\s'
        return indent(v:lnum - 1) + 2
    elseif pline =~ '^\s*\d\+\.\s\+'
        return indent(v:lnum - 1) + 3
    endif
    return indent(prevnonblank(v:lnum - 1))
endfunction

function GetRmdIndent()
    if getline(".") =~ '^```{r .*}$' || getline(".") =~ '^```$'
	return 0
    endif
    if search('^```{r', "bncW") > search('^```$', "bncW")
	return GetRIndent()
    else
	return GetMdIndent()
    endif
endfunction

indent/rnoweb.vim	[[[1
37
" Vim indent file
" Language:	Rnoweb
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Fri Feb 15, 2013  09:47PM


" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
runtime indent/r.vim
unlet b:did_indent
runtime r-plugin/tex_indent.vim
let b:did_indent = 1




setlocal indentkeys=0{,0},!^F,o,O,e,},=\bibitem,=\item
setlocal indentexpr=GetRnowebIndent()

if exists("*GetRnowebIndent")
  finish
endif

function GetRnowebIndent()
    if getline(".") =~ "^<<.*>>=$"
	return 0
    endif
    if search("^<<", "bncW") > search("^@", "bncW")
	return GetRIndent()
    else
	return GetTeXIndent2()
    endif
endfunction

indent/rrst.vim	[[[1
45
" Vim indent file
" Language:	Rrst
" Author:	Jakson Alves de Aquino <jalvesaq@gmail.com>
" URL:		http://www.vim.org/scripts/script.php?script_id=2628
" Last Change:	Fri Feb 15, 2013  09:47PM


" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
runtime indent/r.vim
let b:did_indent = 1

setlocal indentkeys=0{,0},:,!^F,o,O,e
setlocal indentexpr=GetRrstIndent()

if exists("*GetRrstIndent")
  finish
endif

function GetRstIndent()
    let pline = getline(v:lnum - 1)
    let cline = getline(v:lnum)
    if prevnonblank(v:lnum - 1) < v:lnum - 1 || cline =~ '^\s*[-\+\*]\s' || cline =~ '^\s*\d\+\.\s\+'
        return indent(v:lnum)
    elseif pline =~ '^\s*[-\+\*]\s'
        return indent(v:lnum - 1) + 2
    elseif pline =~ '^\s*\d\+\.\s\+'
        return indent(v:lnum - 1) + 3
    endif
    return indent(prevnonblank(v:lnum - 1))
endfunction

function GetRrstIndent()
    if getline(".") =~ '^\.\. {r .*}$' || getline(".") =~ '^\.\. \.\.$'
	return 0
    endif
    if search('^\.\. {r', "bncW") > search('^\.\. \.\.$', "bncW")
	return GetRIndent()
    else
	return GetRstIndent()
    endif
endfunction

r-plugin/common_buffer.vim	[[[1
73
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" ftplugin for R files
"
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"          
"          Based on previous work by Johannes Ranke
"
" Please see doc/r-plugin.txt for usage details.
"==========================================================================


" Set completion with CTRL-X CTRL-O to autoloaded function.
if exists('&ofu')
    setlocal ofu=rcomplete#CompleteR
endif

" This isn't the Object Browser running externally
let b:rplugin_extern_ob = 0

" Set the name of the Object Browser caption if not set yet
let s:tnr = tabpagenr()
if !exists("b:objbrtitle")
    if s:tnr == 1
        let b:objbrtitle = "Object_Browser"
    else
        let b:objbrtitle = "Object_Browser" . s:tnr
    endif
    unlet s:tnr
endif


" Make the file name of files to be sourced
let b:bname = expand("%:t")
let b:bname = substitute(b:bname, " ", "",  "g")
if exists("*getpid") " getpid() was introduced in Vim 7.1.142
    let b:rsource = $VIMRPLUGIN_TMPDIR . "/Rsource-" . getpid() . "-" . b:bname
else
    let b:randnbr = system("echo $RANDOM")
    let b:randnbr = substitute(b:randnbr, "\n", "", "")
    if strlen(b:randnbr) == 0
        let b:randnbr = "NoRandom"
    endif
    let b:rsource = $VIMRPLUGIN_TMPDIR . "/Rsource-" . b:randnbr . "-" . b:bname
    unlet b:randnbr
endif
unlet b:bname

if exists("g:rplugin_firstbuffer") && g:rplugin_firstbuffer == ""
    " The file global_r_plugin.vim was copied to ~/.vim/plugin
    let g:rplugin_firstbuffer = expand("%:p")
endif

let g:rplugin_lastft = &filetype

if !exists("g:SendCmdToR")
    let g:SendCmdToR = function('SendCmdToR_fake')
endif


r-plugin/common_global.vim	[[[1
3529
"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" Authors: Jakson Alves de Aquino <jalvesaq@gmail.com>
"          Jose Claudio Faria
"
" Purposes of this file: Create all functions and commands and set the
" value of all global variables and some buffer variables.for r,
" rnoweb, rhelp, rdoc, and rbrowser files
"
" Why not an autoload script? Because autoload was designed to store
" functions that are only occasionally used. The Vim-R-plugin has
" global variables and functions that are common to five file types
" and most of these functions will be used every time the plugin is
" used.
"==========================================================================


" Do this only once
if exists("g:rplugin_did_global_stuff")
    finish
endif
let g:rplugin_did_global_stuff = 1

"==========================================================================
" Functions that are common to r, rnoweb, rhelp and rdoc
"==========================================================================

function RWarningMsg(wmsg)
    echohl WarningMsg
    echomsg a:wmsg
    echohl Normal
endfunction

function RWarningMsgInp(wmsg)
    let savedlz = &lazyredraw
    if savedlz == 0
        set lazyredraw
    endif
    let savedsm = &shortmess
    set shortmess-=T
    echohl WarningMsg
    echomsg a:wmsg
    echohl Normal
    " The message disappears if starting to edit an empty buffer
    if line("$") == 1 && strlen(getline("$")) == 0
        sleep 2
    endif
    call input("[Press <Enter> to continue] ")
    if savedlz == 0
        set nolazyredraw
    endif
    let &shortmess = savedsm
endfunction

" Set default value of some variables:
function RSetDefaultValue(var, val)
    if !exists(a:var)
        exe "let " . a:var . " = " . a:val
    endif
endfunction

function ReplaceUnderS()
    if &filetype != "r" && b:IsInRCode(0) == 0
        let isString = 1
    else
        let j = col(".")
        let s = getline(".")
        if g:vimrplugin_assign_map == "_" && j > 3 && s[j-3] == "<" && s[j-2] == "-" && s[j-1] == " "
            let save_unnamed_reg = @@
            exe "normal! 3h3xr_"
            let @@ = save_unnamed_reg
            return
        endif
        let isString = 0
        let synName = synIDattr(synID(line("."), j, 1), "name")
        if synName == "rSpecial"
            let isString = 1
        else
            if synName == "rString"
                let isString = 1
                if s[j-1] == '"' || s[j-1] == "'"
                    let synName = synIDattr(synID(line("."), j-2, 1), "name")
                    if synName == "rString" || synName == "rSpecial"
                        let isString = 0
                    endif
                endif
            endif
        endif
    endif
    if isString
        exe "normal! a_"
    else
        exe "normal! a <- "
    endif
endfunction

function! ReadEvalReply()
    let reply = "No reply"
    let haswaitwarn = 0
    let ii = 0
    while ii < 20
        sleep 100m
        if filereadable($VIMRPLUGIN_TMPDIR . "/eval_reply")
            let tmp = readfile($VIMRPLUGIN_TMPDIR . "/eval_reply")
            if len(tmp) > 0
                let reply = tmp[0]
                break
            endif
        endif
        let ii += 1
        if ii == 2
            echohl WarningMsg
            echon "\rWaiting for reply"
            echohl Normal
            let haswaitwarn = 1
        endif
    endwhile
    if haswaitwarn
        echon "\r                 "
        redraw
    endif
    return reply
endfunction

function RCheckVimCom(msg)
    if exists("g:rplugin_vimcom_checked")
        return 1
    endif
    if g:rplugin_vimcomport == 0
        Py DiscoverVimComPort()
    endif
    if g:rplugin_vimcomport && g:rplugin_vimcom_pkg == "vimcom"
	call RWarningMsg("The R package vimcom.plus is required to " . a:msg)
        return 1
    endif
    return 0
endfunction

function! CompleteChunkOptions()
    let cline = getline(".")
    let cpos = getpos(".")
    let idx1 = cpos[2] - 2
    let idx2 = cpos[2] - 1
    while cline[idx1] =~ '\w' || cline[idx1] == '.' || cline[idx1] == '_'
        let idx1 -= 1
    endwhile
    let idx1 += 1
    let base = strpart(cline, idx1, idx2 - idx1)
    let rr = []
    if strlen(base) == 0
        let newbase = '.'
    else
        let newbase = '^' . substitute(base, "\\$$", "", "")
    endif
    let ktopt = ["animation.fun=;hook_ffmpeg_html", "aniopts=;'controls.loop'", "autodep=;FALSE", "background=;'#F7F7F7'",
                \ "cache.path=;'cache/'", "cache.vars=; ", "cache=;FALSE", "child=; ", "comment=;'##'",
                \ "dependson=;''", "dev.args=; ", "dev=; ", "dpi=;72", "echo=;TRUE",
                \ "engine=;'R'", "error=;TRUE", "eval=;TRUE", "external=;TRUE",
                \ "fig.align=;'left|right|center'", "fig.cap=;''", "fig.env=;'figure'",
                \ "fig.ext=; ", "fig.height=;7", "fig.keep=;'high|none|all|first|last'",
                \ "fig.lp=;'fig:'", "fig.path=; ", "fig.pos=;''", "fig.scap=;''", "fig.subcap=; ",
                \ "fig.show=;'asis|hold|animate|hide'", "fig.width=;7", "highlight=;TRUE",
                \ "include=;TRUE", "interval=;1", "message=;TRUE", "opts.label=;''",
                \ "out.extra=; ", "out.height=;'7in'", "out.width=;'7in'",
                \ "prompt=;FALSE", "purl=;TRUE", "ref.label=; ", "resize.height=; ",
                \ "resize.width=; ", "results=;'markup|asis|hold|hide'", "sanitize=;FALSE",
                \ "size=;'normalsize'", "split=;FALSE", "tidy=;TRUE", "tidy.opts=; ", "warning=;TRUE"]
    for kopt in ktopt
      if kopt =~ newbase
        let tmp1 = split(kopt, ";")
        let tmp2 = {'word': tmp1[0], 'menu': tmp1[1]}
        call add(rr, tmp2)
      endif
    endfor
    call complete(idx1 + 1, rr)
endfunction

function RCompleteArgs()
    let line = getline(".")
    if (&filetype == "rnoweb" && line =~ "^<<.*>>=$") || (&filetype == "rmd" && line =~ "^``` *{r.*}$") || (&filetype == "rrst" && line =~ "^.. {r.*}$") || (&filetype == "r" && line =~ "^#\+")
        call CompleteChunkOptions()
      return ''
    endif
    let lnum = line(".")
    let cpos = getpos(".")
    let idx = cpos[2] - 2
    let idx2 = cpos[2] - 2
    call cursor(lnum, cpos[2] - 1)
    if line[idx2] == ' ' || line[idx2] == ',' || line[idx2] == '('
        let idx2 = cpos[2]
        let argkey = ''
    else
        let idx1 = idx2
        while line[idx1] =~ '\w' || line[idx1] == '.' || line[idx1] == '_'
            let idx1 -= 1
        endwhile
        let idx1 += 1
        let argkey = strpart(line, idx1, idx2 - idx1 + 1)
        let idx2 = cpos[2] - strlen(argkey)
    endif
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
      call BuildROmniList()
    endif
    let flines = g:rplugin_globalenvlines + g:rplugin_liblist
    let np = 1
    let nl = 0

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("complete function arguments.")
            return
        endif
    endif

    while np != 0 && nl < 10
        if line[idx] == '('
            let np -= 1
        elseif line[idx] == ')'
            let np += 1
        endif
        if np == 0
            call cursor(lnum, idx)
            let rkeyword0 = RGetKeyWord()
            let classfor = RGetClassFor(rkeyword0)
            let classfor = substitute(classfor, '\\', "", "g")
            let classfor = substitute(classfor, '"', '\\"', "g")
            let rkeyword = '^' . rkeyword0 . "\x06"
            call cursor(cpos[1], cpos[2])

            " If R is running, use it
            call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
            if classfor == ""
                exe 'Py SendToVimCom("' . g:rplugin_vimcom_pkg . ':::vim.args(' . "'" . rkeyword0 . "', '" . argkey . "')" . '")'
            else
                exe 'Py SendToVimCom("' . g:rplugin_vimcom_pkg . ':::vim.args(' . "'" . rkeyword0 . "', '" . argkey . "', classfor = " . classfor . ")" . '")'
            endif
            if g:rplugin_vimcomport > 0
                let g:rplugin_lastrpl = ReadEvalReply()
                if g:rplugin_lastrpl != "NOT_EXISTS" && g:rplugin_lastrpl != "NO_ARGS" && g:rplugin_lastrpl != "R is busy." && g:rplugin_lastrpl != "NOANSWER" && g:rplugin_lastrpl != "INVALID" && g:rplugin_lastrpl != "" && g:rplugin_lastrpl != "No reply"
                    let args = []
                    if g:rplugin_lastrpl[0] == "\x04" && len(split(g:rplugin_lastrpl, "\x04")) == 1
                        return ''
                    endif
                    let tmp0 = split(g:rplugin_lastrpl, "\x04")
                    let tmp = split(tmp0[0], "\x09")
                    if(len(tmp) > 0)
                        for id in range(len(tmp))
                            let tmp2 = split(tmp[id], "\x07")
                            if tmp2[0] == '...'
                                let tmp3 = tmp2[0]
                            else
                                let tmp3 = tmp2[0] . " = "
                            endif
                            if len(tmp2) > 1
                                call add(args,  {'word': tmp3, 'menu': tmp2[1]})
                            else
                                call add(args,  {'word': tmp3, 'menu': ' '})
                            endif
                        endfor
                        if len(args) > 0 && len(tmp0) > 1
                            call add(args, {'word': ' ', 'menu': tmp0[1]})
                        endif
                        call complete(idx2, args)
                    endif
                    return ''
                endif
            endif

            " If R isn't running, use the prebuilt list of objects
            for omniL in flines
                if omniL =~ rkeyword && omniL =~ "\x06function\x06function\x06"
                    let tmp1 = split(omniL, "\x06")
                    if len(tmp1) < 5
                        return ''
                    endif
                    let info = tmp1[4]
                    let argsL = split(info, "\x09")
                    let args = []
                    for id in range(len(argsL))
                        let newkey = '^' . argkey
                        let tmp2 = split(argsL[id], "\x07")
                        if (argkey == '' || tmp2[0] =~ newkey) && tmp2[0] !~ "No arguments"
                            if tmp2[0] != '...'
                                let tmp2[0] = tmp2[0] . " = "
                            endif
                            if len(tmp2) == 2
                                let tmp3 = {'word': tmp2[0], 'menu': tmp2[1]}
                            else
                                let tmp3 = {'word': tmp2[0], 'menu': ''}
                            endif
                            call add(args, tmp3)
                        endif
                    endfor
                    call complete(idx2, args)
                    return ''
                endif
            endfor
            break
        endif
        let idx -= 1
        if idx <= 0
            let lnum -= 1
            if lnum == 0
                break
            endif
            let line = getline(lnum)
            let idx = strlen(line)
            let nl +=1
        endif
    endwhile
    call cursor(cpos[1], cpos[2])
    return ''
endfunction

function RGetFL(mode)
    if a:mode == "normal"
        let fline = line(".")
        let lline = line(".")
    else
        let fline = line("'<")
        let lline = line("'>")
    endif
    if fline > lline
        let tmp = lline
        let lline = fline
        let fline = tmp
    endif
    return [fline, lline]
endfunction

function IsLineInRCode(vrb, line)
    let save_cursor = getpos(".")
    call setpos(".", [0, a:line, 1, 0])
    let isR = b:IsInRCode(a:vrb)
    call setpos('.', save_cursor)
    return isR
endfunction

function RSimpleCommentLine(mode, what)
    let [fline, lline] = RGetFL(a:mode)
    let cstr = g:vimrplugin_rcomment_string
    if (&filetype == "rnoweb"|| &filetype == "rhelp") && IsLineInRCode(0, fline) == 0
        let cstr = "%"
    elseif (&filetype == "rmd" || &filetype == "rrst") && IsLineInRCode(0, fline) == 0
        return
    endif

    if a:what == "c"
        for ii in range(fline, lline)
            call setline(ii, cstr . getline(ii))
        endfor
    else
        for ii in range(fline, lline)
            call setline(ii, substitute(getline(ii), "^" . cstr, "", ""))
        endfor
    endif
endfunction

function RCommentLine(lnum, ind, cmt)
    let line = getline(a:lnum)
    call cursor(a:lnum, 0)

    if line =~ '^\s*' . a:cmt
        let line = substitute(line, '^\s*' . a:cmt . '*', '', '')
        call setline(a:lnum, line)
        normal! ==
    else
        if g:vimrplugin_indent_commented
            while line =~ '^\s*\t'
                let line = substitute(line, '^\(\s*\)\t', '\1' . s:curtabstop, "")
            endwhile
            let line = strpart(line, a:ind)
        endif
        let line = a:cmt . ' ' . line
        call setline(a:lnum, line)
        if g:vimrplugin_indent_commented
            normal! ==
        endif
    endif
endfunction

function RComment(mode)
    let cpos = getpos(".")
    let [fline, lline] = RGetFL(a:mode)

    " What comment string to use?
    if g:r_indent_ess_comments
        if g:vimrplugin_indent_commented
            let cmt = '##'
        else
            let cmt = '###'
        endif
    else
        let cmt = '#'
    endif
    if (&filetype == "rnoweb" || &filetype == "rhelp") && IsLineInRCode(0, fline) == 0
        let cmt = "%"
    elseif (&filetype == "rmd" || &filetype == "rrst") && IsLineInRCode(0, fline) == 0
        return
    endif

    let lnum = fline
    let ind = &tw
    while lnum <= lline
        let idx = indent(lnum)
        if idx < ind
            let ind = idx
        endif
        let lnum += 1
    endwhile

    let lnum = fline
    let s:curtabstop = repeat(' ', &tabstop)
    while lnum <= lline
        call RCommentLine(lnum, ind, cmt)
        let lnum += 1
    endwhile
    call cursor(cpos[1], cpos[2])
endfunction

function MovePosRCodeComment(mode)
    if a:mode == "selection"
        let fline = line("'<")
        let lline = line("'>")
    else
        let fline = line(".")
        let lline = fline
    endif

    let cpos = g:r_indent_comment_column
    let lnum = fline
    while lnum <= lline
        let line = getline(lnum)
        let cleanl = substitute(line, '\s*#.*', "", "")
        let llen = strlen(cleanl)
        if llen > (cpos - 2)
            let cpos = llen + 2
        endif
        let lnum += 1
    endwhile

    let lnum = fline
    while lnum <= lline
        call MovePosRLineComment(lnum, cpos)
        let lnum += 1
    endwhile
    call cursor(fline, cpos + 1)
    if a:mode == "insert"
        startinsert!
    endif
endfunction

function MovePosRLineComment(lnum, cpos)
    let line = getline(a:lnum)

    let ok = 1

    if &filetype == "rnoweb"
        if search("^<<", "bncW") > search("^@", "bncW")
            let ok = 1
        else
            let ok = 0
        endif
        if line =~ "^<<.*>>=$"
            let ok = 0
        endif
        if ok == 0
            call RWarningMsg("Not inside an R code chunk.")
            return
        endif
    endif

    if &filetype == "rhelp"
        let lastsection = search('^\\[a-z]*{', "bncW")
        let secname = getline(lastsection)
        if secname =~ '^\\usage{' || secname =~ '^\\examples{' || secname =~ '^\\dontshow{' || secname =~ '^\\dontrun{' || secname =~ '^\\donttest{' || secname =~ '^\\testonly{' || secname =~ '^\\method{.*}{.*}('
            let ok = 1
        else
            let ok = 0
        endif
        if ok == 0
            call RWarningMsg("Not inside an R code section.")
            return
        endif
    endif

    if line !~ '#'
        " Write the comment character
        let line = line . repeat(' ', a:cpos)
        let cmd = "let line = substitute(line, '^\\(.\\{" . (a:cpos - 1) . "}\\).*', '\\1# ', '')"
        exe cmd
        call setline(a:lnum, line)
    else
        " Align the comment character(s)
        let line = substitute(line, '\s*#', '#', "")
        let idx = stridx(line, '#')
        let str1 = strpart(line, 0, idx)
        let str2 = strpart(line, idx)
        let line = str1 . repeat(' ', a:cpos - idx - 1) . str2
        call setline(a:lnum, line)
    endif
endfunction

" Count braces
function CountBraces(line)
    let line2 = substitute(a:line, "{", "", "g")
    let line3 = substitute(a:line, "}", "", "g")
    let result = strlen(line3) - strlen(line2)
    return result
endfunction

" Skip empty lines and lines whose first non blank char is '#'
function GoDown()
    if &filetype == "rnoweb"
        let curline = getline(".")
        let fc = curline[0]
        if fc == '@'
            call RnwNextChunk()
            return
        endif
    elseif &filetype == "rmd"
        let curline = getline(".")
        if curline =~ '^```$'
            call RmdNextChunk()
            return
        endif
    elseif &filetype == "rrst"
        let curline = getline(".")
        if curline =~ '^\.\. \.\.$'
            call RrstNextChunk()
            return
        endif
    endif

    let i = line(".") + 1
    call cursor(i, 1)
    let curline = substitute(getline("."), '^\s*', "", "")
    let fc = curline[0]
    let lastLine = line("$")
    while i < lastLine && (fc == '#' || strlen(curline) == 0)
        let i = i + 1
        call cursor(i, 1)
        let curline = substitute(getline("."), '^\s*', "", "")
        let fc = curline[0]
    endwhile
endfunction

" Adapted from screen plugin:
function TmuxActivePane()
  let line = system("tmux list-panes | grep \'(active)$'")
  let paneid = matchstr(line, '\v\%\d+ \(active\)')
  if !empty(paneid)
    return matchstr(paneid, '\v^\%\d+')
  else
    return matchstr(line, '\v^\d+')
  endif
endfunction

function StartR_TmuxSplit(rcmd)
    let g:rplugin_vim_pane = TmuxActivePane()
    call system("tmux set-environment -g VIMRPLUGIN_TMPDIR " . g:rplugin_esc_tmpdir)
    call system("tmux set-environment -g VIMRPLUGIN_HOME " . g:rplugin_home)
    call system("tmux set-environment -g VIM_PANE " . g:rplugin_vim_pane)
    if v:servername != ""
        call system("tmux set-environment VIMEDITOR_SVRNM " . v:servername)
    endif
    call system("tmux set-environment VIMINSTANCEID " . $VIMINSTANCEID)
    let tcmd = "tmux split-window "
    if g:vimrplugin_vsplit
        if g:vimrplugin_rconsole_width == -1
            let tcmd .= "-h"
        else
            let tcmd .= "-h -l " . g:vimrplugin_rconsole_width
        endif
    else
        let tcmd .= "-l " . g:vimrplugin_rconsole_height
    endif
    if !g:vimrplugin_restart
        " Let Tmux automatically kill the panel when R quits.
        let tcmd .= " '" . a:rcmd . "'"
    endif
    let rlog = system(tcmd)
    if v:shell_error
        call RWarningMsg(rlog)
        return
    endif
    let g:rplugin_rconsole_pane = TmuxActivePane()
    let rlog = system("tmux select-pane -t " . g:rplugin_vim_pane)
    if v:shell_error
        call RWarningMsg(rlog)
        return
    endif
    let g:SendCmdToR = function('SendCmdToR_TmuxSplit')
    if g:vimrplugin_restart
        sleep 200m
        let ca_ck = g:vimrplugin_ca_ck
        let g:vimrplugin_ca_ck = 0
        call g:SendCmdToR(a:rcmd)
        let g:vimrplugin_ca_ck = ca_ck
    endif
    let g:rplugin_last_rcmd = a:rcmd
endfunction


function StartR_ExternalTerm(rcmd)
    if $DISPLAY == ""
        call RWarningMsg("Start 'tmux' before Vim. The X Window system is required to run R in an external terminal.")
        return
    endif

    " Create a custom tmux.conf
    let cnflines = [
                \ 'set-environment -g VIMRPLUGIN_TMPDIR ' . g:rplugin_esc_tmpdir,
                \ 'set-environment -g VIMRPLUGIN_HOME ' . g:rplugin_home,
                \ 'set-environment VIMINSTANCEID ' . $VIMINSTANCEID ]
    if v:servername != ""
        let cnflines = cnflines + [ 'set-environment VIMEDITOR_SVRNM ' . v:servername ]
    endif
    if g:vimrplugin_notmuxconf
        let cnflines = cnflines + [ 'source-file ~/.tmux.conf' ]
    else
        let cnflines = cnflines + [
                    \ 'set-option -g prefix C-a',
                    \ 'unbind-key C-b',
                    \ 'bind-key C-a send-prefix',
                    \ 'set-window-option -g mode-keys vi',
                    \ 'set -g status off',
                    \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'" ]
        if g:vimrplugin_external_ob || !has("gui_running")
            call extend(cnflines, ['set -g mode-mouse on', 'set -g mouse-select-pane on', 'set -g mouse-resize-pane on'])
        endif
    endif
    call extend(cnflines, ['set-environment VIMINSTANCEID "' . $VIMINSTANCEID . '"'])
    call writefile(cnflines, s:tmxcnf)
	
	let is_bash = system('echo $BASH')
	if v:shell_error || len(is_bash) == 0 || empty(matchstr(tolower(is_bash),'undefined variable')) == 0
		let rcmd = a:rcmd
	else
		let rcmd = "VIMINSTANCEID=" . $VIMINSTANCEID . " " . a:rcmd
	endif

    call system('export VIMRPLUGIN_TMPDIR=' . $VIMRPLUGIN_TMPDIR)
    call system('export VIMRPLUGIN_HOME=' . g:rplugin_home)
    call system('export VIMINSTANCEID=' . $VIMINSTANCEID)
    if v:servername != ""
        call system('export VIMEDITOR_SVRNM=' . v:servername)
    endif
    " Start the terminal emulator even if inside a Tmux session
    if $TMUX != ""
        let tmuxenv = $TMUX
        let $TMUX = ""
        call system('tmux set-option -ga update-environment " TMUX_PANE VIMRPLUGIN_TMPDIR VIMINSTANCEID"')
    endif
    let tmuxcnf = '-f "' . s:tmxcnf . '"'

    call system("tmux has-session -t " . g:rplugin_tmuxsname)
    if v:shell_error
        if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
            let opencmd = printf("%s 'tmux -2 %s new-session -s %s \"%s\"' &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname, rcmd)
        else
            let opencmd = printf("%s tmux -2 %s new-session -s %s \"%s\" &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname, rcmd)
        endif
    else
        if g:rplugin_termcmd =~ "gnome-terminal" || g:rplugin_termcmd =~ "xfce4-terminal" || g:rplugin_termcmd =~ "terminal" || g:rplugin_termcmd =~ "iterm"
            let opencmd = printf("%s 'tmux -2 %s attach-session -d -t %s' &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname)
        else
            let opencmd = printf("%s tmux -2 %s attach-session -d -t %s &", g:rplugin_termcmd, tmuxcnf, g:rplugin_tmuxsname)
        endif
    endif

    let rlog = system(opencmd)
    if v:shell_error
        call RWarningMsg(rlog)
        return
    endif
    if exists("tmuxenv")
        let $TMUX = tmuxenv
    endif
    let g:SendCmdToR = function('SendCmdToR_Term')
endfunction

function StartR_Windows()
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
        Py FindRConsole()
        Py vim.command("let g:rplugin_rconsole_hndl = " + str(RConsole))
        if g:rplugin_rconsole_hndl != 0
            call RWarningMsg("There is already a window called '" . g:rplugin_R_window_ttl . "'.")
            unlet g:rplugin_R_window_ttl
            return
        endif
    endif
    Py StartRPy()
    lcd -
    let g:SendCmdToR = function('SendCmdToR_Windows')
endfunction

function StartR_OSX()
    if IsSendCmdToRFake()
        return
    endif
    if g:rplugin_r64app && g:vimrplugin_i386 == 0
        let rcmd = "/Applications/R64.app"
    else
        let rcmd = "/Applications/R.app"
    endif
    if b:rplugin_r_args != " "
        " https://github.com/jcfaria/Vim-R-plugin/issues/63
        " https://stat.ethz.ch/pipermail/r-sig-mac/2013-February/009978.html
        call RWarningMsg('R.app does not support command line arguments. To pass "' . b:rplugin_r_args . '" to R, you must run it in a console. Set "vimrplugin_applescript = 0" (you may need to install XQuartz)')
    endif
    let rlog = system("open " . rcmd)
    if v:shell_error
        call RWarningMsg(rlog)
    endif
    lcd -
    let g:SendCmdToR = function('SendCmdToR_OSX')
endfunction

function IsSendCmdToRFake()
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
	if exists("g:maplocalleader")
	    call RWarningMsg("As far as I know, R is already running. Did you quit it from within Vim (" . g:maplocalleader . "rq if not remapped)?")
	else
	    call RWarningMsg("As far as I know, R is already running. Did you quit it from within Vim (\\rq if not remapped)?")
	endif
	return 1
    endif
    return 0
endfunction

" Start R
function StartR(whatr)
    call writefile([], $VIMRPLUGIN_TMPDIR . "/globenv_" . $VIMINSTANCEID)
    call writefile([], $VIMRPLUGIN_TMPDIR . "/liblist_" . $VIMINSTANCEID)
    if filereadable($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
        call delete($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
    endif

    if !exists("b:rplugin_R")
        call SetRPath()
    endif

    " Change to buffer's directory before starting R
    lcd %:p:h

    if a:whatr =~ "vanilla"
        let b:rplugin_r_args = "--vanilla"
    else
        if a:whatr =~ "custom"
            call inputsave()
            let b:rplugin_r_args = input('Enter parameters for R: ')
            call inputrestore()
        endif
    endif

    if g:vimrplugin_applescript
        call StartR_OSX()
        return
    endif

    if has("win32") || has("win64")
        call StartR_Windows()
        return
    endif

    if g:vimrplugin_only_in_tmux && $TMUX_PANE == ""
        call RWarningMsg("Not inside Tmux.")
        lcd -
        return
    endif

    " R was already started. Should restart it or warn?
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
        if g:rplugin_tmuxwasfirst
            if g:vimrplugin_restart
                call g:SendCmdToR('quit(save = "no")')
                sleep 100m
                call delete($VIMRPLUGIN_TMPDIR . "/vimcom_running")
                let ca_ck = g:vimrplugin_ca_ck
                let g:vimrplugin_ca_ck = 0
                call g:SendCmdToR(g:rplugin_last_rcmd)
                let g:vimrplugin_ca_ck = ca_ck
                if IsExternalOBRunning()
                    call VimExprToOB('ResetVimComPort()')
                    call WaitVimComStart()
                    exe 'Py SendToVimCom("\007' . g:rplugin_obsname . '")'
                    Py SendToVimCom("\003.GlobalEnv [Restarting R]")
                    Py SendToVimCom("\004Libraries [Restarting()]")
                    " vimcom automatically update the libraries view, but not
                    " the GlobalEnv one because vimcom_count_objects() returns 0.
                    call VimExprToOB('UpdateOB("GlobalEnv")')
                endif
                return
            elseif IsSendCmdToRFake()
		return
            endif
        else
            if g:vimrplugin_restart
                call RQuit("restartR")
                call ResetVimComPort()
            endif
        endif
    endif

    if b:rplugin_r_args == " "
        let rcmd = b:rplugin_R
    else
        let rcmd = b:rplugin_R . " " . b:rplugin_r_args
    endif

    if g:rplugin_tmuxwasfirst
        call StartR_TmuxSplit(rcmd)
    else
        if g:vimrplugin_restart && bufloaded(b:objbrtitle)
            call delete($VIMRPLUGIN_TMPDIR . "/vimcom_running")
        endif
        call StartR_ExternalTerm(rcmd)
        if g:vimrplugin_restart && bufloaded(b:objbrtitle)
            call WaitVimComStart()
            exe 'Py SendToVimCom("\007' . v:servername . '")'
            Py SendToVimCom("\003.GlobalEnv [Restarting R]")
            Py SendToVimCom("\004Libraries [Restarting()]")
            if exists("*UpdateOB")
                call UpdateOB("GlobalEnv")
            endif
        endif
    endif

    " Go back to original directory:
    lcd -
    echon
endfunction

function WaitVimComStart()
    sleep 300m
    let ii = 0
    while !filereadable($VIMRPLUGIN_TMPDIR . "/vimcom_running") && ii < 20
        let ii = ii + 1
        sleep 200m
    endwhile
    if filereadable($VIMRPLUGIN_TMPDIR . "/vimcom_running") && g:rplugin_tmuxwasfirst
        sleep 100m
        call g:SendCmdToR("\014")
    endif
endfunction

function IsExternalOBRunning()
    if exists("g:rplugin_ob_pane")
        let plst = system("tmux list-panes | cat")
        if plst =~ g:rplugin_ob_pane
            return 1
        endif
    endif
    return 0
endfunction

function ResetVimComPort()
    Py VimComPort = 0
endfunction

function StartObjBrowser_Tmux()
    if b:rplugin_extern_ob
        " This is the Object Browser
        echoerr "StartObjBrowser_Tmux() called."
        return
    endif

    " Don't start the Object Browser if it already exists
    if IsExternalOBRunning()
        Py SendToVimCom("\003GlobalEnv [OB StartObjBrowser_Tmux]")
        sleep 50m
        Py SendToVimCom("\004Libraries [OB StartObjBrowser_Tmux]")
        sleep 50m
        if $DISPLAY == "" && exists("g:rplugin_ob_pane")
            let slog = system("tmux set-buffer ':silent call UpdateOB(\"both\")\<C-M>:\<Esc>' && tmux paste-buffer -t " . g:rplugin_ob_pane . " && tmux select-pane -t " . g:rplugin_ob_pane)
            if v:shell_error
                call RWarningMsg(slog)
            endif
        endif
        return
    endif

    let objbrowserfile = $VIMRPLUGIN_TMPDIR . "/objbrowserInit"
    let tmxs = " "

    if v:servername == ""
        let myservername = '""'
    else
        let myservername = '"' . v:servername . '"'
    endif

    call writefile([
                \ 'let g:rplugin_editor_sname = ' . myservername,
                \ 'let g:rplugin_vim_pane = "' . g:rplugin_vim_pane . '"',
                \ 'let g:rplugin_rconsole_pane = "' . g:rplugin_rconsole_pane . '"',
                \ 'let b:objbrtitle = "' . b:objbrtitle . '"',
                \ 'let showmarks_enable = 0',
                \ 'let g:rplugin_tmuxsname = "' . g:rplugin_tmuxsname . '"',
                \ 'let b:rscript_buffer = "' . bufname("%") . '"',
                \ 'set filetype=rbrowser',
                \ 'let b:rplugin_extern_ob = 1',
                \ 'set shortmess=atI',
                \ 'set rulerformat=%3(%l%)',
                \ 'set noruler',
                \ 'exe "PyFile " . substitute(g:rplugin_home, " ", '. "'\\\\ '" . ', "g") . "/r-plugin/vimcom.py"',
                \ 'let g:SendCmdToR = function("SendCmdToR_TmuxSplit")',
                \ 'if has("clientserver") && v:servername != ""',
                \ "   exe 'Py SendToVimCom(" . '"\007' . "' . v:servername . '" . '")' . "'",
                \ 'endif',
                \ 'Py SendToVimCom("\003GlobalEnv [OB init]")',
                \ 'sleep 50m',
                \ 'Py SendToVimCom("\004Libraries [OB init]")',
                \ 'if v:servername == ""',
                \ '    sleep 100m',
                \ '    call UpdateOB("GlobalEnv")',
                \ 'endif'], objbrowserfile)

    if g:vimrplugin_objbr_place =~ "left"
        let panw = system("tmux list-panes | cat")
        if g:vimrplugin_objbr_place =~ "console"
            " Get the R Console width:
            let panw = substitute(panw, '.*[0-9]: \[\([0-9]*\)x[0-9]*.\{-}' . g:rplugin_rconsole_pane . '\>.*', '\1', "")
        else
            " Get the Vim width
            let panw = substitute(panw, '.*[0-9]: \[\([0-9]*\)x[0-9]*.\{-}' . g:rplugin_vim_pane . '\>.*', '\1', "")
        endif
        let panewidth = panw - g:vimrplugin_objbr_w
        " Just to be safe: If the above code doesn't work as expected
        " and we get a spurious value:
        if panewidth < 30 || panewidth > 180
            let panewidth = 80
        endif
    else
        let panewidth = g:vimrplugin_objbr_w
    endif
    if g:vimrplugin_objbr_place =~ "console"
        let obpane = g:rplugin_rconsole_pane
    else
        let obpane = g:rplugin_vim_pane
    endif

    if has("clientserver")
        let obsname = "--servername " . g:rplugin_obsname
    else
        let obsname = " "
    endif

    let cmd = "tmux split-window -h -l " . panewidth . " -t " . obpane . ' "vim ' . obsname . " -c 'source " . substitute(objbrowserfile, ' ', '\\ ', 'g') . "'" . '"'
    let rlog = system(cmd)
    if v:shell_error
        let rlog = substitute(rlog, '\n', ' ', 'g')
        let rlog = substitute(rlog, '\r', ' ', 'g')
        call RWarningMsg(rlog)
        let g:rplugin_running_objbr = 0
        return 0
    endif

    let g:rplugin_ob_pane = TmuxActivePane()
    let rlog = system("tmux select-pane -t " . g:rplugin_vim_pane)
    if v:shell_error
        call RWarningMsg(rlog)
        return 0
    endif

    if g:vimrplugin_objbr_place =~ "left"
        if g:vimrplugin_objbr_place =~ "console"
            call system("tmux swap-pane -d -s " . g:rplugin_rconsole_pane . " -t " . g:rplugin_ob_pane)
        else
            call system("tmux swap-pane -d -s " . g:rplugin_vim_pane . " -t " . g:rplugin_ob_pane)
        endif
    endif
    if g:rplugin_ob_warn_shown == 0
        if !has("clientserver")
            call RWarningMsg("The +clientserver feature is required to automatically update the Object Browser.")
            sleep 200m
        else
            if $DISPLAY == ""
                call RWarningMsg("The X Window system is required to automatically update the Object Browser.")
                sleep 200m
            endif
        endif
        let g:rplugin_ob_warn_shown = 1
    endif
    return
endfunction

function StartObjBrowser_Vim()
    let wmsg = ""
    if v:servername == ""
        if g:rplugin_ob_warn_shown == 0
            if !has("clientserver")
                let wmsg = "The +clientserver feature is required to automatically update the Object Browser."
            else
                if $DISPLAY == "" && !(has("win32") || has("win64"))
                    let wmsg = "The X Window system is required to automatically update the Object Browser."
                else
                    let wmsg ="The Object Browser will not be automatically updated because Vim's client/server was not started."
                endif
            endif
        endif
        let g:rplugin_ob_warn_shown = 1
    else
        exe 'Py SendToVimCom("\007' . v:servername . '")'
    endif

    " Either load or reload the Object Browser
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    if bufloaded(b:objbrtitle)
        exe "sb " . b:objbrtitle
        let wmsg = ""
    else
        " Copy the values of some local variables that will be inherited
        let g:tmp_objbrtitle = b:objbrtitle
        let g:tmp_tmuxsname = g:rplugin_tmuxsname
        let g:tmp_curbufname = bufname("%")

        let l:sr = &splitright
        if g:vimrplugin_objbr_place =~ "left"
            set nosplitright
        else
            set splitright
        endif
        sil exe "vsplit " . b:objbrtitle
        let &splitright = l:sr
        sil exe "vertical resize " . g:vimrplugin_objbr_w
        sil set filetype=rbrowser

        " Inheritance of some local variables
        let g:rplugin_tmuxsname = g:tmp_tmuxsname
        let b:objbrtitle = g:tmp_objbrtitle
        let b:rscript_buffer = g:tmp_curbufname
        unlet g:tmp_objbrtitle
        unlet g:tmp_tmuxsname
        unlet g:tmp_curbufname
        exe "PyFile " . substitute(g:rplugin_home, " ", '\\ ', "g") . "/r-plugin/vimcom.py"
        Py SendToVimCom("\003GlobalEnv [StartObjBrowser_Vim]")
        Py SendToVimCom("\004Libraries [StartObjBrowser_Vim]")
        call UpdateOB("GlobalEnv")
    endif
    if wmsg != ""
        call RWarningMsg(wmsg)
        sleep 200m
    endif
endfunction

" Open an Object Browser window
function RObjBrowser()
    if !has("python") && !has("python3")
        call RWarningMsg("Python support is required to run the Object Browser.")
        return
    endif

    " Only opens the Object Browser if R is running
    if string(g:SendCmdToR) == "function('SendCmdToR_fake')"
        call RWarningMsg("The Object Browser can be opened only if R is running.")
        return
    endif

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("run the Object Browser on Windows.")
            return
        endif
    endif

    if g:rplugin_running_objbr == 1
        " Called twice due to BufEnter event
        return
    endif

    let g:rplugin_running_objbr = 1

    if !b:rplugin_extern_ob
        if g:rplugin_tmuxwasfirst
            call StartObjBrowser_Tmux()
        else
            call StartObjBrowser_Vim()
        endif
    endif
    if exists("*UpdateOB")
        Py SendToVimCom("\003GlobalEnv [RObjBrowser()]")
        Py SendToVimCom("\004Libraries [RObjBrowser()]")
        call UpdateOB("both")
    endif
    let g:rplugin_running_objbr = 0
    return
endfunction

function VimExprToOB(msg)
    if serverlist() =~ "\\<" . g:rplugin_obsname . "\n"
        return remote_expr(g:rplugin_obsname, a:msg)
    endif
    return "Vim server not found"
endfunction

function RBrowserOpenCloseLists(status)
    if a:status == 1
        if exists("g:rplugin_curview")
            let curview = g:rplugin_curview
        else
            if IsExternalOBRunning()
                let curview = VimExprToOB('g:rplugin_curview')
                if curview == "Vim server not found"
                    return
                endif
            else
                let curview = "GlobalEnv"
            endif
        endif
        if curview == "libraries"
            echohl WarningMsg
            echon "GlobalEnv command only."
            sleep 1
            echohl Normal
            normal! :<Esc>
            return
        endif
    endif

    " Avoid possibly freezing cross messages between Vim and R
    if exists("g:rplugin_curview") && v:servername != ""
        Py SendToVimCom("\x08Stop updating info [RBrowserOpenCloseLists()]")
        let stt = a:status
    else
        let stt = a:status + 2
    endif

    let switchedbuf = 0
    if buflisted("Object_Browser") && g:rplugin_curbuf != "Object_Browser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        sil noautocmd sb Object_Browser
        let switchedbuf = 1
    endif

    exe 'Py SendToVimCom("' . "\006" . stt . '")'

    if g:rplugin_lastrpl == "R is busy."
        call RWarningMsg("R is busy.")
    endif

    if switchedbuf
        exe "sil noautocmd sb " . g:rplugin_curbuf
        exe "set switchbuf=" . savesb
    endif
    if exists("g:rplugin_curview")
        call UpdateOB("both")
        if v:servername != ""
            exe 'Py SendToVimCom("\007' . v:servername . '")'
        endif
    elseif IsExternalOBRunning()
        call VimExprToOB('UpdateOB("GlobalEnv")')
        exe 'Py SendToVimCom("\007' . g:rplugin_obsname . '")'
    endif
endfunction

function RFormatCode() range
    if g:rplugin_vimcomport == 0
        exe "Py DiscoverVimComPort()"
        if g:rplugin_vimcomport == 0
            return
        endif
    endif

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("run :Rformat.")
            return
        endif
    endif

    let lns = getline(a:firstline, a:lastline)
    call writefile(lns, $VIMRPLUGIN_TMPDIR . "/unformatted_code")
    let wco = &textwidth
    if wco == 0
        let wco = 78
    elseif wco < 20
        let wco = 20
    elseif wco > 180
        let wco = 180
    endif
    call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
    exe "Py SendToVimCom('formatR::tidy.source(\"" . $VIMRPLUGIN_TMPDIR . "/unformatted_code" . "\", file = \"" . $VIMRPLUGIN_TMPDIR . "/formatted_code\", width.cutoff = " . wco . ")')"
    let g:rplugin_lastrpl = ReadEvalReply()
    if g:rplugin_lastrpl == "R is busy." || g:rplugin_lastrpl == "UNKNOWN" || g:rplugin_lastrpl =~ "^Error" || g:rplugin_lastrpl == "INVALID" || g:rplugin_lastrpl == "ERROR" || g:rplugin_lastrpl == "EMPTY" || g:rplugin_lastrpl == "No reply"
        call RWarningMsg(g:rplugin_lastrpl)
        return
    endif
    let lns = readfile($VIMRPLUGIN_TMPDIR . "/formatted_code")
    silent exe a:firstline . "," . a:lastline . "delete"
    call append(a:firstline - 1, lns)
    echo (a:lastline - a:firstline + 1) . " lines formatted."
endfunction

function RInsert(cmd)
    if g:rplugin_vimcomport == 0
        exe "Py DiscoverVimComPort()"
        if g:rplugin_vimcomport == 0
            return
        endif
    endif

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("run :Rinsert.")
            return
        endif
    endif

    call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
    call delete($VIMRPLUGIN_TMPDIR . "/Rinsert")
    exe "Py SendToVimCom('capture.output(" . a:cmd . ', file = "' . $VIMRPLUGIN_TMPDIR . "/Rinsert" . '")' . "')"
    let g:rplugin_lastrpl = ReadEvalReply()
    if g:rplugin_lastrpl == "R is busy." || g:rplugin_lastrpl == "UNKNOWN" || g:rplugin_lastrpl =~ "^Error" || g:rplugin_lastrpl == "INVALID" || g:rplugin_lastrpl == "ERROR" || g:rplugin_lastrpl == "EMPTY" || g:rplugin_lastrpl == "No reply"
        call RWarningMsg(g:rplugin_lastrpl)
    else
        silent exe "read " . g:rplugin_esc_tmpdir . "/Rinsert"
    endif
endfunction

" Function to send commands
" return 0 on failure and 1 on success
function SendCmdToR_fake(cmd)
    call RWarningMsg("Did you already start R?")
    return 0
endfunction

function SendCmdToR_TmuxSplit(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    if !exists("g:rplugin_rconsole_pane")
        " Should never happen
        call RWarningMsg("Missing internal variable: g:rplugin_rconsole_pane")
    endif
    let str = substitute(cmd, "'", "'\\\\''", "g")
    let scmd = "tmux set-buffer '" . str . "\<C-M>' && tmux paste-buffer -t " . g:rplugin_rconsole_pane
    let rlog = system(scmd)
    if v:shell_error
        let rlog = substitute(rlog, "\n", " ", "g")
        let rlog = substitute(rlog, "\r", " ", "g")
        call RWarningMsg(rlog)
        let g:SendCmdToR = function('SendCmdToR_fake')
        return 0
    endif
    return 1
endfunction

function SendCmdToR_Windows(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    let cmd = cmd . "\n"
    let slen = len(cmd)
    let str = ""
    for i in range(0, slen)
        let str = str . printf("\\x%02X", char2nr(cmd[i]))
    endfor
    exe "Py" . " SendToRConsole(b'" . str . "')"
    return 1
endfunction

function SendCmdToR_OSX(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    if g:rplugin_r64app && g:vimrplugin_i386 == 0
        let rcmd = "R64"
    else
        let rcmd = "R"
    endif

    " for some reason it doesn't like "\025"
    let cmd = a:cmd
    let cmd = substitute(cmd, "\\", '\\\', 'g')
    let cmd = substitute(cmd, '"', '\\"', "g")
    let cmd = substitute(cmd, "'", "'\\\\''", "g")
    call system("osascript -e 'tell application \"".rcmd."\" to cmd \"" . cmd . "\"'")
    return 1
endfunction

function SendCmdToR_Term(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    " Send the command to R running in an external terminal emulator
    let str = substitute(cmd, "'", "'\\\\''", "g")
    let scmd = "tmux set-buffer '" . str . "\<C-M>' && tmux paste-buffer -t " . g:rplugin_tmuxsname . '.0'
    let rlog = system(scmd)
    if v:shell_error
        let rlog = substitute(rlog, '\n', ' ', 'g')
        let rlog = substitute(rlog, '\r', ' ', 'g')
        call RWarningMsg(rlog)
        let g:SendCmdToR = function('SendCmdToR_fake')
        return 0
    endif
    return 1
endfunction

" Get the word either under or after the cursor.
" Works for word(| where | is the cursor position.
function RGetKeyWord()
    " Go back some columns if character under cursor is not valid
    let save_cursor = getpos(".")
    let curline = line(".")
    let line = getline(curline)
    if strlen(line) == 0
        return ""
    endif
    " line index starts in 0; cursor index starts in 1:
    let i = col(".") - 1
    while i > 0 && "({[ " =~ line[i]
        call setpos(".", [0, line("."), i])
        let i -= 1
    endwhile
    let save_keyword = &iskeyword
    setlocal iskeyword=@,48-57,_,.,$,@-@
    let rkeyword = expand("<cword>")
    exe "setlocal iskeyword=" . save_keyword
    call setpos(".", save_cursor)
    return rkeyword
endfunction

" Send sources to R
function RSourceLines(lines, e)
    let lines = a:lines
    if &filetype == "rrst"
        let lines = map(copy(lines), 'substitute(v:val, "^\\.\\. \\?", "", "")')
    endif
    if &filetype == "rmd"
        let lines = map(copy(lines), 'substitute(v:val, "^\\`\\`\\?", "", "")')
    endif
    call writefile(lines, b:rsource)
    if a:e == "echo"
        if exists("g:vimrplugin_maxdeparse")
            let rcmd = 'base::source("' . b:rsource . '", echo=TRUE, max.deparse=' . g:vimrplugin_maxdeparse . ')'
        else
            let rcmd = 'base::source("' . b:rsource . '", echo=TRUE)'
        endif
    else
        let rcmd = 'base::source("' . b:rsource . '")'
    endif
    let ok = g:SendCmdToR(rcmd)
    return ok
endfunction

" Send file to R
function SendFileToR(e)
    update
    let fpath = expand("%:p")
    if has("win32") || has("win64")
        let fpath = substitute(fpath, "\\", "/", "g")
    endif
    if a:e == "echo"
        call g:SendCmdToR('base::source("' . fpath . '", echo=TRUE)')
    else
        call g:SendCmdToR('base::source("' . fpath . '")')
    endif
endfunction

" Send block to R
" Adapted of the plugin marksbrowser
" Function to get the marks which the cursor is between
function SendMBlockToR(e, m)
    if &filetype != "r" && b:IsInRCode(1) == 0
        return
    endif

    let curline = line(".")
    let lineA = 1
    let lineB = line("$")
    let maxmarks = strlen(s:all_marks)
    let n = 0
    while n < maxmarks
        let c = strpart(s:all_marks, n, 1)
        let lnum = line("'" . c)
        if lnum != 0
            if lnum <= curline && lnum > lineA
                let lineA = lnum
            elseif lnum > curline && lnum < lineB
                let lineB = lnum
            endif
        endif
        let n = n + 1
    endwhile
    if lineA == 1 && lineB == (line("$"))
        call RWarningMsg("The file has no mark!")
        return
    endif
    if lineB < line("$")
        let lineB -= 1
    endif
    let lines = getline(lineA, lineB)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down" && lineB != line("$")
        call cursor(lineB, 1)
        call GoDown()
    endif
endfunction

" Send functions to R
function SendFunctionToR(e, m)
    if &filetype != "r" && b:IsInRCode(1) == 0
        return
    endif

    let startline = line(".")
    let save_cursor = getpos(".")
    let line = SanitizeRLine(getline("."))
    let i = line(".")
    while i > 0 && line !~ "function"
        let i -= 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if i == 0
        call RWarningMsg("Begin of function not found.")
        return
    endif
    let functionline = i
    while i > 0 && line !~ "<-"
        let i -= 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if i == 0
        call RWarningMsg("The function assign operator  <-  was not found.")
        return
    endif
    let firstline = i
    let i = functionline
    let line = SanitizeRLine(getline(i))
    let tt = line("$")
    while i < tt && line !~ "{"
        let i += 1
        let line = SanitizeRLine(getline(i))
    endwhile
    if i == tt
        call RWarningMsg("The function opening brace was not found.")
        return
    endif
    let nb = CountBraces(line)
    while i < tt && nb > 0
        let i += 1
        let line = SanitizeRLine(getline(i))
        let nb += CountBraces(line)
    endwhile
    if nb != 0
        call RWarningMsg("The function closing brace was not found.")
        return
    endif
    let lastline = i

    if startline > lastline
        call setpos(".", [0, firstline - 1, 1])
        call SendFunctionToR(a:e, a:m)
        call setpos(".", save_cursor)
        return
    endif

    let lines = getline(firstline, lastline)
    let ok = RSourceLines(lines, a:e)
    if  ok == 0
        return
    endif
    if a:m == "down"
        call cursor(lastline, 1)
        call GoDown()
    endif
endfunction

" Send selection to R
function SendSelectionToR(e, m)
    if &filetype != "r" && b:IsInRCode(1) == 0
        if !(&filetype == "rnoweb" && getline(".") =~ "\\Sexpr{")
            return
        endif
    endif

    if line("'<") == line("'>")
        let i = col("'<") - 1
        let j = col("'>") - i
        let l = getline("'<")
        let line = strpart(l, i, j)
        let ok = g:SendCmdToR(line)
        if ok && a:m =~ "down"
            call GoDown()
        endif
        return
    endif

    let lines = getline("'<", "'>")

    if visualmode() == "\<C-V>"
        let lj = line("'<")
        let cj = col("'<")
        let lk = line("'>")
        let ck = col("'>")
        if cj > ck
            let bb = ck - 1
            let ee = cj - ck + 1
        else
            let bb = cj - 1
            let ee = ck - cj + 1
        endif
        if cj > len(getline(lj)) || ck > len(getline(lk))
            for idx in range(0, len(lines) - 1)
                let lines[idx] = strpart(lines[idx], bb)
            endfor
        else
            for idx in range(0, len(lines) - 1)
                let lines[idx] = strpart(lines[idx], bb, ee)
            endfor
        endif
    else
        let i = col("'<") - 1
        let j = col("'>")
        let lines[0] = strpart(lines[0], i)
        let llen = len(lines) - 1
        let lines[llen] = strpart(lines[llen], 0, j)
    endif

    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif

    if a:m == "down"
        call GoDown()
    else
        normal! gv
    endif
endfunction

" Send paragraph to R
function SendParagraphToR(e, m)
    if &filetype != "r" && b:IsInRCode(1) == 0
        return
    endif

    let i = line(".")
    let c = col(".")
    let max = line("$")
    let j = i
    let gotempty = 0
    while j < max
        let j += 1
        let line = getline(j)
        if &filetype == "rnoweb" && line =~ "^@$"
            let j -= 1
            break
        endif
        if line =~ '^\s*$'
            break
        endif
    endwhile
    let lines = getline(i, j)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if j < max
        call cursor(j, 1)
    else
        call cursor(max, 1)
    endif
    if a:m == "down"
        call GoDown()
    else
        call cursor(i, c)
    endif
endfunction

" Send R code from the first chunk up to current line
function SendFHChunkToR()
    if &filetype == "rnoweb"
        let begchk = "^<<.*>>=\$"
        let endchk = "^@"
    elseif &filetype == "rmd"
        let begchk = "^[ \t]*```[ ]*{r"
        let endchk = "^[ \t]*```$"
    elseif &filetype == "rrst"
        let begchk = "^\\.\\. {r"
        let endchk = "^\\.\\. \\.\\."
    else
        " Should never happen
        call RWarningMsg('Strange filetype (SendFHChunkToR): "' . &filetype '"')
    endif

    let codelines = []
    let here = line(".")
    let curbuf = getline(1, "$")
    let idx = 1
    while idx < here
        if curbuf[idx] =~ begchk
            let idx += 1
            while curbuf[idx] !~ endchk && idx < here
                let codelines += [curbuf[idx]]
                let idx += 1
            endwhile
        else
            let idx += 1
        endif
    endwhile
    call RSourceLines(codelines, "silent")
endfunction

" Send current line to R.
function SendLineToR(godown)
    let line = getline(".")
    if strlen(line) == 0
        if a:godown =~ "down"
            call GoDown()
        endif
        return
    endif

    if &filetype == "rnoweb"
        if line =~ "^@$"
            if a:godown =~ "down"
                call GoDown()
            endif
            return
        endif
        if RnwIsInRCode(1) == 0
            return
        endif
    endif

    if &filetype == "rmd"
        if line =~ "^```$"
            if a:godown =~ "down"
                call GoDown()
            endif
            return
        endif
        let line = substitute(line, "^\\`\\`\\?", "", "")
        if RmdIsInRCode(1) == 0
            return
        endif
    endif

    if &filetype == "rrst"
        if line =~ "^\.\. \.\.$"
            if a:godown =~ "down"
                call GoDown()
            endif
            return
        endif
        let line = substitute(line, "^\\.\\. \\?", "", "")
        if RrstIsInRCode(1) == 0
            return
        endif
    endif

    if &filetype == "rdoc"
        if getline(1) =~ '^The topic'
            let topic = substitute(line, '.*::', '', "")
            let package = substitute(line, '::.*', '', "")
            call ShowRDoc(topic, package, 1)
            return
        endif
        if RdocIsInRCode(1) == 0
            return
        endif
    endif

    if &filetype == "rhelp" && RhelpIsInRCode(1) == 0
        return
    endif

    let ok = g:SendCmdToR(line)
    if ok
        if a:godown =~ "down"
            call GoDown()
        else
            if a:godown == "newline"
                normal! o
            endif
        endif
    endif
endfunction

function RSendPartOfLine(direction, correctpos)
    let lin = getline(".")
    let idx = col(".") - 1
    if a:correctpos
        call cursor(line("."), idx)
    endif
    if a:direction == "right"
        let rcmd = strpart(lin, idx)
    else
        let rcmd = strpart(lin, 0, idx)
    endif
    call g:SendCmdToR(rcmd)
endfunction

" Clear the console screen
function RClearConsole()
    if (has("win32") || has("win64"))
        Py RClearConsolePy()
    else
        call g:SendCmdToR("\014")
    endif
endfunction

" Remove all objects
function RClearAll()
    if g:vimrplugin_rmhidden
        call g:SendCmdToR("rm(list=ls(all.names = TRUE))")
    else
        call g:SendCmdToR("rm(list=ls())")
    endif
    sleep 500m
    call RClearConsole()
endfunction

"Set working directory to the path of current buffer
function RSetWD()
    let wdcmd = 'setwd("' . expand("%:p:h") . '")'
    if has("win32") || has("win64")
        let wdcmd = substitute(wdcmd, "\\", "/", "g")
    endif
    call g:SendCmdToR(wdcmd)
    sleep 100m
endfunction

function CloseExternalOB()
    if IsExternalOBRunning()
        call system("tmux kill-pane -t " . g:rplugin_ob_pane)
        unlet g:rplugin_ob_pane
        sleep 250m
    endif
endfunction

" Quit R
function RQuit(how)
    if a:how != "restartR"
        if bufloaded(b:objbrtitle)
            exe "bunload! " . b:objbrtitle
            sleep 30m
        endif
    endif

    if exists("b:quit_command")
        let qcmd = b:quit_command
    else
        if a:how == "save"
            let qcmd = 'quit(save = "yes")'
        else
            let qcmd = 'quit(save = "no")'
        endif
    endif

    if has("win32") || has("win64")
        exe "Py SendQuitMsg('" . qcmd . "')"
    else
        call g:SendCmdToR(qcmd)
        if g:rplugin_tmuxwasfirst
            if a:how == "save"
                sleep 200m
            endif
            if g:vimrplugin_restart
                let ca_ck = g:vimrplugin_ca_ck
                let g:vimrplugin_ca_ck = 0
                call g:SendCmdToR("exit")
                let g:vimrplugin_ca_ck = ca_ck
            endif
        endif
    endif

    sleep 50m

    call CloseExternalOB()

    if exists("g:rplugin_rconsole_pane")
        unlet g:rplugin_rconsole_pane
    endif

    call delete($VIMRPLUGIN_TMPDIR . "/globenv_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/liblist_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID)
    let g:SendCmdToR = function('SendCmdToR_fake')
endfunction

" knit the current buffer content
function! RKnit()
    update
    call RSetWD()
    call g:SendCmdToR('require(knitr); knit("' . expand("%:t") . '")')
endfunction

" Tell R to create a list of objects file listing all currently available
" objects in its environment. The file is necessary for omni completion.
function BuildROmniList()

    if has("win32") || has("win64") && g:rplugin_vimcom_pkg == "vimcom"
	if !exists("g:rplugin_vimcom_omni_warn")
	    let g:rplugin_vimcom_omni_warn = 1
            if RCheckVimCom("complete the names of objects from R's workspace.")
                sleep 2
                return
            endif
        else
            return
	endif
    endif

    let omnilistcmd = 'vim.bol("' . $VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID . '"'
    if g:vimrplugin_allnames == 1
        let omnilistcmd = omnilistcmd . ', allnames = TRUE'
    endif
    let omnilistcmd = omnilistcmd . ')'

    call delete($VIMRPLUGIN_TMPDIR . "/vimbol_finished")
        call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
        exe "Py SendToVimCom('" . omnilistcmd . "')"
        if g:rplugin_vimcomport == 0
            sleep 500m
            return
        endif
        let g:rplugin_lastrpl = ReadEvalReply()
        if g:rplugin_lastrpl == "R is busy." || g:rplugin_lastrpl == "No reply"
            call RWarningMsg(g:rplugin_lastrpl)
            sleep 800m
            return
        endif
        sleep 20m
    let ii = 0
    while !filereadable($VIMRPLUGIN_TMPDIR . "/vimbol_finished") && ii < 5
        let ii += 1
        sleep
    endwhile
    echon "\r               "
    if ii == 5
        call RWarningMsg("No longer waiting...")
        return
    endif

    let g:rplugin_globalenvlines = readfile($VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID)
    echon
endfunction

function RRemoveFromLibls(nlib)
    let idx = 0
    for lib in g:rplugin_libls
        if lib == a:nlib
            call remove(g:rplugin_libls, idx)
            break
        endif
        let idx += 1
    endfor
endfunction

function RAddToLibList(nlib, verbose)
    if isdirectory(g:rplugin_uservimfiles . "/r-plugin/objlist")
        let omf = split(globpath(&rtp, 'r-plugin/objlist/omnils_' . a:nlib . '_*'), "\n")
        if len(omf) == 1
            let nlist = readfile(omf[0])

            " List of objects for omni completion
            let g:rplugin_liblist = g:rplugin_liblist + nlist

            " List of objects for :Rhelp completion
            for xx in nlist
                let xxx = split(xx, "\x06")
                if len(xxx) > 0 && xxx[0] !~ '\$'
                    call add(s:list_of_objs, xxx[0])
                endif
            endfor
        elseif a:verbose && len(omf) == 0
            call RWarningMsg('Omnils file for "' . a:nlib . '" not found.')
            call RRemoveFromLibls(a:nlib)
            return
        elseif a:verbose && len(omf) > 1
            call RWarningMsg('There is more than one omnils file for "' . a:nlib . '".')
            for obl in omf
                call RWarningMsg(obl)
            endfor
            call RRemoveFromLibls(a:nlib)
            return
        endif
    endif
endfunction

" This function is called by the R package vimcom.plus whenever a library is
" loaded.
function RFillLibList()
    " Update the list of objects for omnicompletion
    if filereadable($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
        let newls = readfile($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
        for nlib in newls
            let isold = 0
            for olib in g:rplugin_libls
                if nlib == olib
                    let isold = 1
                    break
                endif
            endfor
            if isold == 0
                let g:rplugin_libls = g:rplugin_libls + [ nlib ]
                call RAddToLibList(nlib, 1)
            endif
        endfor
    endif

    if exists("*RUpdateFunSyntax")
        call RUpdateFunSyntax(0)
        if &filetype != "r"
            silent exe "set filetype=" . &filetype
        endif
    endif
endfunction

function SetRTextWidth()
    if !bufloaded(s:rdoctitle) || g:vimrplugin_newsize == 1
        " Bug fix for Vim < 7.2.318
        if !(has("win32") || has("win64"))
            let curlang = v:lang
            language C
        endif

        let g:vimrplugin_newsize = 0

        " s:vimpager is used to calculate the width of the R help documentation
        " and to decide whether to obey vimrplugin_vimpager = 'vertical'
        let s:vimpager = g:vimrplugin_vimpager

        let wwidth = winwidth(0)

        " Not enough room to split vertically
        if g:vimrplugin_vimpager == "vertical" && wwidth <= (g:vimrplugin_help_w + g:vimrplugin_editor_w)
            let s:vimpager = "horizontal"
        endif

        if s:vimpager == "horizontal"
            " Use the window width (at most 80 columns)
            let htwf = (wwidth > 80) ? 88.1 : ((wwidth - 1) / 0.9)
        elseif g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
            let wwidth = &columns
            let htwf = (wwidth > 80) ? 88.1 : ((wwidth - 1) / 0.9)
        else
            let min_e = (g:vimrplugin_editor_w > 80) ? g:vimrplugin_editor_w : 80
            let min_h = (g:vimrplugin_help_w > 73) ? g:vimrplugin_help_w : 73

            if wwidth > (min_e + min_h)
                " The editor window is large enough to be split
                let s:hwidth = min_h
            elseif wwidth > (min_e + g:vimrplugin_help_w)
                " The help window must have less than min_h columns
                let s:hwidth = wwidth - min_e
            else
                " The help window must have the minimum value
                let s:hwidth = g:vimrplugin_help_w
            endif
            let htwf = (s:hwidth - 1) / 0.9
        endif
        let htw = printf("%f", htwf)
        let g:rplugin_htw = substitute(htw, "\\..*", "", "")
        let g:rplugin_htw = g:rplugin_htw - (&number || &relativenumber) * &numberwidth
        if !(has("win32") || has("win64"))
            exe "language " . curlang
        endif
    endif
endfunction

function RGetClassFor(rkeyword)
    let classfor = ""
    let line = substitute(getline("."), '#.*', '', "")
    let begin = col(".")
    if strlen(line) > begin
        let piece = strpart(line, begin)
        while piece !~ '^' . a:rkeyword && begin >= 0
            let begin -= 1
            let piece = strpart(line, begin)
        endwhile
        let line = piece
        if line !~ '^\k*\s*('
            return classfor
        endif
        let begin = 1
        let linelen = strlen(line)
        while line[begin] != '(' && begin < linelen
            let begin += 1
        endwhile
        let begin += 1
        let line = strpart(line, begin)
        let line = substitute(line, '^\s*', '', "")
        if (line =~ '^\k*\s*(' || line =~ '^\k*\s*=\s*\k*\s*(') && line !~ '[.*('
            let idx = 0
            while line[idx] != '('
                let idx += 1
            endwhile
            let idx += 1
            let nparen = 1
            let len = strlen(line)
            let lnum = line(".")
            while nparen != 0
                if line[idx] == '('
                    let nparen += 1
                else
                    if line[idx] == ')'
                        let nparen -= 1
                    endif
                endif
                let idx += 1
                if idx == len
                    let lnum += 1
                    let line = line . substitute(getline(lnum), '#.*', '', "")
                    let len = strlen(line)
                endif
            endwhile
            let classfor = strpart(line, 0, idx)
        elseif line =~ '^\(\k\|\$\)*\s*[' || line =~ '^\(k\|\$\)*\s*=\s*\(\k\|\$\)*\s*[.*('
            let idx = 0
            while line[idx] != '['
                let idx += 1
            endwhile
            let idx += 1
            let nparen = 1
            let len = strlen(line)
            let lnum = line(".")
            while nparen != 0
                if line[idx] == '['
                    let nparen += 1
                else
                    if line[idx] == ']'
                        let nparen -= 1
                    endif
                endif
                let idx += 1
                if idx == len
                    let lnum += 1
                    let line = line . substitute(getline(lnum), '#.*', '', "")
                    let len = strlen(line)
                endif
            endwhile
            let classfor = strpart(line, 0, idx)
        else
            let classfor = substitute(line, ').*', '', "")
            let classfor = substitute(classfor, ',.*', '', "")
            let classfor = substitute(classfor, ' .*', '', "")
        endif
    endif
    if classfor =~ "^'" && classfor =~ "'$"
        let classfor = substitute(classfor, "^'", '"', "")
        let classfor = substitute(classfor, "'$", '"', "")
    endif
    return classfor
endfunction

" Show R's help doc in Vim's buffer
" (based  on pydoc plugin)
function ShowRDoc(rkeyword, package, getclass)
    if !has("python") && !has("python3")
        call RWarningMsg("Python support is required to see R documentation on Vim.")
        return
    endif

    if (has("win32") || has("win64")) && g:rplugin_vimcom_pkg == "vimcom"
        if RCheckVimCom("see R help on Vim buffer.")
            return
        endif
    endif

    if filewritable(g:rplugin_docfile)
        call delete(g:rplugin_docfile)
    endif

    let classfor = ""
    if bufname("%") =~ "Object_Browser"
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        exe "sb " . b:rscript_buffer
        exe "set switchbuf=" . savesb
    else
        if a:getclass
            let classfor = RGetClassFor(a:rkeyword)
        endif
    endif

    if classfor =~ '='
        let classfor = "eval(expression(" . classfor . "))"
    endif

    if g:vimrplugin_vimpager == "tabnew"
        let s:rdoctitle = a:rkeyword . "\\ (help)"
    else
        let s:tnr = tabpagenr()
        if g:vimrplugin_vimpager != "tab" && s:tnr > 1
            let s:rdoctitle = "R_doc" . s:tnr
        else
            let s:rdoctitle = "R_doc"
        endif
        unlet s:tnr
    endif

    call SetRTextWidth()

    let g:rplugin_lastrpl = "R did not reply."
    call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
    if classfor == "" && a:package == ""
        exe 'Py SendToVimCom("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . 'L)")'
    elseif a:package != ""
        exe 'Py SendToVimCom("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, package='" . a:package  . "')". '")'
    else
        let classfor = substitute(classfor, '\\', "", "g")
        let classfor = substitute(classfor, '"', '\\"', "g")
        exe 'Py SendToVimCom("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, " . classfor . ")". '")'
    endif
    let g:rplugin_lastrpl = ReadEvalReply()
    if g:rplugin_lastrpl != "VIMHELP"
        if g:rplugin_lastrpl =~ "^MULTILIB"
            echo "The topic '" . a:rkeyword . "' was found in more than one library:"
            let libs = split(g:rplugin_lastrpl)
            for idx in range(1, len(libs) - 1)
                echo idx . " : " . libs[idx]
            endfor
            let chn = input("Please, select one of them: ")
            if chn > 0 && chn < len(libs)
                call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
                exe 'Py SendToVimCom("vim.help(' . "'" . a:rkeyword . "', " . g:rplugin_htw . "L, package='" . libs[chn] . "')" . '")'
                let g:rplugin_lastrpl = ReadEvalReply()
            endif
        else
            call RWarningMsg(g:rplugin_lastrpl)
            return
        endif
    endif

    " Local variables that must be inherited by the rdoc buffer
    let g:tmp_tmuxsname = g:rplugin_tmuxsname
    let g:tmp_objbrtitle = b:objbrtitle

    let rdoccaption = substitute(s:rdoctitle, '\', '', "g")
    if bufloaded(rdoccaption)
        let curtabnr = tabpagenr()
        let savesb = &switchbuf
        set switchbuf=useopen,usetab
        exe "sb ". s:rdoctitle
        exe "set switchbuf=" . savesb
        if g:vimrplugin_vimpager == "tabnew"
            exe "tabmove " . curtabnr
        endif
    else
        if g:vimrplugin_vimpager == "tab" || g:vimrplugin_vimpager == "tabnew"
            exe 'tabnew ' . s:rdoctitle
        elseif s:vimpager == "vertical"
            let l:sr = &splitright
            set splitright
            exe s:hwidth . 'vsplit ' . s:rdoctitle
            let &splitright = l:sr
        elseif s:vimpager == "horizontal"
            exe 'split ' . s:rdoctitle
            if winheight(0) < 20
                resize 20
            endif
        else
            echohl WarningMsg
            echomsg 'Invalid vimrplugin_vimpager value: "' . g:vimrplugin_vimpager . '". Valid values are: "tab", "vertical", "horizontal", "tabnew" and "no".'
            echohl Normal
            return
        endif
    endif

    setlocal modifiable
    let g:rplugin_curbuf = bufname("%")

    " Inheritance of local variables from the script buffer
    let b:objbrtitle = g:tmp_objbrtitle
    let g:rplugin_tmuxsname = g:tmp_tmuxsname
    unlet g:tmp_objbrtitle

    let save_unnamed_reg = @@
    sil normal! ggdG
    let fcntt = readfile(g:rplugin_docfile)
    call setline(1, fcntt)
    set filetype=rdoc
    normal! gg
    let @@ = save_unnamed_reg
    setlocal nomodified
    setlocal nomodifiable
    redraw
endfunction

function RLisObjs(arglead, cmdline, curpos)
    let lob = []
    let rkeyword = '^' . a:arglead
    for xx in s:list_of_objs
        if xx =~ rkeyword
            call add(lob, xx)
        endif
    endfor
    return lob
endfunction

function RSourceDirectory(...)
    if has("win32") || has("win64")
        let dir = substitute(a:1, '\\', '/', "g")
    else
        let dir = a:1
    endif
    if dir == ""
        call g:SendCmdToR("vim.srcdir()")
    else
        call g:SendCmdToR("vim.srcdir('" . dir . "')")
    endif
endfunction

function RAskHelp(...)
    if a:1 == ""
        call g:SendCmdToR("help.start()")
        return
    endif
    if g:vimrplugin_vimpager != "no"
        call ShowRDoc(a:1, "", 0)
    else
        call g:SendCmdToR("help(" . a:1. ")")
    endif
endfunction

function PrintRObject(rkeyword)
    if bufname("%") =~ "Object_Browser"
        let classfor = ""
    else
        let classfor = RGetClassFor(a:rkeyword)
    endif
    if classfor == ""
        call g:SendCmdToR("print(" . a:rkeyword . ")")
    else
        call g:SendCmdToR('vim.print("' . a:rkeyword . '", ' . classfor . ")")
    endif
endfunction

" Call R functions for the word under cursor
function RAction(rcmd)
    if &filetype == "rbrowser"
        let rkeyword = RBrowserGetName(1, 0)
    else
        let rkeyword = RGetKeyWord()
    endif
    if strlen(rkeyword) > 0
        if a:rcmd == "help"
            if g:vimrplugin_vimpager == "no"
                call g:SendCmdToR("help(" . rkeyword . ")")
            else
                if bufname("%") =~ "Object_Browser" || b:rplugin_extern_ob
                    if g:rplugin_curview == "libraries"
                        let pkg = RBGetPkgName()
                    else
                        let pkg = ""
                    endif
                    if b:rplugin_extern_ob
                        if g:rplugin_vim_pane == "none"
                            call RWarningMsg("Cmd not available.")
                        else
                            if g:rplugin_editor_sname == ""
                                let slog = system("tmux set-buffer '" . "\<C-\>\<C-N>" . ':call ShowRDoc("' . rkeyword . '", "' . pkg . '", 0)' . "\<C-M>' && tmux paste-buffer -t " . g:rplugin_vim_pane . " && tmux select-pane -t " . g:rplugin_vim_pane)
                                if v:shell_error
                                    call RWarningMsg(slog)
                                endif
                            else
                                silent exe 'call remote_expr("' . g:rplugin_editor_sname . '", ' . "'ShowRDoc(" . '"' . rkeyword . '", "' . pkg . '", 0)' . "')"
                            endif
                        endif
                    else
                        call ShowRDoc(rkeyword, pkg, 0)
                    endif
                    return
                endif
                call ShowRDoc(rkeyword, "", 1)
            endif
            return
        endif
        if a:rcmd == "print"
            call PrintRObject(rkeyword)
            return
        endif
        let rfun = a:rcmd
        if a:rcmd == "args" && g:vimrplugin_listmethods == 1
            let rfun = "vim.list.args"
        endif
        if a:rcmd == "plot" && g:vimrplugin_specialplot == 1
            let rfun = "vim.plot"
        endif
        if a:rcmd == "plotsumm"
            if g:vimrplugin_specialplot == 1
                let raction = "vim.plot(" . rkeyword . "); summary(" . rkeyword . ")"
            else
                let raction = "plot(" . rkeyword . "); summary(" . rkeyword . ")"
            endif
            call g:SendCmdToR(raction)
            return
        endif

        let raction = rfun . "(" . rkeyword . ")"
        call g:SendCmdToR(raction)
    endif
endfunction

if exists('g:maplocalleader')
    let s:tll = '<Tab>' . g:maplocalleader
else
    let s:tll = '<Tab>\\'
endif

redir => s:ikblist
silent imap
redir END
redir => s:nkblist
silent nmap
redir END
redir => s:vkblist
silent vmap
redir END
let s:iskblist = split(s:ikblist, "\n")
let s:nskblist = split(s:nkblist, "\n")
let s:vskblist = split(s:vkblist, "\n")
let s:imaplist = []
let s:vmaplist = []
let s:nmaplist = []
for i in s:iskblist
    let si = split(i)
    if len(si) == 3 && si[2] =~ "<Plug>R"
        call add(s:imaplist, [si[1], si[2]])
    endif
endfor
for i in s:nskblist
    let si = split(i)
    if len(si) == 3 && si[2] =~ "<Plug>R"
        call add(s:nmaplist, [si[1], si[2]])
    endif
endfor
for i in s:vskblist
    let si = split(i)
    if len(si) == 3 && si[2] =~ "<Plug>R"
        call add(s:vmaplist, [si[1], si[2]])
    endif
endfor
unlet s:ikblist
unlet s:nkblist
unlet s:vkblist
unlet s:iskblist
unlet s:nskblist
unlet s:vskblist
unlet i
unlet si

function RNMapCmd(plug)
    for [el1, el2] in s:nmaplist
        if el2 == a:plug
            return el1
        endif
    endfor
endfunction

function RIMapCmd(plug)
    for [el1, el2] in s:imaplist
        if el2 == a:plug
            return el1
        endif
    endfor
endfunction

function RVMapCmd(plug)
    for [el1, el2] in s:vmaplist
        if el2 == a:plug
            return el1
        endif
    endfor
endfunction

function RCreateMenuItem(type, label, plug, combo, target)
    if a:type =~ '0'
        let tg = a:target . '<CR>0'
        let il = 'i'
    else
        let tg = a:target . '<CR>'
        let il = 'a'
    endif
    if a:type =~ "n"
        if hasmapto(a:plug, "n")
            let boundkey = RNMapCmd(a:plug)
            exec 'nmenu <silent> &R.' . a:label . '<Tab>' . boundkey . ' ' . tg
        else
            exec 'nmenu <silent> &R.' . a:label . s:tll . a:combo . ' ' . tg
        endif
    endif
    if a:type =~ "v"
        if hasmapto(a:plug, "v")
            let boundkey = RVMapCmd(a:plug)
            exec 'vmenu <silent> &R.' . a:label . '<Tab>' . boundkey . ' ' . '<Esc>' . tg
        else
            exec 'vmenu <silent> &R.' . a:label . s:tll . a:combo . ' ' . '<Esc>' . tg
        endif
    endif
    if a:type =~ "i"
        if hasmapto(a:plug, "i")
            let boundkey = RIMapCmd(a:plug)
            exec 'imenu <silent> &R.' . a:label . '<Tab>' . boundkey . ' ' . '<Esc>' . tg . il
        else
            exec 'imenu <silent> &R.' . a:label . s:tll . a:combo . ' ' . '<Esc>' . tg . il
        endif
    endif
endfunction

function RBrowserMenu()
    call RCreateMenuItem("nvi", 'Object\ browser.Show/Update', '<Plug>RUpdateObjBrowser', 'ro', ':call RObjBrowser()')
    call RCreateMenuItem("nvi", 'Object\ browser.Expand\ (all\ lists)', '<Plug>ROpenLists', 'r=', ':call RBrowserOpenCloseLists(1)')
    call RCreateMenuItem("nvi", 'Object\ browser.Collapse\ (all\ lists)', '<Plug>RCloseLists', 'r-', ':call RBrowserOpenCloseLists(0)')
    if &filetype == "rbrowser"
        imenu <silent> R.Object\ browser.Toggle\ (cur)<Tab>Enter <Esc>:call RBrowserDoubleClick()<CR>
        nmenu <silent> R.Object\ browser.Toggle\ (cur)<Tab>Enter :call RBrowserDoubleClick()<CR>
    endif
    let g:rplugin_hasmenu = 1
endfunction

function RControlMenu()
    call RCreateMenuItem("nvi", 'Command.List\ space', '<Plug>RListSpace', 'rl', ':call g:SendCmdToR("ls()")')
    call RCreateMenuItem("nvi", 'Command.Clear\ console\ screen', '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
    call RCreateMenuItem("nvi", 'Command.Clear\ all', '<Plug>RClearAll', 'rm', ':call RClearAll()')
    "-------------------------------
    menu R.Command.-Sep1- <nul>
    call RCreateMenuItem("nvi", 'Command.Print\ (cur)', '<Plug>RObjectPr', 'rp', ':call RAction("print")')
    call RCreateMenuItem("nvi", 'Command.Names\ (cur)', '<Plug>RObjectNames', 'rn', ':call RAction("vim.names")')
    call RCreateMenuItem("nvi", 'Command.Structure\ (cur)', '<Plug>RObjectStr', 'rt', ':call RAction("str")')
    "-------------------------------
    menu R.Command.-Sep2- <nul>
    call RCreateMenuItem("nvi", 'Command.Arguments\ (cur)', '<Plug>RShowArgs', 'ra', ':call RAction("args")')
    call RCreateMenuItem("nvi", 'Command.Example\ (cur)', '<Plug>RShowEx', 're', ':call RAction("example")')
    call RCreateMenuItem("nvi", 'Command.Help\ (cur)', '<Plug>RHelp', 'rh', ':call RAction("help")')
    "-------------------------------
    menu R.Command.-Sep3- <nul>
    call RCreateMenuItem("nvi", 'Command.Summary\ (cur)', '<Plug>RSummary', 'rs', ':call RAction("summary")')
    call RCreateMenuItem("nvi", 'Command.Plot\ (cur)', '<Plug>RPlot', 'rg', ':call RAction("plot")')
    call RCreateMenuItem("nvi", 'Command.Plot\ and\ summary\ (cur)', '<Plug>RSPlot', 'rb', ':call RAction("plotsumm")')
    let g:rplugin_hasmenu = 1
endfunction

function RControlMaps()
    " List space, clear console, clear all
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RListSpace',    'rl', ':call g:SendCmdToR("ls()")')
    call RCreateMaps("nvi", '<Plug>RClearConsole', 'rr', ':call RClearConsole()')
    call RCreateMaps("nvi", '<Plug>RClearAll',     'rm', ':call RClearAll()')

    " Print, names, structure
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RObjectPr',     'rp', ':call RAction("print")')
    call RCreateMaps("nvi", '<Plug>RObjectNames',  'rn', ':call RAction("vim.names")')
    call RCreateMaps("nvi", '<Plug>RObjectStr',    'rt', ':call RAction("str")')

    " Arguments, example, help
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RShowArgs',     'ra', ':call RAction("args")')
    call RCreateMaps("nvi", '<Plug>RShowEx',       're', ':call RAction("example")')
    call RCreateMaps("nvi", '<Plug>RHelp',         'rh', ':call RAction("help")')

    " Summary, plot, both
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RSummary',      'rs', ':call RAction("summary")')
    call RCreateMaps("nvi", '<Plug>RPlot',         'rg', ':call RAction("plot")')
    call RCreateMaps("nvi", '<Plug>RSPlot',        'rb', ':call RAction("plotsumm")')

    " Build list of objects for omni completion
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RUpdateObjBrowser', 'ro', ':call RObjBrowser()')
    call RCreateMaps("nvi", '<Plug>ROpenLists',        'r=', ':call RBrowserOpenCloseLists(1)')
    call RCreateMaps("nvi", '<Plug>RCloseLists',       'r-', ':call RBrowserOpenCloseLists(0)')
endfunction


" For each noremap we need a vnoremap including <Esc> before the :call,
" otherwise vim will call the function as many times as the number of selected
" lines. If we put the <Esc> in the noremap, vim will bell.
" RCreateMaps Args:
"   type : modes to which create maps (normal, visual and insert) and whether
"          the cursor have to go the beginning of the line
"   plug : the <Plug>Name
"   combo: the combination of letter that make the shortcut
"   target: the command or function to be called
function RCreateMaps(type, plug, combo, target)
    if a:type =~ '0'
        let tg = a:target . '<CR>0'
        let il = 'i'
    else
        let tg = a:target . '<CR>'
        let il = 'a'
    endif
    if a:type =~ "n"
        if hasmapto(a:plug, "n")
            exec 'noremap <buffer><silent> ' . a:plug . ' ' . tg
        else
            exec 'noremap <buffer><silent> <LocalLeader>' . a:combo . ' ' . tg
        endif
    endif
    if a:type =~ "v"
        if hasmapto(a:plug, "v")
            exec 'vnoremap <buffer><silent> ' . a:plug . ' <Esc>' . tg
        else
            exec 'vnoremap <buffer><silent> <LocalLeader>' . a:combo . ' <Esc>' . tg
        endif
    endif
    if g:vimrplugin_insert_mode_cmds == 1 && a:type =~ "i"
        if hasmapto(a:plug, "i")
            exec 'inoremap <buffer><silent> ' . a:plug . ' <Esc>' . tg . il
        else
            exec 'inoremap <buffer><silent> <LocalLeader>' . a:combo . ' <Esc>' . tg . il
        endif
    endif
endfunction

function MakeRMenu()
    if g:rplugin_hasmenu == 1
        return
    endif

    " Do not translate "File":
    menutranslate clear

    "----------------------------------------------------------------------------
    " Start/Close
    "----------------------------------------------------------------------------
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (default)', '<Plug>RStart', 'rf', ':call StartR("R")')
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ --vanilla', '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
    call RCreateMenuItem("nvi", 'Start/Close.Start\ R\ (custom)', '<Plug>RCustomStart', 'rc', ':call StartR("custom")')
    "-------------------------------
    menu R.Start/Close.-Sep1- <nul>
    call RCreateMenuItem("nvi", 'Start/Close.Close\ R\ (no\ save)', '<Plug>RClose', 'rq', ":call RQuit('no')")

    "----------------------------------------------------------------------------
    " Send
    "----------------------------------------------------------------------------
    if &filetype == "r" || g:vimrplugin_never_unmake_menu
        call RCreateMenuItem("ni", 'Send.File', '<Plug>RSendFile', 'aa', ':call SendFileToR("silent")')
        call RCreateMenuItem("ni", 'Send.File\ (echo)', '<Plug>RESendFile', 'ae', ':call SendFileToR("echo")')
        call RCreateMenuItem("ni", 'Send.File\ (open\ \.Rout)', '<Plug>RShowRout', 'ao', ':call ShowRout()')
    endif
    "-------------------------------
    menu R.Send.-Sep1- <nul>
    call RCreateMenuItem("ni", 'Send.Block\ (cur)', '<Plug>RSendMBlock', 'bb', ':call SendMBlockToR("silent", "stay")')
    call RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo)', '<Plug>RESendMBlock', 'be', ':call SendMBlockToR("echo", "stay")')
    call RCreateMenuItem("ni", 'Send.Block\ (cur,\ down)', '<Plug>RDSendMBlock', 'bd', ':call SendMBlockToR("silent", "down")')
    call RCreateMenuItem("ni", 'Send.Block\ (cur,\ echo\ and\ down)', '<Plug>REDSendMBlock', 'ba', ':call SendMBlockToR("echo", "down")')
    "-------------------------------
    if &filetype == "rnoweb" || &filetype == "rmd" || &filetype == "rrst" || g:vimrplugin_never_unmake_menu
        menu R.Send.-Sep2- <nul>
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur)', '<Plug>RSendChunk', 'cc', ':call b:SendChunkToR("silent", "stay")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ echo)', '<Plug>RESendChunk', 'ce', ':call b:SendChunkToR("echo", "stay")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ down)', '<Plug>RDSendChunk', 'cd', ':call b:SendChunkToR("silent", "down")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (cur,\ echo\ and\ down)', '<Plug>REDSendChunk', 'ca', ':call b:SendChunkToR("echo", "down")')
        call RCreateMenuItem("ni", 'Send.Chunk\ (from\ first\ to\ here)', '<Plug>RSendChunkFH', 'ch', ':call SendFHChunkToR()')
    endif
    "-------------------------------
    menu R.Send.-Sep3- <nul>
    call RCreateMenuItem("ni", 'Send.Function\ (cur)', '<Plug>RSendFunction', 'ff', ':call SendFunctionToR("silent", "stay")')
    call RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo)', '<Plug>RESendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
    call RCreateMenuItem("ni", 'Send.Function\ (cur\ and\ down)', '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
    call RCreateMenuItem("ni", 'Send.Function\ (cur,\ echo\ and\ down)', '<Plug>REDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')
    "-------------------------------
    menu R.Send.-Sep4- <nul>
    call RCreateMenuItem("v", 'Send.Selection', '<Plug>RSendSelection', 'ss', ':call SendSelectionToR("silent", "stay")')
    call RCreateMenuItem("v", 'Send.Selection\ (echo)', '<Plug>RESendSelection', 'se', ':call SendSelectionToR("echo", "stay")')
    call RCreateMenuItem("v", 'Send.Selection\ (and\ down)', '<Plug>RDSendSelection', 'sd', ':call SendSelectionToR("silent", "down")')
    call RCreateMenuItem("v", 'Send.Selection\ (echo\ and\ down)', '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')
    "-------------------------------
    menu R.Send.-Sep5- <nul>
    call RCreateMenuItem("ni", 'Send.Paragraph', '<Plug>RSendParagraph', 'pp', ':call SendParagraphToR("silent", "stay")')
    call RCreateMenuItem("ni", 'Send.Paragraph\ (echo)', '<Plug>RESendParagraph', 'pe', ':call SendParagraphToR("echo", "stay")')
    call RCreateMenuItem("ni", 'Send.Paragraph\ (and\ down)', '<Plug>RDSendParagraph', 'pd', ':call SendParagraphToR("silent", "down")')
    call RCreateMenuItem("ni", 'Send.Paragraph\ (echo\ and\ down)', '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')
    "-------------------------------
    menu R.Send.-Sep6- <nul>
    call RCreateMenuItem("ni0", 'Send.Line', '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
    call RCreateMenuItem("ni0", 'Send.Line\ (and\ down)', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')
    call RCreateMenuItem("i", 'Send.Line\ (and\ new\ one)', '<Plug>RSendLAndOpenNewOne', 'q', ':call SendLineToR("newline")')
    call RCreateMenuItem("n", 'Send.Left\ part\ of\ line\ (cur)', '<Plug>RNLeftPart', 'r<Left>', ':call RSendPartOfLine("left", 0)')
    call RCreateMenuItem("n", 'Send.Right\ part\ of\ line\ (cur)', '<Plug>RNRightPart', 'r<Right>', ':call RSendPartOfLine("right", 0)')
    call RCreateMenuItem("i", 'Send.Left\ part\ of\ line\ (cur)', '<Plug>RILeftPart', 'r<Left>', 'l:call RSendPartOfLine("left", 1)')
    call RCreateMenuItem("i", 'Send.Right\ part\ of\ line\ (cur)', '<Plug>RIRightPart', 'r<Right>', 'l:call RSendPartOfLine("right", 1)')

    "----------------------------------------------------------------------------
    " Control
    "----------------------------------------------------------------------------
    call RControlMenu()
    "-------------------------------
    menu R.Command.-Sep4- <nul>
    if &filetype != "rdoc"
        call RCreateMenuItem("nvi", 'Command.Set\ working\ directory\ (cur\ file\ path)', '<Plug>RSetwd', 'rd', ':call RSetWD()')
    endif
    "-------------------------------
    if &filetype == "rnoweb" || &filetype == "rmd" || &filetype == "rrst" || g:vimrplugin_never_unmake_menu
        if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
            menu R.Command.-Sep5- <nul>
            call RCreateMenuItem("nvi", 'Command.Sweave\ (cur\ file)', '<Plug>RSweave', 'sw', ':call RSweave()')
            call RCreateMenuItem("nvi", 'Command.Sweave\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'sp', ':call RMakePDF("nobib", 0)')
            if has("win32") || has("win64")
                call RCreateMenuItem("nvi", 'Command.Sweave\ and\ PDF\ (cur\ file,\ verbose)', '<Plug>RMakePDF', 'sv', ':call RMakePDF("verbose", 0)')
            else
                call RCreateMenuItem("nvi", 'Command.Sweave,\ BibTeX\ and\ PDF\ (cur\ file)', '<Plug>RBibTeX', 'sb', ':call RMakePDF("bibtex", 0)')
            endif
        endif
        menu R.Command.-Sep6- <nul>
        call RCreateMenuItem("nvi", 'Command.Knit\ (cur\ file)', '<Plug>RKnit', 'kn', ':call RKnit()')
        if &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDFK', 'kp', ':call RMakePDF("nobib", 1)')
            if has("win32") || has("win64")
                call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file,\ verbose)', '<Plug>RMakePDFKv', 'kv', ':call RMakePDF("verbose", 1)')
            else
                call RCreateMenuItem("nvi", 'Command.Knit,\ BibTeX\ and\ PDF\ (cur\ file)', '<Plug>RBibTeXK', 'kb', ':call RMakePDF("bibtex", 1)')
            endif
        endif
        if &filetype == "rmd" || g:vimrplugin_never_unmake_menu
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDFK', 'kp', ':call RMakePDFrmd("latex")')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ Beamer\ PDF\ (cur\ file)', '<Plug>RMakePDFKb', 'kl', ':call RMakePDFrmd("beamer")')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ HTML\ (cur\ file)', '<Plug>RMakeHTML', 'kh', ':call RMakeHTMLrmd("html")')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ ODT\ (cur\ file)', '<Plug>RMakeODT', 'ko', ':call RMakeHTMLrmd("odt")')
            call RCreateMenuItem("nvi", 'Command.Slidify\ (cur\ file)', '<Plug>RMakeSlides', 'sl', ':call RMakeSlidesrmd()')
        endif
        if &filetype == "rrst" || g:vimrplugin_never_unmake_menu
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDFK', 'kp', ':call RMakePDFrrst()')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ HTML\ (cur\ file)', '<Plug>RMakeHTML', 'kh', ':call RMakeHTMLrrst("html")')
            call RCreateMenuItem("nvi", 'Command.Knit\ and\ ODT\ (cur\ file)', '<Plug>RMakeODT', 'ko', ':call RMakeHTMLrrst("odt")')
        endif
        menu R.Command.-Sep61- <nul>
        call RCreateMenuItem("nvi", 'Command.Open\ PDF\ (cur\ file)', '<Plug>ROpenPDF', 'op', ':call ROpenPDF()')
    endif
    "-------------------------------
    if &filetype == "rrst" || g:vimrplugin_never_unmake_menu
        menu R.Command.-Sep5- <nul>
        call RCreateMenuItem("nvi", 'Command.Knit\ (cur\ file)', '<Plug>RKnit', 'kn', ':call RKnit()')
        call RCreateMenuItem("nvi", 'Command.Knit\ and\ PDF\ (cur\ file)', '<Plug>RMakePDF', 'kp', ':call RMakePDF("nobib")')
    endif
    "-------------------------------
    if &filetype == "r" || g:vimrplugin_never_unmake_menu
        menu R.Command.-Sep71- <nul>
        call RCreateMenuItem("nvi", 'Command.Spin\ (cur\ file)', '<Plug>RSpinFile', 'ks', ':call RSpin()')
    endif
    menu R.Command.-Sep72- <nul>
    if &filetype == "r" || &filetype == "rnoweb" || g:vimrplugin_never_unmake_menu
        nmenu <silent> R.Command.Build\ tags\ file\ (cur\ dir)<Tab>:RBuildTags :call g:SendCmdToR('rtags(ofile = "TAGS")')<CR>
        imenu <silent> R.Command.Build\ tags\ file\ (cur\ dir)<Tab>:RBuildTags <Esc>:call g:SendCmdToR('rtags(ofile = "TAGS")')<CR>a
    endif

    menu R.-Sep7- <nul>

    "----------------------------------------------------------------------------
    " Edit
    "----------------------------------------------------------------------------
    if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rrst" || &filetype == "rhelp" || g:vimrplugin_never_unmake_menu
        if g:vimrplugin_assign == 1
            silent exe 'imenu <silent> R.Edit.Insert\ \"\ <-\ \"<Tab>' . g:vimrplugin_assign_map . ' <Esc>:call ReplaceUnderS()<CR>a'
        endif
        imenu <silent> R.Edit.Complete\ object\ name<Tab>^X^O <C-X><C-O>
        if hasmapto("<Plug>RCompleteArgs", "i")
            let boundkey = RIMapCmd("<Plug>RCompleteArgs")
            exe "imenu <silent> R.Edit.Complete\\ function\\ arguments<Tab>" . boundkey . " " . boundkey
        else
            imenu <silent> R.Edit.Complete\ function\ arguments<Tab>^X^A <C-X><C-A>
        endif
        menu R.Edit.-Sep71- <nul>
        nmenu <silent> R.Edit.Indent\ (line)<Tab>== ==
        vmenu <silent> R.Edit.Indent\ (selected\ lines)<Tab>= =
        nmenu <silent> R.Edit.Indent\ (whole\ buffer)<Tab>gg=G gg=G
        menu R.Edit.-Sep72- <nul>
        call RCreateMenuItem("ni", 'Edit.Toggle\ comment\ (line/sel)', '<Plug>RToggleComment', 'xx', ':call RComment("normal")')
        call RCreateMenuItem("v", 'Edit.Toggle\ comment\ (line/sel)', '<Plug>RToggleComment', 'xx', ':call RComment("selection")')
        call RCreateMenuItem("ni", 'Edit.Comment\ (line/sel)', '<Plug>RSimpleComment', 'xc', ':call RSimpleCommentLine("normal", "c")')
        call RCreateMenuItem("v", 'Edit.Comment\ (line/sel)', '<Plug>RSimpleComment', 'xc', ':call RSimpleCommentLine("selection", "c")')
        call RCreateMenuItem("ni", 'Edit.Uncomment\ (line/sel)', '<Plug>RSimpleUnComment', 'xu', ':call RSimpleCommentLine("normal", "u")')
        call RCreateMenuItem("v", 'Edit.Uncomment\ (line/sel)', '<Plug>RSimpleUnComment', 'xu', ':call RSimpleCommentLine("selection", "u")')
        call RCreateMenuItem("ni", 'Edit.Add/Align\ right\ comment\ (line,\ sel)', '<Plug>RRightComment', ';', ':call MovePosRCodeComment("normal")')
        call RCreateMenuItem("v", 'Edit.Add/Align\ right\ comment\ (line,\ sel)', '<Plug>RRightComment', ';', ':call MovePosRCodeComment("selection")')
        if &filetype == "rnoweb" || &filetype == "rrst" || &filetype == "rmd" || g:vimrplugin_never_unmake_menu
            menu R.Edit.-Sep73- <nul>
            nmenu <silent> R.Edit.Go\ (next\ R\ chunk)<Tab>gn :call b:NextRChunk()<CR>
            nmenu <silent> R.Edit.Go\ (previous\ R\ chunk)<Tab>gN :call b:PreviousRChunk()<CR>
        endif
    endif

    "----------------------------------------------------------------------------
    " Object Browser
    "----------------------------------------------------------------------------
    call RBrowserMenu()

    "----------------------------------------------------------------------------
    " Help
    "----------------------------------------------------------------------------
    menu R.-Sep8- <nul>
    amenu R.Help\ (plugin).Overview :help r-plugin-overview<CR>
    amenu R.Help\ (plugin).Main\ features :help r-plugin-features<CR>
    amenu R.Help\ (plugin).Installation :help r-plugin-installation<CR>
    amenu R.Help\ (plugin).Use :help r-plugin-use<CR>
    amenu R.Help\ (plugin).Known\ bugs\ and\ workarounds :help r-plugin-known-bugs<CR>

    amenu R.Help\ (plugin).Options.Assignment\ operator\ and\ Rnoweb\ code :help vimrplugin_assign<CR>
    amenu R.Help\ (plugin).Options.Object\ Browser :help vimrplugin_objbr_place<CR>
    amenu R.Help\ (plugin).Options.Vim\ as\ pager\ for\ R\ help :help vimrplugin_vimpager<CR>
    if !(has("gui_win32") || has("gui_win64"))
        amenu R.Help\ (plugin).Options.Terminal\ emulator :help vimrplugin_term<CR>
    endif
    if has("gui_macvim") || has("gui_mac") || has("mac") || has("macunix")
        amenu R.Help\ (plugin).Options.Integration\ with\ Apple\ Script :help vimrplugin_applescript<CR>
    endif
    if has("gui_win32") || has("gui_win64")
        amenu R.Help\ (plugin).Options.Use\ 32\ bit\ version\ of\ R :help vimrplugin_i386<CR>
        amenu R.Help\ (plugin).Options.Sleep\ time :help vimrplugin_sleeptime<CR>
    endif
    amenu R.Help\ (plugin).Options.R\ path :help vimrplugin_r_path<CR>
    amenu R.Help\ (plugin).Options.Arguments\ to\ R :help vimrplugin_r_args<CR>
    amenu R.Help\ (plugin).Options.Omni\ completion\ when\ R\ not\ running :help vimrplugin_permanent_libs<CR>
    amenu R.Help\ (plugin).Options.Syntax\ highlighting\ of\ \.Rout\ files :help vimrplugin_routmorecolors<CR>
    amenu R.Help\ (plugin).Options.Automatically\ open\ the\ \.Rout\ file :help vimrplugin_routnotab<CR>
    amenu R.Help\ (plugin).Options.Special\ R\ functions :help vimrplugin_listmethods<CR>
    amenu R.Help\ (plugin).Options.Indent\ commented\ lines :help vimrplugin_indent_commented<CR>
    amenu R.Help\ (plugin).Options.LaTeX\ command :help vimrplugin_latexcmd<CR>
    amenu R.Help\ (plugin).Options.Never\ unmake\ the\ R\ menu :help vimrplugin_never_unmake_menu<CR>

    amenu R.Help\ (plugin).Custom\ key\ bindings :help r-plugin-key-bindings<CR>
    amenu R.Help\ (plugin).Files :help r-plugin-files<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.All\ tips :help r-plugin-tips<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Indenting\ setup :help r-plugin-indenting<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Folding\ setup :help r-plugin-folding<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Remap\ LocalLeader :help r-plugin-localleader<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Customize\ key\ bindings :help r-plugin-bindings<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.ShowMarks :help r-plugin-showmarks<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.SnipMate :help r-plugin-snippets<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.LaTeX-Box :help r-plugin-latex-box<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Highlight\ marks :help r-plugin-showmarks<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Global\ plugin :help r-plugin-global<CR>
    amenu R.Help\ (plugin).FAQ\ and\ tips.Jump\ to\ function\ definitions :help r-plugin-tagsfile<CR>
    amenu R.Help\ (plugin).News :help r-plugin-news<CR>

    amenu R.Help\ (R)<Tab>:Rhelp :call g:SendCmdToR("help.start()")<CR>
    amenu R.Configure\ (Vim-R)<Tab>:RpluginConfig :RpluginConfig<CR>
    let g:rplugin_hasmenu = 1

    "----------------------------------------------------------------------------
    " ToolBar
    "----------------------------------------------------------------------------
    if g:rplugin_has_icons
        " Buttons
        amenu <silent> ToolBar.RStart :call StartR("R")<CR>
        amenu <silent> ToolBar.RClose :call RQuit('no')<CR>
        "---------------------------
        if &filetype == "r" || g:vimrplugin_never_unmake_menu
            nmenu <silent> ToolBar.RSendFile :call SendFileToR("echo")<CR>
            imenu <silent> ToolBar.RSendFile <Esc>:call SendFileToR("echo")<CR>
            let g:rplugin_hasRSFbutton = 1
        endif
        nmenu <silent> ToolBar.RSendBlock :call SendMBlockToR("echo", "down")<CR>
        imenu <silent> ToolBar.RSendBlock <Esc>:call SendMBlockToR("echo", "down")<CR>
        nmenu <silent> ToolBar.RSendFunction :call SendFunctionToR("echo", "down")<CR>
        imenu <silent> ToolBar.RSendFunction <Esc>:call SendFunctionToR("echo", "down")<CR>
        vmenu <silent> ToolBar.RSendSelection <ESC>:call SendSelectionToR("echo", "down")<CR>
        nmenu <silent> ToolBar.RSendParagraph :call SendParagraphToR("echo", "down")<CR>
        imenu <silent> ToolBar.RSendParagraph <Esc>:call SendParagraphToR("echo", "down")<CR>
        nmenu <silent> ToolBar.RSendLine :call SendLineToR("down")<CR>
        imenu <silent> ToolBar.RSendLine <Esc>:call SendLineToR("down")<CR>
        "---------------------------
        nmenu <silent> ToolBar.RListSpace :call g:SendCmdToR("ls()")<CR>
        imenu <silent> ToolBar.RListSpace <Esc>:call g:SendCmdToR("ls()")<CR>
        nmenu <silent> ToolBar.RClear :call RClearConsole()<CR>
        imenu <silent> ToolBar.RClear <Esc>:call RClearConsole()<CR>
        nmenu <silent> ToolBar.RClearAll :call RClearAll()<CR>
        imenu <silent> ToolBar.RClearAll <Esc>:call RClearAll()<CR>

        " Hints
        tmenu ToolBar.RStart Start R (default)
        tmenu ToolBar.RClose Close R (no save)
        if &filetype == "r" || g:vimrplugin_never_unmake_menu
            tmenu ToolBar.RSendFile Send file (echo)
        endif
        tmenu ToolBar.RSendBlock Send block (cur, echo and down)
        tmenu ToolBar.RSendFunction Send function (cur, echo and down)
        tmenu ToolBar.RSendSelection Send selection (cur, echo and down)
        tmenu ToolBar.RSendParagraph Send paragraph (cur, echo and down)
        tmenu ToolBar.RSendLine Send line (cur and down)
        tmenu ToolBar.RListSpace List objects
        tmenu ToolBar.RClear Clear the console screen
        tmenu ToolBar.RClearAll Remove objects from workspace and clear the console screen
        let g:rplugin_hasbuttons = 1
    else
        let g:rplugin_hasbuttons = 0
    endif
endfunction

function UnMakeRMenu()
    if g:rplugin_hasmenu == 0 || g:vimrplugin_never_unmake_menu == 1 || &previewwindow || (&buftype == "nofile" && &filetype != "rbrowser")
        return
    endif
    aunmenu R
    let g:rplugin_hasmenu = 0
    if g:rplugin_hasbuttons
        aunmenu ToolBar.RClearAll
        aunmenu ToolBar.RClear
        aunmenu ToolBar.RListSpace
        aunmenu ToolBar.RSendLine
        aunmenu ToolBar.RSendSelection
        aunmenu ToolBar.RSendParagraph
        aunmenu ToolBar.RSendFunction
        aunmenu ToolBar.RSendBlock
        if g:rplugin_hasRSFbutton
            aunmenu ToolBar.RSendFile
            let g:rplugin_hasRSFbutton = 0
        endif
        aunmenu ToolBar.RClose
        aunmenu ToolBar.RStart
        let g:rplugin_hasbuttons = 0
    endif
endfunction


function SpaceForRGrDevice()
    let savesb = &switchbuf
    set switchbuf=useopen,usetab
    let l:sr = &splitright
    set splitright
    37vsplit Space_for_Graphics
    setlocal nomodifiable
    setlocal noswapfile
    set buftype=nofile
    set nowrap
    set winfixwidth
    exe "sb " . g:rplugin_curbuf
    let &splitright = l:sr
    exe "set switchbuf=" . savesb
endfunction

function RCreateStartMaps()
    " Start
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RStart',        'rf', ':call StartR("R")')
    call RCreateMaps("nvi", '<Plug>RVanillaStart', 'rv', ':call StartR("vanilla")')
    call RCreateMaps("nvi", '<Plug>RCustomStart',  'rc', ':call StartR("custom")')

    " Close
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RClose',        'rq', ":call RQuit('nosave')")
    call RCreateMaps("nvi", '<Plug>RSaveClose',    'rw', ":call RQuit('save')")

endfunction

function RCreateEditMaps()
    " Edit
    "-------------------------------------
    call RCreateMaps("ni", '<Plug>RToggleComment',   'xx', ':call RComment("normal")')
    call RCreateMaps("v", '<Plug>RToggleComment',   'xx', ':call RComment("selection")')
    call RCreateMaps("ni", '<Plug>RSimpleComment',   'xc', ':call RSimpleCommentLine("normal", "c")')
    call RCreateMaps("v", '<Plug>RSimpleComment',   'xc', ':call RSimpleCommentLine("selection", "c")')
    call RCreateMaps("ni", '<Plug>RSimpleUnComment',   'xu', ':call RSimpleCommentLine("normal", "u")')
    call RCreateMaps("v", '<Plug>RSimpleUnComment',   'xu', ':call RSimpleCommentLine("selection", "u")')
    call RCreateMaps("ni", '<Plug>RRightComment',   ';', ':call MovePosRCodeComment("normal")')
    call RCreateMaps("v", '<Plug>RRightComment',    ';', ':call MovePosRCodeComment("selection")')
    " Replace 'underline' with '<-'
    if g:vimrplugin_assign == 1
        silent exe 'imap <buffer><silent> ' . g:vimrplugin_assign_map . ' <Esc>:call ReplaceUnderS()<CR>a'
    endif
    if hasmapto("<Plug>RCompleteArgs", "i")
        imap <buffer><silent> <Plug>RCompleteArgs <C-R>=RCompleteArgs()<CR>
    else
        imap <buffer><silent> <C-X><C-A> <C-R>=RCompleteArgs()<CR>
    endif
endfunction

function RCreateSendMaps()
    " Block
    "-------------------------------------
    call RCreateMaps("ni", '<Plug>RSendMBlock',     'bb', ':call SendMBlockToR("silent", "stay")')
    call RCreateMaps("ni", '<Plug>RESendMBlock',    'be', ':call SendMBlockToR("echo", "stay")')
    call RCreateMaps("ni", '<Plug>RDSendMBlock',    'bd', ':call SendMBlockToR("silent", "down")')
    call RCreateMaps("ni", '<Plug>REDSendMBlock',   'ba', ':call SendMBlockToR("echo", "down")')

    " Function
    "-------------------------------------
    call RCreateMaps("nvi", '<Plug>RSendFunction',  'ff', ':call SendFunctionToR("silent", "stay")')
    call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fe', ':call SendFunctionToR("echo", "stay")')
    call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fd', ':call SendFunctionToR("silent", "down")')
    call RCreateMaps("nvi", '<Plug>RDSendFunction', 'fa', ':call SendFunctionToR("echo", "down")')

    " Selection
    "-------------------------------------
    call RCreateMaps("v", '<Plug>RSendSelection',   'ss', ':call SendSelectionToR("silent", "stay")')
    call RCreateMaps("v", '<Plug>RESendSelection',  'se', ':call SendSelectionToR("echo", "stay")')
    call RCreateMaps("v", '<Plug>RDSendSelection',  'sd', ':call SendSelectionToR("silent", "down")')
    call RCreateMaps("v", '<Plug>REDSendSelection', 'sa', ':call SendSelectionToR("echo", "down")')

    " Paragraph
    "-------------------------------------
    call RCreateMaps("ni", '<Plug>RSendParagraph',   'pp', ':call SendParagraphToR("silent", "stay")')
    call RCreateMaps("ni", '<Plug>RESendParagraph',  'pe', ':call SendParagraphToR("echo", "stay")')
    call RCreateMaps("ni", '<Plug>RDSendParagraph',  'pd', ':call SendParagraphToR("silent", "down")')
    call RCreateMaps("ni", '<Plug>REDSendParagraph', 'pa', ':call SendParagraphToR("echo", "down")')

    if &filetype == "rnoweb" || &filetype == "rmd" || &filetype == "rrst"
        call RCreateMaps("ni", '<Plug>RSendChunkFH', 'ch', ':call SendFHChunkToR()')
    endif

    " *Line*
    "-------------------------------------
    call RCreateMaps("ni", '<Plug>RSendLine', 'l', ':call SendLineToR("stay")')
    call RCreateMaps('ni0', '<Plug>RDSendLine', 'd', ':call SendLineToR("down")')
    call RCreateMaps('i', '<Plug>RSendLAndOpenNewOne', 'q', ':call SendLineToR("newline")')
    nmap <LocalLeader>r<Left> :call RSendPartOfLine("left", 0)<CR>
    nmap <LocalLeader>r<Right> :call RSendPartOfLine("right", 0)<CR>
    if g:vimrplugin_insert_mode_cmds
        imap <buffer><silent> <LocalLeader>r<Left> <Esc>l:call RSendPartOfLine("left", 0)<CR>i
        imap <buffer><silent> <LocalLeader>r<Right> <Esc>l:call RSendPartOfLine("right", 0)<CR>i
    endif

    " For compatibility with Johannes Ranke's plugin
    if g:vimrplugin_map_r == 1
        vnoremap <buffer><silent> r <Esc>:call SendSelectionToR("silent", "down")<CR>
    endif
endfunction

function RBufEnter()
    let g:rplugin_curbuf = bufname("%")
    if has("gui_running")
        if &filetype != g:rplugin_lastft
            call UnMakeRMenu()
            if &filetype == "r" || &filetype == "rnoweb" || &filetype == "rmd" || &filetype == "rrst" || &filetype == "rdoc" || &filetype == "rbrowser" || &filetype == "rhelp"
                if &filetype == "rbrowser"
                    call MakeRBrowserMenu()
                else
                    call MakeRMenu()
                endif
            endif
        endif
        if &buftype != "nofile" || (&buftype == "nofile" && &filetype == "rbrowser")
            let g:rplugin_lastft = &filetype
        endif
    endif

    " It would be better if we could call RUpdateFunSyntax() for all buffers
    " immediately after a new library was loaded, but the command :bufdo
    " temporarily disables Syntax events.
    if exists("b:rplugin_funls") && len(b:rplugin_funls) < len(g:rplugin_libls)
        call RUpdateFunSyntax(0)
        " If R code is included in another file type (like rnoweb or
        " rhelp), the R syntax isn't automatically updated. So, we force
        " it: 
        silent exe "set filetype=" . &filetype
    endif
endfunction

function RVimLeave()
    if exists("b:rsource")
        " b:rsource only exists if the filetype of the last buffer is .R*
        call delete(b:rsource)
    endif
    call delete($VIMRPLUGIN_TMPDIR . "/eval_reply")
    call delete($VIMRPLUGIN_TMPDIR . "/formatted_code")
    call delete($VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/globenv_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/liblist_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/libnames_" . $VIMINSTANCEID)
    call delete($VIMRPLUGIN_TMPDIR . "/objbrowserInit")
    call delete($VIMRPLUGIN_TMPDIR . "/Rdoc")
    call delete($VIMRPLUGIN_TMPDIR . "/Rinsert")
    call delete($VIMRPLUGIN_TMPDIR . "/tmux.conf")
    call delete($VIMRPLUGIN_TMPDIR . "/unformatted_code")
    call delete($VIMRPLUGIN_TMPDIR . "/vimbol_finished")
    call delete($VIMRPLUGIN_TMPDIR . "/vimcom_running")
endfunction

function SetRPath()
    if exists("g:vimrplugin_r_path")
        let b:rplugin_R = expand(g:vimrplugin_r_path)
        if isdirectory(b:rplugin_R)
            let b:rplugin_R = b:rplugin_R . "/R"
        endif
    else
        let b:rplugin_R = "R"
    endif
    if !executable(b:rplugin_R)
        call RWarningMsgInp("R executable not found: '" . b:rplugin_R . "'")
    endif
    if !exists("g:vimrplugin_r_args")
        let b:rplugin_r_args = " "
    else
        let b:rplugin_r_args = g:vimrplugin_r_args
    endif
endfunction

function RSourceOtherScripts()
    if exists("g:vimrplugin_source")
        let flist = split(g:vimrplugin_source, ",")
        for fl in flist
            if fl =~ " "
                call RWarningMsgInp("Invalid file name (empty spaces are not allowed): '" . fl . "'")
            else
                exe "source " . escape(fl, ' \')
            endif
        endfor
    endif
endfunction

command -nargs=1 -complete=customlist,RLisObjs Rinsert :call RInsert(<q-args>)
command -range=% Rformat <line1>,<line2>:call RFormatCode()
command RBuildTags :call g:SendCmdToR('rtags(ofile = "TAGS")')
command -nargs=? -complete=customlist,RLisObjs Rhelp :call RAskHelp(<q-args>)
command -nargs=? -complete=dir RSourceDir :call RSourceDirectory(<q-args>)
command RpluginConfig :runtime r-plugin/vimrconfig.vim

" TODO: Delete these two commands (Nov 2013):
command RUpdateObjList :call RWarningMsg("This command is deprecated. Now the list of objects is automatically updated by the R package vimcom.plus.")
command -nargs=? RAddLibToList :call RWarningMsg("This command is deprecated. Now the list of objects is automatically updated by the R package vimcom.plus.")

"==========================================================================
" Global variables
" Convention: vimrplugin_ for user options
"             rplugin_    for internal parameters
"==========================================================================

" g:rplugin_home should be the directory where the r-plugin files are.  For
" users following the installation instructions it will be at ~/.vim or
" ~/vimfiles, that is, the same value of g:rplugin_uservimfiles. However the
" variables will have different values if the plugin is installed somewhere
" else in the runtimepath.
let g:rplugin_home = expand("<sfile>:h:h")

" g:rplugin_uservimfiles must be a writable directory. It will be g:rplugin_home
" unless it's not writable. Then it wil be ~/.vim or ~/vimfiles.
if filewritable(g:rplugin_home) == 2
    let g:rplugin_uservimfiles = g:rplugin_home
else
    let g:rplugin_uservimfiles = split(&runtimepath, ",")[0]
endif

" From changelog.vim, with bug fixed by "Si" ("i5ivem")
" Windows logins can include domain, e.g: 'DOMAIN\Username', need to remove
" the backslash from this as otherwise cause file path problems.
let g:rplugin_userlogin = substitute(system('whoami'), "\\", "-", "")

if v:shell_error
    let g:rplugin_userlogin = 'unknown'
else
    let newuline = stridx(g:rplugin_userlogin, "\n")
    if newuline != -1
        let g:rplugin_userlogin = strpart(g:rplugin_userlogin, 0, newuline)
    endif
    unlet newuline
endif

if has("win32") || has("win64")
    let g:rplugin_home = substitute(g:rplugin_home, "\\", "/", "g")
    let g:rplugin_uservimfiles = substitute(g:rplugin_uservimfiles, "\\", "/", "g")
    if $USERNAME != ""
        let g:rplugin_userlogin = substitute($USERNAME, " ", "", "g")
    endif
endif

let $VIMRPLUGIN_HOME = g:rplugin_home
if v:servername != ""
    let $VIMEDITOR_SVRNM = v:servername
endif

if isdirectory("/tmp")
    let $VIMRPLUGIN_TMPDIR = "/tmp/r-plugin-" . g:rplugin_userlogin
else
    let $VIMRPLUGIN_TMPDIR = g:rplugin_uservimfiles . "/r-plugin/tmp"
endif
let g:rplugin_esc_tmpdir = substitute($VIMRPLUGIN_TMPDIR, ' ', '\\ ', 'g')

if !isdirectory($VIMRPLUGIN_TMPDIR)
    call mkdir($VIMRPLUGIN_TMPDIR, "p", 0700)
endif

" Old name of vimrplugin_assign option
if exists("g:vimrplugin_underscore")
    let g:vimrplugin_assign = g:vimrplugin_underscore
endif

" Variables whose default value is fixed
call RSetDefaultValue("g:vimrplugin_map_r",             0)
call RSetDefaultValue("g:vimrplugin_allnames",          0)
call RSetDefaultValue("g:vimrplugin_rmhidden",          0)
call RSetDefaultValue("g:vimrplugin_assign",            1)
call RSetDefaultValue("g:vimrplugin_assign_map",    "'_'")
call RSetDefaultValue("g:vimrplugin_rnowebchunk",       1)
call RSetDefaultValue("g:vimrplugin_strict_rst",        1)
call RSetDefaultValue("g:vimrplugin_openpdf",           0)
call RSetDefaultValue("g:vimrplugin_openpdf_quietly",   0)
call RSetDefaultValue("g:vimrplugin_openhtml",          0)
call RSetDefaultValue("g:vimrplugin_i386",              0)
call RSetDefaultValue("g:vimrplugin_Rterm",             0)
call RSetDefaultValue("g:vimrplugin_restart",           0)
call RSetDefaultValue("g:vimrplugin_vsplit",            0)
call RSetDefaultValue("g:vimrplugin_rconsole_width",   -1)
call RSetDefaultValue("g:vimrplugin_rconsole_height",  15)
call RSetDefaultValue("g:vimrplugin_listmethods",       0)
call RSetDefaultValue("g:vimrplugin_specialplot",       0)
call RSetDefaultValue("g:vimrplugin_notmuxconf",        0)
call RSetDefaultValue("g:vimrplugin_only_in_tmux",      0)
call RSetDefaultValue("g:vimrplugin_routnotab",         0)
call RSetDefaultValue("g:vimrplugin_editor_w",         66)
call RSetDefaultValue("g:vimrplugin_help_w",           46)
call RSetDefaultValue("g:vimrplugin_objbr_w",          40)
call RSetDefaultValue("g:vimrplugin_external_ob",       0)
call RSetDefaultValue("g:vimrplugin_show_args",         0)
call RSetDefaultValue("g:vimrplugin_never_unmake_menu", 0)
call RSetDefaultValue("g:vimrplugin_insert_mode_cmds",  1)
call RSetDefaultValue("g:vimrplugin_indent_commented",  1)
call RSetDefaultValue("g:vimrplugin_rcomment_string", "'# '")
call RSetDefaultValue("g:vimrplugin_vimpager",        "'tab'")
call RSetDefaultValue("g:vimrplugin_objbr_place",     "'script,right'")
call RSetDefaultValue("g:vimrplugin_permanent_libs",  "'base,stats,graphics,grDevices,utils,datasets,methods'")

if executable("latexmk")
    call RSetDefaultValue("g:vimrplugin_latexcmd", "'latexmk -pdf'")
else
    call RSetDefaultValue("g:vimrplugin_latexcmd", "'pdflatex'")
endif

" Look for invalid options
let objbrplace = split(g:vimrplugin_objbr_place, ",")
let obpllen = len(objbrplace) - 1
if obpllen > 1
    call RWarningMsgInp("Too many options for vimrplugin_objbr_place.")
    let g:rplugin_failed = 1
    finish
endif
for idx in range(0, obpllen)
    if objbrplace[idx] != "console" && objbrplace[idx] != "script" && objbrplace[idx] != "left" && objbrplace[idx] != "right"
        call RWarningMsgInp('Invalid option for vimrplugin_objbr_place: "' . objbrplace[idx] . '". Valid options are: console or script and right or left."')
        let g:rplugin_failed = 1
        finish
    endif
endfor
unlet objbrplace
unlet obpllen



" python has priority over python3
if has("python3")
    command! -nargs=+ Py :py3 <args>
    command! -nargs=+ PyFile :py3file <args>
elseif has("python")
    command! -nargs=+ Py :py <args>
    command! -nargs=+ PyFile :pyfile <args>
elseif has("python3")
    command! -nargs=+ Py :py3 <args>
    command! -nargs=+ PyFile :py3file <args>
else
    command! -nargs=+ Py :
    command! -nargs=+ PyFile :
endif

exe "PyFile " . substitute(g:rplugin_home, " ", '\\ ', "g") . "/r-plugin/vimcom.py"

" ^K (\013) cleans from cursor to the right and ^U (\025) cleans from cursor
" to the left. However, ^U causes a beep if there is nothing to clean. The
" solution is to use ^A (\001) to move the cursor to the beginning of the line
" before sending ^K. But the control characters may cause problems in some
" circumstances.
call RSetDefaultValue("g:vimrplugin_ca_ck", 0)

" ========================================================================
" Set default mean of communication with R

if has('gui_running')
    let g:rplugin_tmuxwasfirst = 0
endif

if has("win32") || has("win64")
    let g:vimrplugin_applescript = 0
endif

if has("gui_macvim") || has("gui_mac") || has("mac") || has("macunix")
    let g:rplugin_r64app = 0
    if isdirectory("/Applications/R64.app")
        call RSetDefaultValue("g:vimrplugin_applescript", 1)
        let g:rplugin_r64app = 1
    elseif isdirectory("/Applications/R.app")
        call RSetDefaultValue("g:vimrplugin_applescript", 1)
    else
        call RSetDefaultValue("g:vimrplugin_applescript", 0)
    endif
else
    let g:vimrplugin_applescript = 0
endif

if has("gui_running")
    let vimrplugin_only_in_tmux = 0
endif

if g:vimrplugin_applescript
    let g:vimrplugin_only_in_tmux = 0
endif

if $TMUX != ""
    let g:rplugin_tmuxwasfirst = 1
    let g:vimrplugin_applescript = 0
else
    let g:vimrplugin_external_ob = 0
    let g:rplugin_tmuxwasfirst = 0
endif


" ========================================================================

if g:vimrplugin_external_ob == 1
    let g:vimrplugin_objbr_place = substitute(g:vimrplugin_objbr_place, "script", "console", "")
endif

if g:vimrplugin_objbr_place =~ "console"
    let g:vimrplugin_external_ob = 1
endif

" Check whether Tmux is OK
if !has("win32") && !has("win64") && !has("gui_win32") && !has("gui_win64") && g:vimrplugin_applescript == 0
    if !executable('tmux')
        call RWarningMsgInp("Please, install the 'Tmux' application to enable the Vim-R-plugin.")
        let g:rplugin_failed = 1
        finish
    endif

    let s:tmuxversion = system("tmux -V")
    let s:tmuxversion = substitute(s:tmuxversion, '.*tmux \([0-9]\.[0-9]\).*', '\1', '')
    if strlen(s:tmuxversion) != 3
        let s:tmuxversion = "1.0"
    endif
    if s:tmuxversion < "1.5"
        call RWarningMsgInp("Vim-R-plugin requires Tmux >= 1.5")
        let g:rplugin_failed = 1
        finish
    endif
    unlet s:tmuxversion

    " To get 256 colors you have to set the $TERM environment variable to
    " xterm-256color. See   :h r-plugin-tips
    let s:tmxcnf = $VIMRPLUGIN_TMPDIR . "/tmux.conf"
endif

" Start with an empty list of objects in the workspace
let g:rplugin_globalenvlines = []

if has("win32") || has("win64")

    if !has("python") && !has("python3")
        redir => s:vimversion
        silent version
        redir END
        let s:haspy2 = stridx(s:vimversion, '+python ')
        if s:haspy2 < 0
            let s:haspy2 = stridx(s:vimversion, '+python/dyn')
        endif
        let s:haspy3 = stridx(s:vimversion, '+python3')
        if s:haspy2 > 0 || s:haspy3 > 0
            let s:pyver = ""
            if s:haspy2 > 0 && s:haspy3 > 0
                let s:pyver = " (" . substitute(s:vimversion, '.*\(python2.\.dll\).*', '\1', '') . ", "
                let s:pyver = s:pyver . substitute(s:vimversion, '.*\(python3.\.dll\).*', '\1', '') . ")"
            elseif s:haspy3 > 0 && s:haspy2 < 0
                let s:pyver = " (" . substitute(s:vimversion, '.*\(python3.\.dll\).*', '\1', '') . ")"
            elseif s:haspy2 > 0 && s:haspy3 < 0
                let s:pyver = " (" . substitute(s:vimversion, '.*\(python2.\.dll\).*', '\1', '') . ")"
            endif
            let s:xx = substitute(s:vimversion, '.*\([0-9][0-9]-bit\).*', '\1', "")
            call RWarningMsgInp("This version of Vim was compiled against Python" . s:pyver . ", but Python was not found. Please, install " . s:xx . " Python from www.python.org.")
        else
            call RWarningMsgInp("This version of Vim was not compiled with Python support.")
        endif
        let g:rplugin_failed = 1
        finish
    endif
    let rplugin_pywin32 = 1
    exe "PyFile " . substitute(g:rplugin_home, " ", '\\ ', "g") . '\r-plugin\windows.py'
    if rplugin_pywin32 == 0
        let g:rplugin_failed = 1
        finish
    endif
    if !exists("g:rplugin_rpathadded")
        if exists("g:vimrplugin_r_path") && isdirectory(g:vimrplugin_r_path)
            let $PATH = g:vimrplugin_r_path . ";" . $PATH
            let g:rplugin_Rgui = g:vimrplugin_r_path . "\\Rgui.exe"
        else
            Py GetRPath()
            if exists("s:rinstallpath")
                if s:rinstallpath == "Key not found"
                    call RWarningMsgInp("Could not find R key in Windows Registry. Please, either install R or set the value of 'vimrplugin_r_path'.")
                    let g:rplugin_failed = 1
                    finish
                endif
                if s:rinstallpath == "Path not found"
                    call RWarningMsgInp("Could not find R path in Windows Registry. Please, either install R or set the value of 'vimrplugin_r_path'.")
                    let g:rplugin_failed = 1
                    finish
                endif
                if isdirectory(s:rinstallpath . '\bin\i386')
                    if !isdirectory(s:rinstallpath . '\bin\x64')
                        let g:vimrplugin_i386 = 1
                    endif
                    if g:vimrplugin_i386
                        let $PATH = s:rinstallpath . '\bin\i386;' . $PATH
                        let g:rplugin_Rgui = s:rinstallpath . '\bin\i386\Rgui.exe'
                    else
                        let $PATH = s:rinstallpath . '\bin\x64;' . $PATH
                        let g:rplugin_Rgui = s:rinstallpath . '\bin\x64\Rgui.exe'
                    endif
                else
                    let $PATH = s:rinstallpath . '\bin;' . $PATH
                    let g:rplugin_Rgui = s:rinstallpath . '\bin\Rgui.exe'
                endif
                unlet s:rinstallpath
            endif
        endif
        let g:rplugin_rpathadded = 1
    endif
    if !exists("b:rplugin_R")
        let b:rplugin_R = "Rgui.exe"
    endif
    let g:vimrplugin_term_cmd = "none"
    let g:vimrplugin_term = "none"
    if !exists("g:vimrplugin_r_args")
        let g:vimrplugin_r_args = "--sdi"
    endif
    if !exists("g:vimrplugin_sleeptime")
        let g:vimrplugin_sleeptime = 0.02
    endif
    if g:vimrplugin_Rterm
        let g:rplugin_Rgui = substitute(g:rplugin_Rgui, "Rgui", "Rterm", "")
    endif
    if !exists("g:vimrplugin_R_window_title")
        if g:vimrplugin_Rterm
            let g:vimrplugin_R_window_title = "Rterm"
        else
            let g:vimrplugin_R_window_title = "R Console"
        endif
    endif
endif

" Are we in a Debian package? Is the plugin running for the first time?
let g:rplugin_omnidname = g:rplugin_uservimfiles . "/r-plugin/objlist/"
if g:rplugin_home != g:rplugin_uservimfiles
    " Create r-plugin directory if it doesn't exist yet:
    if !isdirectory(g:rplugin_uservimfiles . "/r-plugin")
        call mkdir(g:rplugin_uservimfiles . "/r-plugin", "p")
    endif
endif

" If there is no functions.vim, copy the default one
if !filereadable(g:rplugin_uservimfiles . "/r-plugin/functions.vim")
    if filereadable("/usr/share/vim/addons/r-plugin/functions.vim")
        let ffile = readfile("/usr/share/vim/addons/r-plugin/functions.vim")
        call writefile(ffile, g:rplugin_uservimfiles . "/r-plugin/functions.vim")
        unlet ffile
    else
        if g:rplugin_home != g:rplugin_uservimfiles && filereadable(g:rplugin_home . "/r-plugin/functions.vim")
            let ffile = readfile(g:rplugin_home . "/r-plugin/functions.vim")
            call writefile(ffile, g:rplugin_uservimfiles . "/r-plugin/functions.vim")
            unlet ffile
        endif
    endif
endif

" Minimum width for the Object Browser
if g:vimrplugin_objbr_w < 10
    let g:vimrplugin_objbr_w = 10
endif


" Control the menu 'R' and the tool bar buttons
if !exists("g:rplugin_hasmenu")
    let g:rplugin_hasmenu = 0
endif

" List of marks that the plugin seeks to find the block to be sent to R
let s:all_marks = "abcdefghijklmnopqrstuvwxyz"


" Choose a terminal (code adapted from screen.vim)
if has("win32") || has("win64") || g:vimrplugin_applescript || $DISPLAY == "" || g:rplugin_tmuxwasfirst
    " No external terminal emulator will be called, so any value is good
    let g:vimrplugin_term = "xterm"
else
    let s:terminals = ['gnome-terminal', 'konsole', 'xfce4-terminal', 'terminal', 'Eterm', 'rxvt', 'aterm', 'roxterm', 'terminator', 'lxterminal', 'xterm']
    if has('mac')
        let s:terminals = ['iTerm', 'Terminal', 'Terminal.app'] + s:terminals
    endif
    if exists("g:vimrplugin_term")
        if !executable(g:vimrplugin_term)
            call RWarningMsgInp("'" . g:vimrplugin_term . "' not found. Please change the value of 'vimrplugin_term' in your vimrc.")
            unlet g:vimrplugin_term
        endif
    endif
    if !exists("g:vimrplugin_term")
        for term in s:terminals
            if executable(term)
                let g:vimrplugin_term = term
                break
            endif
        endfor
        unlet term
    endif
    unlet s:terminals
endif

if !exists("g:vimrplugin_term") && !exists("g:vimrplugin_term_cmd")
    call RWarningMsgInp("Please, set the variable 'g:vimrplugin_term_cmd' in your .vimrc. Read the plugin documentation for details.")
    let g:rplugin_failed = 1
    finish
endif

let g:rplugin_termcmd = g:vimrplugin_term . " -e"

if g:vimrplugin_term == "gnome-terminal" || g:vimrplugin_term == "xfce4-terminal" || g:vimrplugin_term == "terminal" || g:vimrplugin_term == "lxterminal"
    " Cannot set gnome-terminal icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
    let g:rplugin_termcmd = g:vimrplugin_term . " --working-directory='" . expand("%:p:h") . "' --title R -e"
endif

if g:vimrplugin_term == "terminator"
    let g:rplugin_termcmd = "terminator --working-directory='" . expand("%:p:h") . "' --title R -x"
endif

if g:vimrplugin_term == "konsole"
    let g:rplugin_termcmd = "konsole --workdir '" . expand("%:p:h") . "' --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "Eterm"
    let g:rplugin_termcmd = "Eterm --icon " . g:rplugin_home . "/bitmaps/ricon.png -e"
endif

if g:vimrplugin_term == "roxterm"
    " Cannot set icon: http://bugzilla.gnome.org/show_bug.cgi?id=126081
    let g:rplugin_termcmd = "roxterm --directory='" . expand("%:p:h") . "' --title R -e"
endif

if g:vimrplugin_term == "xterm" || g:vimrplugin_term == "uxterm"
    let g:rplugin_termcmd = g:vimrplugin_term . " -xrm '*iconPixmap: " . g:rplugin_home . "/bitmaps/ricon.xbm' -e"
endif

" Override default settings:
if exists("g:vimrplugin_term_cmd")
    let g:rplugin_termcmd = g:vimrplugin_term_cmd
endif

autocmd BufEnter * call RBufEnter()
if &filetype != "rbrowser"
    autocmd VimLeave * call RVimLeave()
endif
autocmd BufLeave * if exists("b:rsource") | call delete(b:rsource) | endif

let g:rplugin_firstbuffer = expand("%:p")
let g:rplugin_running_objbr = 0
let g:rplugin_has_new_lib = 0
let g:rplugin_has_new_obj = 0
let g:rplugin_ob_warn_shown = 0
let g:rplugin_vimcomport = 0
let g:rplugin_vimcom_pkg = "vimcom"
let g:rplugin_lastrpl = ""
let g:rplugin_ob_busy = 0
let g:rplugin_hasRSFbutton = 0
let g:rplugin_errlist = []
let g:rplugin_tmuxsname = substitute("vimrplugin-" . g:rplugin_userlogin . localtime() . g:rplugin_firstbuffer, '\W', '', 'g')

" If this is the Object Browser running in a Tmux pane, $VIMINSTANCEID is
" already defined and shouldn't be changed
if $VIMINSTANCEID == ""
    let $VIMINSTANCEID = substitute(g:rplugin_firstbuffer . localtime(), '\W', '', 'g')
endif

let g:rplugin_obsname = toupper(substitute(substitute(expand("%:r"), '\W', '', 'g'), "_", "", "g"))

let g:rplugin_docfile = $VIMRPLUGIN_TMPDIR . "/Rdoc"

" Create an empty file to avoid errors if the user do Ctrl-X Ctrl-O before
" starting R:
if &filetype != "rbrowser"
    call writefile([], $VIMRPLUGIN_TMPDIR . "/GlobalEnvList_" . $VIMINSTANCEID)
endif

call SetRPath()

" Keeps the names object list in memory to avoid the need of reading the files
" repeatedly:
let g:rplugin_libls = split(g:vimrplugin_permanent_libs, ",")
let g:rplugin_liblist = []
let s:list_of_objs = []
for lib in g:rplugin_libls
    call RAddToLibList(lib, 0)
endfor

" Check whether tool bar icons exist
if has("win32") || has("win64")
    let g:rplugin_has_icons = len(globpath(&rtp, "bitmaps/RStart.bmp")) > 0
else
    let g:rplugin_has_icons = len(globpath(&rtp, "bitmaps/RStart.png")) > 0
endif

" Compatibility with old versions (August 2013):
if exists("g:vimrplugin_tmux")
    call RWarningMsg("The option vimrplugin_tmux is deprecated and will be ignored.")
endif
if exists("g:vimrplugin_noscreenrc")
    call RWarningMsg("The option vimrplugin_noscreenrc is deprecated and will be ignored.")
endif
if exists("g:vimrplugin_screenplugin")
    call RWarningMsg("The option vimrplugin_screenplugin is deprecated and will be ignored.")
endif
if exists("g:vimrplugin_screenvsplit")
    call RWarningMsg("The option vimrplugin_screenvsplit is deprecated. Please use vimrplugin_vsplit instead.")
endif
r-plugin/global_r_plugin.vim	[[[1
27

runtime ftplugin/r.vim

function SetExeCmd()
    runtime r-plugin/common_buffer.vim
    if &filetype == "python"
        let b:rplugin_R = "python"
        let b:rplugin_r_args = " "
        let b:quit_command = "quit()"
    elseif &filetype == "haskell"
        let b:rplugin_R = "ghci"
        let b:rplugin_r_args = " "
        let b:quit_command = ":quit"
    elseif &filetype == "ruby"
        let b:rplugin_R = "irb"
        let b:rplugin_r_args = " "
        let b:quit_command = "quit"
    elseif &filetype == "lisp"
        let b:rplugin_R = "clisp"
        let b:rplugin_r_args = " "
        let b:quit_command = "(quit)"
    endif
endfunction

autocmd FileType * call SetExeCmd()
call SetExeCmd()

r-plugin/objlist/README	[[[1
5
The omnils_ and fun_ files in this directory are generated by Vim-R-plugin and
vimcom.plus and are used for omni completion and syntax highlight.

You should manually delete files corresponding to libraries that you no longer
use.
r-plugin/r.snippets	[[[1
33
# library()
snippet li
	library(${1:})
# If Condition
snippet if
	if(${1:condition}){
	    ${2:}
	}
snippet el
	else {
	    ${1:}
	}
snippet wh
	while(${1:condition}){
	    ${2:}
	}
# For Loop
snippet for
	for(${1:i} in ${2:range}){
	    ${3:}
	}
# Function
snippet fun
	${1:funname} <- function(${2:})
	{
	    ${3:}
	}
# repeat
snippet re
	repeat{
	    ${2:}
	    if(${1:condition}) break
	}
r-plugin/tex_indent.vim	[[[1
185
" Downloaded from: http://www.vim.org/scripts/script.php?script_id=218
"
" Vim indent file
" Language:     LaTeX
" Maintainer:   Johannes Tanzler <johannes.tanzler@aon.at>
" Created:      Sat, 16 Feb 2002 16:50:19 +0100
" Last Change:	Wed Feb 09, 2011  01:36PM
" Last Update:  18th feb 2002, by LH :
"               (*) better support for the option
"               (*) use some regex instead of several '||'.
"               Oct 9th, 2003, by JT:
"               (*) don't change indentation of lines starting with '%'
"               2005/06/15, Moshe Kaminsky <kaminsky@math.huji.ac.il>
"               (*) New variables:
"                   g:tex_items, g:tex_itemize_env, g:tex_noindent_env
" Version: 0.4

" Changed by Jakson Aquino to deal with R code chunks in rnoweb files.

" Options: {{{
"
" To set the following options (ok, currently it's just one), add a line like
"   let g:tex_indent_items = 1
" to your ~/.vimrc.
"
" * g:tex_indent_items
"
"   If this variable is set, item-environments are indented like Emacs does
"   it, i.e., continuation lines are indented with a shiftwidth.
"   
"   NOTE: I've already set the variable below; delete the corresponding line
"   if you don't like this behaviour.
"
"   Per default, it is unset.
"   
"              set                                unset
"   ----------------------------------------------------------------
"       \begin{itemize}                      \begin{itemize}  
"         \item blablabla                      \item blablabla
"           bla bla bla                        bla bla bla  
"         \item blablabla                      \item blablabla
"           bla bla bla                        bla bla bla  
"       \end{itemize}                        \end{itemize}    
"
"
" * g:tex_items
"
"   A list of tokens to be considered as commands for the beginning of an item 
"   command. The tokens should be separated with '\|'. The initial '\' should 
"   be escaped. The default is '\\bibitem\|\\item'.
"
" * g:tex_itemize_env
" 
"   A list of environment names, separated with '\|', where the items (item 
"   commands matching g:tex_items) may appear. The default is 
"   'itemize\|description\|enumerate\|thebibliography'.
"
" * g:tex_noindent_env
"
"   A list of environment names. separated with '\|', where no indentation is 
"   required. The default is 'document\|verbatim'.
"
" }}} 

if exists("b:did_indent") | finish
endif
let b:did_indent = 1

" Delete the next line to avoid the special indention of items
if !exists("g:tex_indent_items")
  let g:tex_indent_items = 1
endif
if g:tex_indent_items
  if !exists("g:tex_itemize_env")
    let g:tex_itemize_env = 'itemize\|description\|enumerate\|thebibliography'
  endif
  if !exists('g:tex_items')
    let g:tex_items = '\\bibitem\|\\item' 
  endif
else
  let g:tex_items = ''
endif

if !exists("g:tex_noindent_env")
  let g:tex_noindent_env = 'document\|verbatim'
endif

setlocal indentexpr=GetTeXIndent2()
setlocal nolisp
setlocal nosmartindent
setlocal autoindent
exec 'setlocal indentkeys+=}' . substitute(g:tex_items, '^\|\(\\|\)', ',=', 'g')
let g:tex_items = '^\s*' . g:tex_items


" Only define the function once
if exists("*GetTeXIndent2")
  finish
endif



function GetTeXIndent2()

  " Find a non-blank line above the current line.
  let lnum = prevnonblank(v:lnum - 1)

  " Skip R code chunk if the file type is rnoweb
  if &filetype == "rnoweb" && getline(lnum) =~ "^@$"
    let lnum = search("^<<.*>>=$", "bnW") - 1
    if lnum < 0
      let lnum = 0
    endif
  endif

  " At the start of the file use zero indent.
  if lnum == 0 | return 0 
  endif

  let ind = indent(lnum)
  let line = getline(lnum)             " last line
  let cline = getline(v:lnum)          " current line

  " Ignore comments
  if cline =~ '^\s*%'
      return ind
  endif
  while lnum > 0 && (line =~ '^\s*%' || line =~ '^\s*$')
      let lnum -= 1
      let line = getline(lnum)
  endwhile



  " Add a 'shiftwidth' after beginning of environments.
  " Don't add it for \begin{document} and \begin{verbatim}
  ""if line =~ '^\s*\\begin{\(.*\)}'  && line !~ 'verbatim' 
  " LH modification : \begin does not always start a line
  if line =~ '\\begin{.*}'  && line !~ g:tex_noindent_env

    let ind = ind + &sw

    if g:tex_indent_items
      " Add another sw for item-environments
      if line =~ g:tex_itemize_env
        let ind = ind + &sw
      endif
    endif
  endif

  
  " Subtract a 'shiftwidth' when an environment ends
  if cline =~ '^\s*\\end' && cline !~ g:tex_noindent_env

    if g:tex_indent_items
      " Remove another sw for item-environments
      if cline =~ g:tex_itemize_env
        let ind = ind - &sw
      endif
    endif

    let ind = ind - &sw
  endif

  
  " Special treatment for 'item'
  " ----------------------------
  
  if g:tex_indent_items

    " '\item' or '\bibitem' itself:
    if cline =~ g:tex_items
      let ind = ind - &sw
    endif

    " lines following to '\item' are intented once again:
    if line =~ g:tex_items
      let ind = ind + &sw
    endif

  endif

  return ind
endfunction

r-plugin/vimcom.py	[[[1
96

import socket
import vim
import os
import re
VimComPort = 0
PortWarn = False
VimComFamily = None

def DiscoverVimComPort():
    global PortWarn
    global VimComPort
    global VimComFamily
    HOST = "localhost"
    VimComPort = 9998
    repl = "NOTHING"
    correct_repl = vim.eval("$VIMINSTANCEID")
    if correct_repl is None:
        correct_repl = os.getenv("VIMINSTANCEID")
        if correct_repl is None:
            vim.command("call RWarningMsg('VIMINSTANCEID not found.')")
            return

    while repl.find(correct_repl) < 0 and VimComPort < 10050:
        VimComPort = VimComPort + 1
        for res in socket.getaddrinfo(HOST, VimComPort, socket.AF_UNSPEC, socket.SOCK_DGRAM):
            af, socktype, proto, canonname, sa = res
            try:
                sock = socket.socket(af, socktype, proto)
                sock.settimeout(0.1)
                sock.connect(sa)
                if sys.hexversion < 0x03000000:
                    sock.send("\002What port?")
                    repl = sock.recv(1024)
                else:
                    sock.send("\002What port?".encode())
                    repl = sock.recv(1024).decode()
                sock.close()
                if repl.find(correct_repl):
                    VimComFamily = af
                    if repl.find(" vimcom.plus ") > -1:
                        vim.command("let g:rplugin_vimcom_pkg = 'vimcom.plus'")
                    break
            except:
                sock = None
                continue

    if VimComPort >= 10050:
        VimComPort = 0
        vim.command("let g:rplugin_vimcomport = 0")
        if not PortWarn:
            vim.command("call RWarningMsg('VimCom port not found.')")
        PortWarn = True
    else:
        vim.command("let g:rplugin_vimcomport = " + str(VimComPort))
        PortWarn = False
        if repl.find("0.9-93") != 0:
            vim.command("call RWarningMsg('This version of Vim-R-plugin requires vimcom.plus (or vimcom) 0.9-93.')")
            vim.command("sleep 1")
    return(VimComPort)


def SendToVimCom(aString):
    HOST = "localhost"
    global VimComPort
    global VimComFamily
    if VimComPort == 0:
        VimComPort = DiscoverVimComPort()
        if VimComPort == 0:
            return
    received = None

    sock = socket.socket(VimComFamily, socket.SOCK_DGRAM)
    sock.settimeout(3.0)

    try:
        sock.connect((HOST, VimComPort))
        if sys.hexversion < 0x03000000:
            sock.send(aString)
            received = sock.recv(5012)
        else:
            sock.send(aString.encode())
            received = sock.recv(5012).decode()
    except:
        pass
    finally:
        sock.close()

    if received is None:
        vim.command("let g:rplugin_lastrpl = 'NOANSWER'")
        VimComPort = 0
        DiscoverVimComPort()
    else:
        received = received.replace("'", "' . \"'\" . '")
        vim.command("let g:rplugin_lastrpl = '" + received + "'")

r-plugin/vimrconfig.vim	[[[1
554

function! RFindString(lll, sss)
    for line in a:lll
        if line =~ a:sss
            return 1
        endif
    endfor
    return 0
endfunction

function! RGetYesOrNo(ans)
    if a:ans =~ "^[yY]"
        return 1
    elseif a:ans =~ "^[nN]" || a:ans == ""
        return 0
    else
        echohl WarningMsg
        let newans = input('Please, type "y", "n" or <Enter>: ')
        echohl Normal
        return RGetYesOrNo(newans)
    endif
endfunction

" Configure .Rprofile
function! RConfigRprofile()
    call delete($VIMRPLUGIN_TMPDIR . "/configR_result")
    let configR = ['if(.Platform$OS.type == "windows"){',
                \ '    .rpf <- Sys.getenv("R_PROFILE_USER")',
                \ '    if(.rpf == ""){',
                \ '        if(Sys.getenv("R_USER") == "")',
                \ '            stop("R_USER environment variable not set.")',
                \ '        .rpf <- paste0(Sys.getenv("R_USER"), "\\.Rprofile")',
                \ '    }',
                \ '} else {',
                \ '    if(Sys.getenv("HOME") == ""){',
                \ '        stop("HOME environment variable not set.")',
                \ '    } else {',
                \ '        .rpf <- paste0(Sys.getenv("HOME"), "/.Rprofile")',
                \ '    }',
                \ '}',
                \ 'writeLines(.rpf, con = paste0(Sys.getenv("VIMRPLUGIN_TMPDIR"), "/configR_result"))',
                \ 'rm(.rpf)']
    call RSourceLines(configR, "silent")
    sleep 1
    if !filereadable($VIMRPLUGIN_TMPDIR . "/configR_result")
        sleep 2
    endif
    if filereadable($VIMRPLUGIN_TMPDIR . "/configR_result")
        let res = readfile($VIMRPLUGIN_TMPDIR . "/configR_result")
        call delete($VIMRPLUGIN_TMPDIR . "/configR_result")
        if filereadable(res[0])
            let rpflines = readfile(res[0])
        else
            let rpflines = []
        endif

        let hasvimcom = 0
        for line in rpflines
            if line =~ "library.*vimcom" || line =~ "require.*vimcom"
                let hasvimcom = 1
                break
            endif
        endfor
        if hasvimcom
            echohl WarningMsg
            echo 'The string "vimcom" was found in your .Rprofile. No change was done.'
            echohl Normal
        else
            let rpflines += ['']
            if exists("*strftime")
                let rpflines += ['# Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
            else
                let rpflines += ['# Lines added by the Vim-R-plugin command :RpluginConfig:']
            endif
            let rpflines += ['if(interactive()){']
            if has("win32") || has("win64")
                let rpflines += ["    options(editor = '" . '"C:/Program Files (x86)/Vim/vim74/gvim.exe" "-c" "set filetype=r"' . "')"]
            else
                let rpflines += ['    if(nchar(Sys.getenv("DISPLAY")) > 1)',
                            \ "        options(editor = '" . 'gvim -f -c "set ft=r"' . "')",
                            \ '    else',
                            \ "        options(editor = '" . 'vim -c "set ft=r"' . "')",
                            \ '    library(colorout)',
                            \ '    if(Sys.getenv("TERM") != "linux" && Sys.getenv("TERM") != ""){',
                            \ '        # Choose the colors for R output among 256 options.',
                            \ '        # You should run show256Colors() and help(setOutputColors256) to',
                            \ '        # know how to change the colors according to your taste:',
                            \ '        setOutputColors256(verbose = FALSE)',
                            \ '    }',
                            \ '    library(setwidth)']
            endif
            let rpflines += ['    library(vimcom.plus)']

            if !(has("win32") || has("win64"))
                redraw
                echo " "
                echo "By defalt, R uses the 'less' application to show help documents."
                echohl Question
                let what = input("Dou you prefer to see help documents in Vim? [y/N]: ")
                echohl Normal
                if RGetYesOrNo(what)
                    let rpflines += ['    # See R documentation on Vim buffer even if asking for help in R Console:']
                    if ($PATH =~ "\\~/bin" || $PATH =~ expand("~/bin")) && filewritable(expand("~/bin")) == 2 && !filereadable(expand("~/bin/vimrpager"))
                        call writefile(['#!/bin/sh',
                                    \ 'cat | vim -c "set ft=rdoc" -'], expand("~/bin/vimrpager"))
                        call system("chmod +x " . expand("~/bin/vimrpager"))
                        let rpflines += ['    options(help_type = "text", pager = "' . expand("~/bin/vimrpager") . '")']
                    endif
                    let rpflines += ['    if(Sys.getenv("VIM_PANE") != "")',
                                \ '        options(pager = vim.pager)']
                endif

                if executable("w3m") && ($PATH =~ "\\~/bin" || $PATH =~ expand("~/bin")) && filewritable(expand("~/bin")) == 2 && !filereadable(expand("~/bin/vimrw3mbrowser"))
                    redraw
                    echo " "
                    echo "The w3m application, a text based web browser, is installed in your system."
                    echo "When R is running inside of a Tmux session, it can be configured to"
                    echo "start its help system in w3m running in a Tmux pane."
                    echohl Question
                    let what = input("Do you want to use w3m instead of your default web browser? [y/N]: ")
                    if RGetYesOrNo(what)
                        call writefile(['#!/bin/sh',
                                    \ 'NCOLS=$(tput cols)',
                                    \ 'if [ "$NCOLS" -gt "140" ]',
                                    \ 'then',
                                    \ '    if [ "x$VIM_PANE" = "x" ]',
                                    \ '    then',
                                    \ '        tmux split-window -h "w3m $1 && exit"',
                                    \ '    else',
                                    \ '        tmux split-window -h -t $VIM_PANE "w3m $1 && exit"',
                                    \ '    fi',
                                    \ 'else',
                                    \ '    tmux new-window "w3m $1 && exit"',
                                    \ 'fi'], expand("~/bin/vimrw3mbrowser"))
                        call system("chmod +x " . expand("~/bin/vimrw3mbrowser"))
                        let rpflines += ['    # Use the text based web browser w3m to navigate through R docs:',
                                    \ '    # Replace VIM_PANE with TMUX if you know what you are doing.',
                                    \ '    if(Sys.getenv("VIM_PANE") != "")',
                                    \ '        options(browser="' . expand("~/bin/vimrw3mbrowser") . '")']
                    endif
                endif
            endif

            let rpflines += ["}"]
            call writefile(rpflines, res[0])
            redraw
            echo " "
            echohl WarningMsg
            echo 'Your new .Rprofile was created.'
            echohl Normal
        endif

        if has("win32") || has("win64") || !hasvimcom
            echohl Question
            let what = input("Do you want to see your .Rprofile now? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                silent exe "tabnew " . res[0]
            endif
        else
            echohl Question
            let what = input("Do you want to see your .Rprofile along with tips on how to\nconfigure it? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                silent exe "tabnew " . res[0]
                silent help r-plugin-R-setup
            endif
        endif
        redraw
    else
        redraw
        echo " "
        call RWarningMsg("Error: configR_result not found.")
        sleep 1
        return 1
    endif
    return 0
endfunction

" Configure vimrc
function! RConfigVimrc()
    if has("win32") || has("win64")
        if filereadable($HOME . "/_vimrc")
            let uvimrc = $HOME . "/_vimrc"
        elseif filereadable($HOME . "/vimfiles/vimrc")
            let uvimrc = $HOME . "/vimfiles/vimrc"
        else
            let uvimrc = $HOME . "/_vimrc"
        endif
    else
        if filereadable($HOME . "/.vimrc")
            let uvimrc = $HOME . "/.vimrc"
        elseif filereadable($HOME . "/.vim/vimrc")
            let uvimrc = $HOME . "/.vim/vimrc"
        else
            let uvimrc = $HOME . "/.vimrc"
        endif
    endif

    if filereadable(uvimrc)
        let hasvimrc = 1
        echo " "
        echohl WarningMsg
        echo "You already have a vimrc."
        echohl Normal
        echohl Question
        let what = input("Do you want to add to the bottom of your vimrc some options that\nmost users consider convenient for the Vim-R-plugin? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines = readfile(uvimrc)
        else
            redraw
            return
        endif
    else
        let hasvimrc = 0
        echohl Question
        let what = input("It seems that you don't have a vimrc yet. Should I create it now? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines = []
        else
            redraw
            return
        endif
    endif

    let vlines += ['']
    if exists("*strftime")
        let vlines += ['" Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
    else
        let vlines += ['" Lines added by the Vim-R-plugin command :RpluginConfig:']
    endif

    if RFindString(vlines, 'set\s*nocompatible') == 0 && RFindString(vlines, 'set\s*nocp') == 0
        let vlines += ['set nocompatible']
    endif
    if RFindString(vlines, 'syntax\s*on') == 0
        let vlines += ['syntax on']
    endif
    if RFindString(vlines, 'filet.* plugin on') == 0
        let vlines += ['filetype plugin on']
    endif
    if RFindString(vlines, 'filet.* indent on') == 0
        let vlines += ['filetype indent on']
    endif

    if RFindString(vlines, "maplocalleader") == 0
        redraw
        echo " "
        if hasvimrc
            echohl WarningMsg
            echo "It seems that you didn't map your <LocalLeader> to another key."
            echohl Normal
        endif
        echo "By default, Vim's LocalLeader is the backslash (\\) which is problematic"
        echo "if we are editing LaTeX or Rnoweb (R+LaTeX) files."
        echohl Question
        let what = input("Do you want to change the LocalLeader to a comma (,)? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines += ['" Change the <LocalLeader> key:',
                        \ 'let maplocalleader = ","']
        endif
    endif

    if RFindString(vlines, "<C-x><C-o>") == 0 && RFindString(vlines, "<C-X><C-O>") == 0 && RFindString(vlines, "<c-x><c-o>") == 0
        redraw
        echo " "
        if hasvimrc
            echohl WarningMsg
            echo "It seems that you didn't create an easier map for omnicompletion yet."
            echohl Normal
        endif
        echo "By default, you have to press Ctrl+X Ctrl+O to complete the names of"
        echo "functions and other objects. This is called omnicompletion."
        echohl Question
        let what = input("Do you want to press Ctrl+Space to do omnicompletion?  [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines += ['" Use Ctrl+Space to do omnicompletion:',
                        \ 'if has("gui_running")',
                        \ '    inoremap <C-Space> <C-x><C-o>',
                        \ 'else',
                        \ '    inoremap <Nul> <C-x><C-o>',
                        \ 'endif']
        endif
    endif

    if RFindString(vlines, "RDSendLine") == 0 || RFindString(vlines, "RDSendSelection") == 0
        redraw
        echo " "
        if hasvimrc
            echohl WarningMsg
            echo "It seems that you didn't create an easier map to"
            echo "either send lines or send selected lines."
            echohl Normal
        endif
        echo "By default, you have to press \\d to send one line of code to R"
        echo "and \\ss to send a selection of lines."
        echohl Question
        let what = input("Do you prefer to press the space bar to send lines and selections\nto R Console? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines += ['" Press the space bar to send lines (in Normal mode) and selections to R:',
                        \ 'vmap <Space> <Plug>RDSendSelection',
                        \ 'nmap <Space> <Plug>RDSendLine']
        endif
    endif

    if has("unix") && has("syntax") && RFindString(vlines, "t_Co") == 0
        redraw
        echo " "
        echo "Vim is capable of displaying 256 colors in terminal emulators. However, it"
        echo "doesn't always detect that the terminal has this feature and defaults to"
        echo "using only 8 colors."
        echohl Question
        let what = input("Do you want to enable the use of 256 colors whenever possible? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines += ['',
                        \ '" Force Vim to use 256 colors if running in a capable terminal emulator:',
                        \ 'if &term =~ "xterm" || &term =~ "256" || $DISPLAY != "" || $HAS_256_COLORS == "yes"',
                        \ '    set t_Co=256',
                        \ 'endif']
        endif
    endif

    if !hasvimrc
        redraw
        echo " "
        echo "There are some options that most Vim users like, but that are not enabled by"
        echo "default such as highlighting the last search pattern, incremental search"
        echo "and setting the indentation as four spaces."
        echohl Question
        let what = input("Do you want these options in your vimrc? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let vlines += ['',
                        \ '" The lines below were also added by the Vim-R-plugin because you did not have',
                        \ '" a vimrc yet in the hope that they will help you getting started with Vim:',
                        \ '',
                        \ '" Highlight the last searched pattern:',
                        \ 'set hlsearch',
                        \ '',
                        \ '" Show where the next pattern is as you type it:',
                        \ 'set incsearch',
                        \ '',
                        \ '" By default, Vim indents code by 8 spaces. Most people prefer 4 spaces:',
                        \ 'set sw=4']
        endif
    endif

    if RFindString(vlines, "colorscheme") == 0
        let vlines += ['',
                    \ '" There are hundreds of color schemes for Vim on the internet, but you can',
                    \ '" start with color schemes already installed.',
                    \ '" Click on GVim menu bar "Edit / Color scheme" to know the name of your',
                    \ '" preferred color scheme, then, remove the double quote (which is a comment',
                    \ '" character, like the # is for R language) and replace the value "not_defined"',
                    \ '" below:',
                    \ '"colorscheme not_defined']
    endif
    call writefile(vlines, uvimrc)

    redraw
    echo " "
    echohl WarningMsg
    echo "The changes in your vimrc will be effective"
    echo "only after you quit Vim and start it again."
    echohl Question
    let what = input("Do you want to see your vimrc now? [y/N]: ")
    echohl Normal
    if RGetYesOrNo(what)
        silent exe "tabnew " . uvimrc
        normal! G
    endif
    redraw
endfunction

" Configure .bashrc
function! RConfigBash()
    if filereadable($HOME . "/.bashrc")
        let blines = readfile($HOME . "/.bashrc")
        let hastvim = 0
        for line in blines
            if line =~ "tvim"
                let hastvim = 1
                break
            endif
        endfor

        redraw
        echo " "
        if hastvim
            echohl WarningMsg
            echo "Nothing was added to your ~/.bashrc because the string 'tvim' was found in it."
            echohl Question
            let what = input("Do you want to see your ~/.bashrc along with the plugin\ntips on how to configure Bash? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                silent exe "tabnew " . $HOME . "/.bashrc"
                silent help r-plugin-bash-setup
            endif
        else
            echo "Vim and Tmux can display up to 256 colors in the terminal emulator,"
            echo "but we have to configure the TERM environment variable for that."
            echo "Instead of starting Tmux and then starting Vim, we can configure"
            echo "Bash to start both at once with the 'tvim' command."
            echo "The serverclient feature must be enabled for automatic update of the"
            echo "Object Browser and syntax highlight of function names."
            echohl Question
            let what = input("Do you want that all these features are added to your .bashrc? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                let blines += ['']
                if exists("*strftime")
                    let blines += ['# Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
                else
                    let blines += ['# Lines added by the Vim-R-plugin command :RpluginConfig:']
                endif
                let blines += ['# Change the TERM environment variable (to get 256 colors) and make Vim',
                            \ '# connecting to X Server even if running in a terminal emulator (to get',
                            \ '# dynamic update of syntax highlight and Object Browser):',
                            \ 'if [ "x$DISPLAY" != "x" ]',
                            \ 'then',
                            \ '    export HAS_256_COLORS=yes',
                            \ '    alias tmux="tmux -2"',
                            \ '    if [ "$TERM" = "xterm" ]',
                            \ '    then',
                            \ '        export TERM=xterm-256color',
                            \ '    fi',
                            \ '    alias vim="vim --servername VIM"',
                            \ '    if [ "$TERM" == "xterm" ] || [ "$TERM" == "xterm-256color" ]',
                            \ '    then',
                            \ '        function tvim(){ tmux -2 new-session "TERM=screen-256color vim --servername VIM $@" ; }',
                            \ '    else',
                            \ '        function tvim(){ tmux new-session "vim --servername VIM $@" ; }',
                            \ '    fi',
                            \ 'else',
                            \ '    if [ "$TERM" == "xterm" ] || [ "$TERM" == "xterm-256color" ]',
                            \ '    then',
                            \ '        export HAS_256_COLORS=yes',
                            \ '        alias tmux="tmux -2"',
                            \ '        function tvim(){ tmux -2 new-session "TERM=screen-256color vim $@" ; }',
                            \ '    else',
                            \ '        function tvim(){ tmux new-session "vim $@" ; }',
                            \ '    fi',
                            \ 'fi',
                            \ 'if [ "$TERM" = "screen" ] && [ "$HAS_256_COLORS" = "yes" ]',
                            \ 'then',
                            \ '    export TERM=screen-256color',
                            \ 'fi' ]
                call writefile(blines, $HOME . "/.bashrc")
                if !has("gui_running")
                    redraw
                    echo " "
                    echohl WarningMsg
                    echo "The changes in your bashrc will be effective"
                    echo "only after you exit from Bash and start it again"
                    if $DISPLAY == ""
                        echo "(logoff and login again)."
                    else
                        echo "(close the terminal emulator and start it again)."
                    endif
                endif
                echohl Question
                let what = input("Do you want to see your .bashrc now? [y/N]: ")
                echohl Normal
                if RGetYesOrNo(what)
                    silent exe "tabnew " . $HOME . "/.bashrc"
                    normal! G32k
                endif
            endif
        endif
        redraw
    endif
endfunction

function! RConfigTmux()
    redraw
    echo " "
    if filereadable($HOME . "/.tmux.conf")
        echohl WarningMsg
        echo "You already have a .tmux.conf."
        echohl Question
        let what = input("Do you want to see it along with the plugin tips on how to\nconfigure Tmux? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            silent exe "tabnew " . $HOME . "/.tmux.conf"
            silent help r-plugin-tmux-setup
        endif
        redraw
    else
        echohl Question
        let what = input("You don't have a ~/.tmux.conf yet. Should I create it now? [y/N]: ")
        echohl Normal
        if RGetYesOrNo(what)
            let tlines = ['']
            if exists("*strftime")
                let tlines += ['# Lines added by the Vim-R-plugin command :RpluginConfig (' . strftime("%Y-%b-%d %H:%M") . '):']
            else
                let tlines += ['# Lines added by the Vim-R-plugin command :RpluginConfig:']
            endif
            let tlines += ["set-option -g prefix C-a",
                        \ "unbind-key C-b",
                        \ "bind-key C-a send-prefix",
                        \ "set -g status off",
                        \ "set-window-option -g mode-keys vi",
                        \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'",
                        \ "set -g mode-mouse on",
                        \ "set -g mouse-select-pane on",
                        \ "set -g mouse-resize-pane on"]
            call writefile(tlines, $HOME . "/.tmux.conf")
            redraw
            echo " "
            echohl Question
            let what = input("Do you want to see your .tmux.conf now? [y/N]: ")
            echohl Normal
            if RGetYesOrNo(what)
                silent exe "tabnew " . $HOME . "/.tmux.conf"
            endif
            redraw
        endif
    endif
endfunction

function! RConfigVimR()
    if string(g:SendCmdToR) == "function('SendCmdToR_fake')"
        if hasmapto("<Plug>RStart", "n")
            let cmd = RNMapCmd("<Plug>RStart")
        else
            if exists("g:maplocalleader")
                let cmd = g:maplocalleader . "rf"
            else
                let cmd = "\\rf"
            endif
        endif
        call RWarningMsg("Please type  " . cmd . "  to start R before running  :RpluginConfig")
        return
    endif
    if RConfigRprofile()
        return
    endif
    call RConfigVimrc()
    if has("win32") || has("win64")
        return
    endif
    call RConfigTmux()
    call RConfigBash()
endfunction

call RConfigVimR()

r-plugin/windows.py	[[[1
230

import os
import string
import time
import vim
RConsole = 0
Rterm = False

try:
    import win32api
    import win32clipboard
    import win32com.client
    import win32con
    import win32gui
except ImportError:
    import platform
    myPyVersion = platform.python_version()
    myArch = platform.architecture()
    vim.command("call RWarningMsgInp('Please install PyWin32. The Python version being used is: " + myPyVersion + " (" + myArch[0] + ")')")
    vim.command("let rplugin_pywin32 = 0")

def RightClick():
    global RConsole
    myHandle = win32gui.GetForegroundWindow()
    RaiseRConsole()
    time.sleep(0.05)
    lParam = (100 << 16) | 100
    win32gui.SendMessage(RConsole, win32con.WM_RBUTTONDOWN, 0, lParam)
    win32gui.SendMessage(RConsole, win32con.WM_RBUTTONUP, 0, lParam)
    time.sleep(0.05)
    try:
        win32gui.SetForegroundWindow(myHandle)
    except:
        vim.command("call RWarningMsg('Could not put itself on foreground.')")

def CntrlV():
    global RConsole
    win32api.keybd_event(0x11, 0, 0, 0)
    try:
        win32api.PostMessage(RConsole, 0x100, 0x56, 0x002F0001)
    except:
        vim.command("call RWarningMsg('R Console window not found [1].')")
        RConsole = 0
        pass
    if RConsole:
        time.sleep(0.05)
        try:
            win32api.PostMessage(RConsole, 0x101, 0x56, 0xC02F0001)
        except:
            vim.command("call RWarningMsg('R Console window not found [2].')")
            pass
    win32api.keybd_event(0x11, 0, 2, 0)

def FindRConsole():
    global RConsole
    Rttl = vim.eval("g:vimrplugin_R_window_title")
    Rtitle = Rttl
    RConsole = win32gui.FindWindow(None, Rtitle)
    if RConsole == 0:
        Rtitle = Rttl + " (64-bit)"
        RConsole = win32gui.FindWindow(None, Rtitle)
        if RConsole == 0:
            Rtitle = Rttl + " (32-bit)"
            RConsole = win32gui.FindWindow(None, Rtitle)
            if RConsole == 0:
                vim.command("call RWarningMsg('Could not find R Console.')")
    if RConsole:
        vim.command("let g:rplugin_R_window_ttl = '" + Rtitle + "'")

def SendToRConsole(aString):
    global RConsole
    global Rterm
    SendToVimCom("\x09Set R as busy [SendToRConsole()]")
    if sys.hexversion < 0x03000000:
        finalString = aString.decode("latin-1") + "\n"
    else:
        finalString = aString
    win32clipboard.OpenClipboard(0)
    win32clipboard.EmptyClipboard()
    win32clipboard.SetClipboardText(finalString)
    win32clipboard.CloseClipboard()
    if RConsole == 0:
        FindRConsole()
    if RConsole:
        if Rterm:
            RightClick()
        else:
            CntrlV()

def RClearConsolePy():
    global RConsole
    global Rterm
    if Rterm:
        return
    if RConsole == 0:
        FindRConsole()
    if RConsole:
        win32api.keybd_event(0x11, 0, 0, 0)
        try:
            win32api.PostMessage(RConsole, 0x100, 0x4C, 0x002F0001)
        except:
            vim.command("call RWarningMsg('R Console window not found [1].')")
            RConsole = 0
            pass
        if RConsole:
            time.sleep(0.05)
            try:
                win32api.PostMessage(RConsole, 0x101, 0x4C, 0xC02F0001)
            except:
                vim.command("call RWarningMsg('R Console window not found [2].')")
                pass
        win32api.keybd_event(0x11, 0, 2, 0)

def RaiseRConsole():
    global RConsole
    FindRConsole()
    if RConsole:
        win32gui.SetForegroundWindow(RConsole)
        time.sleep(0.1)

def SendQuitMsg(aString):
    global RConsole
    global Rterm
    SendToVimCom("\x09Set R as busy [SendQuitMsg()]")
    if sys.hexversion < 0x03000000:
        finalString = aString.decode("latin-1") + "\n"
    else:
        finalString = aString + "\n"
    win32clipboard.OpenClipboard(0)
    win32clipboard.EmptyClipboard()
    win32clipboard.SetClipboardText(finalString)
    win32clipboard.CloseClipboard()
    sleepTime = float(vim.eval("g:vimrplugin_sleeptime"))
    RaiseRConsole()
    if RConsole and not Rterm:
        time.sleep(sleepTime)
        win32api.keybd_event(win32con.VK_CONTROL, 0, 0, 0)
        win32api.keybd_event(ord('V'), 0, win32con.KEYEVENTF_EXTENDEDKEY | 0, 0)
        time.sleep(0.05)
        win32api.keybd_event(ord('V'), 0, win32con.KEYEVENTF_EXTENDEDKEY | win32con.KEYEVENTF_KEYUP, 0)
        win32api.keybd_event(win32con.VK_CONTROL, 0, win32con.KEYEVENTF_KEYUP, 0)
        time.sleep(0.05)
        RConsole = 0
    if RConsole and Rterm:
        RightClick()
        RConsole = 0

def GetRPath():
    keyName = "SOFTWARE\\R-core\\R"
    kHandle = None
    try:
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_LOCAL_MACHINE, keyName, 0, win32con.KEY_READ)
        rVersion, reserved, kclass, lastwrite = win32api.RegEnumKeyEx(kHandle)[-1]
        win32api.RegCloseKey(kHandle)
        kHandle = None
        keyName = keyName + "\\" + rVersion
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_LOCAL_MACHINE, keyName, 0, win32con.KEY_READ)
    except:
        try:
            kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
            rVersion, reserved, kclass, lastwrite = win32api.RegEnumKeyEx(kHandle)[-1]
            win32api.RegCloseKey(kHandle)
            kHandle = None
            keyName = keyName + "\\" + rVersion
            kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
        except:
            vim.command("let s:rinstallpath =  'Key not found'")
    if kHandle:
        (kname, rpath, vtype) = win32api.RegEnumValue(kHandle, 0)
        win32api.RegCloseKey(kHandle)
        if kname == 'InstallPath':
            vim.command("let s:rinstallpath = '" + rpath + "'")
        else:
            vim.command("let s:rinstallpath =  'Path not found'")

def StartRPy():
    global Rterm
    if vim.eval("g:vimrplugin_Rterm") == "1":
        Rterm = True
    else:
        Rterm = False
    rpath = vim.eval("g:rplugin_Rgui")
    rpath = rpath.replace("\\", "\\\\")
    rargs = ['"' + rpath + '"']
    r_args = vim.eval("b:rplugin_r_args")
    if r_args != " ":
        r_args = r_args.split(' ')
        i = 0
        alen = len(r_args)
        while i < alen:
            rargs.append(r_args[i])
            i = i + 1

    kHandle = None
    keyName = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders"
    try:
        kHandle = win32api.RegOpenKeyEx(win32con.HKEY_CURRENT_USER, keyName, 0, win32con.KEY_READ)
    except:
        vim.command("RWarningMsg('Personal folder not found in registry')")

    if kHandle:
        i = 0
        folder = "none"
        while folder != "Personal":
            try:
                (folder, fpath, vtype) = win32api.RegEnumValue(kHandle, i)
            except:
                break
            i = i + 1
        win32api.RegCloseKey(kHandle)
        if folder == "Personal":
            rargs.append('HOME="' + fpath + '"')
        else:
            vim.command("RWarningMsg('Personal folder not found in registry')")

    if os.path.isfile(rpath):
        os.spawnv(os.P_NOWAIT, rpath, rargs)
    else:
        vim.command("echoerr 'File ' . g:rplugin_Rgui . ' not found.'")

def OpenPDF(fn):
    try:
        os.startfile(fn)
    except Exception as errmsg:
        errstr = str(errmsg)
        errstr = errstr.replace("'", '"')
        vim.command("call RWarningMsg('" + errstr + "')")
        pass


syntax/r.vim	[[[1
292
" Vim syntax file
" Language:	      R (GNU S)
" Maintainer:	      Jakson Aquino <jalvesaq@gmail.com>
" Former Maintainers: Vaidotas Zemlys <zemlys@gmail.com>
" 		      Tom Payne <tom@tompayne.org>
" Last Change:	      Mon Nov 11, 2013  10:12PM
" Filenames:	      *.R *.r *.Rhistory *.Rt
" 
" NOTE: The highlighting of R functions is defined in the
" r-plugin/functions.vim, which is part of vim-r-plugin2:
" http://www.vim.org/scripts/script.php?script_id=2628
"
" CONFIGURATION:
"   syntax folding can be turned on by
"
"      let r_syntax_folding = 1
"
" Some lines of code were borrowed from Zhuojun Chen.

if exists("b:current_syntax")
    finish
endif

setlocal iskeyword=@,48-57,_,.

if exists("g:r_syntax_folding")
    setlocal foldmethod=syntax
endif

syn case match

" Comment
syn match rCommentTodo contained "\(BUG\|FIXME\|NOTE\|TODO\):"
syn match rComment contains=@Spell,rCommentTodo "#.*"

" Roxygen
syn match rOKeyword contained "@\(param\|return\|name\|rdname\|examples\|include\|docType\)"
syn match rOKeyword contained "@\(S3method\|TODO\|aliases\|alias\|assignee\|author\|callGraphDepth\|callGraph\)"
syn match rOKeyword contained "@\(callGraphPrimitives\|concept\|exportClass\|exportMethod\|exportPattern\|export\|formals\)"
syn match rOKeyword contained "@\(format\|importClassesFrom\|importFrom\|importMethodsFrom\|import\|keywords\)"
syn match rOKeyword contained "@\(method\|nord\|note\|references\|seealso\|setClass\|slot\|source\|title\|usage\)"
syn match rOComment contains=@Spell,rOKeyword "#'.*"


if &filetype == "rhelp"
    " string enclosed in double quotes
    syn region rString contains=rSpecial,@Spell start=/"/ skip=/\\\\\|\\"/ end=/"/
    " string enclosed in single quotes
    syn region rString contains=rSpecial,@Spell start=/'/ skip=/\\\\\|\\'/ end=/'/
else
    " string enclosed in double quotes
    syn region rString contains=rSpecial,rStrError,@Spell start=/"/ skip=/\\\\\|\\"/ end=/"/
    " string enclosed in single quotes
    syn region rString contains=rSpecial,rStrError,@Spell start=/'/ skip=/\\\\\|\\'/ end=/'/
endif

syn match rStrError display contained "\\."


" New line, carriage return, tab, backspace, bell, feed, vertical tab, backslash
syn match rSpecial display contained "\\\(n\|r\|t\|b\|a\|f\|v\|'\|\"\)\|\\\\"

" Hexadecimal and Octal digits
syn match rSpecial display contained "\\\(x\x\{1,2}\|[0-8]\{1,3}\)"

" Unicode characters
syn match rSpecial display contained "\\u\x\{1,4}"
syn match rSpecial display contained "\\U\x\{1,8}"
syn match rSpecial display contained "\\u{\x\{1,4}}"
syn match rSpecial display contained "\\U{\x\{1,8}}"

" Statement
syn keyword rStatement   break next return
syn keyword rConditional if else
syn keyword rRepeat      for in repeat while

" Constant (not really)
syn keyword rConstant T F LETTERS letters month.abb month.name pi
syn keyword rConstant R.version.string

syn keyword rNumber   NA_integer_ NA_real_ NA_complex_ NA_character_ 

" Constants
syn keyword rConstant NULL
syn keyword rBoolean  FALSE TRUE
syn keyword rNumber   NA Inf NaN 

" integer
syn match rInteger "\<\d\+L"
syn match rInteger "\<0x\([0-9]\|[a-f]\|[A-F]\)\+L"
syn match rInteger "\<\d\+[Ee]+\=\d\+L"

" number with no fractional part or exponent
syn match rNumber "\<\d\+\>"
" hexadecimal number 
syn match rNumber "\<0x\([0-9]\|[a-f]\|[A-F]\)\+"

" floating point number with integer and fractional parts and optional exponent
syn match rFloat "\<\d\+\.\d*\([Ee][-+]\=\d\+\)\="
" floating point number with no integer part and optional exponent
syn match rFloat "\<\.\d\+\([Ee][-+]\=\d\+\)\="
" floating point number with no fractional part and optional exponent
syn match rFloat "\<\d\+[Ee][-+]\=\d\+"

" complex number
syn match rComplex "\<\d\+i"
syn match rComplex "\<\d\++\d\+i"
syn match rComplex "\<0x\([0-9]\|[a-f]\|[A-F]\)\+i"
syn match rComplex "\<\d\+\.\d*\([Ee][-+]\=\d\+\)\=i"
syn match rComplex "\<\.\d\+\([Ee][-+]\=\d\+\)\=i"
syn match rComplex "\<\d\+[Ee][-+]\=\d\+i"

syn match rOperator    "&"
syn match rOperator    '-'
syn match rOperator    '\*'
syn match rOperator    '+'
syn match rOperator    '='
if &filetype != "rmd" && &filetype != "rrst"
    syn match rOperator    "[|!<>^~/:]"
else
    syn match rOperator    "[|!<>^~`/:]"
endif
syn match rOperator    "%\{2}\|%\S*%"
syn match rOpError  '\*\{3}'
syn match rOpError  '//'
syn match rOpError  '&&&'
syn match rOpError  '|||'
syn match rOpError  '<<'
syn match rOpError  '>>'

syn match rArrow "<\{1,2}-"
syn match rArrow "->\{1,2}"

" Special
syn match rDelimiter "[,;:]"

" Error
if exists("g:r_syntax_folding")
    syn region rRegion matchgroup=Delimiter start=/(/ matchgroup=Delimiter end=/)/ transparent contains=ALLBUT,rError,rBraceError,rCurlyError fold
    syn region rRegion matchgroup=Delimiter start=/{/ matchgroup=Delimiter end=/}/ transparent contains=ALLBUT,rError,rBraceError,rParenError fold
    syn region rRegion matchgroup=Delimiter start=/\[/ matchgroup=Delimiter end=/]/ transparent contains=ALLBUT,rError,rCurlyError,rParenError fold
else
    syn region rRegion matchgroup=Delimiter start=/(/ matchgroup=Delimiter end=/)/ transparent contains=ALLBUT,rError,rBraceError,rCurlyError
    syn region rRegion matchgroup=Delimiter start=/{/ matchgroup=Delimiter end=/}/ transparent contains=ALLBUT,rError,rBraceError,rParenError
    syn region rRegion matchgroup=Delimiter start=/\[/ matchgroup=Delimiter end=/]/ transparent contains=ALLBUT,rError,rCurlyError,rParenError
endif

syn match rError      "[)\]}]"
syn match rBraceError "[)}]" contained
syn match rCurlyError "[)\]]" contained
syn match rParenError "[\]}]" contained

syn match rDollar display contained "\$"
syn match rDollar display contained "@"

" List elements will not be highlighted as functions:
syn match rLstElmt "\$[a-zA-Z0-9\\._]*" contains=rDollar
syn match rLstElmt "@[a-zA-Z0-9\\._]*" contains=rDollar

" Functions that may add new objects
syn keyword rPreProc     library require attach detach source

if &filetype == "rhelp"
    syn match rHelpIdent '\\method'
    syn match rHelpIdent '\\S4method'
endif

" Type
syn keyword rType array category character complex double function integer list logical matrix numeric vector data.frame 

" Name of object with spaces
if &filetype != "rmd" && &filetype != "rrst"
    syn region rNameWSpace start="`" end="`"
endif

if &filetype == "rhelp"
    syn match rhPreProc "^#ifdef.*" 
    syn match rhPreProc "^#endif.*" 
    syn match rhSection "\\dontrun\>"
endif

" Define the default highlighting.
hi def link rArrow       Statement	
hi def link rBoolean     Boolean
hi def link rBraceError  Error
hi def link rComment     Comment
hi def link rCommentTodo Todo
hi def link rOComment    Comment
hi def link rComplex     Number
hi def link rConditional Conditional
hi def link rConstant    Constant
hi def link rCurlyError  Error
hi def link rDelimiter   Delimiter
hi def link rDollar      SpecialChar
hi def link rError       Error
hi def link rFloat       Float
hi def link rFunction    Function
hi def link rHelpIdent   Identifier
hi def link rhPreProc    PreProc
hi def link rhSection    PreCondit
hi def link rInteger     Number
hi def link rLstElmt	 Normal
hi def link rNameWSpace  Normal
hi def link rNumber      Number
hi def link rOperator    Operator
hi def link rOpError     Error
hi def link rParenError  Error
hi def link rPreProc     PreProc
hi def link rRepeat      Repeat
hi def link rSpecial     SpecialChar
hi def link rStatement   Statement
hi def link rString      String
hi def link rStrError    Error
hi def link rType        Type
hi def link rOKeyword    Title

let b:current_syntax="r"

" The code below is used by the Vim-R-plugin:
" http://www.vim.org/scripts/script.php?script_id=2628

" Users may define the value of g:vimrplugin_permanent_libs to determine what
" functions should be highlighted even if R is not running. By default, the
" functions of packages loaded by R --vanilla are highlighted.
if !exists("g:vimrplugin_permanent_libs")
    let g:vimrplugin_permanent_libs = "base,stats,graphics,grDevices,utils,datasets,methods"
endif

" Store the names R package whose functions were already added to syntax
" highlight to avoid sourcing them repeatedly.
let b:rplugin_funls = []

" The function RUpdateFunSyntax() is called by the Vim-R-plugin whenever the
" user loads a new package in R. The function should be defined only once.
" Thus, if it's already defined, call it and finish.
if exists("*RUpdateFunSyntax")
    call RUpdateFunSyntax(0)
    finish
endif

function RAddToFunList(lib, verbose)
    " Only run once for each package:
    for pkg in b:rplugin_funls
        if pkg == a:lib
            return
        endif
    endfor

    " The fun_ files list functions of R packages and are created by the
    " Vim-R-plugin:
    let fnf = split(globpath(&rtp, 'r-plugin/objlist/fun_' . a:lib . '_*'), "\n")

    if len(fnf) == 1
        silent exe "source " . fnf[0]
        let b:rplugin_funls += [a:lib]
    elseif a:verbose && len(fnf) == 0
        echohl WarningMsg
        echomsg 'Fun_ file for "' . a:lib . '" not found.'
        echohl Normal
        return
    elseif a:verbose && len(fnf) > 1
        echohl WarningMsg
        echomsg 'There is more than one fun_ file for "' . a:lib . '":'
        for fff in fnf
            echomsg fff
        endfor
        echohl Normal
        return
    endif
endfunction

function RUpdateFunSyntax(verbose)
    " Do nothing if called at a buffer that doesn't include R syntax:
    if !exists("b:rplugin_funls")
        return
    endif
    if exists("g:rplugin_libls")
        for lib in g:rplugin_libls
            call RAddToFunList(lib, a:verbose)
        endfor
    else
        if exists("g:vimrplugin_permanent_libs")
            for lib in split(g:vimrplugin_permanent_libs, ",")
                call RAddToFunList(lib, a:verbose)
            endfor
        endif
    endif
endfunction

call RUpdateFunSyntax(0)

" vim: ts=8 sw=4
syntax/rbrowser.vim	[[[1
71
" Vim syntax file
" Language:	Object browser of Vim-R-plugin
" Maintainer:	Jakson Alves de Aquino (jalvesaq@gmail.com)

if exists("b:current_syntax")
    finish
endif
scriptencoding utf-8

setlocal iskeyword=@,48-57,_,.

if has("conceal")
    setlocal conceallevel=2
    setlocal concealcursor=nvc
    syn match rbrowserNumeric	"{#.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserCharacter	/"#.*\t/ contains=rbrowserDelim,rbrowserTab
    syn match rbrowserFactor	"'#.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserFunction	"(#.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserList	"\[#.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserLogical	"%#.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserLibrary	"##.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserS4  	"<#.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserUnknown	"=#.*\t" contains=rbrowserDelim,rbrowserTab
else
    syn match rbrowserNumeric	"{.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserCharacter	/".*\t/ contains=rbrowserDelim,rbrowserTab
    syn match rbrowserFactor	"'.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserFunction	"(.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserList	"\[.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserLogical	"%.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserLibrary	"#.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserS4	        "<.*\t" contains=rbrowserDelim,rbrowserTab
    syn match rbrowserUnknown	"=.*\t" contains=rbrowserDelim,rbrowserTab
endif
syn match rbrowserEnv		"^.GlobalEnv "
syn match rbrowserEnv		"^Libraries "
syn match rbrowserLink		" Libraries$"
syn match rbrowserLink		" .GlobalEnv$"
syn match rbrowserTreePart	"├─"
syn match rbrowserTreePart	"└─"
syn match rbrowserTreePart	"│" 
if &encoding != "utf-8"
    syn match rbrowserTreePart	"|" 
    syn match rbrowserTreePart	"`-"
    syn match rbrowserTreePart	"|-"
endif

syn match rbrowserTab contained "\t"
if has("conceal")
    syn match rbrowserDelim contained /'#\|"#\|(#\|\[#\|{#\|%#\|##\|<#\|=#/ conceal
else
    syn match rbrowserDelim contained /'\|"\|(\|\[\|{\|%\|#\|<\|=/
endif

hi def link rbrowserEnv		Statement
hi def link rbrowserNumeric	Number
hi def link rbrowserCharacter	String
hi def link rbrowserFactor	Special
hi def link rbrowserList	Type
hi def link rbrowserLibrary	PreProc
hi def link rbrowserLink	Comment
hi def link rbrowserLogical	Boolean
hi def link rbrowserFunction	Function
hi def link rbrowserS4  	Statement
hi def link rbrowserUnknown	Normal
hi def link rbrowserWarn	WarningMsg
hi def link rbrowserTreePart	Comment
hi def link rbrowserDelim	Ignore
hi def link rbrowserTab		Ignore

" vim: ts=8 sw=4
syntax/rdoc.vim	[[[1
60
" Vim syntax file
" Language:	R documentation
" Maintainer:	Jakson A. Aquino <jalvesaq@gmail.com>

if exists("b:current_syntax")
    finish
endif

setlocal iskeyword=@,48-57,_,.

if !exists("rdoc_minlines")
    let rdoc_minlines = 200
endif
if !exists("rdoc_maxlines")
    let rdoc_maxlines = 2 * rdoc_minlines
endif
exec "syn sync minlines=" . rdoc_minlines . " maxlines=" . rdoc_maxlines


syn match  rdocTitle	      "^[A-Z].*:$"
syn match  rdocTitle "^\S.*R Documentation$"
syn match rdocFunction "\([A-Z]\|[a-z]\|\.\|_\)\([A-Z]\|[a-z]\|[0-9]\|\.\|_\)*" contained
syn region rdocStringS  start="â" end="â" contains=rdocFunction transparent keepend
syn region rdocStringS  start="" end="" contains=rdocFunction transparent keepend
syn region rdocStringD  start='"' skip='\\"' end='"'
syn match rdocURL `\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^'	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]`
syn keyword rdocNote		note Note NOTE note: Note: NOTE: Notes Notes:

" When using vim as R pager to see the output of help.search():
syn region rdocPackage start="^[A-Za-z]\S*::" end="[\s\r]" contains=rdocPackName,rdocFuncName transparent
syn match rdocPackName "^[A-Za-z][A-Za-z0-9\.]*" contained
syn match rdocFuncName "::[A-Za-z0-9\.\-_]*" contained

syn match rdocArgItems "\n\n.\{-}:" contains=rdocArg contained transparent

syn region rdocArgReg matchgroup=rdocArgTitle start="^Arguments:" end="^[A-Z].*:$" contains=rdocArgItems,rdocArgTitle,rdocPackage,rdocFuncName,rdocStringS keepend transparent
syn match rdocArg "\([A-Z]\|[a-z]\|[0-9]\|\.\|_\)*" contained


syn include @rdocR syntax/r.vim
syn region rdocExample matchgroup=rdocExTitle start="^Examples:$" matchgroup=rdocExEnd end='^###$' contains=@rdocR keepend

" Define the default highlighting.
"hi def link rdocArgReg Statement
hi def link rdocTitle	    Title
hi def link rdocArgTitle    Title
hi def link rdocExTitle   Title
hi def link rdocExEnd   Comment
hi def link rdocFunction    Function
hi def link rdocStringD     String
hi def link rdocURL    HtmlLink
hi def link rdocArg         Special
hi def link rdocNote  Todo

hi def link rdocPackName Title
hi def link rdocFuncName Function

let b:current_syntax = "rdoc"

" vim: ts=8 sw=4
syntax/rhelp.vim	[[[1
247
" Vim syntax file
" Language:    R Help File
" Maintainer: Jakson Aquino <jalvesaq@gmail.com>
" Former Maintainer: Johannes Ranke <jranke@uni-bremen.de>
" Last Change: Sat Nov 09, 2013  07:29PM
" Remarks:     - Includes R syntax highlighting in the appropriate
"                sections if an r.vim file is in the same directory or in the
"                default debian location.
"              - There is no Latex markup in equations
"              - Thanks to Will Gray for finding and fixing a bug
"              - No support for \if, \ifelse and \out as I don't understand
"                them and have no examples at hand (help welcome).
"              - No support for \var tag within quoted string (dito)

" Version Clears: {{{1
" For version 5.x: Clear all syntax items
" For version 6.x and 7.x: Quit when a syntax file was already loaded
if version < 600 
    syntax clear
elseif exists("b:current_syntax")
    finish
endif 

setlocal iskeyword=@,48-57,_,.

syn case match

" R help identifiers {{{1
syn region rhelpIdentifier matchgroup=rhelpSection	start="\\name{" end="}" 
syn region rhelpIdentifier matchgroup=rhelpSection	start="\\alias{" end="}" 
syn region rhelpIdentifier matchgroup=rhelpSection	start="\\pkg{" end="}" contains=rhelpLink
syn region rhelpIdentifier matchgroup=rhelpSection start="\\method{" end="}" contained
syn region rhelpIdentifier matchgroup=rhelpSection start="\\Rdversion{" end="}"

" Highlighting of R code using an existing r.vim syntax file if available {{{1
syn include @R syntax/r.vim

" Strings {{{1
syn region rhelpString start=/"/ skip=/\\"/ end=/"/ contains=rhelpSpecialChar,rhelpCodeSpecial,rhelpLink contained

" Special characters in R strings
syn match rhelpCodeSpecial display contained "\\\\\(n\|r\|t\|b\|a\|f\|v\|'\|\"\)\|\\\\"

" Special characters  ( \$ \& \% \# \{ \} \_)
syn match rhelpSpecialChar        "\\[$&%#{}_]"


" R code {{{1
syn match rhelpDots		"\\dots" containedin=@R
syn region rhelpRcode matchgroup=Delimiter start="\\examples{" matchgroup=Delimiter transparent end="}" contains=@R,rhelpLink,rhelpIdentifier,rhelpString,rhelpSpecialChar,rhelpSection
syn region rhelpRcode matchgroup=Delimiter start="\\usage{" matchgroup=Delimiter transparent end="}" contains=@R,rhelpIdentifier,rhelpS4method
syn region rhelpRcode matchgroup=Delimiter start="\\synopsis{" matchgroup=Delimiter transparent end="}" contains=@R
syn region rhelpRcode matchgroup=Delimiter start="\\special{" matchgroup=Delimiter transparent end="}" contains=@R

if v:version > 703
    syn region rhelpRcode matchgroup=Delimiter start="\\code{" skip='\\\@1<!{.\{-}\\\@1<!}' transparent end="}" contains=@R,rhelpDots,rhelpString,rhelpSpecialChar,rhelpLink keepend
else
    syn region rhelpRcode matchgroup=Delimiter start="\\code{" skip='\\\@<!{.\{-}\\\@<!}' transparent end="}" contains=@R,rhelpDots,rhelpString,rhelpSpecialChar,rhelpLink keepend
endif
syn region rhelpS4method matchgroup=Delimiter start="\\S4method{.*}(" matchgroup=Delimiter transparent end=")" contains=@R,rhelpDots
syn region rhelpSexpr matchgroup=Delimiter start="\\Sexpr{" matchgroup=Delimiter transparent end="}" contains=@R

" PreProc {{{1
syn match rhelpPreProc "^#ifdef.*" 
syn match rhelpPreProc "^#endif.*" 

" Special Delimiters {{{1
syn match rhelpDelimiter		"\\cr"
syn match rhelpDelimiter		"\\tab "

" Keywords {{{1
syn match rhelpKeyword	"\\R"
syn match rhelpKeyword	"\\ldots"
syn match rhelpKeyword  "--"
syn match rhelpKeyword  "---"
syn match rhelpKeyword  "<"
syn match rhelpKeyword  ">"
syn match rhelpKeyword	"\\ge"
syn match rhelpKeyword	"\\le"
syn match rhelpKeyword	"\\alpha"
syn match rhelpKeyword	"\\beta"
syn match rhelpKeyword	"\\gamma"
syn match rhelpKeyword	"\\delta"
syn match rhelpKeyword	"\\epsilon"
syn match rhelpKeyword	"\\zeta"
syn match rhelpKeyword	"\\eta"
syn match rhelpKeyword	"\\theta"
syn match rhelpKeyword	"\\iota"
syn match rhelpKeyword	"\\kappa"
syn match rhelpKeyword	"\\lambda"
syn match rhelpKeyword	"\\mu"
syn match rhelpKeyword	"\\nu"
syn match rhelpKeyword	"\\xi"
syn match rhelpKeyword	"\\omicron"
syn match rhelpKeyword	"\\pi"
syn match rhelpKeyword	"\\rho"
syn match rhelpKeyword	"\\sigma"
syn match rhelpKeyword	"\\tau"
syn match rhelpKeyword	"\\upsilon"
syn match rhelpKeyword	"\\phi"
syn match rhelpKeyword	"\\chi"
syn match rhelpKeyword	"\\psi"
syn match rhelpKeyword	"\\omega"
syn match rhelpKeyword	"\\Alpha"
syn match rhelpKeyword	"\\Beta"
syn match rhelpKeyword	"\\Gamma"
syn match rhelpKeyword	"\\Delta"
syn match rhelpKeyword	"\\Epsilon"
syn match rhelpKeyword	"\\Zeta"
syn match rhelpKeyword	"\\Eta"
syn match rhelpKeyword	"\\Theta"
syn match rhelpKeyword	"\\Iota"
syn match rhelpKeyword	"\\Kappa"
syn match rhelpKeyword	"\\Lambda"
syn match rhelpKeyword	"\\Mu"
syn match rhelpKeyword	"\\Nu"
syn match rhelpKeyword	"\\Xi"
syn match rhelpKeyword	"\\Omicron"
syn match rhelpKeyword	"\\Pi"
syn match rhelpKeyword	"\\Rho"
syn match rhelpKeyword	"\\Sigma"
syn match rhelpKeyword	"\\Tau"
syn match rhelpKeyword	"\\Upsilon"
syn match rhelpKeyword	"\\Phi"
syn match rhelpKeyword	"\\Chi"
syn match rhelpKeyword	"\\Psi"
syn match rhelpKeyword	"\\Omega"

" Links {{{1
syn region rhelpLink matchgroup=rhelpSection start="\\link{" end="}" contained keepend extend
syn region rhelpLink matchgroup=rhelpSection start="\\link\[.\{-}\]{" end="}" contained keepend extend
syn region rhelpLink matchgroup=rhelpSection start="\\linkS4class{" end="}" contained keepend extend

" Verbatim like {{{1
if v:version > 703
    syn region rhelpVerbatim matchgroup=rhelpType start="\\samp{" skip='\\\@1<!{.\{-}\\\@1<!}' end="}" contains=rhelpSpecialChar,rhelpComment
    syn region rhelpVerbatim matchgroup=rhelpType start="\\verb{" skip='\\\@1<!{.\{-}\\\@1<!}' end="}" contains=rhelpSpecialChar,rhelpComment
else
    syn region rhelpVerbatim matchgroup=rhelpType start="\\samp{" skip='\\\@<!{.\{-}\\\@<!}' end="}" contains=rhelpSpecialChar,rhelpComment
    syn region rhelpVerbatim matchgroup=rhelpType start="\\verb{" skip='\\\@<!{.\{-}\\\@<!}' end="}" contains=rhelpSpecialChar,rhelpComment
endif

" Type Styles {{{1
syn match rhelpType		"\\emph\>"
syn match rhelpType		"\\strong\>"
syn match rhelpType		"\\bold\>"
syn match rhelpType		"\\sQuote\>"
syn match rhelpType		"\\dQuote\>"
syn match rhelpType		"\\preformatted\>"
syn match rhelpType		"\\kbd\>"
syn match rhelpType		"\\eqn\>"
syn match rhelpType		"\\deqn\>"
syn match rhelpType		"\\file\>"
syn match rhelpType		"\\email\>"
syn match rhelpType		"\\url\>"
syn match rhelpType		"\\href\>"
syn match rhelpType		"\\var\>"
syn match rhelpType		"\\env\>"
syn match rhelpType		"\\option\>"
syn match rhelpType		"\\command\>"
syn match rhelpType		"\\newcommand\>"
syn match rhelpType		"\\renewcommand\>"
syn match rhelpType		"\\dfn\>"
syn match rhelpType		"\\cite\>"
syn match rhelpType		"\\acronym\>"

" rhelp sections {{{1
syn match rhelpSection		"\\encoding\>"
syn match rhelpSection		"\\title\>"
syn match rhelpSection		"\\item\>"
syn match rhelpSection		"\\description\>"
syn match rhelpSection		"\\concept\>"
syn match rhelpSection		"\\arguments\>"
syn match rhelpSection		"\\details\>"
syn match rhelpSection		"\\value\>"
syn match rhelpSection		"\\references\>"
syn match rhelpSection		"\\note\>"
syn match rhelpSection		"\\author\>"
syn match rhelpSection		"\\seealso\>"
syn match rhelpSection		"\\keyword\>"
syn match rhelpSection		"\\docType\>"
syn match rhelpSection		"\\format\>"
syn match rhelpSection		"\\source\>"
syn match rhelpSection    "\\itemize\>"
syn match rhelpSection    "\\describe\>"
syn match rhelpSection    "\\enumerate\>"
syn match rhelpSection    "\\item "
syn match rhelpSection    "\\item$"
syn match rhelpSection		"\\tabular{[lcr]*}"
syn match rhelpSection		"\\dontrun\>"
syn match rhelpSection		"\\dontshow\>"
syn match rhelpSection		"\\testonly\>"
syn match rhelpSection		"\\donttest\>"

" Freely named Sections {{{1
syn region rhelpFreesec matchgroup=Delimiter start="\\section{" matchgroup=Delimiter transparent end="}"
syn region rhelpFreesubsec matchgroup=Delimiter start="\\subsection{" matchgroup=Delimiter transparent end="}" 

syn match rhelpDelimiter "{\|\[\|(\|)\|\]\|}"

" R help file comments {{{1
syn match rhelpComment /%.*$/

" Error {{{1
syn region rhelpRegion matchgroup=Delimiter start=/(/ matchgroup=Delimiter end=/)/ contains=@Spell,rhelpCodeSpecial,rhelpComment,rhelpDelimiter,rhelpDots,rhelpFreesec,rhelpFreesubsec,rhelpIdentifier,rhelpKeyword,rhelpLink,rhelpPreProc,rhelpRComment,rhelpRcode,rhelpRegion,rhelpS4method,rhelpSection,rhelpSexpr,rhelpSpecialChar,rhelpString,rhelpType,rhelpVerbatim
syn region rhelpRegion matchgroup=Delimiter start=/{/ matchgroup=Delimiter end=/}/ contains=@Spell,rhelpCodeSpecial,rhelpComment,rhelpDelimiter,rhelpDots,rhelpFreesec,rhelpFreesubsec,rhelpIdentifier,rhelpKeyword,rhelpLink,rhelpPreProc,rhelpRComment,rhelpRcode,rhelpRegion,rhelpS4method,rhelpSection,rhelpSexpr,rhelpSpecialChar,rhelpString,rhelpType,rhelpVerbatim
syn region rhelpRegion matchgroup=Delimiter start=/\[/ matchgroup=Delimiter end=/]/ contains=@Spell,rhelpCodeSpecial,rhelpComment,rhelpDelimiter,rhelpDots,rhelpFreesec,rhelpFreesubsec,rhelpIdentifier,rhelpKeyword,rhelpLink,rhelpPreProc,rhelpRComment,rhelpRcode,rhelpRegion,rhelpS4method,rhelpSection,rhelpSexpr,rhelpSpecialChar,rhelpString,rhelpType,rhelpVerbatim
syn match rhelpError      /[)\]}]/
syn match rhelpBraceError /[)}]/ contained
syn match rhelpCurlyError /[)\]]/ contained
syn match rhelpParenError /[\]}]/ contained

" Define the default highlighting {{{1
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_rhelp_syntax_inits")
    if version < 508
        let did_rhelp_syntax_inits = 1
        command -nargs=+ HiLink hi link <args>
    else
        command -nargs=+ HiLink hi def link <args>
    endif
    HiLink rhelpVerbatim    String
    HiLink rhelpDelimiter   Delimiter
    HiLink rhelpIdentifier  Identifier
    HiLink rhelpString      String
    HiLink rhelpCodeSpecial Special
    HiLink rhelpKeyword     Keyword
    HiLink rhelpDots        Keyword
    HiLink rhelpLink        Underlined
    HiLink rhelpType        Type
    HiLink rhelpSection     PreCondit
    HiLink rhelpError       Error
    HiLink rhelpBraceError  Error
    HiLink rhelpCurlyError  Error
    HiLink rhelpParenError  Error
    HiLink rhelpPreProc     PreProc
    HiLink rhelpDelimiter   Delimiter
    HiLink rhelpComment     Comment
    HiLink rhelpRComment    Comment
    HiLink rhelpSpecialChar SpecialChar
    delcommand HiLink
endif 

let   b:current_syntax = "rhelp"

" vim: foldmethod=marker sw=4
syntax/rmd.vim	[[[1
85
" markdown Text with R statements
" Language: markdown with R code chunks
" Last Change: Sat Nov 09, 2013  07:28PM
"
" CONFIGURATION:
"   To highlight chunk headers as R code, put in your vimrc:
"   let rmd_syn_hl_chunk = 1

" for portability
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" load all of pandoc info
runtime syntax/pandoc.vim
if exists("b:current_syntax")
    let rmdIsPandoc = 1
    unlet b:current_syntax
else
    let rmdIsPandoc = 0
    runtime syntax/markdown.vim
    if exists("b:current_syntax")
        unlet b:current_syntax
    endif
endif

" load all of the r syntax highlighting rules into @R
syntax include @R syntax/r.vim
if exists("b:current_syntax")
    unlet b:current_syntax
endif

setlocal iskeyword=@,48-57,_,.

if exists("g:rmd_syn_hl_chunk")
    " highlight R code inside chunk header
    syntax match rmdChunkDelim "^[ \t]*```{r" contained
    syntax match rmdChunkDelim "}$" contained
else
    syntax match rmdChunkDelim "^[ \t]*```{r.*}$" contained
endif
syntax match rmdChunkDelim "^[ \t]*```$" contained
syntax region rmdChunk start="^[ \t]*``` *{r.*}$" end="^[ \t]*```$" contains=@R,rmdChunkDelim keepend fold

" also match and syntax highlight in-line R code
syntax match rmdEndInline "`" contained
syntax match rmdBeginInline "`r " contained
syntax region rmdrInline start="`r "  end="`" contains=@R,rmdBeginInline,rmdEndInline keepend

" match slidify special marker
syntax match rmdSlidifySpecial "\*\*\*"


if rmdIsPandoc == 0
    syn match rmdBlockQuote /^\s*>.*\n\(.*\n\@<!\n\)*/ skipnl
    " LaTeX
    syntax include @LaTeX syntax/tex.vim
    if exists("b:current_syntax")
        unlet b:current_syntax
    endif
    " Inline
    syntax match rmdLaTeXInlDelim "\$"
    syntax match rmdLaTeXInlDelim "\\\$"
    syn region texMathZoneX	matchgroup=Delimiter start="\$" skip="\\\\\|\\\$"	matchgroup=Delimiter end="\$" end="%stopzone\>"	contains=@texMathZoneGroup
    " Region
    syntax match rmdLaTeXRegDelim "\$\$" contained
    syntax match rmdLaTeXRegDelim "\$\$latex$" contained
    syntax region rmdLaTeXRegion start="^\$\$" skip="\\\$" end="\$\$$" contains=@LaTeX,rmdLaTeXSt,rmdLaTeXRegDelim keepend
    syntax region rmdLaTeXRegion2 start="^\\\[" end="\\\]" contains=@LaTeX,rmdLaTeXSt,rmdLaTeXRegDelim keepend
    hi def link rmdLaTeXSt Statement
    hi def link rmdLaTeXInlDelim Special
    hi def link rmdLaTeXRegDelim Special
endif

hi def link rmdChunkDelim Special
hi def link rmdBeginInline Special
hi def link rmdEndInline Special
hi def link rmdBlockQuote Comment
hi def link rmdSlidifySpecial Special

let b:current_syntax = "rmd"

" vim: ts=8 sw=4
syntax/rout.vim	[[[1
136
" Vim syntax file
" Language:    R output Files
" Maintainer:  Jakson Aquino <jalvesaq@gmail.com>
" Last Change: Sat Nov 09, 2013  07:29PM
"

" Version Clears: {{{1
" For version 5.x: Clear all syntax items
" For version 6.x and 7.x: Quit when a syntax file was already loaded
if version < 600 
    syntax clear
elseif exists("b:current_syntax")
    finish
endif 

setlocal iskeyword=@,48-57,_,.

syn case match

" Strings
syn region routString start=/"/ skip=/\\\\\|\\"/ end=/"/ end=/$/

" Constants
syn keyword rConstant NULL
syn keyword rBoolean  FALSE TRUE
syn keyword rNumber   NA Inf NaN 

" integer
syn match rInteger "\<\d\+L"
syn match rInteger "\<0x\([0-9]\|[a-f]\|[A-F]\)\+L"
syn match rInteger "\<\d\+[Ee]+\=\d\+L"

" number with no fractional part or exponent
syn match rNumber "\<\d\+\>"
" hexadecimal number 
syn match rNumber "\<0x\([0-9]\|[a-f]\|[A-F]\)\+"

" floating point number with integer and fractional parts and optional exponent
syn match rFloat "\<\d\+\.\d*\([Ee][-+]\=\d\+\)\="
" floating point number with no integer part and optional exponent
syn match rFloat "\<\.\d\+\([Ee][-+]\=\d\+\)\="
" floating point number with no fractional part and optional exponent
syn match rFloat "\<\d\+[Ee][-+]\=\d\+"

" complex number
syn match rComplex "\<\d\+i"
syn match rComplex "\<\d\++\d\+i"
syn match rComplex "\<0x\([0-9]\|[a-f]\|[A-F]\)\+i"
syn match rComplex "\<\d\+\.\d*\([Ee][-+]\=\d\+\)\=i"
syn match rComplex "\<\.\d\+\([Ee][-+]\=\d\+\)\=i"
syn match rComplex "\<\d\+[Ee][-+]\=\d\+i"

if !exists("g:vimrplugin_routmorecolors")
    let g:vimrplugin_routmorecolors = 0
endif

if g:vimrplugin_routmorecolors == 1
    syn include @routR syntax/r.vim
    syn region routColoredR start="^> " end='$' contains=@routR keepend
    syn region routColoredR start="^+ " end='$' contains=@routR keepend
else
    " Comment
    syn match routComment /^> .*/
    syn match routComment /^+ .*/
endif

" Index of vectors
syn match routIndex /^\s*\[\d\+\]/

" Errors and warnings
syn match routError "^Error.*"
syn match routWarn "^Warning.*"

if v:lang =~ "^de"
    syn match routError	"^Fehler.*"
    syn match routWarn	"^Warnung.*"
endif

if v:lang =~ "^es"
    syn match routWarn	"^Aviso.*"
endif

if v:lang =~ "^fr"
    syn match routError	"^Erreur.*"
    syn match routWarn	"^Avis.*"
endif

if v:lang =~ "^it"
    syn match routError	"^Errore.*"
    syn match routWarn	"^Avviso.*"
endif

if v:lang =~ "^nn"
    syn match routError	"^Feil.*"
    syn match routWarn	"^Åtvaring.*"
endif

if v:lang =~ "^pl"
    syn match routError	"^BŁĄD.*"
    syn match routError	"^Błąd.*"
    syn match routWarn	"^Ostrzeżenie.*"
endif

if v:lang =~ "^pt_BR"
    syn match routError	"^Erro.*"
    syn match routWarn	"^Aviso.*"
endif

if v:lang =~ "^ru"
    syn match routError	"^Ошибка.*"
    syn match routWarn	"^Предупреждение.*"
endif

if v:lang =~ "^tr"
    syn match routError	"^Hata.*"
    syn match routWarn	"^Uyarı.*"
endif

" Define the default highlighting.
if g:vimrplugin_routmorecolors == 0
    hi def link routComment	Comment
endif
hi def link rNumber	Number
hi def link rComplex	Number
hi def link rInteger	Number
hi def link rBoolean	Boolean
hi def link rConstant	Constant
hi def link rFloat	Float
hi def link routString	String
hi def link routError	Error
hi def link routWarn	WarningMsg
hi def link routIndex	Special

let   b:current_syntax = "rout"

" vim: ts=8 sw=4
syntax/rrst.vim	[[[1
47
" reStructured Text with R statements
" Language: reST with R code chunks
" Maintainer: Alex Zvoleff, azvoleff@mail.sdsu.edu
" Last Change: Sat Nov 09, 2013  07:28PM
"
" CONFIGURATION:
"   To highlight chunk headers as R code, put in your vimrc:
"   let rrst_syn_hl_chunk = 1

" for portability
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" load all of the rst info
runtime syntax/rst.vim
unlet b:current_syntax

" load all of the r syntax highlighting rules into @R
syntax include @R syntax/r.vim

setlocal iskeyword=@,48-57,_,.

" highlight R chunks
if exists("g:rrst_syn_hl_chunk")
    " highlight R code inside chunk header
    syntax match rrstChunkDelim "^\.\. {r" contained
    syntax match rrstChunkDelim "}$" contained
else
    syntax match rrstChunkDelim "^\.\. {r .*}$" contained
endif
syntax match rrstChunkDelim "^\.\. \.\.$" contained
syntax region rrstChunk start="^\.\. {r.*}$" end="^\.\. \.\.$" contains=@R,rrstChunkDelim keepend transparent fold

" also highlight in-line R code
syntax match rrstInlineDelim "`" contained
syntax match rrstInlineDelim ":r:" contained
syntax region rrstInline start=":r: *`" skip=/\\\\\|\\`/ end="`" contains=@R,rrstInlineDelim keepend

hi def link rrstChunkDelim Special
hi def link rrstInlineDelim Special

let b:current_syntax = "rrst"

" vim: ts=8 sw=4
