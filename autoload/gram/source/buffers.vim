scriptversion 4

let s:source = {}
function! s:source.gather_candidates(Callbacks) abort
  let bufs = split(execute('ls'), "\n")
  let items = []
  for buf in bufs
    let bufnr = str2nr(matchstr(buf, '^\s*\zs\d\+\ze'))
    call add(items, #{word: buf, action_bufnr: bufnr})
  endfor

  call a:Callbacks.clear()
  call a:Callbacks.add(items)
endfunction

function! gram#source#buffers#register() abort
  call gram#source#register('buffers', s:source)
endfunction
