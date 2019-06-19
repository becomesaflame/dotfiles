call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-sensible'

" Make sure you use single quotes
"
" " Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
" Plug 'junegunn/vim-easy-align'
"
" " Any valid git URL is allowed
" Plug 'https://github.com/junegunn/vim-github-dashboard.git'
"
" " Group dependencies, vim-snippets depends on ultisnips
" Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }

" Commenting!
Plug 'scrooloose/nerdcommenter'

" Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
"
" " Using a non-master branch
" Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }
"
" " Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
" Plug 'fatih/vim-go', { 'tag': '*' }
"
" " Plugin options
" Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }
"
" " Plugin outside ~/.vim/plugged with post-update hook
" Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
"
" " Unmanaged plugin (manually installed and updated)
" Plug '~/my-prototype-plugin'

" Add plugins to &runtimepath


" fzf plugin - sublime text style Ctrl+p file open
"
Plug 'junegunn/fzf', { 'tag': '0.12.2', 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim', { 'commit': '4d91156' }

call plug#end()
" ------------------------------------------------------

" NERDTree setup
" close vim if the only window left open is a NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" Toggle NERDTree with Ctrl+n
map <C-n> :NERDTreeToggle<CR>

" fzf settings (Ctrl+p)
map <C-P> :FZF<CR>


" NERD Commenter settings
filetype plugin on
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1

" Add your own custom formats or override the defaults
" let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1



" Use two spaces instead of tabs
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab

" Open new split panes to right and bottom
set splitbelow
set splitright

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

" syntax highlighting for ROS xml files
syntax on
au BufRead,BufNewFile *.launch setfiletype xml
au BufRead,BufNewFile *.machine setfiletype xml

" syntax highlighting for Arduino files
au BufRead,BufNewFile *.ino setfiletype c

" Set syntax highlighting for system verilog
au BufNewFile,BufRead *.sv set filetype=verilog
au BufNewFile,BufRead *.svh set filetype=verilog

" Clear highlighting on escape in normal mode
nnoremap <esc> :noh<return><esc>
nnoremap <esc>^[ <esc>^[

" Handle common capital W typo
map :W :w
map :Wq :wq

" Leader commmands
noremap <leader>w :%s/\s\+$//g<CR> " remove all trailing whitespace from a file
noremap <leader>/ :NERDComToggleComment<CR>

" Automatically change current directory to the opened file
set autochdir

" Source local settings
source ~/.vimrc.local
