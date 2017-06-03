/*
DLFilter.mrc - Filter out messages on file sharing channels
Authors: DukeLupus with recent updates by Sophist

Annoyed by advertising messages from the various file serving bots?
Fed up with endless channel messages by other users searching for and requesting files?
Are the responses to your own requests getting lost in the crowd?

This script filters out the crud, leaving only the useful messages displayed in the channel.
By default, the filtered messages are thrown away, but you can direct them to custom windows if you wish.

Download from: http://dukelupus.com/dlfilter
or https://raw.githubusercontent.com/SanderSade/dlFilter/master/dlFilter.mrc
Update regularly to handle new forms of message.

To load: use /load -rs DLFilter.mrc

Note that DLFilter loads itself automatically as a first script.
This avoids problems where other scripts halt events preventing this scripts events from running.
*/

/* CHANGE LOG
  1.17  Update opening comments and add change log
        Use custom identifiers for creating bold, colour etc.
        Use custom identifiers instead of $chr(xx)
        Use alias for status messages
        Hash tables for message matching
        Options dialog improvements
          Layout
          Enable / disable now global
          Custom filter Add / Remove button enable / disable
          Custom filter list multi-select
*/

alias DLF.SetVersion {
  %DLF.version = 1.17
  return %DLF.version
}

; ========== Initialisation / Termination ==========
alias DLF.init {
  if ($version < 6) {
    DLF.Error DLFilter requires mIRC 6+. Loading stopped.
    .unload -rs $script
  }
  if ($script(onotice.mrc)) .unload -rs onotice.mrc
  if ($script(onotice.txt)) .unload -rs onotice.txt
  ; Initialise hashtables
  DLF.SetHashTables
}

on *:start: {
  DLF.init
  ; Reload script if needed to be first to execute
  if ($script != $script(1)) .reload -rs1 $qt($script)
}

on *:load: {
  DLF.init
  ; Reload script if needed to be first to execute
  if ($script != $script(1)) .load -rs1 $qt($script)

  ; Announce ourself
  DLF.Status Loading $c(4,$+(version,$space,$DLF.SetVersion)) by DukeLupus
  DLF.Status Please check DLFilter homepage $br($c(12,9,$u(http://dukelupus.com/dlfilter))) for help.

  ; Initialise variables
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
  if (%DLF.custom.chantext == $null) {
    %DLF.custom.chantext = $addtok(%DLF.custom.chantext,*bonga*,$asc($comma))
    %DLF.custom.chantext = $addtok(%DLF.custom.chantext,*agnob*,$asc($comma))
    %DLF.custom.chantext = $addtok(%DLF.custom.chantext,*meep*,$asc($comma))
  }
  if (%DLF.channels == $null) {
    DLF.Status Setting channels to $c(4,all) $+ .
    %DLF.channels = #
    DLF.Options.Show
  }
  DLF.Status Loading complete.
  return

  :error
  DLF.Error During load: $qt($error)
}

ctcp *:VERSION: .ctcpreply $nick VERSION $c(1,9,$logo version $DLF.SetVersion by DukeLupus.) $c(1,15,Get it from $c(12,15,$u(http://dukelupus.com/dlfilter)))

on *:unload: {
  DLF.Status Unloading $c(4,9,version $DLF.SetVersion) by DukeLupus.
  DLF.Status Unsetting variables..
  .unset %DLF.*
  DLF.Status Closing open DLFilter windows
  if ($dialog(DLF.Options.GUI)) .dialog -x DLF.Options.GUI DLF.Options.GUI
  if ($window(@DLF.filtered)) window -c @DLF.filtered
  if ($window(@DLF.filtered.search)) window -c @DLF.filtered.search
  if ($window(@DLF.server)) window -c @DLF.server
  if ($window(@DLF.server.search)) window -c @DLF.server.search
  if ($window(@DLF.@find.results)) window -c @DLF.@find.results
  close -@ @#*
  DLF.Status Unloading complete. $crlf
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
  ..Options: dialog -md DLF.Options.GUI DLF.Options.GUI
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
  .Options: dialog -md DLF.Options.GUI DLF.Options.GUI
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
  Options: dialog -md DLF.Options.GUI DLF.Options.GUI
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
  Options: dialog -md DLF.Options.GUI DLF.Options.GUI
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
  Options: dialog -md DLF.Options.GUI DLF.Options.GUI
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
  Options: dialog -md DLF.Options.GUI DLF.Options.GUI
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
  Options: dialog -md DLF.Options.GUI DLF.Options.GUI
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
; ========== DLF Options Dialog ==========
alias DLF.Options.Show dialog $iif($dialog(DLF.Options.GUI),-v,-md) DLF.Options.GUI DLF.Options.GUI

dialog DLF.Options.GUI {
  ; Main dialogue
  title DLFilter v $+ $DLF.SetVersion
  size -1 -1 152 225
  option dbu notheme
  check "Enable/disable DLFilter", 5, 2 2 66 8
  tab "Main", 1, 1 10 151 196, disable
  tab "Capturing/Spam/Security", 2, disable
  tab "Custom", 3, disable
  button "Close", 4, 2 211 43 11, ok
  check "Show/hide filtered lines", 21, 47 211 103 11, push
  ; tab 1 Main
  text "Channels (comma separated, use # for all):", 7, 6 27 125 8, tab 1
  edit "", 6, 5 35 144 10, tab 1 autohs %DLF.channels
  box " Filters ", 8, 4 46 144 47, tab 1
  check "Ads and announcements", 9, 7 55 80 8, tab 1
  check "Requests and searches", 10, 7 64 69 8, tab 1
  check "Channel mode changes", 17, 7 73 75 8, tab 1
  check "Requests sent to you in pm (@yournick, !yournick)", 33, 7 82 133 8, tab 1
  box " User events ", 11, 4 96 144 84, tab 1
  check "Joins", 12, 7 105 50 9, tab 1
  check "Parts", 13, 7 114 50 9, tab 1
  check "Quits", 14, 7 123 50 9, tab 1
  check "Nick changes", 15, 7 132 50 9, tab 1
  check "Kicks", 16, 7 141 50 9, tab 1
  check "... but show them in Status window.", 18, 15 150 95 9, tab 1
  check "Away and thank-you messages", 19, 7 159 95 9, tab 1
  check "User mode changes", 20, 7 168 62 9, tab 1
  text "Checking for DLFilter updates...", 56, 5 182 144 8, tab 1
  button "DLFilter website", 67, 4 191 70 12, tab 1 flat
  button "Direct download", 66, 78 191 70 12, tab 1 flat
  ; Tab 2 Capturing / Spam / Security
  box " Capturing ", 22, 4 25 144 50, tab 2
  check "Capture server notices to separate window", 23, 7 35 120 8, tab 2
  check "Group @find/@locator results", 24, 7 44 118 8, tab 2
  check "Capture 'New Release' to separate window", 25, 7 53 123 8, tab 2
  check "Capture onotices to separate @#window (OpsTalk)", 61, 7 62 132 8, tab 2
  box " Spam and security ", 26, 4 79 145 115, tab 2
  check "Filter spam on channel", 27, 7 88 87 8, tab 2
  check "Notify, if you are an op", 28, 15 97 72 8, tab 2
  check "Filter private spam", 29, 7 106 58 8, tab 2
  check "Notify, if you are an op in common channel", 30, 15 115 117 8, tab 2
  check "Add spammer to /ignore for 1h (asks confirmation)", 31, 15 124 130 8, tab 2
  check "Don't accept any messages or files from users with whom you do not have a common channel", 32, 7 132 136 16, tab 2 multi
  check "... but accept DCC chats", 72, 15 148 86 8, tab 2
  check "Do not accept files from regular users (except mIRC trusted users)", 34, 7 157 115 16, tab 2 multi
  check "... block only potentially dangerous filetypes", 75, 15 173 127 8, tab 2
  check "Do not accept private messages from regulars", 35, 7 182 135 8, tab 2
  check "Color uncolored fileservers", 62, 4 196 138 8, tab 2
  ; tab 3 Custom
  check "Enable custom strings", 36, 5 27 100 8, tab 3
  text "Message type:", 42, 5 36 50 8, tab 3
  combo 37, 45 36 65 35, tab 3 drop
  edit "", 41, 4 47 144 12, tab 3 autohs
  button "Add", 46, 5 61 67 12, tab 3 flat disable
  button "Remove", 52, 79 61 68 12, tab 3 flat disable
  list 51, 4 74 144 123, tab 3 hsbar vsbar size sort extsel
}

on *:dialog:DLF.Options.GUI:init:0: {
  DLF.SetVersion
  did -o DLF.Options.GUI 6 1 %DLF.Channels
  if (%DLF.enabled == 1) did -c DLF.Options.GUI 5
  if (%DLF.ads == 1) did -c DLF.Options.GUI 9
  if (%DLF.requests == 1) did -c DLF.Options.GUI 10
  if (%DLF.joins == 1) did -c DLF.Options.GUI 12
  if (%DLF.parts == 1) did -c DLF.Options.GUI 13
  if (%DLF.quits == 1) did -c DLF.Options.GUI 14
  if (%DLF.nicks == 1) did -c DLF.Options.GUI 15
  if (%DLF.kicks == 1) did -c DLF.Options.GUI 16
  if (%DLF.chmode == 1) did -c DLF.Options.GUI 17
  if (%DLF.showstatus == 1) did -c DLF.Options.GUI 18
  if (%DLF.away == 1) did -c DLF.Options.GUI 19
  if (%DLF.usrmode == 1) did -c DLF.Options.GUI 20
  if (%DLF.privrequests == 1) did -c DLF.Options.GUI 33
  if (%DLF.showfiltered == 1) did -c DLF.Options.GUI 21
  if (%DLF.server == 1) did -c DLF.Options.GUI 23
  if (%DLF.searchresults == 1) did -c DLF.Options.GUI 24
  if (%DLF.newreleases == 1) did -c DLF.Options.GUI 25
  if (%DLF.chspam == 1) did -c DLF.Options.GUI 27
  if (%DLF.chspam.opnotify == 1) did -c DLF.Options.GUI 28
  if (%DLF.privspam == 1) did -c DLF.Options.GUI 29
  if (%DLF.privspam.opnotify == 1) did -c DLF.Options.GUI 30
  if (%DLF.spam.addignore == 1) did -c DLF.Options.GUI 31
  if (%DLF.nocomchan == 1) did -c DLF.Options.GUI 32
  if (%DLF.nocomchan.dcc == 1) did -c DLF.Options.GUI 72
  if (%DLF.askregfile.type == 1) {
    did -c DLF.Options.GUI 75
    %DLF.askregfile = 1
  }
  if (%DLF.askregfile == 1) did -c DLF.Options.GUI 34
  else %DLF.askregfile.type = 0
  if (%DLF.noregmsg == 1) did -c DLF.Options.GUI 35
  if (%DLF.colornicks == 1) did -c DLF.Options.GUI 62
  if (%DLF.o.enabled == 1) did -c DLF.Options.GUI 61
  if (%DLF.custom.enabled == 1) did -c DLF.Options.GUI 36
  did -a DLF.Options.GUI 37 Channel text
  did -a DLF.Options.GUI 37 Channel action
  did -a DLF.Options.GUI 37 Channel notice
  did -a DLF.Options.GUI 37 Channel ctcp
  did -a DLF.Options.GUI 37 Private text
  did -a DLF.Options.GUI 37 Private action
  did -a DLF.Options.GUI 37 Private notice
  did -a DLF.Options.GUI 37 Private ctcp
  did -c DLF.Options.GUI 37 1
  didtok DLF.Options.GUI 51 44 %DLF.custom.chantext
  %DLF.custom.selected = Channel text
  DLF.Update
}

; Change enabled state
on *:dialog:DLF.Options.GUI:sclick:5: DLF.Options.setEnabledState

alias DLF.Options.setEnabledState {
  %DLF.enabled = $did(5).state
  if (%DLF.enabled) .enable #dlf_enabled
  else .disable #dlf_enabled
}

; Close button click
on *:dialog:DLF.Options.GUI:sclick:4: {
  DLF.Options.setEnabledState
  %DLF.Channels = $did(6).text
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

; Show / hide filtered messages check box
on *:dialog:DLF.Options.GUI:sclick:21: {
  %DLF.showfiltered = $did(21).state
  if (%DLF.showfiltered == 0) window -c @DLF.filtered
}

; Do not accept files from regular users checkbox
on *:dialog:DLF.Options.GUI:sclick:34: {
  if (($did(34).state == 0) && ($did(75).state == 1)) did -u DLF.Options.GUI 75
}

; Block only potentially dangerous filetypes checkbox
on *:dialog:DLF.Options.GUI:sclick:75: {
  if ($did(75).state == 1) {
    %DLF.askregfile = 1
    did -c DLF.Options.GUI 34
  }
  else %DLF.askregfile = 0
}

; Select custom message type
on *:dialog:DLF.Options.GUI:sclick:37: {
  %DLF.custom.selected = $did(37).seltext
  DLF.Options.SetCustomType $did(37).seltext
}

alias DLF.Options.SetCustomType {
  did -r DLF.Options.GUI 51
  if ($1- == Channel text) didtok DLF.Options.GUI 51 44 %DLF.custom.chantext
  if ($1- == Channel action) didtok DLF.Options.GUI 51 44 %DLF.custom.chanaction
  if ($1- == Channel notice) didtok DLF.Options.GUI 51 44 %DLF.custom.channotice
  if ($1- == Channel ctcp) didtok DLF.Options.GUI 51 44 %DLF.custom.chanctcp
  if ($1- == Private text) didtok DLF.Options.GUI 51 44 %DLF.custom.privtext
  if ($1- == Private action) didtok DLF.Options.GUI 51 44 %DLF.custom.privaction
  if ($1- == Private notice) didtok DLF.Options.GUI 51 44 %DLF.custom.privnotice
  if ($1- == Private ctcp) didtok DLF.Options.GUI 51 44 %DLF.custom.privctcp
}

; Enable / disable Add custom message button
on *:dialog:DLF.Options.GUI:edit:41: DLF.Options.SetAddButton
alias DLF.Options.SetAddButton {
  if ($did(41)) did -te DLF.Options.GUI 46
  else {
    did -b DLF.Options.GUI 46
    did -t DLF.Options.GUI 4
  }
}

; Enable / disable Remove custom message button
on *:dialog:DLF.Options.GUI:sclick:51: DLF.Options.SetRemoveButton
alias DLF.Options.SetRemoveButton {
  if ($did(51,0).sel > 0) did -te DLF.Options.GUI 52
  else {
    did -b DLF.Options.GUI 52
    DLF.Options.SetAddButton
  }
}

; Customer filter Add button clicked
on *:dialog:DLF.Options.GUI:sclick:46: {
  var %new = $did(41).text
  %new = $+(*,%new,*)
  %new = $regsubex(%new,$+(/[][!#$%&()/:;<=>.|,$comma,$lcurly,$rcurly,]+/g),$star)
  %new = $regsubex(%new,/[*] *[*]+/g,$star)
  if (%new == *) return
  if (%DLF.custom.selected == Channel text) %DLF.custom.chantext = $addtok(%DLF.custom.chantext,%new,$asc($comma))
  if (%DLF.custom.selected == Channel action) %DLF.custom.chanaction = $addtok(%DLF.custom.chanaction,%new,$asc($comma))
  if (%DLF.custom.selected == Channel notice) %DLF.custom.channotice = $addtok(%DLF.custom.channotice,%new,$asc($comma))
  if (%DLF.custom.selected == Channel ctcp) %DLF.custom.chanctcp = $addtok(%DLF.custom.chanctcp,%new,$asc($comma))
  if (%DLF.custom.selected == Private text) %DLF.custom.privtext = $addtok(%DLF.custom.privtext,%new,$asc($comma))
  if (%DLF.custom.selected == Private action) %DLF.custom.privaction = $addtok(%DLF.custom.privaction,%new,$asc($comma))
  if (%DLF.custom.selected == Private notice) %DLF.custom.privnotice = $addtok(%DLF.custom.privnotice,%new,$asc($comma))
  if (%DLF.custom.selected == Private ctcp) %DLF.custom.privctcp = $addtok(%DLF.custom.privctcp,%new,$asc($comma))
  ; Clear edit field, list selection and disable add button
  did -r DLF.Options.GUI 41
  DLF.Options.SetAddButton
  DLF.Options.SetCustomType $did(37).seltext
}

; Customer filter Remove button clicked
on *:dialog:DLF.Options.GUI:sclick:52: {
  var %selcnt = $did(51,0).sel
  while (%selcnt) {
    var %seltext = $did(51,$did(51,%selcnt).sel).text
    if (%DLF.custom.selected == Channel text) %DLF.custom.chantext = $remtok(%DLF.custom.chantext,%seltext,1,$asc($comma))
    if (%DLF.custom.selected == Channel action) %DLF.custom.chanaction = $remtok(%DLF.custom.chanaction,%seltext,1,$asc($comma))
    if (%DLF.custom.selected == Channel notice) %DLF.custom.channotice = $remtok(%DLF.custom.channotice,%seltext,1,$asc($comma))
    if (%DLF.custom.selected == Channel ctcp) %DLF.custom.chanctcp = $remtok(%DLF.custom.chanctcp,%seltext,1,$asc($comma))
    if (%DLF.custom.selected == Private text) %DLF.custom.privtext = $remtok(%DLF.custom.privtext,%seltext,1,$asc($comma))
    if (%DLF.custom.selected == Private action) %DLF.custom.privaction = $remtok(%DLF.custom.privaction,%seltext,1,$asc($comma))
    if (%DLF.custom.selected == Private notice) %DLF.custom.privnotice = $remtok(%DLF.custom.privnotice,%seltext,1,$asc($comma))
    if (%DLF.custom.selected == Private ctcp) %DLF.custom.privctcp = $remtok(%DLF.custom.privctcp,%seltext,1,$asc($comma))
    dec %selcnt
  }
  did -b DLF.Options.GUI 52
  DLF.Options.SetCustomType $did(37).seltext
  DLF.Options.SetRemoveButton
}
on *:dialog:DLF.Options.GUI:sclick:67: url -an http://dukelupus.com/dlfilter
on *:dialog:DLF.Options.GUI:sclick:66: url -an http://www.dukelupus.pri.ee/download.php?f=187932020

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

on ^*:text:*:%DLF.channels: {
  var %DLF.txt = $strip($1-)
  if ((%DLF.ads == 1) && ($hfind(DLF.text.ads,%DLF.txt,1,W))) TextSetNickColor $chan $nick $1-
  if ((%DLF.requests == 1) && ($hfind(DLF.text.cmds,%DLF.txt,1,W))) DLF_textfilter $chan $nick $1-
  if ((%DLF.away == 1) && ($hfind(DLF.text.away,%DLF.txt,1,W))) DLF_textfilter $chan $nick $1-
  if ((%DLF.newreleases == 1) && ($hfind(DLF.text.newrels,%DLF.txt,1,W))) NewRFilter $nick $2-
  if ((%DLF.newreleases == 1) && (Wiz* iswm $nick) && (--*!* iswm %DLF.txt)) NewRFilter $nick $2-
  if ($hfind(DLF.text.always,%DLF.txt,1,W)) DLF_textfilter $chan $nick $1-

  /*if (%DLF.chspam == 1) {
    ;no channel spam right now
  }
  */
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.chantext)) {
    var %nr = $numtok(%DLF.custom.chantext,$asc($comma))
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.chantext,%cnter,$asc($comma)) iswm %DLF.txt) DLF_textfilter $chan $nick $1-
      inc %cnter
    }
  }
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
  var %DLF.action = $strip($1-)
  if ((%DLF.ads == 1) && ($hfind(DLF.action.ads,%DLF.action,1,W))) DLF_actionfilter $chan $nick $1-
  if ((%DLF.away == 1) && ($hfind(DLF.action.away,%DLF.action,1,W))) DLF_actionfilter $chan $nick $1-

  if ((%DLF.custom.enabled == 1) && (%DLF.custom.chanaction)) {
    var %nr = $numtok(%DLF.custom.chanaction,$asc($comma))
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.chanaction,%cnter,$asc($comma)) iswm %DLF.act) DLF_actionfilter $chan $nick %DLF.action
      inc %cnter
    }
  }
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
  %DLF.ptext = $strip($1-)
  if ($window(1)) DoCheckComChan $1 $2-
  if ((%DLF.noregmsg == 1) && ($CheckRegular($1) == IsRegular)) {
    DLF.Warning Regular user $1 $br($address($1,0)) tried to: $2-
    if ($window($1)) window -c $1
    halt
  }
  if (%DLF.privrequests == 1) {
    if ($1 === $me) return
    var %fword = $strip($2)
    var %nicklist = @ $+ $me
    var %nickfile = ! $+ $me
    if ((%nicklist == %fword) || (%nickfile == %fword) || (%nickfile == $gettok($strip($2),1,$asc($hyphen)))) {
      .msg $1 Please $u(do not request in private) $+ . All commands go to $u(channel).
      .msg $1 You may have to go to $c(2,mIRC options --->> Sounds --->> Requests) and uncheck $qt($c(3,Send '!nick file' as private message))
      if (($window($1)) && ($line($1,0) == 0)) .window -c $1
      halt
    }
  }
  if ((%DLF.privspam == 1) && ($hfind(DLF.priv.spam,%DLF.ptext,1,W)) && (!$window($1))) PSpamFilter $1-
  if ((%DLF.searchresults == 1) && (%DLF.searchactive == 1)) {
    if ($hfind(DLF.search.headers,%DLF.ptext,1,W)) FindHeaders $1-
    var %nick = $1
    tokenize 32 %DLF.ptext
    if ((*Omen* iswm $1) && ($pling isin $2)) FindResults %nick $1-
    if ($pos($1,$pling,1) == 1) FindResults %nick $1-
    if (($1 == $colon) && ($pos($2,$pling,1) == 1)) FindResults %nick $1-
  }
  if ((%DLF.server == 1) && ($hfind(DLF.priv.spam,%DLF.ptext,1,W)) FindHeaders $1-
  if ((%DLF.away == 1)  && ($hfind(DLF.priv.away,%DLF.ptext,1,W)) PrivText $1-
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.privtext)) {
    var %nr = $numtok(%DLF.custom.privtext,$asc($comma))
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.privtext,%cnter,$asc($comma)) iswm %DLF.ptext) {
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
  var %DLF.pnotice = $strip($1-)
  DoCheckComChan $nick %DLF.pnotice
  if ((%DLF.noregmsg == 1) && ($CheckRegular($nick) == IsRegular)) {
    DLF.Warning Regular user $nick $br($address) tried to send you a notice: $1-
    halt
  }
  if ((%DLF.server == 1) && ($hfind(DLF.notice.server,%DLF.pnotice,1,W))) ServerFilter $nick $1-
  if (*SLOTS My mom always told me not to talk to strangers* iswm %DLF.pnotice) DLF_textfilter Notice $nick $1-
  if (*CTCP flood detected, protection enabled* iswm %DLF.pnotice) DLF_textfilter Notice $nick $1-
  if ((%DLF.searchresults == 1) && (%DLF.searchactive == 1)) {
    if (No match found for* iswm %DLF.ptext) ServerFilter $nick $1-
    if (*I have*match* for*in listfile* iswm %DLF.ptext) ServerFilter $nick $1-
    tokenize $asc($space) %DLF.ptext
    if ($pos($1,$pling,1) == 1) FindResults $nick $1-
  }
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.privnotice)) {
    var %nr = $numtok(%DLF.custom.privnotice,$asc($comma))
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.privnotice,%cnter,$asc($comma)) iswm $strip($1-)) DLF_textfilter Private $nick $1-
      inc %cnter
    }
  }
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

on *:CTCPREPLY:*: {
  if ($hfind(DLF.ctcp.reply,$1-,1,W)) halt
  if (%DLF.nocomchan == 1) DoCheckComChan $nick $1-
  if ((%DLF.noregmsg == 1) && (($CheckRegular($nick) == IsRegular)) && (DCC send !isin $1-)) {
    DLF.Warning Regular user $nick ( $+ $address $+ ) tried to: $1-
    halt
  }
  if ((%DLF.custom.enabled == 1) && (%DLF.custom.privctcp)) {
    var %nr = $numtok(%DLF.custom.privctcp,$asc($comma))
    var %cnter = 1
    while (%cnter <= %nr) {
      if ($gettok(%DLF.custom.privctcp,%cnter,$asc($comma)) iswm $1-) DLF_textfilter Private $nick $1-
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
    if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 56 1 Connection to DLFilter website failed!
    else echo -s 4,15[DLFilter]2,15 Connection to DLFilter website failed!
    .sockclose dlf
    halt
  }
  sockwrite -n $sockname GET /versions.txt HTTP/1.1
  sockwrite -n $sockname Host: dukelupus.com $+ $crlf $+ $crlf
}
on *:sockread:dlf: {
  if ($sockerr > 0) {
    if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 56 1 Connection to DLFilter website failed!
    else echo -s 4,15[DLFilter]2,15 Connection to DLFilter website failed!
    .sockclose dlf
    halt
  }
  else {
    var %t
    sockread %t
    if (($gettok(%t,1,59) == DLFilter) && ($gettok(%t,2,59) > $Set.DLF.version)) {
      if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 56 1 You should update! Version $gettok(%t,2,59) is available!
      else echo -a 4,15[DLFilter]2,15 You should update DLFilter. You are using $Set.DLF.version $+ , but version $gettok(%t,2,59) is available from DLFilter website at 12http://dukelupus.com
      .sockclose dlf
    }
    elseif (($gettok(%t,1,59) == DLFilter) && ($gettok(%t,2,59) == $Set.DLF.version)) {
      if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 56 1 You have current version of DLFilter
  ;;     else echo -a 4,15[DLFilter]2,15 You have current version of DLFilter
      .sockclose dlf
    }
    if (($gettok(%t,1,59) == DLFilter) && ($gettok(%t,2,59) < $Set.DLF.version)) {
      if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 56 1 You have newer version then website
;;      else echo -a 4,15[DLFilter]2,15 You have newer version then website
      .sockclose dlf
    }
  }
}

; ========== Define message matching hash tables ==========
alias DLF.hadd {
  var %h = DLF. $+ $1
  if (!$hget(%h)) hmake %h
  var %n = $hget($1, 0)
  hadd %h %n $2-
}

alias DLF.SetHashTables {
  if ($hget(DLF.text.ads)) hfree DLF.text.ads
  DLF.hadd text.ads *Type*@*
  DLF.hadd text.ads *Trigger*@*
  DLF.hadd text.ads *List*@*
  DLF.hadd text.ads *Type*!*to get this*
  DLF.hadd text.ads *[BWI]*@*
  DLF.hadd text.ads *Trigger*ctcp*
  DLF.hadd text.ads *@*Finålity*
  DLF.hadd text.ads *@*SDFind*
  DLF.hadd text.ads *I have just finished sending*to*Empty*
  DLF.hadd text.ads *§kÎn§*ßy*§hådõ*
  DLF.hadd text.ads *-SpR-*
  DLF.hadd text.ads *Escribe*@*
  DLF.hadd text.ads *±*
  DLF.hadd text.ads *Escribe*!*
  DLF.hadd text.ads *-SpR skin used by PepsiScript*
  DLF.hadd text.ads *Type*!*.*
  DLF.hadd text.ads *Empty! Grab one fast!*
  DLF.hadd text.ads *Random Play MP3*Now Activated*
  DLF.hadd text.ads *The Dcc Transfer to*has gone under*Transfer*
  DLF.hadd text.ads *just left*Sending file Aborted*
  DLF.hadd text.ads *has just received*for a total of*
  DLF.hadd text.ads *There is a Slot Opening*Grab it Fast*
  DLF.hadd text.ads *Tapez*Pour avoir ce Fichier*
  DLF.hadd text.ads *Tapez*Pour Ma Liste De*Fichier En Attente*
  DLF.hadd text.ads *left irc and didn't return in*min. Sending file Aborted*
  DLF.hadd text.ads *FTP*address*port*login*password*
  DLF.hadd text.ads *I have sent a total of*files and leeched a total of*since*
  DLF.hadd text.ads *I have just finished sending*I have now sent a total of*files since*
  DLF.hadd text.ads *I have just finished recieving*from*I have now recieved a total of*
  DLF.hadd text.ads *Proofpack Server*Looking for new scans to proof*@proofpack for available proofing packs*
  DLF.hadd text.ads *SpR JUKEBOX*filesize*
  DLF.hadd text.ads *I have spent a total time of*sending files and a total time of*recieving files*
  DLF.hadd text.ads *Tape*@*
  DLF.hadd text.ads *Tape*!*MB*
  DLF.hadd text.ads *Tape*!*.mp3*
  DLF.hadd text.ads *§*DCC Send Failed*to*§*
  DLF.hadd text.ads *Wireless*mb*br*
  DLF.hadd text.ads *Sent*OS-Limits V*
  DLF.hadd text.ads *File Servers Online*Polaris*
  DLF.hadd text.ads *There is a*Open*Say's Grab*
  DLF.hadd text.ads *left*and didn't return in*mins. Sending file Aborted*
  DLF.hadd text.ads *to*just got timed out*slot*Empty*
  DLF.hadd text.ads *Softwind*Softwind*
  DLF.hadd text.ads *Statistici 1*by Un_DuLciC*
  DLF.hadd text.ads *tìnkërßëll`s collection*Love Quotes*
  DLF.hadd text.ads *I-n-v-i-s-i-o-n*
  DLF.hadd text.ads *DCC SEND COMPLETE*to*slot*
  DLF.hadd text.ads *« * » -*
  DLF.hadd text.ads *¥*Mp3s*¥*
  DLF.hadd text.ads *DCC GET COMPLETE*from*slot*open*
  DLF.hadd text.ads *Je viens juste de terminer l'envoi de*Prenez-en un vite*
  DLF.hadd text.ads *Random Play MP3 filez Now Plugged In*
  DLF.hadd text.ads *a recu*pour un total de*fichiers*
  DLF.hadd text.ads *vient d'etre interrompu*Dcc Libre*
  DLF.hadd text.ads *failed*DCC Send Failed of*to*failed*
  DLF.hadd text.ads *is playing*info*secs*
  DLF.hadd text.ads *--PepsiScript--*
  DLF.hadd text.ads *«Scøøp MP3»*
  DLF.hadd text.ads *~*~SpR~*~*
  DLF.hadd text.ads *SpR*[*mp3*]*
  DLF.hadd text.ads *©§©*
  DLF.hadd text.ads *I am opening up*more slot*Taken*
  DLF.hadd text.ads *.mp3*t×PLåY6*
  DLF.hadd text.ads *!*.mp3*SpR*
  DLF.hadd text.ads *SPr*!*.mp3*
  DLF.hadd text.ads *Successfully*Tx.Track*
  DLF.hadd text.ads *[Mp3xBR]*
  DLF.hadd text.ads *OmeNServE*©^OmeN^*
  DLF.hadd text.ads *@*DragonServe*
  DLF.hadd text.ads *Now Sending*QwIRC*
  DLF.hadd text.ads *sent*to*size*speed*time*sent*
  DLF.hadd text.ads *Bandwith*Usage*Current*Record*
  DLF.hadd text.ads *Files In List*slots open*Queued*Next Send*
  DLF.hadd text.ads *Rank*~*x*~*
  DLF.hadd text.ads *Total Offered*Files*Total Sent*Files*Total Sent Today*Files*
  DLF.hadd text.ads *Control*IRC Client*CTCPSERV*
  DLF.hadd text.ads *Download this exciting book*
  DLF.hadd text.ads *» Port «*»*
  DLF.hadd text.ads *Tasteazã*@*
  DLF.hadd text.ads *File Servers Online*Trigger*Accessed*Served*
  DLF.hadd text.ads *- DCC Transfer Status -*
  DLF.hadd text.ads *Enter @*to see the menu*
  DLF.hadd text.ads *User Slots*Sends*Queues*Next Send Available*¤UControl¤*
  DLF.hadd text.ads *Total*File Transfer in Progress*slot*empty*
  DLF.hadd text.ads *!*MB*Kbps*Khz*
  DLF.hadd text.ads *I have just finished sending*.mp3 to*
  DLF.hadd text.ads *Files*free Slots*Queued*Speed*Served*
  DLF.hadd text.ads *I am using*SpR JUKEBOX*http://spr.darkrealms.org*
  DLF.hadd text.ads *FTP service*FTP*port*bookz*
  DLF.hadd text.ads *<><><*><><>*
  DLF.hadd text.ads *To serve and to be served*@*
  DLF.hadd text.ads *send - to*at*cps*complete*left*
  DLF.hadd text.ads *DCC Send Failed of*to*
  DLF.hadd text.ads *[Fserve Active]*
  DLF.hadd text.ads *File Server Online*Triggers*Sends*Queues*
  DLF.hadd text.ads *Teclea: @*
  DLF.hadd text.ads *rßP£a*sk*n*
  DLF.hadd text.ads *rßPLåY*
  DLF.hadd text.ads *<*>*!*
  DLF.Status Added $hget(DLF.text.ads,0).item matches for $b(adverts) as text

  if ($hget(DLF.text.cmds)) hfree DLF.text.cmds
  DLF.hadd text.cmds !*
  DLF.hadd text.cmds @*
  DLF.Status Added $hget(DLF.text.cmds,0).item matches for $b(user requests)

  if ($hget(DLF.text.away)) hfree DLF.text.away
  DLF.hadd text.away *KeepTrack*de adisoru*
  DLF.hadd text.away *Leaving*reason*auto away after*
  DLF.hadd text.away *I am AWAY*Reason*To page me*
  DLF.hadd text.away *sets away*auto idle away*since*
  DLF.hadd text.away *away*since*pager*
  DLF.hadd text.away *Thanks for the +v*
  DLF.hadd text.away *I have just finished receiving*from*
  DLF.hadd text.away *We have just finished receiving*From The One And Only*
  DLF.hadd text.away *Thank You*for serving in*
  DLF.hadd text.away *Thanks for the @*
  DLF.hadd text.away *Thanks*For*The*Voice*
  DLF.hadd text.away *I am AWAY*Reason*I have been Away for*
  DLF.hadd text.away *HêåvêñlyAway*
  DLF.hadd text.away *[F][U][N]*
  DLF.hadd text.away *Tx TIMEOUT*
  DLF.hadd text.away *Receive Successful*Thanks for*
  DLF.hadd text.away *Thanks*for Supplying an server in*
  DLF.hadd text.away *have just finished recieving*from*I have leeched a total*
  DLF.hadd text.away *DCC Send Failed of*to*Starting next in Que*
  DLF.hadd text.away *KeepTrack*by*^OmeN*
  DLF.hadd text.away *Message*SysReset*
  DLF.hadd text.away *YAY* Another brave soldier in the war to educate the masses*Onward Comrades*
  DLF.hadd text.away *WaS auTo-VoiCeD THaNX FoR SHaRiNG HeRe iN*
  DLF.hadd text.away *I have just received*from*leeched since*
  DLF.hadd text.away *mp3 server detected*
  DLF.hadd text.away *KiLLJarX*channel policy is that we are a*
  DLF.hadd text.away *rbPlay20.mrc*
  DLF.hadd text.away *rßPLåY2.0*
  DLF.hadd text.away *I have just finished receiving*from*have now received a total*
  DLF.hadd text.away *ROLL TIDE*Now Playing*mp3*
  DLF.hadd text.away *Tocmai am primit*KeepTrack*
  DLF.hadd text.away *Total Received*Files*Total Received Today*Files*
  DLF.hadd text.away *BJFileTracker V06 by BossJoe*
  DLF.hadd text.away *Just Sent To*Filename*Slots Free*Queued*
  DLF.hadd text.away *Received*From*Size*Speed*Time*since*
  DLF.hadd text.away *I have just received*from*for a total of*KeepTrack*
  DLF.hadd text.away *« Ë×Çü®§îöñ »*
  DLF.hadd text.away *Thanks*For The*@*
  DLF.hadd text.away *get - from*at*cps*complete*
  DLF.hadd text.away *Je viens juste de terminer de recevoir*de*Prenez-en un vite*
  DLF.hadd text.away *§ÐfíñÐ âÐÐ-øñ§*
  DLF.hadd text.away *Welcome back to #* operator*.*
  DLF.hadd text.away *[Away]*SysReset*
  DLF.hadd text.away *Back*Duration*
  DLF.hadd text.away *MisheBORG*SendStat*v.*
  DLF.Status Added $hget(DLF.text.away,0).item matches for $b(away spam) as text

  if ($hget(DLF.text.newrels)) hfree DLF.text.newrels
  DLF.hadd text.newrels *NEW from the excellent proofers of*
  DLF.hadd text.newrels *N e w release*
  DLF.hadd text.newrels N E W *
  DLF.hadd text.newrels *-=NEW=-*
  DLF.hadd text.newrels *-=NEW RELEASE=-*
  DLF.Status Added $hget(DLF.text.newrels,0).item matches for $b(new release spam) as text

  if ($hget(DLF.text.always)) hfree DLF.text.always
  DLF.hadd text.always 2find *
  DLF.hadd text.always Sign in to turn on 1-Click ordering.
  DLF.hadd text.always ---*KB
  DLF.hadd text.always ---*MB
  DLF.hadd text.always ---*KB*s*
  DLF.hadd text.always ---*MB*s*
  DLF.hadd text.always #find *
  DLF.hadd text.always "find *
  DLF.Status Added $hget(DLF.text.always,0).item matches for $b(always filter) items

  if ($hget(DLF.action.away)) hfree DLF.action.away
  DLF.hadd action.away *has taken a seat on the channel couch*Couch v*by Kavey*
  DLF.hadd action.away *has stumbled to the channel couch*Couch v*by Kavey*
  DLF.hadd action.away *has returned from*I was gone for*
  DLF.hadd action.away *is gone. Away after*minutes of inactivity*
  DLF.hadd action.away *is away*Reason*since*
  DLF.hadd action.away *is BACK from*auto-away*
  DLF.hadd action.away *is back*From*Gone for*
  DLF.hadd action.away *sets away*Auto Idle Away after*
  DLF.hadd action.away *is back from*Gone*
  DLF.hadd action.away *is BACK from*Away*
  DLF.hadd action.away *asculta*
  DLF.hadd action.away *is AWAY*auto-away*
  DLF.hadd action.away *Avertisseur*Journal*
  DLF.hadd action.away *I-n-v-i-s-i-o-n*
  DLF.hadd action.away *is back*from*Auto IdleAway*
  DLF.hadd action.away *way*since*pager*
  DLF.hadd action.away *[Backing Up]*
  DLF.hadd action.away *está away*pager*
  DLF.hadd action.away *uses cracked software*I will respond to the following commands*
  DLF.hadd action.away *I Have Send My List*Times*Files*Times*
  DLF.hadd action.away *Type Or Copy*Paste*To Get This Song*
  DLF.hadd action.away *is currently boogying away to*
  DLF.hadd action.away *is listening to*Kbps*KHz*
  DLF.hadd action.away *Now*Playing*Kbps*KHz*
  DLF.Status Added $hget(DLF.action.away,0).item matches for $b(away spam) as actions

  if ($hget(DLF.action.ads)) hfree DLF.action.ads
  DLF.hadd action.ads *FTP*port*user*pass*
  DLF.hadd action.ads *get AMIP*plug-in at http*amip.tools-for.net*
  DLF.Status Added $hget(DLF.action.ads,0).item matches for $b(adverts) as actions

  if ($hget(DLF.notice.server)) hfree DLF.notice.server
  DLF.hadd notice.server *I have added*
  DLF.hadd notice.server *After waiting*min*
  DLF.hadd notice.server *This makes*times*
  DLF.hadd notice.server *is on the way!*
  DLF.hadd notice.server *has been sent sucessfully*
  DLF.hadd notice.server *send will be initiated as soon as possible*
  DLF.hadd notice.server *«SoftServe»*
  DLF.hadd notice.server *You are the successful downloader number*
  DLF.hadd notice.server *You are in*
  DLF.hadd notice.server *Request Denied*
  DLF.hadd notice.server *OmeNServE v*
  DLF.hadd notice.server *«OmeN»*
  DLF.hadd notice.server *is not found*
  DLF.hadd notice.server *file not located*
  DLF.hadd notice.server *I don't have the file*
  DLF.hadd notice.server *is on its way*
  DLF.hadd notice.server *±*
  DLF.hadd notice.server *Transfer Started*File*
  DLF.hadd notice.server *is on it's way!*
  DLF.hadd notice.server *Requested File's*
  DLF.hadd notice.server *Please make a resume request!*
  DLF.hadd notice.server *File Transfer of*
  DLF.hadd notice.server *Please reinitiate File-transfer!*
  DLF.hadd notice.server *on its way*
  DLF.hadd notice.server *OS-Limits*
  DLF.hadd notice.server *Transfer Complete*I have successfully sent*QwIRC
  DLF.hadd notice.server *Request Accepted*File*Queue position*
  DLF.hadd notice.server *Le Transfert de*Est Completé*
  DLF.hadd notice.server *Query refused*in*seconds*
  DLF.hadd notice.server *Keeptrack*omen*
  DLF.hadd notice.server *U Got A File From Me*files since*
  DLF.hadd notice.server *Transfer Complete*sent*
  DLF.hadd notice.server *Transmision de*finalizada*
  DLF.hadd notice.server *Send Failed*at*Please make a resume request*
  DLF.hadd notice.server *t×PLåY*
  DLF.hadd notice.server *OS-Limites V*t×PLåY*
  DLF.hadd notice.server *rßPLåY2*
  DLF.hadd notice.server Request Accepted*Has Been Placed In The Priority Queue At Position*
  DLF.hadd notice.server *esta en camino!*
  DLF.hadd notice.server *Envio cancelado*
  DLF.hadd notice.server *de mi lista de espera*
  DLF.hadd notice.server *Después de esperar*min*
  DLF.hadd notice.server *veces que he enviado*
  DLF.hadd notice.server *archivos, Disfrutalo*
  DLF.hadd notice.server Thank you for*.*!
  DLF.hadd notice.server *veces que env*
  DLF.hadd notice.server *zip va en camino*
  DLF.hadd notice.server *Enviando*(*)*
  DLF.hadd notice.server *Unable to locate any files with*associated within them*
  DLF.hadd notice.server *Has Been Placed In The Priority Queue At Position*Omenserve*
  DLF.hadd notice.server *Thanks*for sharing*with me*
  DLF.hadd notice.server *«[RDC]»*
  DLF.hadd notice.server *Your send of*was successfully completed*
  DLF.hadd notice.server *AFK, auto away after*minutes*
  DLF.hadd notice.server *Envío completo*DragonServe*
  DLF.hadd notice.server *Empieza transferencia*DragonServe*
  DLF.hadd notice.server *Ahora has recibido*DragonServe*
  DLF.hadd notice.server *Starting Transfer*DragonServe*
  DLF.hadd notice.server *You have now received*from me*for a total of*sent since*
  DLF.hadd notice.server *Thanks For File*It is File*That I have recieved*
  DLF.hadd notice.server *Thank You*I have now received*file*from you*for a total of*
  DLF.hadd notice.server *You Are Downloader Number*Overall Downloader Number*
  DLF.hadd notice.server *DCC Get of*FAILED Please Re-Send file*
  DLF.hadd notice.server *request for*acknowledged*send will be initiated as soon as possible*
  DLF.hadd notice.server *file not located*
  DLF.hadd notice.server *t×PLÅY*
  DLF.hadd notice.server *I'm currently away*your message has been logged*
  DLF.hadd notice.server *If your message is urgent, you may page me by typing*PAGE*
  DLF.hadd notice.server *Gracias*Ahora he recibido*DragonServe*
  DLF.hadd notice.server *Request Accepted*List Has Been Placed In The Priority Queue At Position*
  DLF.hadd notice.server *Send Complete*File*Sent*times*
  DLF.hadd notice.server *Sent*Files Allowed per day*User Class*BWI-Limits*
  DLF.hadd notice.server *Now I have received*DragonServe*
  DLF.Status Added $hget(DLF.notice.server,0).item matches for $b(server messages) as notices

  if ($hget(DLF.ctcp.reply)) hfree DLF.ctcp.reply
  DLF.hadd ctcp.reply *SLOTS*
  DLF.hadd ctcp.reply *ERRMSG*
  DLF.hadd ctcp.reply *MP3*
  DLF.Status Added $hget(DLF.ctcp.reply,0).item matches for $b(ctcp replies)

  if ($hget(DLF.priv.spam)) hfree DLF.priv.spam
  DLF.hadd priv.spam *www*sex*
  DLF.hadd priv.spam *www*xxx*
  DLF.hadd priv.spam *http*sex*
  DLF.hadd priv.spam *http*xxx*
  DLF.hadd priv.spam *sex*www*
  DLF.hadd priv.spam *xxx*www*
  DLF.hadd priv.spam *sex*http*
  DLF.hadd priv.spam *xxx*http*
  DLF.hadd priv.spam *porn*http*
  DLF.Status Added $hget(DLF.priv.spam,0).item matches for $b(spam) as private message

  if ($hget(DLF.search.headers)) hfree DLF.search.headers
  DLF.hadd search.headers *Search Result*OmeNServE*
  DLF.hadd search.headers *OmeN*Search Result*ServE*
  DLF.hadd search.headers *Matches for*Copy and paste in channel*
  DLF.hadd search.headers *Total*files found*
  DLF.hadd search.headers *Search Results*QwIRC*
  DLF.hadd search.headers *Search Result*Too many files*Type*
  DLF.hadd search.headers *@Find Results*SysReset*
  DLF.hadd search.headers *End of @Find*
  DLF.hadd search.headers *I have*match*for*in listfile*
  DLF.hadd search.headers *SoftServe*Search result*
  DLF.hadd search.headers *Tengo*coincidencia* para*
  DLF.hadd search.headers *I have*match*for*Copy and Paste*
  DLF.hadd search.headers *Too many results*@*
  DLF.hadd search.headers *Tengo*resultado*slots*
  DLF.hadd search.headers *I have*matches for*You might want to get my list by typing*
  DLF.hadd search.headers *Résultat De Recherche*OmeNServE*
  DLF.hadd search.headers *Resultados De Busqueda*OmenServe*
  DLF.hadd search.headers *Total de*fichier*Trouvé*
  DLF.hadd search.headers *Fichier* Correspondant pour*Copie*
  DLF.hadd search.headers *Search Result*Matches For*Copy And Paste*
  DLF.hadd search.headers *Resultados de la búsqueda*DragonServe*
  DLF.hadd search.headers *Results for your search*DragonServe*
  DLF.hadd search.headers *«SoftServe»*
  DLF.hadd search.headers *search for*returned*results on list*
  DLF.hadd search.headers *List trigger:*Slots*Next Send*CPS in use*CPS Record*
  DLF.hadd search.headers *Searched*files and found*matching*To get a file, copy !*
  DLF.hadd search.headers *Note*Hey look at what i found!*
  DLF.hadd search.headers *Note*MP3-MP3*
  DLF.hadd search.headers *Search Result*Matches For*Get My List Of*Files By Typing @*
  DLF.hadd search.headers *Resultado Da Busca*Arquivos*Pegue A Minha Lista De*@*
  DLF.hadd search.headers *J'ai Trop de Résultats Correspondants*@*
  DLF.hadd search.headers *Search Results*Found*matches for*Type @*to download my list*
  DLF.hadd search.headers *I have found*file*for your query*Displaying*
  DLF.hadd search.headers *From list*found*displaying*
  DLF.Status Added $hget(DLF.search.headers,0).item matches for $b(search headers) as private message

  if ($hget(DLF.priv.server)) hfree DLF.priv.server
  DLF.hadd priv.server Sorry, I'm making a new list right now, please try later*
  DLF.hadd priv.server *Request Denied*OmeNServE*
  DLF.hadd priv.server *Sorry for cancelling this send*OmeNServE*
  DLF.hadd priv.server Lo Siento, no te puedo enviar mi lista ahora, intenta despues*
  DLF.hadd priv.server Lo siento, pero estoy creando una nueva lista ahora*
  DLF.hadd priv.server I have successfully sent you*OS*
  DLF.hadd priv.server *Petición rechazada*DragonServe*
  DLF.hadd priv.server *I don't have*Please check your spelling or get my newest list by typing @* in the channel*
  DLF.hadd priv.server *you already have*in my que*has NOT been added to my que*
  DLF.hadd priv.server *You already have*in my que*Type @*-help for more info*
  DLF.hadd priv.server *Request Denied*Reason: *DragonServe*
  DLF.hadd priv.server *You already have*requests in my queue*is not queued*
  DLF.hadd priv.server *Queue Status*File*Position*Waiting Time*OmeNServE*
  DLF.hadd priv.server *Empieza transferencia*IMPORTANTE*dccallow*
  DLF.hadd priv.server *Sorry, I'm too busy to send my list right now, please try later*
  DLF.hadd priv.server *Please standby for acknowledgement. I am using a secure query event*
  DLF.Status Added $hget(DLF.priv.server,0).item matches for $b(server messages) as private message

  if ($hget(DLF.priv.away)) hfree DLF.priv.away
  DLF.hadd priv.away *AFK, auto away after*minutes. Gone*
  DLF.hadd priv.away *Away*Reason*Auto Away*
  DLF.hadd priv.away *Away*Reason*Duration*
  DLF.hadd priv.away *Away*Reason*Gone for*Pager*
  DLF.hadd priv.away *^Auto-Thanker^*
  DLF.hadd priv.away *If i didn't know any better*I would have thought you were flooding me*
  DLF.hadd priv.away *Message's from strangers are Auto-Rejected*
  DLF.hadd priv.away *Dacia Script v1.2*
  DLF.hadd priv.away *Away*SysReset*
  DLF.hadd priv.away *automated msg*
  DLF.Status Added $hget(DLF.priv.away,0).item matches for $b(away spam) as private message
}

; ========== Status and error messages ==========
alias -l DLF.logo return $rev([DLFilter])
alias DLF.Status echo -s $c(1,9,$DLF.logo $1-)
alias DLF.Warning echo -as $c(1,9,$DLF.logo $1-)
alias DLF.Error DLF.Warning $c(4,$b(Error:)) $1-

; ========== Identifiers instead of $chr(xx) - more readable ==========
alias space return $chr(32)
alias nbsp return $chr(160)
alias amp return $chr(38)
alias star return $chr(42)
alias dollar return $chr(36)
alias comma return $chr(44)
alias hyphen return $chr(45)
alias colon return $chr(58)
alias semicolon return $chr(59)
alias pling return $chr(33)
alias period return $chr(46)
alias lcurly return $chr(123)
alias rcurly return $chr(125)
alias lsquare return $chr(91)
alias rsquare return $chr(93)
alias sqbr return $+($lsquare,$1-,$rsquare)
alias lbr return $chr(40)
alias rbr return $chr(41)
alias br return $+($lbr,$1-,$rbr)
alias eq return $chr(61)
alias lt return $chr(60)
alias gt return $chr(62)
alias tag return $+($lt,$1-,$gt)

; ========== Control Codes using aliases ==========
; Color, bold, underline, italic, reverse e.g.
; echo 1 This line has $b(bold) $+ , $i(italic) $+ , $u(underscored) $+ , $c(4,red) $+ , and $rev(reversed) text.
; Calls can be nested e.g. echo 1 $c(12,$u(http://www.dukelupus.com))
alias b return $+($chr(2),$1-,$chr(2))
alias u return $+($chr(31),$1-,$chr(31))
alias i return $+($chr(29),$1-,$chr(29))
alias rev return $+($chr(22),$1-,$chr(22))
alias c {
  var %code, %text
  if ($0 < 2) {
    DLF.Error Insufficient parameters to colour text
    halt
  }
  elseif ($1 !isnum 0-15) {
    DLF.Error Colour value invalid
    halt
  }
  elseif (($0 >= 3) && ($2 isnum 0-15)) {
    %code = $+($chr(3),$1,$comma,$2)
    %text = $3-
  }
  else {
    %code = $+($chr(3),$1)
    %text = $2-
  }
  %text = $replace(%text,$chr(15),%code)
  return $+(%code,%text,$chr(15))
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
