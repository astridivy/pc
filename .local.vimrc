"colorscheme Chasing_Logic
"colorscheme lilydjwg_dark
colorscheme Tomorrow-Night-Nineties

inoremap <c-u> <esc>u
nnoremap n j
vnoremap n j
nnoremap <c-n> n

nnoremap ik k
nnoremap ki k

vnoremap x "xygvx
nnoremap yy "yyyyy
vnoremap y "yygvy
nnoremap Y "zYY
vnoremap Y "zYY

augroup visual_cleanup
  autocmd!
  autocmd ModeChanged *:[ni] call s:VisualLeave()
augroup END

function! s:VisualLeave()
  set norelativenumber
endfunction

nnoremap <silent> V :set relativenumber<CR>:noh<CR>V


" transparent bg
hi Normal guibg=NONE ctermbg=none

"doctor colorscheme a bit
hi Comment ctermfg=8
hi Visual ctermbg=lightcyan ctermfg=0
hi Number ctermfg=yellow
hi Conceal ctermfg=8 ctermbg=0
hi String ctermfg=darkgreen
hi Constant ctermfg=gray
hi Special ctermfg=5
hi Todo ctermfg=5

hi Label ctermfg=5

hi javaScriptNumber ctermfg=3
hi javaScriptBraces ctermfg=5
hi javaScriptNull ctermfg=12
hi javaScriptBoolean ctermfg=12
hi javaScriptStatement ctermfg=10
hi javaScriptConditional ctermfg=1
hi javaScriptLogicSymbols ctermfg=80
hi javaScriptSource ctermfg=1
hi javaScriptRepeat ctermfg=1
hi javaScriptExceptions ctermfg=150
hi javaScriptRegExp ctermfg=150
hi javaScriptRegExpstring ctermfg=150
hi javaScriptFuncExp ctermfg=15
hi javaScriptBranch ctermfg=1
hi javaScriptCommentTodo ctermfg=5

"hmm this is hacky but we'll unify them someday
if (&term == "xterm")
  hi javaScriptExceptions ctermfg=3
  hi javaScriptRegExp ctermfg=3
  hi javaScriptRegExpstring ctermfg=3
  hi Number ctermfg=209
  hi javaScriptNumber ctermfg=209
endif


hi ErrorMsg ctermbg=black ctermfg=red
hi WarningMsg ctermbg=black ctermfg=lightred
