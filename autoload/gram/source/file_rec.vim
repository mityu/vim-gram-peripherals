scriptversion 4

const s:plugin_top = expand('<sfile>:p:h:h:h:h')
let s:listfile_script_path = '/script/listfiles.vim'
if has('win32')
  let s:listfile_script_path = substitute(s:listfile_script_path, '/', '\\', 'g')
endif

const s:cmd = [
  \ exepath(v:progpath),
  \ '-u', 'NONE', '-i', 'NONE', '-n', '-N', '-e', '-s',
  \ '-S', s:plugin_top .. s:listfile_script_path,
  \ ]
let s:job_id = v:null
let s:session_id = 0
let s:source = {}
function! s:source.gather_candidates(Callbacks) abort
  " TODO: Search .git/ directory to find cwd
  call s:kill()
  call a:Callbacks.clear()
  let s:job_id = job_start(s:cmd, {
  \ 'out_cb': function('s:out_cb', [a:Callbacks.add, s:session_id]),
  \ 'close_cb': {-> s:kill()},
  \ 'cwd': getcwd(winnr()),
  \ 'env': {'VIM_GRAM_FILE_REC_IGNORE_FILES': string(['.git', '.DS_Store'])},
  \ })
endfunction

function! s:source.quit() abort
  call s:kill()
endfunction

function! s:out_cb(Callback, session_id, _, msg) abort
  if s:session_id == a:session_id
    call call(a:Callback, [[{'word': a:msg, 'action_path': a:msg}]])
  endif
endfunction

function! s:kill() abort
  if s:job_id != v:null && job_status(s:job_id) ==# 'run'
    call job_stop(s:job_id)
    sleep 5m
    if job_status(s:job_id) ==# 'run'
      call job_stop(s:job_id, 'kill')
    endif
  endif
  let s:session_id += 1
endfunction

function! gram#source#file_rec#register() abort
  call gram#source#register('file_rec', s:source)
endfunction
