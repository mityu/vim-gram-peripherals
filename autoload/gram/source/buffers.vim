scriptversion 4

let s:source = {}
function! s:source.gather_candidates(Callbacks) abort
  " TODO: Exclude terminal buffers
  let bufs = split(execute('ls'), "\n")
  let items = []
  for buf in bufs
    let bufnr = str2nr(matchstr(buf, '^\s*\zs\d\+\ze'))
    call add(items, #{word: buf, action_bufnr: bufnr})
  endfor

  call a:Callbacks.clear()
  call a:Callbacks.add(items)
endfunction

function! s:source.on_request_preview(Previewer, item) abort
  call a:Previewer.buffer(a:item.action_bufnr)
endfunction

function! gram#source#buffers#register() abort
  call gram#source#register('buffers', s:source)
endfunction
