"colorscheme Chasing_Logic
"colorscheme lilydjwg_dark
colorscheme Tomorrow-Night-Nineties

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
