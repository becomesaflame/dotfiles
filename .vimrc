" Use two spaces instead of tabs
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab

set autoread

set number

" Set updatetime to 500ms
" " This is the time used by CursorHold and CursorHoldI
set updatetime=500

" Save whenever switching windows or leaving vim. This is useful when running
" " the tests inside vim without having to save all files first.
" au FocusLost,WinLeave * :silent! wa

" Trigger autoread when changing buffers or coming back to vim.
au FocusGained,BufEnter,CursorHold,CursorHoldI * :checktime

" set color scheme
colorscheme elflord

" Automatically switch to case sensitive search if you use any capital letters
set smartcase

