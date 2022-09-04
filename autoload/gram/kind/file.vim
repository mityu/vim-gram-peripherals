scriptversion 4

function! s:edit(items) abort
  for item in a:items
    let path = get(item, 'action_path', 'word')
    execute 'edit' fnameescape(path)
  endfor
endfunction

function! gram#kind#file#register()
  call gram#item_action#register('file', {
        \'edit': function('s:edit'),
        \})
endfunction
