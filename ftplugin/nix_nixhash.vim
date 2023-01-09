" Only do this when not done yet for this buffer
if exists("b:did_nixhash_ftplugin")
  finish
endif
let b:did_nixhash_ftplugin = 1

" plug bindings
nnoremap <buffer> <expr> <Plug>nixhash_random_base32_hash "i".nixhash#random_base32_hash()."<esc>"
inoremap <buffer> <expr> <Plug>nixhash_random_base32_hash nixhash#random_base32_hash()
nnoremap <buffer> <expr> <Plug>nixhash_random_sri_hash "i".nixhash#random_sri_hash()."<esc>"
inoremap <buffer> <expr> <Plug>nixhash_random_sri_hash nixhash#random_sri_hash()

" if not disabled, default bindings for the above
if exists("g:nixhash_disable_bindings")
  finish
endif

nmap <buffer> <M-h> <plug>nixhash_random_base32_hash
imap <buffer> <M-h> <plug>nixhash_random_base32_hash
nmap <buffer> <M-s> <plug>nixhash_random_sri_hash
imap <buffer> <M-s> <plug>nixhash_random_sri_hash
