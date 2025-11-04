set nocompatible " be iMproved, required
filetype off " required

autocmd filetype crontab setlocal nobackup nowritebackup

if has('nvim')
  function! DoRemote(arg)
    UpdateRemotePlugins
  endfunction
endif

"call plug#begin('~/.vim/plugged')

function! BuildYCM(info)
  " info is a dictionary with 3 fields
  " - name:   name of the plugin
  " - status: 'installed', 'updated', or 'unchanged'
  " - force:  set on PlugInstall! or PlugUpdate!
  if a:info.status == 'installed' || a:info.force
    !./install.py
  endif
endfunction
"Plug 'zhou13/vim-easyescape'
"Plug 'vim-scripts/ingo-library'
"Plug 'vim-scripts/gtags.vim'
"Plug 'ctrlpvim/ctrlp.vim'
"Plug 'scrooloose/nerdtree'
""Plug 'francoiscabrol/ranger.vim'
""Plug 'Valloric/YouCompleteMe', { 'do': function('BuildYCM') }
"
"Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }

if has('nvim')
  "Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  "Plug 'Shougo/deoplete.nvim'
  "Plug 'roxma/nvim-yarp'
  "Plug 'roxma/vim-hug-neovim-rpc'
endif

"Plug 'Shougo/vimproc.vim', {'do': 'make'}

"Plug 'MattesGroeger/vim-bookmarks'

" Syntax checker
"Plug 'benekastah/neomake'

"Plug 'Chiel92/vim-autoformat'

"" Color scheme
"Plug 'mhartington/oceanic-next'

""***** Languages *****
""Plug 'sebastianmarkow/deoplete-rust'
"Plug 'rust-lang/rust.vim'
"Plug 'prabirshrestha/async.vim'
"Plug 'prabirshrestha/vim-lsp'
"Plug 'prabirshrestha/asyncomplete.vim'
"Plug 'prabirshrestha/asyncomplete-lsp.vim'


"" vim-go
"Plug 'fatih/vim-go'
"Plug 'nsf/gocode', {'rtp': 'vim/'}	" Go autocomplete daemon

"" HTML
"Plug 'othree/html5.vim'

"Plug 'artur-shaik/vim-javacomplete2', { 'for': 'java' }

"Plug 'Shougo/echodoc.vim'                                   " Show messages in echo area

"Plug 'mbbill/undotree'         " Show history

"Plug 'tpope/vim-vinegar'

"Plug 'rust-lang/rust.vim'      " Rust highlighting and other stuff
"Plug 'racer-rust/vim-racer'    " Rust autocomplete

"Plug 'plasticboy/vim-markdown' " Markdown mode

"Plug 'fidian/hexmode'          " Binary files

"" Utilities
"Plug 'AndrewRadev/splitjoin.vim'
"Plug 'tpope/vim-commentary'
"Plug 'tpope/vim-surround'
"Plug 'tpope/vim-sleuth'         " Detect tabwidth from file
"Plug 'jremmen/vim-ripgrep'
"Plug 'airblade/vim-rooter'      " Automatically set project root
"Plug 'osyo-manga/vim-over'      " Substitution preview
"Plug 'scrooloose/nerdcommenter' " Commenting crap
"Plug 'godlygeek/tabular'        " Align things at their equal sign
"Plug 'vim-scripts/Smart-Tabs'   " Smart tabs
"Plug 'jceb/vim-orgmode'         " Orgmode
"Plug 'vim-scripts/utl.vim'      " Universal text linking
"Plug 'vim-scripts/repeat.vim'   " Repeat actions
"Plug 'chrisbra/NrrwRgn'         " Narrow regions
"Plug 'tpope/vim-speeddating'    " Increment/decrement dates
"Plug 'vim-scripts/SyntaxRange'  " Change the syntax for a range
"Plug 'Konfekt/FastFold'         " Speeds up folding
"Plug 'editorconfig/editorconfig-vim' " Editorconfig support

"Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
"Plug 'junegunn/fzf.vim'

"Plug 'tpope/vim-fugitive'
"Plug 'xolox/vim-misc'			" Required for easytags
""Plug 'xolox/vim-easytags' " ctags integration
"Plug 'easymotion/vim-easymotion'
"Plug 'ap/vim-css-color'

" Interface
"Plug 'vim-airline/vim-airline'
"Plug 'vim-airline/vim-airline-themes'
"Plug 'rbgrouleff/bclose.vim'
"Plug 'spf13/vim-autoclose'
"Plug 'airblade/vim-gitgutter'
"Plug 'ntpeters/vim-better-whitespace'
"Plug 'mhinz/vim-startify'  " Start screen
"Plug 'junegunn/goyo.vim'	 " Distraction-free writing
"Plug 'Yggdroot/indentLine' " Indent indicators and lines
"Plug 'vim-scripts/restore_view.vim' " Save/restore views

"call plug#end()						 " required

"" ===== General settings ====
set conceallevel=1

" Folding
"set foldenable
"set foldlevelstart=20		" open most folds by default
"set foldnestmax=10			" 10 nested fold max

"" f open/closes folds
nnoremap f za
""set foldmethod=syntax

" Move around "visual" lines instead of actual lines
nnoremap j gj
nnoremap k gk

let g:easyescape_chars = { "j": 1, "k": 1 }
let g:easyescape_timeout = 100
cnoremap jk <ESC>
cnoremap kj <ESC>

set hidden " Allow having multiple dirty buffers

"set termencoding=utf-8
set autoindent	" Indent based off the last line
set smartindent

set ruler " Show the line number and column

"set textwidth=80 " Maximum width of text that is being inserted. A longer
		 "" line will be broken after white space to get this width.

set formatoptions=c,q,r,t " This is a sequence of letters which describes how
			  "" automatic formatting is to be done.
			  ""
			  "" letter		meaning when present in 'formatoptions'
			  "" ------		---------------------------------------
			  "" c					Auto-wrap comments using textwidth, inserting
			  "" the current comment leader automatically.
			  "" q					Allow formatting of comments with               " gq " .
			  "" r					Automatically insert the current comment leader
			  "" after hitting <Enter> in Insert mode.
			  "" t					Auto-wrap text using textwidth (does not apply
			  "" to comments)<Paste>

"set showmatch " Jump to matching bracket when one is inserted

set hlsearch	" When there is a previous search pattern highlight all of its
		"" matches

set incsearch	" Show matches while typing

set ignorecase	" Ignore case when searching

set smartcase	" Override ignorecase if an uppercase char is in the search

" Misc

" Load .vimrc files in the current dir
set exrc

" Show the line number
set number
set mouse=a

" Set backspace stuff
set backspace=indent,eol,start
set clipboard=unnamed " make clipboard work

" Show completion suggestions for commands
set wildmenu
set wildchar=<Tab>
set wildmode=list:longest,full

" Tab config
filetype plugin indent on
set smarttab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

set scrolloff=3                     " always keep cursor centered
set shiftround                        " always indent by multiple of shiftwidth

set shortmess+=A                      " ignore annoying swapfile messages
set shortmess+=I                      " no splash screen
set shortmess+=O                      " file-read message overwrites previous
set shortmess+=T                      " truncate non-file messages in middle
set shortmess+=W                      " don't echo "[w]"/"[written]" when writing
set shortmess+=a                      " use abbreviations in messages eg. `[RO]` instead of `[readonly]`
set shortmess+=o                      " overwrite file-written messages
set shortmess+=t                      " truncate file messages at start

if has('linebreak')
  let &showbreak='⤷ '                 " ARROW POINTING DOWNWARDS THEN CURVING RIGHTWARDS (U+2937, UTF-8: E2 A4 B7)
endif

if v:progname !=# 'vi'
  set softtabstop=-1                  " use 'shiftwidth' for tab/bs at end of line
endif

if has('windows')
  set splitbelow                      " open horizontal splits below current window
endif

if has('vertsplit')
  set splitright                      " open vertical splits to the right of the current window
endif

" Show the X-char color column in all files
"if exists('+colorcolumn')
 """ Highlight up to 255 columns (this is the current Vim max) beyond 'textwidth'
 ""let &l:colorcolumn='+' . join(range(0, 254), ',+')
"endif
" highlight ColorColumn ctermbg=lightgrey guibg=lightgrey
" set colorcolumn=80

" Show the colorcolumn when editing a git commit
au FileType gitcommit set tw=72 |  set colorcolumn=50

" Enable spellcheck
"setlocal spell spelllang=en_us

"" ======== UI Config =========
" Color scheme
let base16colorspace=256	" Access colors present in 256 colorspace
set background=dark
"colorscheme OceanicNext

" Enable truecolor support
set termguicolors

set colorcolumn=100

if has('nvim')
  " Enable pipe cursor when in insert mode
  let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
endif

"" Highlight current line number
"hi CursorLineNr term=bold ctermfg=Yellow gui=bold guifg=Yellow

let g:terminal_color_0  = '#2b303b'
let g:terminal_color_1  = '#bf616a'
let g:terminal_color_2  = '#a3be8c'
let g:terminal_color_3  = '#ebcb8b'
let g:terminal_color_4  = '#8fa1b3'
let g:terminal_color_5  = '#b48ead'
let g:terminal_color_6  = '#96b5b4'
let g:terminal_color_7  = '#c0c5ce'
let g:terminal_color_8  = '#65737e'
let g:terminal_color_9  = '#2b303b'
let g:terminal_color_10 = '#bf616a'
let g:terminal_color_11 = '#a3be8c'
let g:terminal_color_12 = '#ebcb8b'
let g:terminal_color_13 = '#8fa1b3'
let g:terminal_color_14 = '#b48ead'
let g:terminal_color_15 = '#eff1f5'
let g:terminal_color_16 = '#d08770'
let g:terminal_color_17 = '#ab7967'
let g:terminal_color_18 = '#343d46'
let g:terminal_color_19 = '#4f5b66'
let g:terminal_color_20 = '#a7adba'
let g:terminal_color_21 = '#dfe1e8'

" Airline
set laststatus=2
let g:airline_powerline_fonts = 1
let g:airline_theme = "base16_ocean"
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tagbar#flags = 'f'
let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline_left_alt_sep=''
let g:airline_right_alt_sep=''

" View saving
set viewoptions=cursor,folds,slash,unix

" Indent indicators
"set list                              " show whitespace
"set listchars=nbsp:⦸                  " CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
"set listchars+=tab:\ \                   " WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7)
                                     """ + BOX DRAWINGS HEAVY TRIPLE DASH HORIZONTAL (U+2505, UTF-8: E2 94 85)
"set listchars+=extends:»              " RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
"set listchars+=precedes:«             " LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
"set listchars+=trail:•                " BULLET (U+2022, UTF-8: E2 80 A2)
let g:indentLine_char = '│'
let g:indentLine_enabled=1
let g:indentLine_leadingSpaceEnabled=1
let g:indentLine_leadingSpaceChar='·'
let g:indentLine_concealcursor = 'niv' " (default 'inc')
let g:indentLine_conceallevel = 2  " (default 2)
let g:indentLine_color_term = 239

"" ========= Utility Config ===========
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd BufWritePre * StripWhitespace
map <C-n> :NERDTreeToggle<CR>
map <leader>k :NERDTreeFind<CR>

"let g:ranger_replace_netrw = 1 " open ranger when vim open a directory

let g:indentLine_fileTypeExclude = ['nerdtree']
autocmd FileType help,nerdtree IndentLinesToggle

" === Key bindings ===

" From http://ddrscott.github.io/blog/2016/vim-toggle-movement/
function! ToggleMovement(firstOp, thenOp)
  let pos = getpos('.')
  execute "normal! " . a:firstOp
  if pos == getpos('.')
    execute "normal! " . a:thenOp
  endif
endfunction


" For buffer switching
map <leader>n :bn<cr>
map <leader>p :bp<cr>
map <leader>d :bd<cr>

" Ranger bindings
map <leader>rr :RangerCurrentDirectory<cr>

" The original carat 0 swap
nnoremap <silent> 0 :call ToggleMovement('^', '0')<CR>

" How about ; and ,
nnoremap <silent> ; :call ToggleMovement(';', ',')<CR>
nnoremap <silent> , :call ToggleMovement(',', ';')<CR>

" How about H and L
nnoremap <silent> H :call ToggleMovement('H', 'L')<CR>
nnoremap <silent> L :call ToggleMovement('L', 'H')<CR>

" How about G and gg
nnoremap <silent> G :call ToggleMovement('G', 'gg')<CR>
nnoremap <silent> gg :call ToggleMovement('gg', 'G')<CR>

" Press shift-enter to add a new line without moving cursor
inoremap <silent> <s-cr> <esc>m`o<esc>``a

" Disable search highlighting when backspace is pressed
nmap <silent> <BS>	:nohlsearch<CR>

" Remap leader to <SPC>
let mapleader=','

if has('nvim')
  " Map ,e to go out of term mode to normal mode
  tnoremap <ESC> <C-\><C-n>
endif

" <Ctrl-l> redraws the screen and removes any search highlighting.
nnoremap <silent> <C-l> :nohl<CR><C-l>

" Tabular config
if exists(":Tabularize")
  nnoremap <Leader>t= :Tabularize /=<CR>

  nnoremap <Leader>t: :Tabularize /:<CR>
endif

" Undotree
nnoremap <Leader>ut :UndotreeToggle<cr>

" AutoFormat
noremap <Leader>af :Autoformat<CR>

" Move text blocks up and down
"nnoremap <A-j> :m .+1<CR>==
"nnoremap <A-k> :m .-2<CR>==
"inoremap <A-j> <Esc>:m .+1<CR>==gi
"inoremap <A-k> <Esc>:m .-2<CR>==gi
"vnoremap <A-j> :m '>+1<CR>gv=gv
"noremap <A-k> :m '<-2<CR>gv=gv


" === Utility configuration ===

" Enable matchit
runtime macros/matchit.vim

" Autoclose
let g:autoclose_vim_commentmode = 1

" Orgmode
let g:org_export_emacs="~/bin/emacs"

" Markdown
let g:vim_markdown_conceal=0

" Rust
let g:rustfmt_autosave = 1
let g:racer_experimental_completer = 1
"autocmd User asyncomplete_setup call asyncomplete#register_source(
"    \ asyncomplete#sources#racer#get_source_options())
if executable('rls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'nightly', 'rls']},
        \ 'whitelist': ['rust'],
        \ })
endif

"au FileType rust nmap gd <Plug>(rust-def)
"au FileType rust nmap gs <Plug>(rust-def-split)
"au FileType rust nmap gx <Plug>(rust-def-vertical)
"au FileType rust nmap <leader>gd <Plug>(rust-doc)

" fzf
nnoremap <silent> <leader>p :FZF<CR>
nnoremap <silent> <leader>p :Files<CR>
nnoremap <silent> <leader>bb :Buffers<CR>
nnoremap <silent> <leader>fr :History<CR>
nnoremap <silent> <leader>t :Tags<CR>
nnoremap <silent> <leader>l :Lines<CR>
nnoremap <silent> <leader>pc :Commits<CR>
nnoremap <silent> <leader>gc :BCommits<CR>
command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>), 1, <bang>0)

" Echodoc
set noshowmode
let g:echodoc_enable_at_startup=1

" YouCompleteMe (YCM)
let g:ycm_global_ycm_extra_conf = '~/.vim/plugged/YouCompleteMe/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py'

" Deoplete
" neocomplete like
" https://github.com/Shougo/deoplete.nvim/blob/master/doc/deoplete.txt
"set completeopt+=noinsert
"set completeopt+=noselect
"set completeopt-=preview
let g:deoplete#enable_at_startup = 1
" disable autocomplete by default
"let b:deoplete_disable_auto_complete=1
"let g:deoplete_disable_auto_complete=1

"call deoplete#custom#source('LanguageClient',
"            \ 'min_pattern_length',
"            \ 2)

if !exists('g:deoplete#omni#input_patterns')
    let g:deoplete#omni#input_patterns = {}
endif

" Disable the candidates in Comment/String syntaxes.
"call deoplete#custom#source('_',
"            \ 'disabled_syntaxes', ['Comment', 'String'])

autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

"call deoplete#custom#option('sources', {
"    \ 'python': ['LanguageClient'],
"    \ 'rust': ['LanguageClient'],
"\})


set isfname-==

" Autoformat configs
let g:formatdef_dfmt = '"dfmt --brace_style=otbs"'
let g:formatters_d = ['dfmt']
let g:formatdef_rustfmt = 'rustfmt'
let g:formatters_rs = ['rustfmt']

" Autochdir
" set vim to chdir for each file
if exists('+autochdir')
   set autochdir
else
   autocmd BufEnter * silent! lcd %:p:h:gs/ /\\ /
endif

" Go
let g:go_fmt_command = "goimports"

" Neomake
set statusline+=%#warningmsg#
set statusline+=%*
let g:neomake_always_populate_loc_list = 1
let g:neomake_auto_loc_list = 0
let g:neomake_check_on_open = 1
" autocmd! BufWritePost * Neomake
let g:neomake_check_on_wq = 0
let g:neomake_mode_map = { 'passive_filetypes': ['d'] }
let g:neomake_html_tidy_exec = '/usr/local/bin/tidy -config ~/.config/tidy/tidy.conf' " Override for HTML5 tidy
let g:neomake_html_tidy_blocklevel_tags = ['nav']

" ====== Other Vim config ======
" Automatically highlight symbol under cursor
function! s:highlight_symbol()
  augroup HighlightSymbol
    autocmd HighlightSymbol CursorMoved * exe printf('match IncSearch /\V\<%s\>/', escape(expand('<cword>'), '/\'))
  augroup END
endfunction

function! s:unhighlight_symbol()
  autocmd! HighlightSymbol CursorMoved
  let @/ = ""
  match IncSearch //
endfunction

command! -bar HighlightSymbol call s:highlight_symbol()
command! -bar UnhighlightSymbol call s:unhighlight_symbol()

" Performance improving things
set lazyredraw

if has('gui_running')
  set guifont=Hack:h11
  set guicolors
endif

if has('pythonx')
  set pyxversion=3
endif

" language server commands
let g:LanguageClient_autoStart = 1
let g:LanguageClient_serverCommands = {
            \ 'cpp': ['cquery'],
            \ 'c': ['cquery'],
            \ 'rust': ['rustup', 'run', 'nightly', 'rls'],
\ }
"set completefunc=LanguageClient#complete
set formatexpr=LanguageClient_textDocument_rangeFormatting()
inoremap <expr><Tab> (pumvisible()?(empty(v:completed_item)?"\<C-n>":"\<C-y>"):"\<Tab>")
inoremap <expr><CR> (pumvisible()?(empty(v:completed_item)?"\<CR>\<CR>":"\<C-y>"):"\<CR>")
