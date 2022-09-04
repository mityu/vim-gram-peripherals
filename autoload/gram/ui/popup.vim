scriptversion 4

let s:sign_name = 'gram-cursorline'
let s:sign_group = 'PopUpGramCursorline'
let s:ui = {
      \'signID': 0,
      \'popupID': 0,
      \'bufnr': 0,
      \'prompt_text': '',
      \}
let s:textbox = {
      \'popupID': 0,
      \'bufnr': 0,
      \'cursor_column': 0,
      \'text_display_line': 2,
      \}
let s:info_area_height = s:textbox.text_display_line + 1

function! s:ui.setup(params) abort
  highlight def link gramUIPopupSelectedItem Cursorline
  highlight def link gramUIPopupPanel Normal
  call sign_define(s:sign_name, {
        \'linehl': 'gramUIPopupSelectedItem',
        \'text': '>',
        \})
  let self.signID = 0

  let pheight = &lines * 3 / 4
  if pheight < 35
    let pheight = min([&lines - 6, 35])
  endif

  let pwidth = &columns / 2
  if pwidth < 90
    let pwidth = min([&columns, 90])
  endif

  let pline = (&lines - pheight) / 2
  if (pline - s:info_area_height) < 0
    let pline = s:info_area_height
  endif

  let pcol = (&columns - pwidth) / 2

  let self.popupID = popup_create('', {
        \'scrollbar': 0,
        \'wrap': 0,
        \'line': pline,
        \'col': pcol,
        \'maxheight': pheight,
        \'minheight': pheight,
        \'maxwidth': pwidth,
        \'minwidth': pwidth,
        \'highlight': 'gramUIPopupPanel',
        \'border': [0, 1, 1, 1],
        \})
  let self.bufnr = winbufnr(self.popupID)
  let self.textbox = copy(s:textbox)
  call self.textbox.setup(a:params, {
        \'line': pline,
        \'col': pcol,
        \'height': pheight,
        \'width': pwidth,
        \})
  call setwinvar(self.popupID, '&signcolumn', 'yes')
  " TODO: Make it available to specify highlight group
  call prop_type_add('gramUIPopupPropMatchpos', #{
        \bufnr: self.bufnr,
        \highlight: 'Special',
        \})
endfunction

function! s:ui.quit() abort
  call prop_type_delete('gramUIPopupPropMatchpos', #{bufnr: self.bufnr})
  call self.textbox.quit()
  call popup_close(self.popupID)
  let self.popupID = 0
  let self.bufnr = 0
  let self.signID = 0
endfunction

function! s:ui.on_selected_item_changed(idx) abort
  let l:Line = {expr -> line(expr, self.popupID)}
  let linenr = a:idx + 1
  let scrolloff = getwinvar(self.popupID, '&scrolloff')
  let firstline = 0
  let win_height = popup_getpos(self.popupID).core_height

  if linenr < 1
    let linenr = 1
  elseif linenr > l:Line('$')
    let linenr = l:Line('$')
  endif

  if win_height <= (scrolloff * 2)
    let firstline = linenr - (win_height / 2) + 1
    if firstline <= 0
      let firstline = 1
    endif
  elseif linenr <= scrolloff
    let firstline = 1
  elseif linenr > (l:Line('$') - scrolloff)
    let firstline = l:Line('$') - win_height + 1
  elseif (linenr + scrolloff) > l:Line('w$')
    let firstline = linenr + scrolloff - win_height + 1
  elseif (linenr - scrolloff) < l:Line('w0')
    let firstline = linenr - scrolloff
  endif

  if firstline != 0
    call popup_setoptions(self.popupID, {'firstline': firstline})
  endif

  if self.signID != 0
    call sign_unplace(s:sign_group, {
          \'buffer': self.bufnr,
          \'id': self.signID
          \})
    let self.signID = 0
  endif
  let self.signID =
        \sign_place(0, s:sign_group, s:sign_name, self.bufnr, {'lnum': linenr})
  redraw
endfunction

function! s:ui.on_input_changed(text, column) abort
  call self.textbox.on_input_changed(a:text, a:column)
endfunction

function! s:ui.on_cursor_moved(column) abort
  call self.textbox.move_cursor(a:column)
endfunction

function! s:ui.on_items_added(idx, items) abort
  let linenr = 0
  if self.signID != 0
    try
      let signs = sign_getplaced(
            \self.bufnr,
            \{'group': s:sign_group, 'id': self.signID})
      let linenr = signs[0].signs[0].lnum
    catch
      call self.notify_error('Internal Error:')
      call self.notify_error(v:throwpoint)
      call self.notify_error(v:exception)
      call self.notify_error(signs)
    endtry
  endif
  " TODO: More good expression?
  let had_no_items = 0
  if line('$', self.popupID) == 1 && getbufline(self.bufnr, 1) == ['']
    let had_no_items = 1
  endif

  let idx = a:idx
  for item in a:items
    call appendbufline(self.bufnr, idx, item.word)
    " NOTE: Matchpos are expressed in 0-indexed byte-index.
    for m in get(item, 'matchpos', [])
      call prop_add(idx + 1, m[0] + 1, #{
            \length: m[1],
            \bufnr: self.bufnr,
            \type: 'gramUIPopupPropMatchpos'
            \})
    endfor
  endfor

  if linenr != 0
    call self.on_selected_item_changed(linenr - 1)
  endif
endfunction

function! s:ui.on_items_deleted(ibegin, iend) abort
  let linenr = 0
  if self.signID != 0
    try
      let signs = sign_getplaced(
            \self.bufnr,
            \{'group': s:sign_group, 'id': self.signID})
      let linenr = signs[0].signs[0].lnum
    catch
      call self.notify_error('Internal Error:')
      call self.notify_error(v:throwpoint)
      call self.notify_error(v:exception)
    endtry
  endif
  silent call deletebufline(self.bufnr, a:ibegin + 1, a:iend + 1)
  if linenr != 0
    call self.on_selected_item_changed(linenr - 1)
  endif
endfunction

function! s:ui.hide_cursor() abort
  call self.textbox.hide_cursor()
endfunction

function! s:ui.show_cursor() abort
  call self.textbox.show_cursor()
endfunction

function! s:ui.notify_error(msg) abort
  echohl Error
  echomsg a:msg
  echohl NONE
endfunction


function! s:textbox.setup(params, config) abort
  " TODO: Show border?
  " TODO: Modify 'line' value with border height consideration
  let self.popupID = popup_create('', {
        \'scrollbar': 0,
        \'wrap': 0,
        \'line': a:config.line - s:info_area_height,
        \'col': a:config.col,
        \'maxwidth': a:config.width,
        \'minwidth': a:config.width,
        \'maxheight': self.text_display_line,
        \'minheight': self.text_display_line,
        \'highlight': 'gramUIPopupPanel',
        \'border': [1, 1, 0, 1],
        \})
  let self.bufnr = winbufnr(self.popupID)
  let self.prompt_text = a:params.prompt_text
  let self.matchID = -1
  call self.set_statusline('statusline')
endfunction

function! s:textbox.quit() abort
  call popup_close(self.popupID)
  let self.popupID = 0
  let self.bufnr = 0
  let self.prompt_text = ''
  let self.matchID = -1
endfunction

" Show the filter text and cursor.  If the filter text is too long, truncate
" it and adjust cursor column.
function! s:textbox.on_input_changed(text, column) abort
  let width = popup_getpos(self.popupID).core_width -
        \strdisplaywidth(self.prompt_text) - 1  " A room for cursor
  let text = a:text
  let display_width = strdisplaywidth(text[: a:column])
  let is_cursor_end = 0
  let trimlen = 0
  let trimlen_bytes = 0  " trimlen_chars in Vim9 script
  if a:column >= strlen(text)
    let display_width += 1
    let is_cursor_end = 1
  endif
  if display_width >= width
    let overlen = display_width - width
    for c in split(text, '\zs')
      let trimlen += strdisplaywidth(c, trimlen)
      let trimlen_bytes += strlen(c)
      if trimlen >= overlen
        break
      endif
    endfor
    let text = text[trimlen_bytes :]
  endif
  if is_cursor_end
    let text ..= ' '
  endif
  call setbufline(self.bufnr, self.text_display_line, self.prompt_text .. text)
  call self.move_cursor(a:column + strlen(self.prompt_text) - trimlen_bytes)
endfunction

" Hide cursor
function! s:textbox.hide_cursor() abort
  if self.matchID != -1
    call matchdelete(self.matchID, self.popupID)
    let self.matchID = -1
  endif
endfunction

" Show cursor at self.cursor_column.
function! s:textbox.show_cursor() abort
  highlight def link gramUIPopupCursor Cursor
  let self.matchID = matchaddpos(
        \'gramUIPopupCursor',
        \[[self.text_display_line, self.cursor_column]],
        \10,
        \-1,
        \{'window': self.popupID})
endfunction

function! s:textbox.move_cursor(column) abort
  let self.cursor_column = a:column
  call self.hide_cursor()
  call self.show_cursor()
endfunction

function! s:textbox.set_statusline(text) abort
  let pwidth = popup_getpos(self.popupID).core_width
  let text = a:text .. repeat(' ', pwidth - strdisplaywidth(a:text))
  call setbufline(self.bufnr, 1, text)
endfunction


function! gram#ui#popup#register() abort
  call gram#ui#register('popup', s:ui)
endfunction
