scriptversion 4

let s:job_id = v:null
let s:session_id = 0
let s:source = {}

function! s:source.gather_candidates(Callbacks) abort
  call s:kill()
  call a:Callbacks.clear()

  let repo = s:find_git_root()
  if repo ==# ''
    return
  endif
  let repo = fnamemodify(repo, ':p')

  let s:job_id = job_start('git ls-files', {
        \'out_cb': function('s:out_cb', [a:Callbacks.add, s:session_id, repo]),
        \'close_cb': {-> s:kill()},
        \'cwd': repo,
        \})
endfunction

function! s:source.quit() abort
  call s:kill()
endfunction

function! s:out_cb(Callback, session_id, cwd, _, msg) abort
  if s:session_id == a:session_id
    call call(a:Callback, [[{'word': a:msg, 'action_path': a:cwd .. a:msg}]])
  endif
endfunction

function! s:kill() abort
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
