autocmd FileType cf nnoremap <c-f> i<cfmail from="noreply@simpleviewinc.com" to="redacted@debug.com" subject="debug" type="html"><return></cfmail><esc>
autocmd FileType cf nnoremap <c-n> i<cfdump format="text" var="##"><esc>F#

" for these massive 3000 line CF files it's pretty slow
set redrawtime=6666

" (F1 Key) If I needed help, I'd use :h
nnoremap OP <Esc>

" crude way to test if we are in WSL
if (filereadable('/etc/wsl.conf'))
  "idk how to do motion mappings and do not have time to look it up
  "so to copy you must first use visual mode to select. sorry not sorry.
  "so we can still use registers, you must specify the * register to use
  "windows clipboard 
  "
  "another limitation is apparently we can only work on lines. look it's not
  "perfect but I really can't spend any more time on this
  "vnoremap "*y :<c-u>silent '<,'>write !win32yank.exe -i<CR>'<
  "vnoremap <expr>"*p mode()==#'v' ? "myxh:silent read !win32yank.exe -o<CR>`y" : "myxk:silent read !win32yank.exe -o<CR>'y"
  "vnoremap "*p myxk:silent read !win32yank.exe -o<CR>`y
  "nnoremap "*p :silent read !win32yank.exe -o<CR>
  "
  "i learned about `system` today! that solves all our problems
  vnoremap y y:WinYank<CR>
  vnoremap d d:WinYank<CR>
  vnoremap x d:WinYank<CR>
  "intentionally do not put these in the windows clipboard bc honestly
  "that's rarely what we want
  vnoremap p :<C-u>WinPut<CR>gvp
  vnoremap P :<C-u>WinPut<CR>gvP
  "ezz
  nnoremap yy yy:WinYank<CR>
  nnoremap dd dd:WinYank<CR>
  nnoremap d$ d$:WinYank<CR>
  nmap dil dil:WinYank<CR>
  nmap daw daw:WinYank<CR>
  nnoremap p :WinPut<CR>p
  nnoremap P :WinPut<CR>P

  "it's not going to work well with <C-r> so add maps to manually feed
  "the register
  nnoremap "*y :WinYank<CR>
  nnoremap "*p :WinPut<CR>

  command WinYank let res = system("win32yank.exe -i", @")|echo res
  command WinPut let @" = system("win32yank.exe -o --lf")

  command! -nargs=* E call FASD_V(<f-args>)
  function! FASD_V (...)
	let cmd = 'fasd -f -e printf'
	for arg in a:000
	  let cmd = cmd . ' ' . arg
	endfor
	let path = system(cmd)
	if filereadable(path)
	  echo path
	  exec 'edit' fnameescape(path)
	  call Here()
	else
	  echo "sorry, but no"
	endif
  endfunction

  command! -nargs=* Z call FASD_Z(<f-args>)
  function! FASD_Z (...)
	let cmd = 'fasd -d -e printf'
	for arg in a:000
	  let cmd = cmd . ' ' . arg
	endfor
	let path = system(cmd)
	if filereadable(path)
	  echo path
	  exec 'cd' fnameescape(path)
	else
	  echo "sorry, but no"
	endif
  endfunction
endif

" no more cfsets without ending >
" hopefully this is not annoying
inoremap fset fset><Esc>i

" WHY DOES THIS KEEP TURNING ON
set textwidth=999999
