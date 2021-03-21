packadd vim-c64jasm
set makeprg=make\ %<.prg
noremap <F6> :wa<CR>:silent! make <bar> cwindow<CR>:redraw!<CR>
noremap <S-F6> :wa<CR>:silent! make clean %<.prg <bar> vertical botright copen 80<CR>:redraw!<CR>
noremap <F7> :wa<CR>:make %<.debug<bar> cwindow<CR>:redraw!<CR>
noremap <F8> :wa<CR>:make %<.exe.prg<bar> cwindow<CR>:redraw!<CR>
noremap <F9> O!break<ESC>
set autoindent
set shiftwidth=2
set tabstop=2
set softtabstop=2
set smartindent
set expandtab
set foldmethod=marker
set foldlevel=0
set foldcolumn=3
set autochdir
au BufNewFile,BufRead *.asm set ft=c64jasm
au BufNewFile,BufRead *.asm setlocal foldmarker={,}
au FileType asm set commentstring=;%s
au FileType asm set errorformat=%f:%l:%c:\ %m
au FileType asm set foldmethod=marker
