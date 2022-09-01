scriptversion 4

let s:matcher = {}

function! s:matcher.match(items, input, Callback) abort
  let items = a:items
  let comparers = s:split_input(a:input)
  call filter(items, 's:filter_func(comparers, v:val)')
  call a:Callback(items)
endfunction

function! s:split_input(input) abort
  let comparers = split(a:input, '\v%(^|[^\\])%(\\\\)*\zs\s+')
  call filter(comparers, {_, v -> v !=# ''})
  call map(
        \comparers,
        \{_, v -> substitute(v, '\v%(^|[^\\])%(\\\\)*\zs\\\ze\s', '', 'g')})
  return comparers
endfunction

function! s:filter_func(comparers, v) abort
  for c in a:comparers
    if a:v.word !~? c
      return 0
    endif
  endfor
  return 1
endfunction

function! gram#matcher#regexp#register() abort
  call gram#matcher#register('regexp', s:matcher)
endfunction
