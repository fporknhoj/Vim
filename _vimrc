"  set nocompatible              " be iMproved, required
"  filetype off                  " required
"  
"  " set the runtime path to include Vundle and initialize
"  set rtp+=~/.vim/bundle/Vundle.vim
"  call vundle#begin()
"  " alternatively, pass a path where Vundle should install plugins
"  call vundle#begin('~/some/path/here')
"  set nocompatible              " be iMproved, required
"  filetype off                  " required
"  
" set the runtime path to include Vundle and initialize
"  set rtp+=~/.vim/bundle/Vundle.vim
"  call vundle#begin()
"  " alternatively, pass a path where Vundle should install plugins
"  call vundle#begin('~/some/path/here')
"  
"  " let Vundle manage Vundle, required
"  Plugin 'gmarik/Vundle.vim'
"  
"  " The following are examples of different formats supported.
"  " Keep Plugin commands between vundle#begin/end.
"  " plugin on GitHub repo
"  Plugin 'tpope/vim-fugitive'
"  " plugin from http://vim-scripts.org/vim/scripts.html
"  Plugin 'L9'
"  " Git plugin not hosted on GitHub
"  Plugin 'git://git.wincent.com/command-t.git'
"  " git repos on your local machine (i.e. when working on your own plugin)
"  Plugin 'file:///home/gmarik/path/to/plugin'
"  " The sparkup vim script is in a subdirectory of this repo called vim.
"  " Pass the path to set the runtimepath properly.
"  Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
"  " Avoid a name conflict with L9
"  Plugin 'user/L9', {'name': 'newL9'}
"  
"  " All of your Plugins must be added before the following line
"  call vundle#end()            " required
"  filetype plugin indent on    " required
"  " To ignore plugin indent changes, instead use:
"  "filetype plugin on
"  "
"  " Brief help
"  " :PluginList          - list configured plugins
"  " :PluginInstall(!)    - install (update) plugins
"  " :PluginSearch(!) foo - search (or refresh cache first) for foo
"  " :PluginClean(!)      - confirm (or auto-approve) removal of unused plugins
"  "
"  " see :h vundle for more details or wiki for FAQ
"  " Put your non-Plugin stuff after this line"
"  " " let Vundle manage Vundle, required
"  " Plugin 'gmarik/Vundle.vim'
"  "
"  " " The following are examples of different formats supported.
"  " " Keep Plugin commands between vundle#begin/end.
"  " " plugin on GitHub repo
"  " Plugin 'tpope/vim-fugitive'
"  " " plugin from http://vim-scripts.org/vim/scripts.html
"  " Plugin 'L9'
"  " " Git plugin not hosted on GitHub
"  " Plugin 'git://git.wincent.com/command-t.git'
"  " " git repos on your local machine (i.e. when working on your own plugin)
"  " Plugin 'file:///home/gmarik/path/to/plugin'
"  " " The sparkup vim script is in a subdirectory of this repo called vim.
"  " " Pass the path to set the runtimepath properly.
"  " Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
"  " " Avoid a name conflict with L9
"  " Plugin 'user/L9', {'name': 'newL9'}
"  "
"  " " All of your Plugins must be added before the following line
"  " call vundle#end()            " required
"  " filetype plugin indent on    " required
"  " " To ignore plugin indent changes, instead use:
"  " "filetype plugin on
"  " "
"  " " Brief help
"  " " :PluginList          - list configured plugins
"  " " :PluginInstall(!)    - install (update) plugins
"  " " :PluginSearch(!) foo - search (or refresh cache first) for foo
"  " " :PluginClean(!)      - confirm (or auto-approve) removal of unused plugins
"  " "
"  " " see :h vundle for more details or wiki for FAQ
"  " " Put your non-Plugin stuff after this line
"  
"  
"
"

let mapleader =  "\\"
let g:mapleader = "\\"

"set guifont=source\ code\ pro:h8
"set guifont=ProFontWindows:h9
"set guifont=Anonymous\ Pro\ Minus:h9
"set guifont=PT\ Mono:h8
set gfn=M+_1mn_regular:h10:cANSI
set gfn=Consolas:h10
set gfn=Luxi\ Mono:h8
set gfn=ProFontWindows:h9
set gfn=Anonymous\ Pro\ Minus:h10
set gfn=Prestige12\ BT:h8
set gfn=Prestige\ Becker:h11

colo github

set number
set nohlsearch

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

set hidden
set backspace=2
set clipboard=unnamed
set autochdir
set expandtab
set nowrap

filetype plugin on
set omnifunc=syntaxcomplete#Complete

behave xterm
cd \Users\John.Kropf\Documents\Projects\Text\ Files\

"set backupdir=\program\ files\ vim\backup\
"set directory=
set backupdir=$TEMP,$TMP,.

"remove toolbar
set go-=T

"map esc to jj 
imap jj <esc>
map j gj
map k gk
map <up> gk
map <down> gj
map <left> h
map <right> l

"change semicolon to colon
map ; :
noremap ;; ;
" nnoremap ; :
" nnoremap : ;
" vnoremap ; :
" vnoremap : ;

"switch buffers
" map <C-Tab> :bn<CR>
" map <C-S-Tab> :bp<CR>
" map <C-PageUp> :bn<CR>
" map <C-PageDown> :bp<CR>

map <C-Tab> ;bn<CR>
map <C-S-Tab> ;bp<CR>
map <C-PageUp> ;bn<CR>
map <C-PageDown> ;bp<CR>



"Cursor
"highlight Cursor guifg=green guibg=green
"highlight iCursor guifg=green guibg=green
"set guicursor=n-v-c:block-Cursor
"set guicursor+=i:ver100-iCursor
"set guicursor+=n-v-c:blinkon0
"set guicursor+=i:blinkwait10


source $VIMRUNTIME/vimrc_example.vim
"source $VIMRUNTIME/mswin.vim
"behave mswin

function! SQLfix()
	%s/SELECT  /SELECT   \n/g
	%s/FROM  /FROM   \n/g
	%s/JOIN  /JOIN \n/g
	%s/ ON  / ON   \n/g
	%s/WHERE  /WHERE   \n/g
	%s/GROUP BY  /GROUP BY   \n/g
	%s/HAVING  /HAVING   \n/g
endfunction

set diffexpr=MyDiff()
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let eq = ''
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      let cmd = '""' . $VIMRUNTIME . '\diff"'
      let eq = '"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction

