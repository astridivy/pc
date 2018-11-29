"2017/May
"TODO
"what the fuck do (  ) do in normal mode? it's completely useless in code
"look into jedi for python?
"project ROOT ofc
"actually use sessions! how?
"have vim automagically create undo / session directories if they don't yet "exist
"customize airline??? ignore trailing whitespace sometimes (notes, .vimrc)
"> maybe if this is a function it'll work?

set nocompatible				"be IMproved!
cd %:p:h						"change working directory to path of open file, if there is one

if has('win32')
	set encoding=utf-8			"makes alt keys work
	set clipboard=unnamed		"makes clipboard work
	set rtp+=$HOME/vimfiles/bundle/Vundle.vim		"setup for Vundle
	let path='$HOME/vimfiles/bundle'				"with Windows paths
elseif has('unix')
	set rtp+=$HOME/.vim/bundle/Vundle.vim			"setup for Vundle
	let path='$HOME/.vim/bundle'					"with Unix paths
endif

"mac is uncomfortable since it's both Unix and Windows-like
if has('osx')
	set encoding=utf-8			"makes alt keys work
	set clipboard=unnamed		"makes clipboard work
end

" PLUGINS
filetype off
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/syntastic'
Plugin 'Shougo/neocomplete.vim'
Plugin 'kien/ctrlp.vim'
Plugin 'flazz/vim-colorschemes'
Plugin 'jiangmiao/auto-pairs'
Plugin 'easymotion/vim-easymotion'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'gavocanov/vim-js-indent'
"Plugin 'helino/vim-json'
"Plugin 'pangloss/vim-javascript'
"Plugin 'SirVer/ultisnips'
Plugin 'michaeljsmith/vim-indent-object'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'junegunn/vim-easy-align'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'hdima/python-syntax'
Plugin 'hynek/vim-python-pep8-indent'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'justinmk/vim-gtfo'
Plugin 'tikhomirov/vim-glsl'
"Plugin 'PProvost/vim-ps1'
Plugin 'alvan/vim-closetag'
Plugin 'tpope/vim-obsession'
Plugin 'itchyny/vim-haskell-indent'
"Plugin 'andy-morris/happy.vim'
"Plugin 'ternjs/tern_for_vim'
Plugin 'bkad/CamelCaseMotion'
" Cool colors
Plugin 'mhinz/vim-janah'
Plugin 'GGalizzi/cake-vim'
Plugin 'bcicen/vim-vice'
Plugin 'mustache/vim-mustache-handlebars'
"Cold fusion
Plugin 'ernstvanderlinden/vim-coldfusion'
Plugin 'cflint/cflint-syntastic'

call vundle#end()

" INITIALIZATION
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !isdirectory($HOME."/.vim/undo/")
    call mkdir($HOME."/.vim/undo", "p")
endif

" SETTINGS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on
set mousehide			" hide mouse while typing
set history=1000		" big history
set number				" line numbers
set showmatch			" match brackets
set incsearch			" incremental search
set hlsearch			" search highlighting
set whichwrap=b,s,h,l,<,>,[,]	" give keys wraparound
set backspace=indent,eol,start	" thank you jesus, normal acting backspace
set nowrap				" who needs it
set tabstop=4			" width of tab character
set shiftwidth=4		" indents have a width of 4
set showtabline=1
set t_RV= ttymouse=xterm2		" fixes weird 2c at startup HACK (shouldn't need it forever)
"set mouse=n 			" only important in macvim?
set ignorecase			" let search be case insensitive
set smartcase			" *unless* it contains a capitalized letter
set hidden				" hide buffers without saving them
"set relativenumber		" interesting, but not performant
set scrolloff=3
set noswapfile
set undofile
set undodir=~/.vim/undo/
set autoread
set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=

"Special for python <3
autocmd FileType python :setlocal softtabstop=4 | :setlocal expandtab
"Special for HTML <3
autocmd FileType html :setlocal shiftwidth=2 | :setlocal tabstop=2
autocmd FileType javascript :setlocal shiftwidth=2 | :setlocal tabstop=2 | :setlocal softtabstop=2 | :setlocal expandtab
"autocmd FileType javascript :setlocal shiftwidth=4 | :setlocal tabstop=4

autocmd FileType haskell :setlocal softtabstop=4 | :setlocal expandtab

"maps the autoinsert semicolon function, appending <CR>'s functionality
"autocmd FileType javascript :execute 'inoremap <CR> ' . maparg('<CR>','i') . "<c-o>:call <SID>CallbackSemicolon()\r"

" close preview window automatically when using annotated code completions
"autocmd CursorMovedI * if pumvisible() == 0|pclose|endif " delete straight away
autocmd InsertLeave * if pumvisible() == 0|pclose|endif " waits until exit
"autocmd CompleteDone * pclose " probably more performant

" ABBREVIATONS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"make help open in tabs instead of windows
cnoreabbrev <expr> help getcmdtype() == ":" && getcmdline() == 'help' ? 'tab help' : 'h'
"common typos

" FUNCTIONS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"when moving by word, skip until alphanumeric word is found
" TODO: apply a count though

function! s:JumpToNextWord()
    normal! w
    while strpart(getline('.'), col('.')-1, 1) !~ '\w'
        normal! w
	endwhile
endfunction

function! s:JumpToPrevWord()
    normal! b
	while strpart(getline('.'), col('.')-1, 1) !~ '\w'
        normal! b
    endwhile
endfunction

" Inserts semicolons at the end of constructs like Callback(function() {})
"function! s:CallbackSemicolon()
"	if strpart(getline('.'), col('.')-1) == '})'
"		execute "normal! A;\<Esc>"
"		execute "normal! O\t\b"
"	endif
"endfunction

function! s:LineEmpty()
	return getline('.') == ''
endfunction

" Switches between unix and windows vimrc's
function! MergeVimrc()
	if has('win32')
		exec '!move /Y .vimrc _vimrc'
		exec '!move /Y .gvimrc _gvimrc'
	elseif has('unix')
		exec '!sed "s/$//" _vimrc > .vimrc'
		exec '!rm -f _vimrc'
		exec '!sed "s/$//" _gvimrc > .gvimrc'
		exec '!rm -f _gvimrc'
	endif
endfunction

" KEY MAPPINGS """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" let mapleader = ';'
let mapleader=';'

"make ;k act as close to <Esc> as possible
set iminsert=1
lnoremap ;k <Esc>
vnoremap ;k <Esc>
nnoremap <silent>;k :noh<CR>:set norelativenumber<CR>
cnoremap ;k <c-e><c-u><Esc>:echo ""<CR>

"convenience commands
if has('win32')
	nnoremap ! :Cmd 
endif " (only need this on windows really)
nnoremap <leader>s :%s /
nnoremap <leader>R :so ./Session.vim<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>q! :q!<CR>
nnoremap <leader>cd :cd %:h<CR>:pwd<CR>

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
nnoremap <leader>d :bp<CR>:bd #<CR>
nnoremap <leader>e :enew<CR>
nnoremap <leader>tt :tabnew<CR>
nnoremap <leader>tn :tabn<CR>
nnoremap <leader>tb :tabp<CR>

"relative line number in visual line and visual block mode

"TODO: loop over all "exit" keys (well, whatever's specified)
"      and map "enter / exit visual mode" on top of original functionality
"      this is gonna get garish, prolly but eh

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
vnoremap <silent>;k :<BS><BS><BS><BS><BS>set norelativenumber<CR>
vnoremap <silent><Esc> :<BS><BS><BS><BS><BS>set norelativenumber<CR>

"ridiculous maps
" TODO: add "insert date"
nnoremap ;fn i = function<Esc>

"insert single character without leaving normal mode
nnoremap <leader>i i <Esc>r
nnoremap <leader>a a <Esc>r
nnoremap <leader>I mmI <Esc>r
nnoremap <leader>A mmA <Esc>r

"TODO: make i autotab the way o does
" note: just use S

"toggle semicolon at the end of a line;
nnoremap <expr><leader>; <SID>trailing_semicolon() ? 'mm$"_x`m' : "mmA;\<Esc>`m"
function! s:trailing_semicolon()
	let l:line = getline('.')
	return strpart(l:line, strlen(l:line) - 1) == ';'
endfunction

"navigate the jumplist with + and -
nnoremap + :lnext<CR>
nnoremap - :lprevious<CR>

"Hides search highlighting with CR
"Any subsequent search action will bring the highlighting back
nnoremap <silent><CR> :noh<CR>
"nnoremap <silent><Esc> :noh<CR><Esc>
" -> breaks terminal on mac. i never really hit the escape key anyway

"insert empty lines without changing modes
nnoremap <a-o> o<Esc>
nnoremap <a-O> O<Esc>
inoremap <a-o> <Esc>o
inoremap <a-O> <Esc>O
vnoremap <a-o> <Esc>'>o<Esc>gv
vnoremap <a-O> <Esc>'<O<Esc>gv

"change indentation all modes preserving cursor location
nnoremap <Tab> mm>>`ml
nnoremap <S-Tab> mm<<`mh
inoremap <C-Tab> <Esc>>>gi<Right>
inoremap <S-Tab> <Esc><<gi<Left>
" idk why vnoremap <Tab> doesn't work
vnoremap > >gv
vnoremap < <gv

"line as a text object
onoremap <silent>al :<c-u>normal! 0v$<CR>
onoremap <silent>il :<c-u>normal! 0v$h<CR>
vnoremap <silent>al <Esc>0v$
vnoremap <silent>il <Esc>0v$h

"Have K split lines the way J joins lines
nnoremap <expr>K getline('.')[col('.')-1]==' ' ? "r<CR>" : "i<CR><Esc>"

"change move by word functionality to modified sexiness
nnoremap <silent>w :call <SID>JumpToNextWord()<CR>
nnoremap <silent>b :call <SID>JumpToPrevWord()<CR>
"keep normal move by word in place of move by WORD
nnoremap W w
nnoremap B b

"have x write to a separate x register
nnoremap x "xx
nnoremap X "xX

"neocomplete's recommended key maps
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()
" <CR>: close popup and save indent.
inoremap <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
	return pumvisible() ? "\<C-y>" : "\<CR>"
endfunction
" <TAB>: next option (ok so, tab's actually taken so we use ` instead)
" was it ultisnips that ate tab? let's switch it back for now
inoremap <expr><Tab>  pumvisible() ? "\<C-n>" : "<Tab>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"

vmap <CR> <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

"prevent accidentally joining lines because the shift key is held
vnoremap J j
vnoremap K k

"easy motion
nmap <Space> <Plug>(easymotion-prefix)
nmap <Space><Space> <Plug>(easymotion-bd-jk)

" ctrl A behaves as expected
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

nnoremap <C-N> :NERDTreeToggle<CR>

"COLORS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256				"make colors work on xterm
set background=dark			" dark background
colorscheme sorcerer
syntax on
"removes italics from sorcerer theme
hi Comment gui=NONE
hi diffOldFile gui=NONE
hi diffNewFile gui=NONE
hi diffFile gui=NONE
hi diffLine gui=NONE

"COMMANDS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command Restart :mksession! ~/_restart_.vim | Cmd gvim -S ~/_restart_.vim
command ShowWhitespace :set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:< | :set list
command MergeVimrc :call MergeVimrc()
"displays the output of a command inside of vim (for windows)
command -nargs=+ Cmd :let @r = system(<q-args>) | echo @r
"move to current file's location
command Here cd %:p:h
command Root :call GoToRoot()
command NoItalics hi Comment gui=NONE | hi diffOldFile gui=NONE | hi diffNewFile gui=NONE | hi diffFile gui=NONE | hi diffLine gui=NONE 

"NEOCOMPLETE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.;
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'
" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
        \ }
" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'
let g:neocomplete#enable_auto_select = 1
" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
"autocmd FileType javascript setlocal omnifunc=tern#Complete
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif


" too slow! 
"if !exists('g:neocomplete#force_omni_input_patterns')
  "let g:neocomplete#force_omni_input_patterns = {}
"endif
"let g:neocomplete#force_omni_input_patterns.javascript = '[^. \t]\.\w*'

"if !exists('g:neocomplete#sources#omni#functions')
  "let g:neocomplete#sources#omni#functions = {}
"endif
"let g:neocomplete#sources#omni#functions.javascript = ['tern#Complete']

autocmd CompleteDone * pclose

" TERN
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" AUTOPAIRS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '#':'#', '`':'`'} "take out backticks

" SYNTASTIC
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:syntastic_always_populate_loc_list=1
"let g:syntastic_javascript_checkers = ['jshint']
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_cf_checkers=['cflint']
let g:syntastic_cfml_checkers=['cflint']

" EASYMOTION
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:EasyMotion_use_upper = 1
let g:EasyMotion_keys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

" AIRLINE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set laststatus=2
set noshowmode
let g:airline_theme = 'bubblegum'
let g:airline#extensions#tabline#enabled = 1
let g:airline_left_sep=''
let g:airline_right_sep=''

" CAMELCASEMOTION
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call camelcasemotion#CreateMotionMappings('<leader>')

" cool ideas:
" make VIM into a notes program
" flip flop plugin
" less shitty underscore navigation
" move swap / undo directories

" get length of previous line
command TEST :let AYY = getline(line('.') - 1) | :echo AYY| :echo "length:" . strlen(AYY)

nnoremap <silent>;k :noh<CR>:set norelativenumber<CR>

if (&term == "win32")
	set termencoding=utf8
	set term=xterm
	set t_Co=256
	let &t_AB="\e[48;5;%dm"
	let &t_AF="\e[38;5;%dm"
	inoremap <Char-0x07F> <BS>
	nnoremap <Char-0x07F> <BS>
endif

" System Specifics
if filereadable($HOME."/.local.vimrc")
	so ~/.local.vimrc
endif

"set a background color
hi Normal                 cterm=NONE             ctermbg=234  ctermfg=145

"to do diffs do :vert diffsplit <filename>
"close with diffoff!
"dp :diffput, do :diffget (obtain)
