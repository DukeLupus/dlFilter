/*
to load: use /load -rs DLFilter.mrc
Note that DLFilter loads itself automatically as a first script (starting from v0.983).
That helps to avoid a lot of problems with other scripts messing with events.
Since creation of a good filter is never-ending job, get new versions from http://dukelupus.com/
Use same site for help about DLFilter.
If you want to reach me, send mail to dukelupus@hot.ee .
Trust this script only if you've downloaded it from http://dukelupus.com/ -
- all other distribution methods and places are not authorized and the script may be tampered.
*/
alias Set.DLF.version {
  %DLF.version = 1.16
  return %DLF.version
}
on *:start: {
  if ($script(onotice.mrc)) .unload -rs onotice.mrc
  if ($script(onotice.txt)) .unload -rs onotice.txt
}

on *:load: {
  if ($version < 6) {
    echo -a 1,9[DLFilter] Sorry, but this script requires mIRC 6+. Loading stopped.
    .unload -rs $script
  }
  if ($script != $script(1)) .load -rs1 $+(",$scriptdir,DLFilter.mrc,")
  echo -s 1,9Loading [DLFilter] version $Set.DLF.version by DukeLupus
  echo -s 1,9[DLFilter] Please check DLFilter homepage (12,9http://dukelupus.com1,9) for help.
  if (%DLF.enabled == $null) %DLF.enabled = 1
  if (%DLF.ads == $null) %DLF.ads = 1
  if (%DLF.requests == $null) %DLF.requests = 1
  if (%DLF.joins == $null) %DLF.joins = 0
  if (%DLF.parts == $null) %DLF.parts = 0
  if (%DLF.quits == $null) %DLF.quits = 0
  if (%DLF.nicks == $null) %DLF.nicks = 0
  if (%DLF.kicks == $null) %DLF.kicks = 0
  if (%DLF.chmode == $null) %DLF.chmode = 0
  if (%DLF.showstatus == $null) %DLF.showstatus = 0
  if (%DLF.showfiltered == $null) %DLF.showfiltered = 1
  if (%DLF.away == $null) %DLF.away = 1
  if (%DLF.usrmode == $null) %DLF.usrmode = 0
  if (%DLF.privrequests == $null) %DLF.privrequests = 1
  if (%DLF.server == $null) %DLF.server = 1
  if (%DLF.searchresults == $null) %DLF.searchresults = 1
  if (%DLF.newreleases == $null) %DLF.newreleases = 1
  if (%DLF.chspam == $null) %DLF.chspam = 1
  if (%DLF.chspam.opnotify == $null) %DLF.chspam.opnotify = 1
  if (%DLF.privspam == $null) %DLF.privspam = 1
  if (%DLF.privspam.opnotify == $null) %DLF.privspam.opnotify = 1
  if (%DLF.spam.addignore == $null) %DLF.spam.addignore = 0
  if (%DLF.nocomchan == $null) %DLF.nocomchan = 1
  if (%DLF.nocomchan.dcc == $null) %DLF.nocomchan.dcc = 1
  if (%DLF.askregfile == $null) %DLF.askregfile = 0
  if (%DLF.askregfile.type == $null) %DLF.askregfile.type = 0
  if (%DLF.noregmsg == $null) %DLF.noregmsg = 0
  if (%DLF.custom.enabled == $null) %DLF.custom.enabled = 1
  if (%DLF.colornicks == $null) %DLF.colornicks = 0
  if (%DLF.server.limit == $null) %DLF.server.limit = 1
  if (%DLF.filtered.limit == $null) %DLF.filtered.limit = 1
  if (%DLF.server.timestamp == $null) %DLF.server.timestamp = 1
  if (%DLF.filtered.timestamp == $null) %DLF.filtered.timestamp = 1
  if (%DLF.server.wrap == $null) %DLF.server.wrap = 1
  if (%DLF.filtered.wrap == $null) %DLF.filtered.wrap = 0
  if (%DLF.server.strip == $null) %DLF.server.strip = 0
  if (%DLF.filtered.strip == $null) %DLF.filtered.strip = 0
  if (%DLF.o.enabled == $null) %DLF.o.enabled = 1
  if (%DLF.o.timestamp == $null) %DLF.o.timestamp = 1
  if (%DLF.o.log == $null) %DLF.o.log = 1
  %DLF.custom.chantext = $addtok(%DLF.custom.chantext,*bonga*,44)
  %DLF.custom.chantext = $addtok(%DLF.custom.chantext,*agnob*,44)
  %DLF.custom.chantext = $addtok(%DLF.custom.chantext,*meep*,44)


  if ($script(onotice.mrc)) .unload -rs onotice.mrc
  if ($script(onotice.txt)) .unload -rs onotice.txt
  if (%DLF.channels == $null) {
    echo -s 1,9[DLFilter] Setting channels to 4all
    %DLF.channels = $chr(35)
    dialog -md DLFilter_GUI DLFilter_GUI
  }
  :error
  echo -s 1,9Loading [DLFilter] complete.
}
ctcp *:VERSION: .ctcpreply $nick VERSION 1,9[DLFilter] version $Set.DLF.version by DukeLupus.1,15 Get it from 12,15http://dukelupus.com/
on *:unload: {
  echo -s 1,9Unloading [DLFilter] version $Set.DLF.version by DukeLupus
  echo 10 -s Unsetting variables..
  .unset %DLF.*
  echo 10 -s Closing open DLFilter windows
  if ($dialog(DLFilter_GUI)) .dialog -x DLFilter_GUI DLFilter_GUI
  if ($window(@DLF.filtered)) window -c @DLF.filtered
  if ($window(@DLF.filtered.search)) window -c @DLF.filtered.search
  if ($window(@DLF.server)) window -c @DLF.server
  if ($window(@DLF.server.search)) window -c @DLF.server.search
  if ($window(@DLF.@find.results)) window -c @DLF.@find.results
  /close -@ @#*
  echo -s 1,9Unloading [DLFilter] complete.
}
menu channel {
  -
  $iif($me !isop #, $style(2)) Send onotice: {
    var %chatwindow = @ $+ $chan
    if (!$window(%chatwindow)) {
      window -eg1k1l12mSw %chatwindow
      if ((%DLF.o.log == 1) && ($exists($+(",$logdir,%chatwindow,.log,")))) {
        write $+(",$logdir,%chatwindow,.log,") $crlf
        write $+(",$logdir,%chatwindow,.log,") $+($chr(91) $+ $fulldate $+ $chr(93),$chr(32) ----- Session started -----)
        write $+(",$logdir,%chatwindow,.log,") $crlf
        .loadbuf -r %chatwindow $+(",$logdir,%chatwindow,.log,")
      }
    }
  }
  -
  DLFilter
  ..Options: dialog -md DLFilter_GUI DLFilter_GUI
  ..$iif($chan isin %DLF.channels,Remove,Add) this channel: {
    var %chan = $chan
    if (%chan !isin %DLF.channels) {
      if (%DLF.channels != $chr(35)) %DLF.channels = $addtok(%DLF.channels,%chan,44)
      else %DLF.channels = %chan
      echo -a 4,15 $chr(91) $+ DLFilter $+ $chr(93) 6Channels set to4 %DLF.channels
    }
    else {
      %DLF.channels = $remtok(%DLF.channels,%chan,1,44)
      echo -a 4,15 $chr(91) $+ DLFilter $+ $chr(93) 6Channels set to4 %DLF.channels
    }
  }
  ..$iif(%DLF.channels == $chr(35), $style(3)) Set to all channels: {
    %DLF.channels = $chr(35)
    echo -a 4,15 $chr(91) $+ DLFilter $+ $chr(93) 6Channels set to4 all
  }
  ..-
  ..$iif(%DLF.showfiltered == 1,$style(1)) Show filtered lines: {
    if (%DLF.showfiltered == 1 ) {
      set %DLF.showfiltered 0
      /window -c @DLF.filtered
    }
    else {
      set %DLF.showfiltered 1
    }
  }
}
menu menubar {
  DLFilter
  .Options: dialog -md DLFilter_GUI DLFilter_GUI
  .$iif(%DLF.showfiltered == 1,$style(1)) Show filtered lines: {
    if (%DLF.showfiltered == 1 ) {
      set %DLF.showfiltered 0
      /window -c @DLF.filtered
    }
    else {
      set %DLF.showfiltered 1
    }
  }
  .Visit filter website: .url -an http://dukelupus.com/
  .-
  .Unload DLFilter: if ($?!="Do you want to unload DLFilter?" == $true) .unload -rs $+(",$script,")
}
menu @DLF.@find.Results,@DLF.NewReleases {
  .-
  .Copy line(s): {
    var %lines = $sline($active,0)
    if (!%lines) halt
    var %allines = $line($active,0)
    var %cnter1 = 1
    while (%cnter1 <= %allines) {
      cline $color(text) $active %cnter1
      inc %cnter1
    }
    var %cnter = 1
    clipboard
    while (%cnter <= %lines) {
      if (%cnter == 1) {
        var %line = $gettok($sline($active,1),1,32) $+ $chr(32) $+ $GetFileName($gettok($sline($active,1),2-,32))
        clipboard %line
        cline 14 $active $sline($active,1).ln
      }
      else {
        clipboard -a $chr(13) $+ $chr(10)
        var %line = $gettok($sline($active,%cnter),1,32) $+ $chr(32) $+ $GetFileName($gettok($sline($active,%cnter),2-,32))
        clipboard -a %line
        cline 14 $active $sline($active,%cnter).ln
      }
      inc %cnter
    }
    if ($active == @DLF.@find.Results) titlebar $active -=- $line(@DLF.@find.Results,0) results so far -=- $calc(%cnter - 1) line(s) copied into clipboard
    else titlebar $active -=- New Releases -=- $calc(%cnter - 1) line(s) copied into clipboard
  }
  $iif(!$script(AutoGet.mrc), $style(2)) Send to AutoGet: {
    var %lines = $sline($active,0)
    if (!%lines) halt
    if ($fopen(MTlisttowaiting)) .fclose MTlisttowaiting
    .fopen MTlisttowaiting $+(",$remove($script(AutoGet.mrc),Autoget.mrc),AGwaiting.ini,")
    set %MTpath %MTdefaultfolder
    var %i = 1
    var %j = 0
    while (%i <= $sline($active,0)) {
      var %temp = $MTlisttowaiting($replace($sline($active,%i),$chr(160),$chr(32)))
      var %j = $calc(%j + $gettok(%temp,1,32))
      if ($sbClient.Online($sline($active,%i)) == 1) { cline 10 $active $sline($active,%i).ln }
      else { cline 6 $active $sline($active,%i).ln }
      inc %i
    }
    .fclose MTlisttowaiting
    unset %MTpath
    if (%MTautorequest == 1) { MTkickstart $gettok(%temp,2,32) }
    MTwhosinque
    echo -s %MTlogo Added %j File(s) To Waiting List From DLFilter
    if ($active == @DLF.@find.Results) titlebar $active -=- $line($active,0) results so far -=- %j line(s) sent to AutoGet
    else titlebar $active -=- New releases -=- %j line(s) sent to AutoGet
  }
  $iif(!$script(vPowerGet.net.mrc), $style(2)) Send to vPowerGet.NET: {
    var %lines = $sline($active,0)
    if (!%lines) halt
    var %allines = $line($active,0)
    var %cnter1 = 1
    while (%cnter1 <= %allines) {
      cline $color(text) $active %cnter1
      inc %cnter1
    }
    var %cnter = 1
    while (%cnter <= %lines) {
      if ($com(vPG.NET,AddFiles,1,bstr,$sline($active,%cnter)) == 0) {
        echo -s vPG.NET: AddFiles failed
      }
      cline 14 $active $sline($active,%cnter).ln
      inc %cnter
    }
    if ($active == @DLF.@find.Results) titlebar $active -=- $line(@DLF.@find.Results,0) results so far -=- $calc(%cnter - 1) line(s) sent to vPowerGet.NET
    else titlebar $active -=- New releases -=- $calc(%cnter - 1) line(s) sent to vPowerGet.NET
  }
  Save results: {
    var %filename = $sfile($mircdir,Save $active contents,Save)
    if (!%filename) haltdef
    %filename = $chr(34) $+ $remove(%filename,.txt) $+ .txt $+ $chr(34)
    savebuf $active %filename
  }
  Options: dialog -md DLFilter_GUI DLFilter_GUI
  Clear: /clear
  .-
  Close: /window -c $active
  .-
}
menu @DLF.Filtered {
  Clear: /clear
  Search: {
    var %searchstring = $?="Enter search string"
    if (%searchstring == $null) halt
    else FilteredSearch %searchstring
  }
  $iif(%DLF.filtered.timestamp == 1,$style(1)) Timestamp: {
    if (%DLF.filtered.timestamp == 1 ) {
      set %DLF.filtered.timestamp 0
    }
    else {
      set %DLF.filtered.timestamp 1
    }
  }
  $iif(%DLF.filtered.strip == 1,$style(1)) Strip codes: {
    if (%DLF.filtered.strip == 1 ) {
      set %DLF.filtered.strip 0
    }
    else {
      set %DLF.filtered.strip 1
    }
  }
  $iif(%DLF.filtered.wrap == 1,$style(1)) Wrap lines: {
    if (%DLF.filtered.wrap == 1 ) {
      set %DLF.filtered.wrap 0
    }
    else {
      set %DLF.filtered.wrap 1
    }
  }
  $iif(%DLF.filtered.limit == 1,$style(1)) Limit number of lines: {
    if (%DLF.filtered.limit == 1 ) {
      set %DLF.filtered.limit 0
    }
    else {
      set %DLF.filtered.limit 1
    }
  }
  $iif(%DLF.filtered.log == 1,$style(1)) Log: {
    if (%DLF.filtered.log == 1) {
      set %DLF.filtered.log 0
    }
    else {
      set %DLF.filtered.log 1
    }
  }
  -
  Options: dialog -md DLFilter_GUI DLFilter_GUI
  Close: {
    %DLF.showfiltered = 0
    /window -c @DLF.Filtered
  }
  -
}
menu @DLF.Server {
  Clear: /clear
  Search: {
    var %searchstring = $?="Enter search string"
    if (%searchstring == $null) halt
    else ServerSearch %searchstring
  }
  $iif(%DLF.server.timestamp == 1,$style(1)) Timestamp: {
    if (%DLF.server.timestamp == 1 ) {
      set %DLF.server.timestamp 0
    }
    else {
      set %DLF.server.timestamp 1
    }
  }
  $iif(%DLF.server.strip == 1,$style(1)) Strip codes: {
    if (%DLF.server.strip == 1 ) {
      set %DLF.server.strip 0
    }
    else {
      set %DLF.server.strip 1
    }
  }
  $iif(%DLF.server.wrap == 1,$style(1)) Wrap lines: {
    if (%DLF.server.wrap == 1 ) {
      set %DLF.server.wrap 0
    }
    else {
      set %DLF.server.wrap 1
    }
  }
  $iif(%DLF.server.limit == 1,$style(1)) Limit number of lines: {
    if (%DLF.server.limit == 1 ) {
      set %DLF.server.limit 0
    }
    else {
      set %DLF.server.limit 1
    }
  }
  $iif(%DLF.server.log == 1,$style(1)) Log: {
    if (%DLF.server.log == 1) {
      set %DLF.server.log 0
    }
    else {
      set %DLF.server.log 1
    }
  }
  -
  Options: dialog -md DLFilter_GUI DLFilter_GUI
  Close: window -c @DLF.Server
  -
}
menu @DLF.*.search {
  Copy line: {
    .clipboard
    .clipboard $sline($active,1)
    cline 14 $active $sline($active,1).ln
  }
  Clear: /clear
  Close: /window -c $active
  Options: dialog -md DLFilter_GUI DLFilter_GUI
}
menu @#* {
  Clear: /clear
  $iif(%DLF.o.timestamp == 1,$style(1)) Timestamp: {
    if (%DLF.o.timestamp == 1) {
      set %DLF.o.timestamp 0
    }
    else {
      set %DLF.o.timestamp 1
    }
  }
  $iif(%DLF.o.log == 1,$style(1)) Logging: {
    if (%DLF.o.log == 1) {
      set %DLF.o.log 0
    }
    else {
      .log off $active
      set %DLF.o.log 1
    }
  }
  Options: dialog -md DLFilter_GUI DLFilter_GUI
  -
  Close: {
    var %chatwindow = $active
    if ((%DLF.o.log == 1) && ($exists($+(",$logdir,%chatwindow,.log,")))) {
      write $+(",$logdir,%chatwindow,.log,") $crlf
      write $+(",$logdir,%chatwindow,.log,") $+($chr(91) $+ $fulldate $+ $chr(93),$chr(32) ----- Session closed -----)
      write $+(",$logdir,%chatwindow,.log,") $crlf
    }
    window -c $active
  }
  -
}
dialog DLFilter_GUI {
  title DLFilter v $+ $Set.DLF.version
  size -1 -1 152 225
  option dbu notheme
  tab "Main", 1, 1 2 151 202
  tab "Capturing/Spam/Security", 2
  tab "Custom", 3
  button "Close", 4, 2 211 43 11, ok
  check "Enable/disable DLFilter", 5, 7 18 66 8, tab 1
  edit "", 6, 5 35 144 10, tab 1 autohs %DLF.channels
  text "Channels (comma separated, use # for all):", 7, 6 27 125 8, tab 1
  text "Filter...", 8, 5 46 50 8, tab 1
  check "..ads and announcements", 9, 7 56 80 9, tab 1
  check "..requests and searches", 10, 7 65 69 8, tab 1
  box "User related", 11, 3 92 145 89, tab 1
  check "..joins", 12, 7 99 50 9, tab 1
  check "..parts", 13, 7 109 50 9, tab 1
  check "..quits", 14, 7 119 50 9, tab 1
  check "..nick changes", 15, 7 129 50 9, tab 1
  check "..kicks", 16, 7 139 50 9, tab 1
  check "..channel mode changes", 17, 7 73 75 9, tab 1
  check "..but show them in Status window.", 18, 27 149 95 9, tab 1
  check "..away and thank-you messages", 19, 7 159 95 9, tab 1
  check "..user mode changes", 20, 7 169 62 9, tab 1
  check "Show/hide filtered lines", 21, 47 211 103 11, push
  box "Capturing", 22, 4 16 144 55, tab 2
  check "Capture server notices to separate window", 23, 10 26 120 9, tab 2
  check "Group @find/@locator results", 24, 10 37 118 8, tab 2
  check "Capture 'New Release' to separate window", 25, 10 48 123 8, tab 2
  box "Spam and security", 26, 4 75 145 116, tab 2
  check "Filter spam on channel", 27, 10 82 87 10, tab 2
  check "Notify, if you are an op", 28, 18 93 72 8, tab 2
  check "Filter private spam", 29, 10 102 58 9, tab 2
  check "Notify, if you are an op in common channel", 30, 18 112 117 8, tab 2
  check "Add spammer to /ignore for 1h (asks confirmation)", 31, 18 121 130 9, tab 2
  check "Don't accept any messages or files from users with whom you do not have a common channel", 32, 10 131 136 19, tab 2 multi
  check "..requests sent to you in pm (@yournick, !yournick)", 33, 7 82 133 8, tab 1
  check "Do not accept files from regular users", 34, 10 160 135 8, tab 2
  check "Do not accept private messages from regulars", 35, 10 178 135 9, tab 2
  check "Enable custom strings", 36, 5 20 100 8, tab 3
  combo 37, 7 40 65 35, tab 3 drop
  text "Filtering type:", 42, 5 30 50 8, tab 3
  edit "", 41, 4 53 144 10, tab 3 autohs
  button "Add", 46, 5 64 67 12, tab 3 flat
  button "Remove", 52, 79 64 68 12, tab 3 flat
  list 51, 5 78 144 123, tab 3 hsbar vsbar size sort
  check "Color uncolored fileservers", 62, 10 192 138 10, tab 2
  check "Capture onotices to separate @#window (OpsTalk)", 61, 10 58 132 8, tab 2
  text "Checking for DLFilter updates...", 56, 5 182 144 8, tab 1
  button "DLFilter website", 67, 4 191 70 12, tab 1 flat
  button "Direct download", 66, 78 191 70 12, tab 1 flat multi
  check "...but accept DCC chats", 72, 18 151 86 8, tab 2
  check "..block only potentially dangerous filetypes", 75, 18 169 127 8, tab 2
}
on *:dialog:DLFilter_GUI:init:0: {
  Set.DLF.version
  did -o DLFilter_GUI 6 1 %DLF.Channels
  if (%DLF.enabled == 1) did -c DLFilter_GUI 5
  if (%DLF.ads == 1) did -c DLFilter_GUI 9
  if (%DLF.requests == 1) did -c DLFilter_GUI 10
  if (%DLF.joins == 1) did -c DLFilter_GUI 12
  if (%DLF.parts == 1) did -c DLFilter_GUI 13
  if (%DLF.quits == 1) did -c DLFilter_GUI 14
  if (%DLF.nicks == 1) did -c DLFilter_GUI 15
  if (%DLF.kicks == 1) did -c DLFilter_GUI 16
  if (%DLF.chmode == 1) did -c DLFilter_GUI 17
  if (%DLF.showstatus == 1) did -c DLFilter_GUI 18
  if (%DLF.away == 1) did -c DLFilter_GUI 19
  if (%DLF.usrmode == 1) did -c DLFilter_GUI 20
  if (%DLF.privrequests == 1) did -c DLFilter_GUI 33
  if (%DLF.showfiltered == 1) did -c DLFilter_GUI 21
  if (%DLF.server == 1) did -c DLFilter_GUI 23
  if (%DLF.searchresults == 1) did -c DLFilter_GUI 24
  if (%DLF.newreleases == 1) did -c DLFilter_GUI 25
  if (%DLF.chspam == 1) did -c DLFilter_GUI 27
  if (%DLF.chspam.opnotify == 1) did -c DLFilter_GUI 28
  if (%DLF.privspam == 1) did -c DLFilter_GUI 29
  if (%DLF.privspam.opnotify == 1) did -c DLFilter_GUI 30
  if (%DLF.spam.addignore == 1) did -c DLFilter_GUI 31
  if (%DLF.nocomchan == 1) did -c DLFilter_GUI 32
  if (%DLF.nocomchan.dcc == 1) did -c DLFilter_GUI 72
  if (%DLF.askregfile.type == 1) {
    did -c DLFilter_GUI 75
    %DLF.askregfile = 1
  }
  if (%DLF.askregfile == 1) did -c DLFilter_GUI 34
  else %DLF.askregfile.type = 0
  if (%DLF.noregmsg == 1) did -c DLFilter_GUI 35
  if (%DLF.colornicks == 1) did -c DLFilter_GUI 62
  if (%DLF.o.enabled == 1) did -c DLFilter_GUI 61
  if (%DLF.custom.enabled == 1) did -c DLFilter_GUI 36
  did -a DLFilter_GUI 37 Channel text
  did -a DLFilter_GUI 37 Channel action
  did -a DLFilter_GUI 37 Channel notice
  did -a DLFilter_GUI 37 Channel ctcp
  did -a DLFilter_GUI 37 Private text
  did -a DLFilter_GUI 37 Private action
  did -a DLFilter_GUI 37 Private notice
  did -a DLFilter_GUI 37 Private ctcp
  did -c DLFilter_GUI 37 1
  didtok DLFilter_GUI 51 44 %DLF.custom.chantext
  %DLF.custom.selected = Channel text
  DLF.update
}
on *:dialog:DLFilter_GUI:sclick:4: {
  %DLF.Channels = $did(6).text
  %DLF.enabled = $did(5).state
  %DLF.ads = $did(9).state
  %DLF.requests = $did(10).state
  %DLF.joins = $did(12).state
  %DLF.parts = $did(13).state
  %DLF.quits = $did(14).state
  %DLF.nicks = $did(15).state
  %DLF.kicks = $did(16).state
  %DLF.chmode = $did(17).state
  %DLF.showstatus = $did(18).state
  %DLF.away = $did(19).state
  %DLF.usrmode = $did(20).state
  %DLF.privrequests = $did(33).state
  %DLF.server = $did(23).state
  %DLF.searchresults = $did(24).state
  %DLF.newreleases = $did(25).state
  %DLF.chspam = $did(27).state
  %DLF.chspam.opnotify = $did(28).state
  %DLF.privspam = $did(29).state
  %DLF.privspam.opnotify = $did(30).state
  %DLF.spam.addignore = $did(31).state
  %DLF.nocomchan = $did(32).state
  %DLF.nocomchan.dcc = $did(72).state
  %DLF.askregfile = $did(34).state
  %DLF.askregfile.type = $did(75).state
  if (%DLF.askregfile.type == 1) %DLF.askregfile = 1
  %DLF.noregmsg = $did(35).state
  %DLF.colornicks = $did(62).state
  %DLF.o.enabled = $did(61).state
  %DLF.custom.enabled = $did(36).state
  .unset %DLF.custom.selected
}
on *:dialog:DLFilter_GUI:sclick:21: {
  %DLF.showfiltered = $did(21).state
  if (%DLF.showfiltered == 0) window -c @DLF.filtered
}
on *:dialog:DLFilter_GUI:sclick:75: {
  if ($did(75).state == 1) {
    %DLF.askregfile = 1
    did -c DLFilter_GUI 34
  }
  else {
    %DLF.askregfile = 0
    did -u DLFilter_GUI 34
  }
}
on *:dialog:DLFilter_GUI:sclick:34: {
  if (($did(34).state == 0) && ($did(75).state == 1)) did -u DLFilter_GUI 75
}
on *:dialog:DLFilter_GUI:sclick:37: {
  %DLF.custom.selected = $did(37).seltext
  did -r DLFilter_GUI 51
  if (%DLF.custom.selected == Channel text) didtok DLFilter_GUI 51 44 %DLF.custom.chantext
  if (%DLF.custom.selected == Channel action) didtok DLFilter_GUI 51 44 %DLF.custom.chanaction
  if (%DLF.custom.selected == Channel notice) didtok DLFilter_GUI 51 44 %DLF.custom.channotice
  if (%DLF.custom.selected == Channel ctcp) didtok DLFilter_GUI 51 44 %DLF.custom.chanctcp
  if (%DLF.custom.selected == Private text) didtok DLFilter_GUI 51 44 %DLF.custom.privtext
  if (%DLF.custom.selected == Private action) didtok DLFilter_GUI 51 44 %DLF.custom.privaction
  if (%DLF.custom.selected == Private notice) didtok DLFilter_GUI 51 44 %DLF.custom.privnotice
  if (%DLF.custom.selected == Private ctcp) didtok DLFilter_GUI 51 44 %DLF.custom.privctcp
}
on *:dialog:DLFilter_GUI:sclick:46: {
  var %new = $did(41).text
  if (!%new) halt
  var %c = 1
  %new = $chr(42) $+ %new $+ $chr(42)
  while (%c <= 3) {
    %new = $replace(%new,$chr(33),$chr(42),$chr(35),$chr(42),$chr(36),$chr(42),$chr(37),$chr(42),$chr(38),$chr(42),$chr(40),$chr(42),$chr(41),$chr(42),$chr(47),$chr(42),$chr(58),$chr(42),$chr(59),$chr(42),$chr(60),$chr(42),$chr(61),$chr(42),$chr(62),$chr(42),$chr(91),$chr(42),$chr(93),$chr(42),$chr(123),$chr(42),$chr(124),$chr(42),$chr(125),$chr(42),$chr(42) $+ $chr(42), $chr(42))
    %new = $replace(%new,$chr(32) $+ $chr(32),$chr(42))
    %new = $replace(%new,$chr(46), $chr(42))
    %new = $replace(%new,$chr(44), $chr(42))
    %new = $replace(%new,$chr(42) $+ $chr(32),$chr(42))
    %new = $replace(%new,$chr(32) $+ $chr(42),$chr(42))
    %new = $replace(%new,$chr(42) $+ $chr(42), $chr(42),$chr(42) $+ $chr(42), $chr(42))
    inc %c
  }
  if (%DLF.custom.selected == Channel text) %DLF.custom.chantext = $addtok(%DLF.custom.chantext,%new,44)
  if (%DLF.custom.selected == Channel action) %DLF.custom.chanaction = $addtok(%DLF.custom.chanaction,%new,44)
  if (%DLF.custom.selected == Channel notice) %DLF.custom.channotice = $addtok(%DLF.custom.channotice,%new,44)
  if (%DLF.custom.selected == Channel ctcp) %DLF.custom.chanctcp = $addtok(%DLF.custom.chanctcp,%new,44)
  if (%DLF.custom.selected == Private text) %DLF.custom.privtext = $addtok(%DLF.custom.privtext,%new,44)
  if (%DLF.custom.selected == Private action) %DLF.custom.privaction = $addtok(%DLF.custom.privaction,%new,44)
  if (%DLF.custom.selected == Private notice) %DLF.custom.privnotice = $addtok(%DLF.custom.privnotice,%new,44)
  if (%DLF.custom.selected == Private ctcp) %DLF.custom.privctcp = $addtok(%DLF.custom.privctcp,%new,44)
  did -r DLFilter_GUI 51
  if (%DLF.custom.selected == Channel text) didtok DLFilter_GUI 51 44 %DLF.custom.chantext
  if (%DLF.custom.selected == Channel action) didtok DLFilter_GUI 51 44 %DLF.custom.chanaction
  if (%DLF.custom.selected == Channel notice) didtok DLFilter_GUI 51 44 %DLF.custom.channotice
  if (%DLF.custom.selected == Channel ctcp) didtok DLFilter_GUI 51 44 %DLF.custom.chanctcp
  if (%DLF.custom.selected == Private text) didtok DLFilter_GUI 51 44 %DLF.custom.privtext
  if (%DLF.custom.selected == Private action) didtok DLFilter_GUI 51 44 %DLF.custom.privaction
  if (%DLF.custom.selected == Private notice) didtok DLFilter_GUI 51 44 %DLF.custom.privnotice
  if (%DLF.custom.selected == Private ctcp) didtok DLFilter_GUI 51 44 %DLF.custom.privctcp
}
on *:dialog:DLFilter_GUI:sclick:52: {
  var %seltext = $did(51).seltext
  if (!%seltext) halt
  if (%DLF.custom.selected == Channel text) %DLF.custom.chantext = $remtok(%DLF.custom.chantext,%seltext,1,44)
  if (%DLF.custom.selected == Channel action) %DLF.custom.chanaction = $remtok(%DLF.custom.chanaction,%seltext,1,44)
  if (%DLF.custom.selected == Channel notice) %DLF.custom.channotice = $remtok(%DLF.custom.channotice,%seltext,1,44)
  if (%DLF.custom.selected == Channel ctcp) %DLF.custom.chanctcp = $remtok(%DLF.custom.chanctcp,%seltext,1,44)
  if (%DLF.custom.selected == Private text) %DLF.custom.privtext = $remtok(%DLF.custom.privtext,%seltext,1,44)
  if (%DLF.custom.selected == Private action) %DLF.custom.privaction = $remtok(%DLF.custom.privaction,%seltext,1,44)
  if (%DLF.custom.selected == Private notice) %DLF.custom.privnotice = $remtok(%DLF.custom.privnotice,%seltext,1,44)
  if (%DLF.custom.selected == Private ctcp) %DLF.custom.privctcp = $remtok(%DLF.custom.privctcp,%seltext,1,44)
  did -r DLFilter_GUI 51
  if (%DLF.custom.selected == Channel text) didtok DLFilter_GUI 51 44 %DLF.custom.chantext
  if (%DLF.custom.selected == Channel action) didtok DLFilter_GUI 51 44 %DLF.custom.chanaction
  if (%DLF.custom.selected == Channel notice) didtok DLFilter_GUI 51 44 %DLF.custom.channotice
  if (%DLF.custom.selected == Channel ctcp) didtok DLFilter_GUI 51 44 %DLF.custom.chanctcp
  if (%DLF.custom.selected == Private text) didtok DLFilter_GUI 51 44 %DLF.custom.privtext
  if (%DLF.custom.selected == Private action) didtok DLFilter_GUI 51 44 %DLF.custom.privaction
  if (%DLF.custom.selected == Private notice) didtok DLFilter_GUI 51 44 %DLF.custom.privnotice
  if (%DLF.custom.selected == Private ctcp) didtok DLFilter_GUI 51 44 %DLF.custom.privctcp
}
on *:dialog:DLFilter_GUI:sclick:67: url -an http://dukelupus.com/
on *:dialog:DLFilter_GUI:sclick:66: url -an http://www.dukelupus.pri.ee/download.php?f=187932020
ctcp *:*SLOTS*:%DLF.channels: {
  if (%DLF.colornicks == 1) DLFSetNickColor $chan $nick
  haltdef
}
ctcp *:*OmeNServE*:%DLF.channels: {
  if (%DLF.colornicks == 1) DLFSetNickColor $chan $nick
  haltdef
}
ctcp *:*RAR*:%DLF.channels: {
  if (%DLF.colornicks == 1) DLFSetNickColor $chan $nick
  haltdef
}
ctcp *:*WMA*:%DLF.channels: {
  if (%DLF.colornicks == 1) DLFSetNickColor $chan $nick
  haltdef
}
ctcp *:*ASF*:%DLF.channels: {
  if (%DLF.colornicks == 1) DLFSetNickColor $chan $nick
  haltdef
}
ctcp *:*SOUND*:%DLF.channels: {
  if (%DLF.colornicks == 1) DLFSetNickColor $chan $nick
  haltdef
}

ctcp *:*MP*:%DLF.channels: {
  if (%DLF.colornicks == 1) DLFSetNickColor $chan $nick
  haltdef
}


ctcp *:*ping*:%DLF.channels: haltdef
ctcp *:*:%DLF.channels: {
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.chanctcp)) {
    var %nr = $numtok(%DLF.custom.chanctcp,44)
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.chanctcp,%cnter,44) iswm $1-) DLF_textfilter $target $nick $1-
      inc %cnter
    }
  }
}

ctcp *:*:?: {
  if (%DLF.enabled == 0) goto DLFnoctcp
  if ((%DLF.nocomchan.dcc == 1) && ($1-2 === DCC CHAT)) {
    %DLF.accepthis = $nick
    goto DLFnoctcp
  }
  if (%DLF.nocomchan == 1) DoCheckComChan $nick $1-
  if ((%DLF.askregfile == 1) && (DCC SEND isin $1-)) {
    if ($CheckRegular($nick) == IsRegular) {
      if (%DLF.askregfile.type == 1) {
        var %ext = $right($nopath($filename),4)
        if ($pos(%ext,$chr(46),1) == 2) %ext = $right(%ext,3)
        if ((.exe == %ext) || (.com == %ext) || (.bat == %ext) || (.scr == %ext) || (.mrc == %ext) || (.pif == %ext) || (.vbs == %ext) || (.js == %ext) || (.doc == %ext)) {
        }
        else {
          goto DLFnoctcp
        }
      }
      echo -s 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to send you file " $+ $gettok($1-,3-$numtok($1-,32), 32) $+ ".
      haltdef
      halt
    }
  }
  if ((%DLF.noregmsg == 1) && (($CheckRegular($nick) == IsRegular)) && (DCC send !isin $1-)) {
    echo -s 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to:4,15 $1-
    echo -a 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to:4,15 $1-
    haltdef
    halt
  }
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.privctcp)) {
    var %nr = $numtok(%DLF.custom.privctcp,44)
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.privctcp,%cnter,44) iswm $1-) DLF_textfilter Private $nick $1-
      inc %cnter
    }
  }
  :DLFnoctcp
}

on ^*:text:#find *:%DLF.channels: DLF_textfilter $chan $nick $1-
on ^*:text:"find *:%DLF.channels: DLF_textfilter $chan $nick $1-
on ^*:text:*:%DLF.channels: {
  if (%DLF.enabled == 0) goto DLFnofilter
  var %DLF.text = $1-
  var %DLF.txt = $strip(%DLF.text)
  if (%DLF.ads == 1) {
    if (*Type*@* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Trigger*@* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*List*@* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Type*!*to get this* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*[BWI]*@* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Trigger*ctcp* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*@*Finålity* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*@*SDFind* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*I have just finished sending*to*Empty* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*§kÎn§*ßy*§hådõ* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*-SpR-* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Escribe*@* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*±* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Escribe*!* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*-SpR skin used by PepsiScript* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Type*!*.* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Empty! Grab one fast!* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Random Play MP3*Now Activated* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*The Dcc Transfer to*has gone under*Transfer* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*just left*Sending file Aborted* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*has just received*for a total of* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*There is a Slot Opening*Grab it Fast* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Tapez*Pour avoir ce Fichier* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Tapez*Pour Ma Liste De*Fichier En Attente* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*left irc and didn't return in*min. Sending file Aborted* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*FTP*address*port*login*password* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*I have sent a total of*files and leeched a total of*since* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*I have just finished sending*I have now sent a total of*files since* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*I have just finished recieving*from*I have now recieved a total of* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Proofpack Server*Looking for new scans to proof*@proofpack for available proofing packs* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*SpR JUKEBOX*filesize* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*I have spent a total time of*sending files and a total time of*recieving files* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Tape*@* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Tape*!*MB* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Tape*!*.mp3* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*§*DCC Send Failed*to*§* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Wireless*mb*br* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Sent*OS-Limits V* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*File Servers Online*Polaris* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*There is a*Open*Say's Grab* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*left*and didn't return in*mins. Sending file Aborted* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*to*just got timed out*slot*Empty* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Softwind*Softwind* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Statistici 1*by Un_DuLciC* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*tìnkërßëll`s collection*Love Quotes* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*—I-n-v-i-s-i-o-n—* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*DCC SEND COMPLETE*to*slot* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*« * » -* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*¥*Mp3s*¥* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*DCC GET COMPLETE*from*slot*open* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Je viens juste de terminer l'envoi de*Prenez-en un vite* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Random Play MP3 filez Now Plugged In* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*a recu*pour un total de*fichiers* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*vient d'etre interrompu*Dcc Libre* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*failed*DCC Send Failed of*to*failed* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*is playing*info*secs* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*--PepsiScript--* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*«Scøøp MP3»* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*~*~SpR~*~* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*SpR*[*mp3*]* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*©§©* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*I am opening up*more slot*Taken* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*.mp3*t×PLåY6* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*!*.mp3*SpR* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*SPr*!*.mp3* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Successfully*Tx.Track* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*[Mp3xBR]* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*OmeNServE*©^OmeN^* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*@*DragonServe* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Now Sending*QwIRC* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*sent*to*size*speed*time*sent* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Bandwith*Usage*Current*Record* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Files In List*slots open*Queued*Next Send* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Rank*~*x*~* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Total Offered*Files*Total Sent*Files*Total Sent Today*Files* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Control*IRC Client*CTCPSERV* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Download this exciting book* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*» Port «*»* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Tasteazã*@* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*File Servers Online*Trigger*Accessed*Served* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*- DCC Transfer Status -* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Enter @*to see the menu* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*User Slots*Sends*Queues*Next Send Available*¤UControl¤* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Total*File Transfer in Progress*slot*empty* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*!*MB*Kbps*Khz* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*I have just finished sending*.mp3 to* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Files*free Slots*Queued*Speed*Served* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*I am using*SpR JUKEBOX*http://spr.darkrealms.org* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*FTP service*FTP*port*bookz* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*<><><*><><>* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*To serve and to be served*@* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*send - to*at*cps*complete*left* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*DCC Send Failed of*to* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*[Fserve Active]* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*File Server Online*Triggers*Sends*Queues* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*Teclea: @* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*rßP£a*sk*n* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*rßPLåY* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
    if (*<*>*!* iswm %DLF.txt) TextSetNickColor $chan $nick %DLF.text
  }
  if (%DLF.requests == 1) {
    if (!* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (@* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
  }
  if (%DLF.away == 1) {
    if (*KeepTrack*de adisoru* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Leaving*reason*auto away after* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*I am AWAY*Reason*To page me* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*sets away*auto idle away*since* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*away*since*pager* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Thanks for the +v* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*I have just finished receiving*from* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*We have just finished receiving*From The One And Only* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Thank You*for serving in* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Thanks for the @* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Thanks*For*The*Voice* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*I am AWAY*Reason*I have been Away for* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*HêåvêñlyAway* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*[F][U][N]* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Tx TIMEOUT* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Receive Successful*Thanks for* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Thanks*for Supplying an server in* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*have just finished recieving*from*I have leeched a total* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*DCC Send Failed of*to*Starting next in Que* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*KeepTrack*by*^OmeN* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Message*SysReset* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*YAY* Another brave soldier in the war to educate the masses*Onward Comrades* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*WaS auTo-VoiCeD THaNX FoR SHaRiNG HeRe iN* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*I have just received*from*leeched since* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*mp3 server detected* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*KiLLJarX*channel policy is that we are a* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*rbPlay20.mrc* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*rßPLåY2.0* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*I have just finished receiving*from*have now received a total* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*ROLL TIDE*Now Playing*mp3* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Tocmai am primit*KeepTrack* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Total Received*Files*Total Received Today*Files* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*BJFileTracker V06 by BossJoe* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Just Sent To*Filename*Slots Free*Queued* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Received*From*Size*Speed*Time*since* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*I have just received*from*for a total of*KeepTrack* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*« Ë×Çü®§îöñ »* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Thanks*For The*@* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*get - from*at*cps*complete* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Je viens juste de terminer de recevoir*de*Prenez-en un vite* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*§ÐfíñÐ âÐÐ-øñ§* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Welcome back to #* operator*.* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*[Away]*SysReset* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*Back*Duration* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if (*MisheBORG*SendStat*v.* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
  }
  if (%DLF.newreleases == 1) {
    if (*NEW from the excellent proofers of* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
    if ((Wiz* iswm $nick) && (--*!* iswm %DLF.txt)) NewRFilter $nick $2-
    if (*N e w release* iswm %DLF.txt) NewRFilter $nick $1-
    if (N E W * iswm %DLF.txt) NewRFilter $nick $1-
    if (*-=NEW=-* iswm %DLF.txt) NewRFilter $nick $1-
    if (*-=NEW RELEASE=-* iswm %DLF.txt) NewRFilter $nick $1-
  }
  /*if (%DLF.chspam == 1) {
    ;no channel spam right now
  }
  */
  if ($1 == 2find) DLF_textfilter $chan $nick %DLF.text
  if ($1- == Sign in to turn on 1-Click ordering.) DLF_textfilter $chan $nick %DLF.text
  if (---*KB iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
  if (---*MB iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
  if (---*KB*s* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
  if (---*MB*s* iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.chantext)) {
    var %nr = $numtok(%DLF.custom.chantext,44)
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.chantext,%cnter,44) iswm %DLF.txt) DLF_textfilter $chan $nick %DLF.text
      inc %cnter
    }
  }
  :DLFnofilter
}
alias TextSetNickColor {
  if ((%DLF.colornicks == 1) && ($nick($1,$2).color == $color(nicklist))) cline 2 $1 $2
  DLF_textfilter $1-
}
alias DLF_textfilter {
  if (%DLF.filtered.log == 1) write $+(",$logdir,DLF.Filtered,.log,") $+($chr(91),$fulldate,$chr(93)) $+ $chr(32) $+ $chr(91) $+ $1 $+ $chr(93) $+ $chr(32) $+ $chr(60) $+ $2 $+ $chr(62) $+ $chr(32) $+ $strip($3-)
  if (%DLF.showfiltered == 1) {
    if (!$window(@DLF.Filtered)) {
      window -k0nwz @DLF.filtered
      titlebar @DLF.filtered -=- Right-click for options
    }
    var %line = $chr(91) $+ $1 $+ $chr(93) $+ $chr(32) $+ $chr(60) $+ $2 $+ $chr(62) $+ $chr(32) $+ $3-
    if ((%DLF.filtered.limit == 1) && ($line(@DLF.filtered,0) >= 5000)) dline @DLF.Filtered 1-100
    if (%DLF.filtered.timestamp == 1) %line = $timestamp $+ $chr(32) $+ %line
    if (%DLF.filtered.strip == 1) %line = $strip(%line)
    if (%DLF.filtered.wrap == 1) aline -p @DLF.filtered %line
    else aline @DLF.filtered %line
  }
  halt
}
on ^*:action:*:%DLF.channels: {
  if (%DLF.enabled == 0) goto DLFnofilter2
  var %DLF.action = $1-
  var %DLF.act = $strip(%DLF.action)
  if (%DLF.ads == 1) {
    if (*FTP*port*user*pass* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*get AMIP*plug-in at http*amip.tools-for.net* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
  }
  if (%DLF.away == 1) {
    if (*has taken a seat on the channel couch*Couch v*by Kavey* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*has stumbled to the channel couch*Couch v*by Kavey* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*has returned from*I was gone for* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is gone. Away after*minutes of inactivity* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is away*Reason*since* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is BACK from*auto-away* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is back*From*Gone for* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*sets away*Auto Idle Away after* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is back from*Gone* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is BACK from*Away* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*asculta* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is AWAY*auto-away* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*Avertisseur*Journal* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.text
    if (*I-n-v-i-s-i-o-n* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is back*from*Auto IdleAway* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*way*since*pager* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*[Backing Up]* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*está away*pager* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*uses cracked software*I will respond to the following commands* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*I Have Send My List*Times*Files*Times* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*Type Or Copy*Paste*To Get This Song* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is currently boogying away to* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*is listening to*Kbps*KHz* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
    if (*Now*Playing*Kbps*KHz* iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action

  }
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.chanaction)) {
    var %nr = $numtok(%DLF.custom.chanaction,44)
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.chanaction,%cnter,44) iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
      inc %cnter
    }
  }
  :DLFnofilter2
}
alias DLF_actionfilter {
  if (%DLF.filtered.log == 1) write $+(",$logdir,DLF.Filtered,.log,") $+($chr(91),$fulldate,$chr(93)) $+ $chr(32) $+ $chr(91) $+ $1 $+ $chr(93) $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $2 $+ $chr(32) $+ $strip($3-)
  if (%DLF.showfiltered == 1) {
    if (!$window(@DLF.Filtered)) {
      window -k0nwz @DLF.Filtered
      titlebar @DLF.Filtered -=- Right-click for options
    }
    var %line = $chr(91) $+ $1 $+ $chr(93) $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $2 $+ $chr(32) $+ $3-
    if ((%DLF.filtered.limit == 1) && ($line(@DLF.Filtered,0) >= 5000)) dline @DLF.Filtered 1-100
    if (%DLF.filtered.timestamp == 1) %line = $timestamp $+ $chr(32) $+ %line
    if (%DLF.filtered.strip == 1) %line = $strip(%line)
    if (%DLF.filtered.wrap == 1) aline -p $color(action) @DLF.Filtered %line
    else aline $color(action) @DLF.Filtered %line
  }
  halt
}
on *:input:@DLF.Filtered.Search: FilteredSearch $1-
alias FilteredSearch {
  window -ealbk0wz @DLF.filtered.search
  var %sstring = $chr(42) $+ $1- $+ $chr(42)
  titlebar @DLF.filtered.search -=- Searching for %sstring
  filter -wwbpc @DLF.filtered @DLF.Filtered.search %sstring
  if ($line(@DLF.Filtered.search,0) == 0) titlebar @DLF.filtered.search -=- Search finished. No matches for " $+ %sstring $+ " found.
  else titlebar @DLF.filtered.search -=- Search finished. $line(@DLF.Filtered.search,0) matches found for " $+ %sstring $+ ".
}
on ^*:join:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter3
  if ((%DLF.joins == 1) && (%DLF.showstatus == 1)) echo -snc join $timestamp $+ $chr(32) $+ $chr(91) $+ $chan $+ $chr(93) $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $nick $+ $chr(32) $+ ( $+ $address $+ ) has joined $chan
  if (%DLF.joins == 1) halt
  :nofilter3
}
on ^*:part:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter4
  if ((%DLF.showstatus == 1) && (%DLF.parts == 1)) echo -snc part $timestamp $+ $chr(32) $+ $chr(91) $+ $chan $+ $chr(93) $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $nick $+ $chr(32) $+ ( $+ $address $+ ) has left $chan
  if (%DLF.parts == 1) halt
  :nofilter4
}
on ^*:nick: {
  if (%DLF.enabled == 0) goto nofilter5
  if ((%DLF.nicks == 1) && (%DLF.showstatus == 1)) echo -snc nick $timestamp $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $nick $+ $chr(32) $+ ( $+ $address $+ ) is now known as $newnick
  if ((%DLF.nicks == 1) && (%DLF.channels == $chr(35))) halt
  if (%DLF.nicks == 1) {
    var %chans = $comchan($newnick,0)
    var %cnter2 = 0
    while (%cnter2 < %chans) {
      inc %cnter2
      if ($comchan($newnick,%cnter2) isin %DLF.channels) continue
      else echo -c nick $comchan($newnick,%cnter2) $timestamp $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $nick $+ $chr(32) $+ ( $+ $address $+ ) is now known as $newnick
    }
    halt
  }
  :nofilter5
}
on ^*:quit: {
  if (%DLF.enabled == 0) goto nofilter6
  if ((%DLF.quits == 1) && (%DLF.showstatus == 0)) haltdef
  if ((%DLF.quits == 1) && (%DLF.showstatus == 1) && ($len(%DLF.channels) == 1)) {
    echo -snc Quit $timestamp $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $nick $+ $chr(32) $+ ( $+ $address $+ ) Quit ( $+ $1- $+ ).
    haltdef
  }
  if ((%DLF.quits == 1) && (%DLF.showstatus == 1) && ($len(%DLF.channels) != 1)) {
    var %f.i = 1
    var %c = 0
    var %f.chan
    while (%f.i <= $comchan($nick, 0)) {
      %f.chan = $comchan($nick, %f.i)
      if ($comchan($nick, %f.i) isin %dlf.channels) {
        if (%c == 0) {
          echo -snc quit $timestamp $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $nick $+ $chr(32) $+ ( $+ $address $+ ) Quit ( $+ $1- $+ )
          %c = 1
        }
      }
      else echo -c quit %f.chan $timestamp $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $nick $+ $chr(32) $+ ( $+ $address $+ ) Quit ( $+ $1- $+ )
      inc %f.i
    }
    haltdef
  }
  :nofilter6
}
on ^*:kick:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter7
  if ((%DLF.kicks == 1) && (%DLF.showstatus == 1)) echo -snc kick $timestamp $+ $chr(32) $+ $chr(91) $+ $chan $+ $chr(93) $+ $chr(32) $+ $chr(42) $+ $chr(32) $+ $knick $+ $chr(32) $+ ( $+ $address($knick,5) $+ ) was kicked from $chan by $nick ( $+ $1- $+ ).
  if (%DLF.kicks == 1) halt
  :nofilter7
}
on ^*:ban:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter8
  if (%DLF.usrmode == 1) halt
  :nofilter8
}
on ^*:op:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter9
  if (%DLF.usrmode == 1) halt
  :nofilter9
}
on ^*:deop:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter10
  if (%DLF.usrmode == 1) halt
  :nofilter10
}
on ^*:voice:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter11
  if (%DLF.usrmode == 1) halt
  :nofilter11
}
on ^*:devoice:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter12
  if (%DLF.usrmode == 1) halt
  :nofilter12
}
on ^*:unban:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter13
  if (%DLF.usrmode == 1) halt
  :nofilter13
}
on ^*:serverop:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter14
  if (%DLF.usrmode == 1) halt
  :nofilter14
}
on ^*:serverderop:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter15
  if (%DLF.usrmode == 1) halt
  :nofilter15
}
on ^*:servervoice:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter16
  if (%DLF.usrmode == 1) halt
  :nofilter16
}
on ^*:serverdevoice:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter17
  if (%DLF.usrmode == 1) halt
  :nofilter17
}
on ^*:mode:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter18
  if (%DLF.chmode == 1) halt
  :nofilter18
}
on ^*:servermode:%DLF.channels: {
  if (%DLF.enabled == 0) goto nofilter19
  if (%DLF.chmode == 1) halt
  :nofilter19
}
on ^*:open:*: {
  if (%DLF.enabled == 0) goto nofilter20
  if ((%DLF.nocomchan.dcc == 1) && (%DLF.accepthis == $target)) {
    goto nofilter20
  }
  %DLF.ptext = $strip($1-)
  CheckPrivText $nick $1-
  :nofilter20
}
on ^*:text:*:?: {
  if (%DLF.enabled == 0) goto nofilterpt
  if ((%DLF.nocomchan.dcc == 1) && (%DLF.accepthis == $target)) {
    goto nofilterpt
  }
  if (* $+ $chr(36) $+ decode* iswm $1-) echo 4 -a [dlFilter] Do not paste any messages containg $chr(36) $+ decode to your mIRC. They are mIRC worms, people sending them are infected. Report such messages to channel ops.
  %DLF.ptext = $strip($1-)
  CheckPrivText $nick $1-
  :nofilterpt
}
alias CheckPrivText {
  if ($window(1)) DoCheckComChan $1 $2-
  if ((%DLF.noregmsg == 1) && ($CheckRegular($1) == IsRegular)) {
    echo -s 1,9[DLFilter] Regular user $1 ( $+ $address($1,0) $+ ) tried to:4,15 $2-
    echo -a 1,9[DLFilter] Regular user $1 ( $+ $address $+ ) tried to:4,15 $2-
    if ($window($1)) window -c $1
    halt
  }
  if (%DLF.privrequests == 1) {
    if ($1 === $me) return
    var %fword = $strip($2)
    var %nicklist = @ $+ $me
    var %nickfile = ! $+ $me
    if ((%nicklist == %fword) || (%nickfile == %fword) || (%nickfile == $gettok($strip($2),1,45))) {
      .msg $1 Please do not request in private. All commands go to channel.
      .msg $1 You may have to go to 2mIRC options --->> Sounds --->> Requests and uncheck "3Send '!nick file' as private message"
      if (($window($1)) && ($line($1,0) == 0)) .window -c $1
      halt
    }
  }
  if (%DLF.privspam == 1) {
    if ((*www*sex* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1-
    if ((*www*xxx* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1-
    if ((*http*sex* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1-
    if ((*http*xxx* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1-
    if ((*sex*www* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1-
    if ((*xxx*www* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1-
    if ((*sex*http* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1-
    if ((*xxx*http* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1
    if ((*porn*http* iswm %DLF.ptext) && (!$window($1))) PSpamFilter $1
  }
  if ((%DLF.searchresults == 1) && (%DLF.searchactive == 1)) {
    if (*Search Result*OmeNServE* iswm %DLF.ptext) FindHeaders $1-
    if (*OmeN*Search Result*ServE* iswm %DLF.ptext) FindHeaders $1-
    if (*Matches for*Copy and paste in channel* iswm %DLF.ptext) FindHeaders $1-
    if (*Total*files found* iswm %DLF.ptext) FindHeaders $1-
    if (*Search Results*QwIRC* iswm %DLF.ptext) FindHeaders $1-
    if (*Search Result*Too many files*Type* iswm %DLF.ptext) FindHeaders $1-
    if (*@Find Results*SysReset* iswm %DLF.ptext) FindHeaders $1-
    if (*End of @Find* iswm %DLF.ptext) FindHeaders $1-
    if (*I have*match*for*in listfile* iswm %DLF.ptext) FindHeaders $1-
    if (*SoftServe*Search result* iswm %DLF.ptext) FindHeaders $1-
    if (*Tengo*coincidencia* para* iswm %DLF.ptext) FindHeaders $1-
    if (*I have*match*for*Copy and Paste* iswm %DLF.ptext) FindHeaders $1-
    if (*Too many results*@* iswm %DLF.ptext) FindHeaders $1-
    if (*Tengo*resultado*slots* iswm %DLF.ptext) FindHeaders $1-
    if (*I have*matches for*You might want to get my list by typing* iswm %DLF.ptext) FindHeaders $1-
    if (*Résultat De Recherche*OmeNServE* iswm %DLF.ptext) FindHeaders $1-
    if (*Resultados De Busqueda*OmenServe* iswm %DLF.ptext) FindHeaders $1-
    if (*Total de*fichier*Trouvé* iswm %DLF.ptext) FindHeaders $1-
    if (*Fichier* Correspondant pour*Copie* iswm %DLF.ptext) FindHeaders $1-
    if (*Search Result*Matches For*Copy And Paste* iswm %DLF.ptext) FindHeaders $1-
    if (*Resultados de la búsqueda*DragonServe* iswm %DLF.ptext) FindHeaders $1-
    if (*Results for your search*DragonServe* iswm %DLF.ptext) FindHeaders $1-
    if (*«SoftServe»* iswm %DLF.ptext) FindHeaders $1-
    if (*search for*returned*results on list* iswm %DLF.ptext) FindHeaders $1-
    if (*List trigger:*Slots*Next Send*CPS in use*CPS Record* iswm %DLF.ptext) FindHeaders $1-
    if (*Searched*files and found*matching*To get a file, copy !* iswm %DLF.ptext) FindHeaders $1-
    if (*Note*Hey look at what i found!* iswm %DLF.ptext) FindHeaders $1-
    if (*Note*MP3-MP3* iswm %DLF.ptext) FindHeaders $1-
    if (*Search Result*Matches For*Get My List Of*Files By Typing @* iswm %DLF.ptext) FindHeaders $1-
    if (*Resultado Da Busca*Arquivos*Pegue A Minha Lista De*@* iswm %DLF.ptext) FindHeaders $1-
    if (*J'ai Trop de Résultats Correspondants*@* iswm %DLF.ptext) FindHeaders $1-
    if (*Search Results*Found*matches for*Type @*to download my list* iswm %DLF.ptext) FindHeaders $1-
    if (*I have found*file*for your query*Displaying* iswm %DLF.ptext) FindHeaders $1-
    if (*From list*found*displaying* iswm %DLF.ptext) FindHeaders $1-
    var %nick = $1
    tokenize 32 %DLF.ptext
    if ((*Omen* iswm $1) && ($chr(33) isin $2)) FindResults %nick $1-
    if ($pos($1,$chr(33),1) == 1) FindResults %nick $1-
    if (($1 == $chr(58)) && ($pos($2,$chr(33),1) == 1)) FindResults %nick $1-
  }
  if (%DLF.server == 1) {
    if (Sorry, I'm making a new list right now, please try later* iswm %DLF.ptext) FindHeaders $1-
    if (*Request Denied*OmeNServE* iswm %DLF.ptext) FindHeaders $1-
    if (*Sorry for cancelling this send*OmeNServE* iswm %DLF.ptext) FindHeaders $1-
    if (Lo Siento, no te puedo enviar mi lista ahora, intenta despues* iswm %DLF.ptext) FindHeaders $1-
    if (Lo siento, pero estoy creando una nueva lista ahora* iswm %DLF.ptext) FindHeaders $1-
    if (I have successfully sent you*OS* iswm %DLF.ptext) FindHeaders $1-
    if (*Petición rechazada*DragonServe* iswm %DLF.ptext) FindHeaders $1-
    if (*I don't have*Please check your spelling or get my newest list by typing @* in the channel* iswm %DLF.ptext) FindHeaders $1-
    if (*you already have*in my que*has NOT been added to my que* iswm %DLF.ptext) FindHeaders $1-
    if (*You already have*in my que*Type @*-help for more info* iswm %DLF.ptext) FindHeaders $1-
    if (*Request Denied*Reason: *DragonServe* iswm %DLF.ptext) FindHeaders $1-
    if (*You already have*requests in my queue*is not queued* iswm %DLF.ptext) FindHeaders $1-
    if (*Queue Status*File*Position*Waiting Time*OmeNServE* iswm %DLF.ptext) FindHeaders $1-
    if (*Empieza transferencia*IMPORTANTE*dccallow* iswm %DLF.ptext) FindHeaders $1-
    if (*Sorry, I'm too busy to send my list right now, please try later* iswm %DLF.ptext) FindHeaders $1-
    if (*Please standby for acknowledgement. I am using a secure query event* iswm %DLF.ptext) FindHeaders $1-
  }
  if (%DLF.away == 1) {
    if (*AFK, auto away after*minutes. Gone* iswm %DLF.ptext) PrivText $1-
    if (*Away*Reason*Auto Away* iswm %DLF.ptext) PrivText $1-
    if (*Away*Reason*Duration* iswm %DLF.ptext) PrivText $1-
    if (*Away*Reason*Gone for*Pager* iswm %DLF.ptext) PrivText $1-
    if (*^Auto-Thanker^* iswm %DLF.ptext) PrivText $1-
    if (*If i didn't know any better*I would have thought you were flooding me* iswm %DLF.ptext) PrivText $1-
    if (*Message's from strangers are Auto-Rejected* iswm %DLF.ptext) PrivText $1-
    if (*Dacia Script v1.2* iswm %DLF.ptext) PrivText $1-
    if (*Away*SysReset* iswm %DLF.ptext) PrivText $1-
    if (*automated msg* iswm %DLF.ptext) PrivText $1-
  }
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.privtext)) {
    var %nr = $numtok(%DLF.custom.privtext,44)
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.privtext,%cnter,44) iswm %DLF.ptext) {
        PrivText $1-
      }
      inc %cnter
    }
  }
}
alias PrivText {
  if ($window($1)) .window -c $1
  DLF_TextFilter Private $1-
  halt
}
on ^*:notice:*:#: {
  if (%DLF.o.enabled == 1) {
    var %DLF.o.chan = $chan
    var %DLF.o.target = @ $+ $chan
    if ($target == %DLF.o.target) {
      if (($nick isop %DLF.o.chan) && ($me isop %DLF.o.chan)) {
        if ($1 != @) var %omsg = $1-
        if ($1 == @) var %omsg = $2-
        if ($gettok(%omsg,1,32) != /me) {
          var %chatwindow = @ $+ %DLF.o.chan
          if (!$window(%chatwindow)) {
            window -eg1k1l12mnSw %chatwindow
            if ((%DLF.o.log == 1) && ($exists($+(",$logdir,%chatwindow,.log,")))) {
              write $+(",$logdir,%chatwindow,.log,") $crlf
              write $+(",$logdir,%chatwindow,.log,") $+($chr(91) $+ $fulldate $+ $chr(93),$chr(32) ----- Session started -----)
              write $+(",$logdir,%chatwindow,.log,") $crlf
              .loadbuf -r %chatwindow $+(",$logdir,%chatwindow,.log,")
            }
          }
          var %omsg = < $+ $nick $+ > $+ $chr(32) $+ %omsg
          if (%DLF.o.timestamp == 1) var %omsg = $timestamp $+ $chr(32) $+ %omsg
          aline -nl $color(nicklist) %chatwindow $nick
          window -S %chatwindow
          aline -ph $color(text) %chatwindow %omsg
          if (%DLF.o.log == 1) write $+(",$logdir,%chatwindow,.log,") %omsg
          halt
        }
        else {
          %omsg = $gettok(%omsg,2-,32)
          var %chatwindow = @ $+ %DLF.o.chan
          if (!$window(%chatwindow)) window -eg1k1l12mnSw %chatwindow
          var %omsg = $chr(42) $+ $chr(32) $+ $nick $+ $chr(32) $+ %omsg
          if (%DLF.o.timestamp == 1) var %omsg = $timestamp $+ $chr(32) $+ %omsg
          aline -nl $color(nicklist) %chatwindow $nick
          window -S %chatwindow
          aline -ph $color(action) %chatwindow %omsg
          if (%DLF.o.log == 1) write $+(",$logdir,%chatwindow,.log,") %omsg
          halt
        }
        halt
      }
    }
  }
  if ($istok(%dlf.channels,$chan,44)) {
    if ((%DLF.custom.enabled == 1) && (%DLF.custom.channotice)) {
      var %nr = $numtok(%DLF.custom.channotice,44)
      var %cnter = 1
      while (%cnter <= %nr) {
        if ($gettok(%DLF.custom.channotice,%cnter,44) iswm $strip($1-)) DLF_textfilter $chan $nick $1-
        inc %cnter
      }
    }
    if (%DLF.chspam == 1) {
      if (*WWW.TURKSMSBOT.CJB.NET* iswm $1-) DLFSpamFilter $chan $nick $1-
      if (*free-download* iswm $1-) DLFSpamFilter $chan $nick $1-
    }
  }
}
on *:input:@#* {
  if ((/ == $left($1,1)) && ($ctrlenter == $false) && ($1 != /me)) return
  if (($1 != /me) || ($ctrlenter == $true)) {
    var %omsg = < $+ $me $+ > $+ $chr(32) $+ $1-
    if (%DLF.o.timestamp == 1) var %omsg = $timestamp $+ $chr(32) $+ %omsg
    aline -p $color(text) $active %omsg
    aline -nl $color(nicklist) $active $me
    window -S $active
    var %ochan = $replace($active,@,$null)
    .onotice %ochan $1-
    if (%DLF.o.log == 1) write $+(",$logdir,$active,.log") %omsg
  }
  else {
    var %omsg = $chr(42) $+ $chr(32) $+ $me $+ $chr(32) $+ $2-
    if (%DLF.o.timestamp == 1) var %omsg = $timestamp $+ $chr(32) $+ %omsg
    aline -p $color(action) $active %omsg
    aline -nl $color(nicklist) $active $me
    window -S $active
    var %ochan = $replace($active,@,$null)
    .onotice %ochan $1-
    if (%DLF.o.log == 1) write $+(",$logdir,$active,.log") %omsg
    halt
  }
}

on *:close:@#*: {
  var %chatwindow = $target
  if ((%DLF.o.log == 1) && ($exists($+(",$logdir,%chatwindow,.log,")))) {
    write $+(",$logdir,%chatwindow,.log,") $crlf
    write $+(",$logdir,%chatwindow,.log,") $+($chr(91) $+ $fulldate $+ $chr(93),$chr(32) ----- Session closed -----)
    write $+(",$logdir,%chatwindow,.log,") $crlf
  }
}

alias ServerFilter {
  var %line = $chr(60) $+ $1 $+ $chr(62) $+ $chr(32) $+ $2-
  if ($2 == $chr(58)) %line = $remtok(%line,$chr(58),1,32)
  if (%DLF.server.log == 1) write $+(",$logdir,DLF.Server,.log,") $+($chr(91),$fulldate,$chr(93)) $+ $chr(32) $+ $strip(%line)
  if (!$window(@DLF.Server)) {
    window -k0nwz @DLF.Server
    titlebar @DLF.Server -=- Right-click for options
  }
  if ((%DLF.server.limit == 1) && ($line(@DLF.Server,0) >= 5000)) dline @DLF.Server 1-100
  if (%DLF.server.timestamp == 1) %line = $timestamp $+ $chr(32) $+ %line
  if (%DLF.server.strip == 1) %line = $strip(%line)
  if (%DLF.server.wrap == 1) aline -p @DLF.Server %line
  else aline @DLF.Server %line
  halt
}
on *:input:@DLF.Server.Search: ServerSearch $1-
alias ServerSearch {
  window -ealbk0wz @DLF.Server.Search
  var %sstring = $chr(42) $+ $1- $+ $chr(42)
  titlebar @DLF.server.search -=- Searching for %sstring
  filter -wwbpc @DLF.server @DLF.server.search %sstring
  if ($line(@DLF.server.search,0) == 0) titlebar @DLF.server.search -=- Search finished. No matches for " $+ %sstring $+ " found.
  else titlebar @DLF.server.search -=- Search finished. $line(@DLF.server.search,0) matches found for " $+ %sstring $+ ".
}
alias newRfilter {
  var %line = $strip($2-)
  %line = $remove(%line,+++ N e w release +++,to download this ebook.)
  %line = $remove(%line,-=NEW=-)
  %line = $mid(%line,$calc($pos(%line,!,1) - 1),$len(%line))
  if (!$window(@DLF.NewReleases)) {
    window -lbsk0nwz @DLF.NewReleases
    titlebar @DLF.NewReleases -=- Right-click for options
  }
  aline -n @DLF.NewReleases %line
  window -b @DLF.NewReleases
  haltdef
  halt
}
alias DLFSpamFilter {
  if ((%DLF.chspam.opnotify == 1) && ($me isop $1)) {
    echo -s 1,9[DLFilter] Spam detected:4,15 $chr(32) $+ $chr(91) $+ $1 $+ $chr(93) $+ $chr(32) $+ $chr(60) $+ $2 $+ $chr(62) $+ $chr(32) $+ ( $+ $address($2,1) $+ ) $+ $chr(32) $+ -->> $+ $chr(32) $+ 4 $$3-
    echo $1 1,9[DLFilter] Spam detected:4,15 $chr(32) $+ $chr(91) $+ $1 $+ $chr(93) $+ $chr(32) $+ $chr(60) $+ $2 $+ $chr(62) $+ $chr(32) $+ ( $+ $address($2,1) $+ ) $+ $chr(32) $+ -->> $+ $chr(32) $+ 4 $$3-
  }
  haltdef
  halt
}
alias PSpamFilter {
  if ((%DLF.privspam.opnotify == 1) && ($comchan($1,1).op)) {
    echo -s 1,9[DLFilter] Spam detected:4,15 $chr(32) $+ $chr(60) $+ $1 $+ $chr(62) $+ $chr(32) $+ ( $+ $address($1,1) $+ ) $+ $chr(32) $+ -->> $+ $chr(32) $+ 4 $$2-
    echo $comchan($1,1) 1,9[DLFilter] Spam detected:4,15 $chr(32) $+ $chr(60) $+ $1 $+ $chr(62) $+ $chr(32) $+ ( $+ $address($1,1) $+ ) $+ $chr(32) $+ -->> $+ $chr(32) $+ 4 $$2-
  }
  if ((%DLF.spam.addignore == 1) && ($input(Spam received from $1 ( $+ $address($1,1) $+ ). Spam was: " $+ $2- $+ ". Add this user to ignore for one hour?,yq,Add spammer to /ignore?) == $true)) /ignore -wu3600 $1 4
  if ($window($1)) .window -c $1
  halt
}
on *:input:%DLF.channels: {
  if (($1 == @find) || ($1 == @locator)) {
    .set -u600 %DLF.searchactive 1
  }
}
on ^*:notice:*:?: {
  if (%DLF.enabled == 0) goto nnotenabled
  var %DLF.ptext = $strip($1-)
  DoCheckComChan $nick %DLF.ptext
  if ((%DLF.noregmsg == 1) && ($CheckRegular($nick) == IsRegular)) {
    echo -s 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to:4,15 $1-
    echo -a 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to:4,15 $1-
    haltdef
    halt
  }
  if (%DLF.server == 1) {
    var %DLF.pnotice = $strip($1-)
    if (*I have added* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*After waiting*min* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*This makes*times* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*is on the way!* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*has been sent sucessfully* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*send will be initiated as soon as possible* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*«SoftServe»* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*You are the successful downloader number* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*You are in* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Request Denied* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*OmeNServE v* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*«OmeN»* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*is not found* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*file not located* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*I don't have the file* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*is on its way* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*±* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Transfer Started*File* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*is on it's way!* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Requested File's* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Please make a resume request!* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*File Transfer of* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Please reinitiate File-transfer!* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*on its way* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*OS-Limits* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Transfer Complete*I have successfully sent*QwIRC iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Request Accepted*File*Queue position* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Le Transfert de*Est Completé* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Query refused*in*seconds* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Keeptrack*omen* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*U Got A File From Me*files since* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Transfer Complete*sent* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Transmision de*finalizada* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Send Failed*at*Please make a resume request* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*t×PLåY* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*OS-Limites V*t×PLåY* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*rßPLåY2* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (Request Accepted*Has Been Placed In The Priority Queue At Position* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*esta en camino!* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Envio cancelado* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*de mi lista de espera* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Después de esperar*min* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*veces que he enviado* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*archivos, Disfrutalo* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (Thank you for*.*! iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*veces que env* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*zip va en camino* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Enviando*(*)* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Unable to locate any files with*associated within them* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Has Been Placed In The Priority Queue At Position*Omenserve* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Thanks*for sharing*with me* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*«[RDC]»* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Your send of*was successfully completed* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*AFK, auto away after*minutes* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Envío completo*DragonServe* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Empieza transferencia*DragonServe* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Ahora has recibido*DragonServe* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Starting Transfer*DragonServe* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*You have now received*from me*for a total of*sent since* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Thanks For File*It is File*That I have recieved* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Thank You*I have now received*file*from you*for a total of* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*You Are Downloader Number*Overall Downloader Number* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*DCC Get of*FAILED Please Re-Send file* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*request for*acknowledged*send will be initiated as soon as possible* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*file not located* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*t×PLÅY* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*I'm currently away*your message has been logged* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*If your message is urgent, you may page me by typing*PAGE* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Gracias*Ahora he recibido*DragonServe* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Request Accepted*List Has Been Placed In The Priority Queue At Position* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Send Complete*File*Sent*times* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Sent*Files Allowed per day*User Class*BWI-Limits* iswm %DLF.pnotice) ServerFilter $nick $1-
    if (*Now I have received*DragonServe* iswm %DLF.pnotice) ServerFilter $nick $1-
  }
  if (*SLOTS My mom always told me not to talk to strangers* iswm %DLF.pnotice) DLF_textfilter Notice $nick $1-
  if (*CTCP flood detected, protection enabled* iswm %DLF.pnotice) DLF_textfilter Notice $nick $1-
  if ((%DLF.searchresults == 1) && (%DLF.searchactive == 1)) {
    if (No match found for* iswm %DLF.ptext) ServerFilter $nick $1-
    if (*I have*match* for*in listfile* iswm %DLF.ptext) ServerFilter $nick $1-
    tokenize 32 %DLF.ptext
    if ($pos($1,$chr(33),1) == 1) FindResults $nick $1-
  }
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.privnotice)) {
    var %nr = $numtok(%DLF.custom.privnotice,44)
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.privnotice,%cnter,44) iswm $strip($1-)) DLF_textfilter Private $nick $1-
      inc %cnter
    }
  }
  :nnotenabled
}
alias FindHeaders {
  if (($window($1)) && (!$line($1,0))) .window -c $1
  ServerFilter $1-
  halt
}
alias FindResults {
  if (($window($1)) && (!$line($1,0))) .window -c $1
  if (!$window(@DLF.@find.Results)) window -slk0wnz @DLF.@find.Results
  var %line = $right($2-,$calc($len($2-) - ($pos($2-,$chr(33),1) - 1)))
  aline -n @DLF.@find.Results %line
  window -b @DLF.@find.Results
  titlebar @DLF.@find.Results -=- $line(@DLF.@find.Results,0) results so far -=- Right-click for options
  halt
}
on ^*:action:*:?: {
  if (%DLF.enabled == 0) got anotenabled
  DoCheckComChan $nick $1-
  if ((%DLF.noregmsg == 1) && ($CheckRegular($nick) == IsRegular)) {
    echo -s 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to:4,15 $1-
    echo -a 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to:4,15 $1-
    .window -c $1
    .close -m $1
    haltdef
    halt
  }
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.privaction)) {
    var %nr = $numtok(%DLF.custom.privaction,44)
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.privaction,%cnter,44) iswm $strip($1-)) DLF_actionfilter Private $nick $1-
      inc %cnter
    }
  }
  :anotenabled
}
alias DoCheckComChan {
  if ((%DLF.accepthis == $1) && (%DLF.nocomchan.dcc == 1)) {
    .unset %DLF.accepthis
    goto networkservs
  }
  if ((!$comchan($1,1)) && (%DLF.nocomchan == 1)) {
    if (($1 == X) || ($1 == ChanServ) || ($1 == NickServ) || ($1 == MemoServ) || ($1 == Global)) goto networkservs
    if (($window($1)) && (!$line($1,0))) {
      echo -s 1,9[DLFilter] $1 (no common channel) tried:4,15 $2-
      .window -c $1
    }
    if (($window($chr(61) $+ $1)) && (%DLF.nocomchan.dcc == 0)) {
      .window -c $chr(61) $+ $1
    }
    halt
  }
  :networkservs
}
alias CheckRegular {
  var %rcnter = 1
  var %rmax = $comchan($1,0)
  while (%rcnter <= %rmax) {
    if (($1 isop $comchan($1,%rcnter)) || ($1 isvoice $comchan($1,%rcnter))) return $comchan($1,%rcnter)
    inc %rcnter
  }
  return IsRegular
}
alias GetFileName {
  var %file = $1-
  var %Filetypes = .mp3;.wma;.mpg;.mpeg;.zip;.bz2;.txt;.exe;.rar;.tar;.jpg;.gif;.wav;.aac;.asf;.vqf;.avi;.mov;.mp2;.m3u;.kar;.nfo;.sfv;.m2v;.iso;.vcd;.doc;.lit;.pdf;.r00;.r01;.r02;.r03;.r04;.r05;.r06;.r07;.r08;.r09;.r10;.shn;.md5;.html;.htm;.jpeg;.ace;.png;.c01;.c02;.c03;.c04;.rtf;.wri;.txt
  tokenize 32 $replace($1-,$chr(160),$chr(32))
  var %Temp.Count = 1
  while (%Temp.Count <= $numtok($1-,46)) {
    var %Temp.Position = $pos($1-,.,%Temp.Count)
    var %Temp.Filetype = $mid($1-,%Temp.Position,5)
    var %Temp.Length = $len(%Temp.Filetype)
    if ($istok(%Filetypes,%Temp.Filetype,59)) { return $left($1-,$calc(%Temp.Position + %Temp.Length)) }
    inc %Temp.Count
  }
  if ($pos(%file,.,0) == 2) return $mid(%file,1,$calc($pos(%file,.,1) + 4))
  return $1-
}
on *:CTCPREPLY:*SLOTS*: {
  haltdef
  halt
}
on *:CTCPREPLY:*ERRMSG*: {
  haltdef
  halt
}
on *:CTCPREPLY:*MP3*: {
  haltdef
  halt
}
on *:CTCPREPLY:*: {
  if (%DLF.nocomchan == 1) DoCheckComChan $nick $1-
  if ((%DLF.noregmsg == 1) && (($CheckRegular($nick) == IsRegular)) && (DCC send !isin $1-)) {
    echo -s 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to:4,15 $1-
    echo -a 1,9[DLFilter] Regular user $nick ( $+ $address $+ ) tried to:4,15 $1-
    haltdef
    halt
  }
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.privctcp)) {
    var %nr = $numtok(%DLF.custom.privctcp,44)
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.privctcp,%cnter,44) iswm $1-) DLF_textfilter Private $nick $1-
      inc %cnter
    }
  }
}
alias DLFSetNickColor {
  if ($nick($1,$2).color == $color(nicklist)) cline 2 $1 $2
}
alias CheckOpStatus {
  if ($me isop $1) && ($1 isin %DLF.channels) && (%DLF.o.enabled == 1) return 1
  else if ($me isop $1) && (%DLF.channels == $chr(35)) && (%DLF.o.enabled == 1) return 1
  else return 0
}
on *:connect: {
  DLF.update
  :error
}
alias DLF.update { sockopen dlf dukelupus.com 80 }
on *:sockopen:dlf: {
  if ($sockerr > 0) {
    if ($dialog(DLFilter_GUI)) did -o DLFilter_GUI 56 1 Connection to DLFilter website failed!
    else echo -s 4,15[DLFilter]2,15 Connection to DLFilter website failed!
    .sockclose dlf
    halt
  }
  sockwrite -n $sockname GET /versions.txt HTTP/1.1
  sockwrite -n $sockname Host: dukelupus.com $+ $crlf $+ $crlf
}
on *:sockread:dlf: {
  if ($sockerr > 0) {
    if ($dialog(DLFilter_GUI)) did -o DLFilter_GUI 56 1 Connection to DLFilter website failed!
    else echo -s 4,15[DLFilter]2,15 Connection to DLFilter website failed!
    .sockclose dlf
    halt
  }
  else {
    var %t
    sockread %t
    if (($gettok(%t,1,59) == DLFilter) && ($gettok(%t,2,59) > $Set.DLF.version)) {
      if ($dialog(DLFilter_GUI)) did -o DLFilter_GUI 56 1 You should update! Version $gettok(%t,2,59) is available!
      else echo -a 4,15[DLFilter]2,15 You should update DLFilter. You are using $Set.DLF.version $+ , but version $gettok(%t,2,59) is available from DLFilter website at 12http://dukelupus.com
      .sockclose dlf
    }
    elseif (($gettok(%t,1,59) == DLFilter) && ($gettok(%t,2,59) == $Set.DLF.version)) {
      if ($dialog(DLFilter_GUI)) did -o DLFilter_GUI 56 1 You have current version of DLFilter
  ;;     else echo -a 4,15[DLFilter]2,15 You have current version of DLFilter
      .sockclose dlf
    }
    if (($gettok(%t,1,59) == DLFilter) && ($gettok(%t,2,59) < $Set.DLF.version)) {
      if ($dialog(DLFilter_GUI)) did -o DLFilter_GUI 56 1 You have newer version then website
;;      else echo -a 4,15[DLFilter]2,15 You have newer version then website
      .sockclose dlf
    }
  }
}
alias DLF.debug {
  write -i DLFilter.debug.txt
  write -i DLFilter.debug.txt
  echo 14 -s [DLFilter] Debug started.
  echo 14 -s [DLFilter] Creating DLFilter.debug.txt
  write DLFilter.debug.txt --- $fulldate ---
  write -i DLFilter.debug.txt
  write DLFilter.debug.txt Executing $script from $scriptdir
  write DLFilter.debug.txt DLFilter version %DLF.version
  write DLFilter.debug.txt mIRC version $version
  write DLFilter.debug.txt Running Windows $os
  write DLFilter.debug.txt Nick: $me
  write DLFilter.debug.txt Host: $host
  write DLFilter.debug.txt IP: $ip
  write DLFilter.debug.txt Connected to $server $+ , port $port
  write -i DLFilter.debug.txt
  write -i DLFilter.debug.txt
  write DLFilter.debug.txt --- Scripts ---
  write -i DLFilter.debug.txt
  var %scripts = $script(0)
  echo 14 -s [DLFilter] %scripts scripts loaded
  write DLFilter.debug.txt %scripts scripts loaded
  var %cnter = 1
  while (%cnter <= %scripts) {
    write DLFilter.debug.txt Script %cnter is $script(%cnter)
    echo 14 -s [DLFilter] Script %cnter is $script(%cnter)
    write DLFilter.debug.txt $script(%cnter) is $lines($script(%cnter)) lines and $file($script(%cnter)).size bytes
    inc %cnter
  }
  echo 14 -s [DLFilter] Checking variables
  write -i DLFilter.debug.txt
  write -i DLFilter.debug.txt
  write DLFilter.debug.txt --- DLFilter Variables ---
  write -i DLFilter.debug.txt
  saveini
  var %lines = $ini(remote.ini,variables,0) - 1
  var %Dlfvariables = 0
  var %cnter = 0
  while (%cnter <= %lines) {
    var %line = $readini(remote.ini,n,variables,n $+ %cnter)
    if (DLF isin %line) {
      write DLFilter.debug.txt %line
      inc %Dlfvariables
    }
    inc %cnter
  }
  write -i DLFilter.debug.txt
  echo 14 -s [DLFilter] Found %lines variables, $calc(%Dlfvariables - 1) of them are DLFilter variables.
  write DLFilter.debug.txt Found %lines variables, $calc(%Dlfvariables - 1) of them are DLFilter variables.
  write -i DLFilter.debug.txt
  write -i DLFilter.debug.txt
  write DLFilter.debug.txt --- Groups ---
  write -i DLFilter.debug.txt
  echo 14 -s [DLFilter] $group(0) group(s) found
  write DLFilter.debug.txt $group(0) group(s) found
  var %grps = $group(0)
  var %cnter = 1
  while (%cnter <= %grps) {
    echo 14 -s [DLFilter] Group %cnter $+ : $group(%cnter) is from $group(%cnter).fname $+ . Status: $group(%cnter).status
    write DLFilter.debug.txt Group %cnter $+ : $group(%cnter) is from $group(%cnter).fname $+ . Status: $group(%cnter).status
    inc %cnter
  }
  write -i DLFilter.debug.txt
  write -i DLFilter.debug.txt
  write DLFilter.debug.txt --- Hash tables ---
  write -i DLFilter.debug.txt
  echo 14 -s [DLFilter] $hget(0) hash table(s) found
  write DLFilter.debug.txt $hget(0) hash table(s) found
  var %hs = $hget(0)
  var %cnter = 1
  while (%cnter <= %hs) {
    echo 14 -s [DLFilter] Table %cnter $+ : $hget(%cnter) $+ , size $hget(%cnter).size
    write DLFilter.debug.txt Table %cnter $+ : $hget(%cnter) $+ , size $hget(%cnter).size
    inc %cnter
  }
  write -i DLFilter.debug.txt
  write DLFilter.debug.txt --- End of debug info ---
}
raw 301:*: {
  if (%DLF.away == 1) DLF_TextFilter RawAway $2-
  haltdef
}
