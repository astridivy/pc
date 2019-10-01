" grab the command name
execute "normal! \"cdd"
" grab the tagline
execute "normal! \"tdd"
" grab the usage info (some day)
"execute "normal! \"ud$dd"

" switch to the real file
execute "cd ~/bin"
execute "edit! " . @c
" print the shebang
execute "normal! i#!/bin/bash\<CR>#\<CR># "

" print the command name
execute "normal! \"cp"
execute "normal! kJ"

" print the tagline (maybe)
if (strlen(@t) > 1)
  execute "normal! o#\<CR># "
  execute "normal! \"tp"
  execute "normal! kJ"
endif

" print usage info (some day)
" TODO automatically write out a getopts skeleton whose -h opt prints the tagline and/or usage
"if (strlen(@u) > 1)
"  execute "normal! o#\<CR># "
"  execute "normal! \"up"
"endif

" print author
execute "normal! o#\<CR># "
if filereadable("~/.whoami")
  execute "read ~/.whoami"
else
  execute "read !whoami"
endif
execute "normal! kJ"

"print date
execute "normal! o# "
execute "read !date -I"
execute "normal! kJ"

" done
execute "normal! o\<CR>\<ESC>"
