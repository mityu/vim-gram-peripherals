scriptversion 4

function! s:edit(items) abort
  for item in a:items
    if s:_has_action_bufnr(item)
      execute item.action_bufnr 'buffer'
    endif
  endfor
endfunction

function! s:wipeout(items) abort
  for item in a:items
    if s:_has_action_bufnr(item)
      execute item.action_bufnr 'bwipeout!'
    endif
  endfor
endfunction

function! s:_has_action_bufnr(item) abort
  if !has_key(a:item, 'action_bufnr')
    echohl Error
    echomsg 'Missing action_bufnr:' string(a:item)
    echohl NONE
    return 0
  endif
  return 1
endfunction

function! gram#kind#buffer#register()
  call gram#item_action#register('buffer', {
        \'edit': function('s:edit'),
        \'wipeout': function('s:wipeout'),
        \})
endfunction
