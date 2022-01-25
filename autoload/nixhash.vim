function nixhash#run_and_fix(cmd)
  call luaeval('require("nixhash").run_and_fix(_A)', a:cmd)
endfunction
function nixhash#random_hash()
  return luaeval('require("nixhash").random_hash()')
endfunction
