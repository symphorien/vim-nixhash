if exists("g:nixhash_disable_bindings")
  finish
endif
" Only do this when not done yet for this buffer
if exists("b:did_nixhash_ftplugin")
  finish
endif
let b:did_nixhash_ftplugin = 1

nnoremap <buffer> <expr> <M-h> "i".nixhash#random_hash()."<esc>"
inoremap <buffer> <expr> <M-h> nixhash#random_hash()
