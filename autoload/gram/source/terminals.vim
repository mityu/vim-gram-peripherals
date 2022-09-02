scriptversion 4

let s:source = {}
function! s:source.gather_candidates(Callbacks) abort
  let items = []
  let terms = term_list()
  let bufnr_align_len = max(terms)->strlen()
  let formatter = '% ' .. bufnr_align_len .. 'd  %s'
  for term in terms
    let name = bufname(term)
    call add(items, #{word: printf(formatter, term, name), action_bufnr: term})
  endfor

  call a:Callbacks.clear()
  call a:Callbacks.add(items)
endfunction

function! gram#source#terminals#register() abort
  call gram#source#register('terminals', s:source)
endfunction
