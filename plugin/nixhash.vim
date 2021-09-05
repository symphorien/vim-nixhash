if exists('g:nixhash_loaded')
  finish
endif
let g:nixhash_loaded = 1

command -nargs=1 -complete=shellcmd NixHash :call nixhash#run_and_fix(<q-args>)
