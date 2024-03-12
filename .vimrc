"2021/Nov

set nocompatible    "be IMproved!

" update 2018-11 consistently use .vim directory regardless of OS
set rtp+=$HOME/.vim/bundle/Vundle.vim  "setup for Vundle
let path='$HOME/.vim/bundle'           "with Unix paths

if has('unix')
  set encoding=utf-8      "makes alt keys work
  set clipboard=unnamedplus   "makes clipboard work
end

if has('win32')
  set encoding=utf-8      "makes alt keys work
  set clipboard=unnamed   "makes clipboard work
end

"mac is uncomfortable since it's both Unix and Windows-like
if has('osx')
  set encoding=utf-8      "makes alt keys work
  set clipboard=unnamed   "makes clipboard work
end

" PLUGINS
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype off
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/syntastic'
Plugin 'Shougo/deoplete.nvim'
Plugin 'roxma/nvim-yarp'
Plugin 'roxma/vim-hug-neovim-rpc'
Plugin 'flazz/vim-colorschemes'
Plugin 'jiangmiao/auto-pairs'
Plugin 'easymotion/vim-easymotion'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'michaeljsmith/vim-indent-object'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'junegunn/vim-easy-align'
Plugin 'scrooloose/nerdcommenter'
Plugin 'hdima/python-syntax'
Plugin 'hynek/vim-python-pep8-indent'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'alvan/vim-closetag' " can cause trouble
Plugin 'bkad/CamelCaseMotion'
" Cool colors
Plugin 'mhinz/vim-janah'
Plugin 'GGalizzi/cake-vim'
Plugin 'bcicen/vim-vice'
Plugin 'mbbill/undotree'
"TODO: learn how to use this! super useful but a bit unwieldy
Plugin 'jeetsukumaran/vim-indentwise'
Plugin 'Yggdroot/indentLine'
" NO RUBY
"Plugin 'sjbach/lusty'
Plugin 'https://gitlab.com/HiPhish/info.vim'

" unused languages
"Plugin 'itchyny/vim-haskell-indent'
"Plugin 'andy-morris/happy.vim'
"Plugin 'tikhomirov/vim-glsl'
"Plugin 'PProvost/vim-ps1'

" unused utilities
"Plugin 'FredKSchott/CoVim' #damn, it'd be really cool if this had worked
"Plugin 'justinmk/vim-gtfo'
"Plugin 'scrooloose/nerdtree'
"Plugin 'ternjs/tern_for_vim'
"Plugin 'kien/ctrlp.vim'

" replaced
"Plugin 'gavocanov/vim-js-indent'
"Plugin 'helino/vim-json'
"Plugin 'pangloss/vim-javascript'
"Plugin 'SirVer/ultisnips'
 

call vundle#end()

" INITIALIZATION
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !isdirectory($HOME."/.vim/undo/")
  call mkdir($HOME."/.vim/undo", "p")
endif

" SETTINGS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on
set mousehide      " hide mouse while typing
set history=1000   " big history
set number         " line numbers
set showmatch      " match brackets
set incsearch      " incremental search
set hlsearch       " search highlighting
set whichwrap=b,s,h,l,<,>,[,]   " give keys wraparound
set backspace=indent,eol,start  " thank you jesus, normal acting backspace
set nowrap        " who needs it
"WELCOME TO 2019: we 2 spaces now
set shiftwidth=2   " indents have a width of 2
set softtabstop=2
set expandtab      "look into when we do or don't want this
set tabstop=2      " width of tab character. useful to set this to 2 so we don't go out of sync
set showtabline=2
set t_RV= ttymouse=xterm2  " fixes weird 2c at startup HACK (shouldn't need it forever)
"set mouse=n       " only important in macvim?
set ignorecase     " let search be case insensitive
set smartcase      " *unless* it contains a capitalized letter
set hidden         " hide buffers without saving them
set scrolloff=5    " just a shade more than normal
set noswapfile     " no thx
set undofile       " persistent undo
set undodir=~/.vim/undo/ "but without polluting working directories
set autoread       " idk what this does i should look it up

"set noerrorbells visualbell t_vb=
"actually i like the bell :P

augroup VIMRC
  autocmd!
  autocmd GUIEnter * set visualbell t_vb=
  autocmd GUIEnter * set visualbell t_vb=

  "Special for python <3
  autocmd FileType python setlocal softtabstop=4 | setlocal expandtab
  "Special for HTML <3
  "autocmd FileType javascript setlocal shiftwidth=2 | setlocal tabstop=2 | setlocal softtabstop=2 | setlocal expandtab | hi Conceal ctermfg=8
  "autocmd FileType javascript :setlocal shiftwidth=4 | :setlocal tabstop=4

  autocmd FileType haskell setlocal softtabstop=4 | setlocal expandtab

  "REDACTED (A relic of the bygone era of nested callback hell)
  "autocmd FileType javascript :execute 'inoremap <CR> ' . maparg('<CR>','i') . "<c-o>:call <SID>CallbackSemicolon()\r"

  " close preview window automatically when using annotated code completions
  "autocmd CursorMovedI * if pumvisible() == 0|pclose|endif 
  "                                                         delete straight away
  autocmd InsertLeave * if pumvisible() == 0|pclose|endif 
  "                                                        waits until exit
  "autocmd CompleteDone * pclose 
  "                               probably more performant

  " please god make the indent lines dark
  autocmd BufReadPost * hi Conceal ctermfg=8 ctermbg=0
  autocmd BufWritePost * hi Conceal ctermfg=8 ctermbg=0

augroup end


" ABBREVIATONS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"common typos
" this is either really smart or REALLY dumb
iab fucntion function
" idk why i can't spell this word specifically
iab PropTyptes PropTypes
iab propTyptes propTypes

" FUNCTIONS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"when moving by word, skip until alphanumeric word is found
" TODO: apply a count though

function! s:JumpToNextWord()
	let l:lastln = -1
	let l:lastcol = -1
  normal! w
  while strpart(getline('.'), col('.')-1, 1) !~ '\w'
    normal! w
    if (l:lastln == line('.')) && (l:lastcol == col('.')) 
      break
    endif
    let l:lastln = line('.')
    let l:lastcol = col('.')
  endwhile
endfunction

function! s:JumpToPrevWord()
  normal! b
  while strpart(getline('.'), col('.')-1, 1) !~ '\w' && ( col('.') > 1 || line('.') > 1)
      normal! b
  endwhile
endfunction

" Inserts semicolons at the end of constructs like Callback(function() {})
"function! s:CallbackSemicolon()
"  if strpart(getline('.'), col('.')-1) == '})'
"    execute "normal! A;\<Esc>"
"    execute "normal! O\t\b"
"  endif
"endfunction

function! s:LineEmpty()
  return getline('.') == ''
endfunction


function! s:TrailingChar(check)
	let l:line = getline('.')
	return strpart(l:line, strlen(l:line) - 1) == a:check
endfunction


" KEY MAPPINGS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader=';'

"make ;k act as close to <Esc> as possible
set iminsert=1
lnoremap ;k <Esc>
vnoremap ;k <Esc>
nnoremap <silent>;k :noh<CR>:set norelativenumber<CR>
cnoremap ;k <c-e><c-u><Esc>:echo ""<CR>
" if only we had this in Bash too lol
tnoremap ;k <Esc>

"convenience commands
"available for something else now
"nnoremap <leader>s :%s /
nnoremap <c-/> /\v
nnoremap \ :%s /
nnoremap <c-\> :%s /\v

"hop out of vim real quick
nnoremap ! :!$SHELL<CR>
"make sure to make a $SHELL command in windows :^)

"insert single character without leaving normal mode
" very useful when auto pairs is being a pain
nnoremap <leader>i i <Esc>r
nnoremap <leader>a a <Esc>r
"heck why not just do braces
nnoremap <expr><leader>} <SID>TrailingChar('}') ? 'mm$"_x`m' : "mmA}\<Esc>`m"
nnoremap <expr><leader>) <SID>TrailingChar(')') ? 'mm$"_x`m' : "mmA)\<Esc>`m"}

"todo???? : make i autotab the way o does
"actually : just use S

"toggle semicolon at the end of a line;
nnoremap <expr>;; <SID>TrailingChar(';') ? 'mm$"_x`m' : "mmA;\<Esc>`m"
"same deal but with commas (nice)
nnoremap <expr>,, <SID>TrailingChar(',') ? 'mm$"_x`m' : "mmA,\<Esc>`"

let &t_TI = "\<Esc>[>4;2m"
let &t_TE = "\<Esc>[>4;m"

" this was mostly to get rid of .js when it snuck in imports and requires
" but then , it turned out !!! deleting everything back to the . is useful, like , all the time !
nnoremap <Backspace> ldF.
" ah HECK let's make all KINDS OF THESE
nnoremap <S-Backspace> dT x
inoremap <S-Backspace> <Esc>dT xi

" TIL backspace was  control - h ??? (2022-12)
nnoremap <Backspace> ldF.
nnoremap <S-Backspace> dT x
inoremap <S-Backspace> <Esc>dT xi


"new window nav shortcuts
nnoremap <c-W><c-H> <c-W>v
nnoremap <c-W><c-L> <c-W>v<c-W>l
nnoremap <c-W><c-K> <c-W>s
nnoremap <c-W><c-J> <c-W>s<c-W>j

"easily resize windows
nnoremap <C-up> <C-w>+
nnoremap <C-down> <C-w>-
nnoremap <C-left> <C-w><
nnoremap <C-right> <C-w>>

"buffer / tab stuff
nnoremap <leader>n :bn<CR>
nnoremap <leader>p :bp<CR>
" delete buffers without changing window flow
"(this also means ;d won't delete the last buffer)
" TODO: this could use considerable improvement
" heck this messes up tabs though
" also EPICALLY fails when the previous buffer is a terminal
" also causes reflow 
" TODO: separate terminals from normal ;n ;p flow
" ideally a ;t switches to and between terminals
nnoremap <leader>d :bn<CR>:bd #<CR>
" May start using vim as "tmux" in which case tabs would be
" a welcome replacement to actually switching ttys
nnoremap <leader>tt :tabnew<CR>
nnoremap <leader>tn :tabn<CR>
nnoremap <leader>tb :tabp<CR>
nnoremap <leader>tp :tabp<CR>
" TODO: figure out a way to open / close windows without totally f***ing tabs

"relative line number in visual line and visual block mode

function! s:enter_visual_line()
  execute "set relativenumber"
  execute "normal! V"
endfunction
function! s:enter_visual_block()
  execute "set relativenumber"
  execute "normal! "
endfunction
nnoremap <silent>V :call <SID>enter_visual_line()<CR>
nnoremap <silent><c-v> :call <SID>enter_visual_block()<CR>
vnoremap <silent>;k :<C-U>set norelativenumber<CR>
vnoremap <silent><Esc> :<C-U>set norelativenumber<CR>
" most common exits from visual mode
vnoremap <silent>y y:<C-U>set norelativenumber<CR>
vnoremap <silent>d d:<C-U>set norelativenumber<CR>
vnoremap <silent>x x:<C-U>set norelativenumber<CR>
"don't clobber register when pasting 
"vnoremap p "xd"pp
vnoremap <C-p> p

nnoremap <leader>I mmI <Esc>r
nnoremap <leader>A mmA <Esc>r

"TODO: make i autotab the way o does
" note: just use S

"navigate the jumplist with + and -
nnoremap + :lnext<CR>
nnoremap - :lprevious<CR>

"ridiculous maps
command! Date read !date -I
command! Sign execute "normal! a4strid (Astrid Ivy)\<CR>"

"text decoration
nnoremap __ yypVr-
nnoremap _= yypVr=
"lol
nnoremap _# yyPVr#I####<Esc>yyjpkI# <Esc>A #<Esc>
"TODO: would be nice if these worked in visual line mode

"Hides search highlighting with CR
"Any subsequent search action will bring the highlighting back
nnoremap <silent><CR> :noh<CR>
"nnoremap <silent><Esc> :noh<CR><Esc>
" -> breaks terminal on mac. i never really hit the escape key anyway

"change indentation all modes preserving cursor location
nnoremap <Tab> mm>>`ml
nnoremap <S-Tab> mm<<`mh
" idk why vnoremap <Tab> doesn't work
vnoremap > >gv
vnoremap < <gv

"line as a text object
onoremap <silent>al :<c-u>normal! 0v$<CR>
onoremap <silent>il :<c-u>normal! 0v$h<CR>
" why do these exist?
vnoremap <silent>al <Esc>0v$
vnoremap <silent>il <Esc>0v$h

"Have K split lines the way J joins lines
nnoremap <expr>K getline('.')[col('.')-1]==' ' ? "r<CR>" : "i<CR><Esc>"

"change move by word functionality to modified sexiness
nnoremap <silent>w :call <SID>JumpToNextWord()<CR>
nnoremap <silent>b :call <SID>JumpToPrevWord()<CR>
"keep normal move by word in place of move by WORD
"(incidentally, I have no idea what a WORD is)
nnoremap W w
nnoremap B b

"have x write to a separate x register (don't overwrite main register)
nnoremap x "xx
nnoremap X "xX

"neocomplete's recommended key maps
inoremap <expr><C-g>     deoplete#undo_completion()
" <CR>: close popup and save indent.
inoremap <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return pumvisible() ? "\<C-y>" : "\<CR>"
endfunction
"inoremap <expr><Tab>  pumvisible() ? "\<C-n>" : deoplete#complete()
inoremap <expr><Tab> Is_whitespace() ? "\<Tab>" : "\<C-n>"
function! Is_whitespace()
  if col('.') == 1
    return 1
  endif
  return strpart(getline('.'), col('.')-2, 1) =~ '\s'
endfunction

" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> deoplete#close_popup()."\<C-h>"
inoremap <expr><BS> deoplete#close_popup()."\<C-h>"

vmap <CR> <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

"prevent accidentally joining lines because the shift key is held
vnoremap J j
vnoremap K k

"easy motion
" TODO: use this more, it's f***ing awesome
nmap <Space> <Plug>(easymotion-prefix)
nmap <Space><Space> <Plug>(easymotion-bd-jk)

" ctrl A behaves as in notepad
nnoremap <C-A> ggVG

"change f and t functionality to be multiline
"(thanks to q335r49 from StackOverflow)
let [pvft,pvftc]=[1,32]
fun! Multift(x,c,i)
    let [g:pvftc,g:pvft]=[a:c,a:i]
    let pos=searchpos((a:x==2? mode(1)=='no'? '\C\V\_.\zs' : '\C\V\_.' : '\C\V').(a:x==1 && mode(1)=='no' || a:x==-2? nr2char(g:pvftc).'\zs' : nr2char(g:pvftc)),a:x<0? 'bW':'W')
    call setpos("'x", pos[0]? [0,pos[0],pos[1],0] : [0,line('.'),col('.'),0])
    return "`x"
endfun
no <expr> F Multift(-1,getchar(),-1)
no <expr> f Multift(1,getchar(),1)
no <expr> T Multift(-2,getchar(),-2)
no <expr> t Multift(2,getchar(),2)

"COLORS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256         "make colors work on xterm
set background=dark  " dark background
colorscheme sorcerer
syntax on
"removes italics from sorcerer theme
hi Comment gui=NONE
hi diffOldFile gui=NONE
hi diffNewFile gui=NONE
hi diffFile gui=NONE
hi diffLine gui=NONE

"set a background color (maybe machine specific? sorcerer specific?)
hi Normal                 cterm=NONE             ctermbg=234  ctermfg=145

"COMMANDS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! Restart mksession! ~/.vim/restart.vim | call VimAndDie()
"command! Restart :mksession! ~/.vim/_restart_.vim | Cmd gvim -S ~/.vim/_restart_.vim
"(better for gvim, add to .local.vimrc if desired)
command! ShowWhitespace :set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:< | :set list
"displays the output of a command inside of vim (for windows)
command! -nargs=+ Cmd :let @r = system(<q-args>) | echo @r
"move to current file's location
command! Here call Here()
command! NoItalics hi Comment gui=NONE | hi diffOldFile gui=NONE | hi diffNewFile gui=NONE | hi diffFile gui=NONE | hi diffLine gui=NONE 

command! Spaces setlocal shiftwidth=2 | setlocal softtabstop=2 | set expandtab
command! Tabs setlocal shiftwidth=2 | setlocal tabstop=2 | set noexpandtab
command! BigTabs setlocal shiftwidth=4 | setlocal tabstop=4 | set noexpandtab

command! FixSpaces %s /\t/  /g
command! FixSpaces4 %s /\t/    /g
command! FixTabs %s /  /\t/g
command! FixTabs4 %s /    /\t/g

"edit something next to the current file
command! -nargs=1 E call SiblingEdit(<f-args>)

"oh you forgot to run vim with sudo did ya?
command! W execute 'silent w !sudo tee "%" > /dev/null' | edit!

function VimAndDie ()
  execute "!vim -S ~/.vim/restart.vim"
  exit
endfunction

function! Here () 
  cd %:p:h
endfunction



function! SiblingEdit (filename)
  execute "edit " . expand("%:h") . "/" . a:filename . "*"
endfunction

"NEOCOMPLETE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
"let g:neocomplete#enable_at_startup = 1
let g:deoplete#enable_at_startup = 1

call deoplete#custom#option({
\'auto_complete': 1,
\'auto_complete_popup': 'automatic',
\})

call deoplete#custom#var('around', {
      \  'range_above': 40,
      \'range_below': 20,
      \'mark_above': '[^]',
      \'mark_below': '[_]',
      \'mark_changes': '[*]',
      \})

call deoplete#custom#var('file', { 'enable_buffer_path': 1, 'enable_slash_completion': 1})

call deoplete#custom#var('omni', 'input_patterns', {
\ 'javascript': '[^. *\t]\.\w*',
\ })
call deoplete#custom#var('omni', 'functions', {
\ 'javascript': ['javascriptcomplete#CompleteJS']
\})

call deoplete#custom#option('sources' , {
      \'_': [],
      \})

set shortmess+=c
set completeopt=menu,longest,preview

" Use smartcase.
"let g:deoplete#enable_smart_case = 1
" Set minimum syntax keyword length.;
"let g:deoplete#sources#syntax#min_keyword_length = 3
"let g:deoplete#lock_buffer_name_pattern = '\*ku\*'
" Define dictionary.
"let g:deoplete#sources#dictionary#dictionaries = {;
    "\ 'default' : '',
    "\ 'vimshell' : $HOME.'/.vimshell_hist',
    "\ 'scheme' : $HOME.'/.gosh_completions'
        "\ }
"" Define keyword.
"if !exists('g:neocomplete#keyword_patterns')
    "let g:deoplete#keyword_patterns = {}
"endif

call deoplete#custom#option('keyword_patterns' , {'default': '\h\w*'})

"let g:deoplete#keyword_patterns['default'] = '\h\w*'
"let g:deoplete#enable_auto_select = 1
" Enable omni completion.
augroup VIMRC_NEOCOMPLETE
  autocmd!
  autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
  autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  "autocmd FileType javascript setlocal omnifunc=tern#Complete
  autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
  autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

  autocmd CompleteDone * pclose
augroup end
" Enable heavy omni completion.
"if !exists('g:neocomplete#sources#omni#input_patterns')
  "let g:neocomplete#sources#omni#input_patterns = {}
"endif

" too slow! 
"if !exists('g:neocomplete#force_omni_input_patterns')
  "let g:neocomplete#force_omni_input_patterns = {}
"endif
"let g:neocomplete#force_omni_input_patterns.javascript = '[^. \t]\.\w*'

"if !exists('g:neocomplete#sources#omni#functions')
  "let g:neocomplete#sources#omni#functions = {}
"endif
"let g:neocomplete#sources#omni#functions.javascript = ['tern#Complete']

" TERN
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" AUTOPAIRS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"TODO: change this based on filetype
let g:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '`':'`'}

" SYNTASTIC
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:syntastic_always_populate_loc_list=1
"let g:syntastic_javascript_checkers = ['jshint']
let g:syntastic_javascript_checkers = ['eslint']

" EASYMOTION
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:EasyMotion_use_upper = 1
let g:EasyMotion_keys = "ABCDEFGHIJKLMNPQRSTUVWXZ12390"

" AIRLINE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set laststatus=2
set noshowmode
let g:airline_theme = 'bubblegum'
let g:airline_symbols_ascii = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline_left_sep=''
let g:airline_right_sep=''

" CAMELCASEMOTION
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call camelcasemotion#CreateMotionMappings('<leader>')

nnoremap <silent>;k :noh<CR>:set norelativenumber<CR>

" only relevant to conemu (add to .local.vimrc if using conemu)
"if (&term == "win32")
	"set termencoding=utf-8
	"set term=xterm
	"set t_Co=256
	"let &t_AB="\e[48;5;%dm"
	"let &t_AF="\e[38;5;%dm"
	"inoremap <Char-0x07F> <BS>
	"nnoremap <Char-0x07F> <BS>
"endif

" GOD YES TERMINAL MODE. I THOUGHT I DIDN'T NEED IT BUT IT IS EVERYTHING I WANT
" change buffers in a terminal
tnoremap <leader>n <C-w>:bn<CR>
tnoremap <leader>p <C-w>:bp<CR>
tnoremap <leader>d <C-w>:bn<CR>:bd! #<CR>
tnoremap <C-w><C-u> <C-w>N<C-u>
tnoremap <C-u> <C-w>N<C-u>
"nnoremap <C-w>;n :bn<CR>
nnoremap <C-w>t :belowright term<CR>
nnoremap <C-w><C-t> :term++curwin<CR>

" ODDS N ENDS
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <expr>q IsThisHelp() ? "<C-w>q" : "q"

function! IsThisHelp ()
  return &filetype == "help"
endfunction

function! Remember ()
  if g:remember_me == 1
    mksession! $HOME/.vim/restore.session
  endif
endfunction

function! AutoCloseEmpty ()
  let lastline = line("$")
  if lastline == 1 && getline(lastline) == "" && expand("%") == ""
    exec "bdelete!"
  endif
endfunction

function! Recall ()
  source $HOME/.vim/restore.session
  let g:remember_me = 1
endfunction

" seems weird to reset the airline theme but after much, much trial and error it's the
" only thing I've found to recover tabline when reloading vimrc
command! Vimrc source $MYVIMRC | AirlineRefresh | redraw | echon "reticulating vimrc..."

if ! exists("g:remember_me")
  let g:remember_me = 0
endif

command! RememberMe let g:remember_me = 1
command! Recall call Recall() | Vimrc

command! StdLayout vert split rightbelow | vert split rightbelow | split belowright | term++curwin

augroup VIMRC_BUFF_STUFF
  autocmd!
  "autocmd BufLeave * call AutoCloseEmpty()
  autocmd ExitPre * bufdo call AutoCloseEmpty()
  autocmd ExitPre * call Remember()

  autocmd TabEnter * Here

  " at least try to keep viminfos in sync between vim instances (:wv and :rv can be used)
  " to trigger it manually
  " this is probably not smart
  "autocmd BufWritePost * rv | wv
  "autocmd BufEnter * rv

  autocmd BufWritePost $MYVIMRC Vimrc
  autocmd BufWritePost ~/.local.vimrc Vimrc
  "autocmd BufWritePost .vimrc Vimrc 
  "autocmd BufWritePost _vimrc Vimrc 

augroup end

"if i wanted help, i'd type :help (Kill F1)
nnoremap [[A <Esc>
lnoremap [[A <Esc>
cnoremap [[A <Esc>
inoremap [[A <Esc>
vnoremap [[A <Esc>

" System Specifics
if filereadable($HOME . "/.local.vimrc")
  so ~/.local.vimrc
endif

"pesky indentLine 
set conceallevel=1

" WHY DOES THIS KEEP TURNING ON
set textwidth=999999

noh

"TODO:
"why is vim so slow in WSL?
"flip flop plugin

"NOTES
"to do diffs do :vert diffsplit <filename>
"close with diffoff!
"dp :diffput, do :diffget (mnemonic 'obtain')
