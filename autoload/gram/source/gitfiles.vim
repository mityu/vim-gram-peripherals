scriptversion 4

let s:job_id = v:null
let s:session_id = 0
let s:source = {'_stack': [], '_lastOutputTime': reltime()}
let s:FlushRest = v:null
const s:debounceThreshold = 0.03

function! s:source.gather_candidates(Callbacks) abort
  let s:FlushRest = v:null
  call s:kill()
  call a:Callbacks.clear()

  let repo = s:find_git_root()
  if repo ==# ''
    return
  endif
  let repo = fnamemodify(repo, ':p')

  let self._stack = []
  let self._lastOutputTime = reltime()
  let s:job_id = job_start('git ls-files', {
        \'out_cb': function('s:out_cb', [self, a:Callbacks.add, s:session_id, repo]),
        \'close_cb': {-> s:kill()},
        \'cwd': repo,
        \'noblock': 1,
        \})
endfunction

function! s:source.quit() abort
  call s:kill()
endfunction

function! s:source.on_request_preview(Previewer, item) abort
  call a:Previewer.file(a:item.action_path)
endfunction

function! s:out_cb(source, Callback, session_id, cwd, _, msg) abort
  if s:session_id == a:session_id
    call add(a:source._stack, {'word': a:msg, 'action_path': a:cwd .. a:msg})
    if reltimefloat(reltime(a:source._lastOutputTime)) >= s:debounceThreshold
      call call(a:Callback, [a:source._stack])
      let a:source._stack = []
      let a:source._lastOutputTime = reltime()
    else
      let s:FlushRest = {-> call(a:Callback, [a:source._stack])}
    endif
  endif
endfunction

function! s:kill() abort
  if s:FlushRest != v:null
    call call(s:FlushRest, [])
    let s:FlushRest = v:null
  endif
  let s:session_id += 1
  if s:job_id != v:null && job_status(s:job_id) ==# 'run'
    call job_stop(s:job_id)
    sleep 5m
    if job_status(s:job_id) ==# 'run'
      call job_stop(s:job_id, 'kill')
    endif
  endif
endfunction

function! s:find_git_root() abort
  let cwd = getcwd(winnr())
  if expand('%') !=# ''
    let cwd = resolve(expand('%:p:h'))
  endif
  let dotgit = finddir('.git', cwd .. ';')
  if dotgit ==# ''
    return ''
  endif
  return fnamemodify(dotgit, ':p:h:h')
endfunction

function! gram#source#gitfiles#register() abort
  call gram#source#register('gitfiles', s:source)
endfunction
