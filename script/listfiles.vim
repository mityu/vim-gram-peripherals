def ListFiles()
  var cwdlen = getcwd()->strlen() + 1
  var dirs = [getcwd()]
  var ignoreFiles = eval($VIM_GRAM_FILE_REC_IGNORE_FILES)
  while !empty(dirs)
    var dir = remove(dirs, 0)->fnamemodify(':p')
    var prefix = dir->strpart(cwdlen)
    try
      readdir(dir, (fname: string): number => {
        if index(ignoreFiles, fname) == -1
          var fullname = dir .. fname
          if isdirectory(fullname)
            dirs->add(fullname)
          else
            :%delete _
            setline(1, prefix .. fname)
            :%print
          endif
        endif
        return 0
      })
    catch
      # ignore
    endtry
  endwhile
enddef
call ListFiles()
quitall!
