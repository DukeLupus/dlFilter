/*
dlFilter.mrc
Filter out messages on file sharing channels
Authors: DukeLupus and Sophist

Annoyed by advertising messages from the various file serving bots? Fed up with endless channel messages by other users searching for and requesting files? Are the responses to your own requests getting lost in the crowd?

This script filters out the crud, leaving only the useful messages displayed in the channel. By default, the filtered messages are thrown away, but you can direct them to custom windows if you wish.

Download from https://github.com/SanderSade/dlFilter/releases
Update regularly to handle new forms of message.

To load: use /load -rs dlFilter.mrc

Note that dlFilter loads itself automatically as a first script. This avoids problems where other scripts halt events preventing this scripts events from running.

Acknowledgements
================
dlFilter uses the following code from other people:

o GetFileName from TipiTunes' OS-Quicksearch
o automatic version check based on code developed for dlFilter by TipiTunes
o Support for AG6 & 7 by TipiTunes
o Some of the spam definitions are from HugHug's SoftSnow filter.
o Vadi wrote special function to vPowerGet dll that allows sending files from DLF.@find.Results window to vPowerGet.
*/

/* CHANGE LOG
  1.18  Fix reinitialisation of hash tables after update.
        Add another hash table for ctcp.spam
        Option to update to beta versions
        Track minimum mIRC version for web update and
          not offer update if mirc needs upgrade
        On download of new version, rename old version to .vxxx so
          user can recover if they have issues with the new version.
        Code remediation
        All dialog option changes now immediate
        Subsidiary check-boxes now enable / disable with parent
        Menu and events broken out into aliases
        Disable rather than unload script if mIRC version is too low
        Add extra options for windows for Server Ads and per connection
        Remove New Release filters
        Improve DLF.debug code
        Channel names can now be network#channel as well as #channel (any network)
        Create toolbar gif file from embedded data without needing to download it.
          (And code to turn gif into compressed encoded embedded data.)
        Added about tab populated with first comment block in this file

      TODO
        Use native logging for custom windows instead of script logging
        Use native timestamps for custom windows instead of script timestamps
        Centralise custom window management to a single routine
        Implement extra windows for fileserver ads and multi-server
        Development debug functionality - if mIRC debug is on, add DLF debug
          messages to the debug log.
        Menus to support network#channel
        Fuller implementation of script groups to enable / disable events
        Custom filters empty on initialisation
        Right click menu items for changing options base on line clicked
        Right click menu items for adding to custom filters
        More menu options equivalent to dialog options
        More menu options for adding custom filters
        Somehow send us details of user adding custom filters
          for our own analysis (privacy issues?)
        Add dlF icons to toolbar & options dialog
        Add menu to toolbar item
        Use CTCP halt to stop DCC CHAT and SEND rather than convoluted ctcp/open processing
        Rewrite anti-chat code
        Separate CTCP processing for these.
        Switch options channels text box to a list box in a separate tab.
          (And add functionality to add from list of opened channels.)
        Track requests in channels and allow dcc sends and responses regardless of matching
        Rewrite / fix @find code
        Own find results not captured
        Other @find command not sent to filters window
        Send to... menus - do they work?

  1.17  Update opening comments and add change log
        Use custom identifiers for creating bold, colour etc.
        Use custom identifiers instead of $chr(xx)
        Use alias for status messages
        Hash tables for message matching instead of lists of ifs
        Options dialog improvements
          Layout
          Enable / disable now global
          Custom filter Add / Remove button enable / disable
          Custom filter list multi-select
        Menu code cleanup
        Add generic sockets code
        Use GitHub for version check
        Download button to update from GitHub
        Use script groups to enable / disable DLF event handling
        Allow msgs from Chanserv etc. and self
        Cleanup menu code
        Files now always accepted from Regular users who are in DCC Trust List
        Allow user to choose whether to delete configuration variables on unload
        Limit load/start/connect update check to once per 7 days.
          (Options update check still runs every time options dialog is loaded.)
        All aliases and dialogs local (-l flag)
*/

alias -l DLF.SetVersion {
  %DLF.version = 1.18
  return %DLF.version
}

; ==================== Initialisation / Termination ====================
on *:start: {
  ; Reload script if needed to be first to execute
  if ($script != $script(1)) .reload -rs1 $qt($script)
  if (%DLF.JustLoaded) return
  DLF.Initialise
  return

  :error
  DLF.Error During start: $qt($error)
}

on *:load: {
  ; Reload script if needed to be first to execute
  if ($script != $script(1)) .load -rs1 $qt($script)

  set -u1 %DLF.JustLoaded 1
  DLF.Initialise
  DLF.Options.Show
  DLF.Status Loading complete.
  return

  :error
  DLF.Error During load: $qt($error)
}

alias -l DLF.Initialise {
  ; Delete obsolete variables
  .unset %DLF.custom.selected
  .unset %DLF.newreleases
  .unset %DLF.ptext

  if ($script(onotice.mrc)) .unload -rs onotice.mrc
  if ($script(onotice.txt)) .unload -rs onotice.txt
  DLF.Status $iif(%DLF.JustLoaded,Loading,Starting) $c(4,version $DLF.SetVersion) by DukeLupus & Sophist.
  DLF.Status Please check dlFilter homepage $br($c(12,9,$u(https://github.com/SanderSade/dlFilter/issues))) for help.
  DLF.CreateGif
  DLF.CreateHashTables
  DLF.Options.Initialise
  var %ver = $DLF.mIRCversion
  if (%ver != 0) DLF.Error dlFilter requires mIRC %ver $+ +. dlFilter disabled until mIRC is updated.
  DLF.Groups.Events
}

alias -l DLF.mIRCversion {
  ; We need returnex first implemented in 6.17
  ; We need regml.group first implemented in 7.44
  if ($version < 7.44) {
    %DLF.enabled = 0
    return 7.44
  }
  return 0
}

ctcp *:VERSION:*: .ctcpreply $nick VERSION $c(1,9,$DLF.logo version $DLF.SetVersion by DukeLupus & Sophist.) $+ $c(1,15,$space $+ Get it from $c(12,15,$u(https://github.com/SanderSade/dlFilter/releases)))

on *:unload: {
  var %keepvars = $?!="Do you want to keep your dlFilter configuration?"
  DLF.Status Unloading $c(4,9,version $DLF.SetVersion) by DukeLupus & Sophist.
  if (%keepvars == $false) {
    DLF.Status Unsetting variables..
    .unset %DLF.*
  }
  DLF.Status Closing open dlFilter windows
  if ($dialog(DLF.Options.GUI)) .dialog -x DLF.Options.GUI DLF.Options.GUI
  if ($window(@DLF.filtered)) window -c @DLF.filtered
  if ($window(@DLF.filtered.search)) window -c @DLF.filtered.search
  if ($window(@DLF.server)) window -c @DLF.server
  if ($window(@DLF.server.search)) window -c @DLF.server.search
  if ($window(@DLF.@find.results)) window -c @DLF.@find.results
  close -@ @#*
  DLF.Status Unloading complete.
  DLF.Status $space
  DLF.Status To reload run /load -rs1 $qt($script)
  DLF.Status $space
}

; ============================== Menus ==============================

; ========== Menus - Main DLF functionality ==========
menu channel {
  -
  ;$iif($me !isop $chan, $style(2)) Send onotice: DLF.oNotice.Send
  Send onotice: DLF.oNotice.Send
  -
  dlFilter
  ..Options: DLF.Options.Show
  ..$iif($DLF.IsChannel($network,$chan),Remove,Add) this channel: DLF.Channels.AddRemove
  ..$iif(%DLF.netchans == $hashtag, $style(3)) Set to all channels: {
    DLF.Channels.Set $hashtag
    DLF.Status $c(6,Channels set to $c(4,$hashtag))
  }
  ..-
  ..$iif(%DLF.showfiltered == 1,$style(1)) Show filtered lines: DLF.Menu.ShowFilter
}

menu menubar {
  dlFilter
  .Options: DLF.Options.Show
  .$iif(%DLF.showfiltered == 1,$style(1)) Show filtered lines: DLF.Menu.ShowFilter
  .Visit filter website: .url -a https://github.com/SanderSade/dlFilter
  .-
  .Unload dlFilter: if ($?!="Do you want to unload dlFilter?" == $true) .unload -rs $qt($script)
}

menu @DLF.Filtered {
  Clear: clear
  Search: {
    var %searchstring = $?="Enter search string"
    if (%searchstring == $null) halt
    else FilteredSearch %searchstring
  }
  $iif(%DLF.filtered.timestamp == 1,$style(1)) Timestamp: DLF.Option.Toggle filtered.timestamp
  $iif(%DLF.filtered.strip == 1,$style(1)) Strip codes: DLF.Option.Toggle filtered.strip
  $iif(%DLF.filtered.wrap == 1,$style(1)) Wrap lines: DLF.Option.Toggle filtered.wrap
  $iif(%DLF.filtered.limit == 1,$style(1)) Limit number of lines: DLF.Option.Toggle filtered.limit
  $iif(%DLF.filtered.log == 1,$style(1)) Log: DLF.Option.Toggle filtered.log
  -
  Options: DLF.Options.Show
  Close: {
    %DLF.showfiltered = 0
    window -c @DLF.Filtered
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
  $iif(%DLF.server.timestamp == 1,$style(1)) Timestamp: DLF.Option.Toggle server.timestamp
  $iif(%DLF.server.strip == 1,$style(1)) Strip codes: DLF.Option.Toggle server.strip
  $iif(%DLF.server.wrap == 1,$style(1)) Wrap lines: DLF.Option.Toggle server.wrap
  $iif(%DLF.server.limit == 1,$style(1)) Limit number of lines: DLF.Option.Toggle server.limit
  $iif(%DLF.server.log == 1,$style(1)) Log: DLF.Option.Toggle server.log
  -
  Options: DLF.Options.Show
  Close: window -c @DLF.Server
  -
}

alias -l DLF.Channels.AddRemove {
  if ($DLF.IsChannel($network,$chan)) DLF.Channels.Add $chan $network
  else DLF.Channels.Remove $chan $network
  if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 6 1 %DLF.netchans
  DLF.Status $c(6,Channels set to $c(4,%DLF.netchans))
}

alias -l DLF.Channels.Add {
  var %net = $iif($0 >= 2,$2,$network)
  var %chan = $iif($0 >= 1,$1,$chan)
  var %netchan = $+(%net,%chan)
  %DLF.netchans = $remtok(%DLF.netchans,%chan,$asc($comma))
  if (%DLF.netchans != $hashtag) DLF.Channels.Set $addtok(%DLF.netchans,%netchan,$asc($comma))
  else DLF.Channels.Set %netchan
}

alias -l DLF.Channels.Remove {
  var %net = $iif($0 >= 2,$2,$network)
  var %chan = $iif($0 >= 1,$1,$chan)
  %DLF.netchans = $remtok(%DLF.netchans,%chan,1,$asc($comma))
  DLF.Channels.Set $remtok(%DLF.netchans,$+(%net,%chan),1,$asc($comma))
}

alias -l DLF.Menu.ShowFilter {
  if (%DLF.showfiltered == 1) window -c @DLF.filtered
  DLF.Option.Toggle showfiltered
}

alias -l DLF.Option.Toggle {
  var %newval = 1 - % [ $+ DLF. [ $+ [ $1 ] ] ]
  % [ $+ [ DLF. [ $+ [ $1 ] ] ] ] = %newval
  ;if ($2 != $null) did
  if (%newval) DLF.Status Option $1 set
  else DLF.status Option $1 cleared
}

; ========== Menus - @find functionality ==========
menu @DLF.*.search {
  Copy line: {
    .clipboard
    .clipboard $sline($active,1)
    cline 14 $active $sline($active,1).ln
  }
  Clear: clear
  Close: window -c $active
  Options: DLF.Options.Show
}

menu @DLF.@find.Results {
  .-
  .Copy line(s): DLF.@find.CopyLines
  $iif(!$script(AutoGet.mrc), $style(2)) Send to AutoGet: DLF.@find.SendToAutoGet
  $iif(!$script(vPowerGet.net.mrc), $style(2)) Send to vPowerGet.NET: DLF.@find.SendTovPowerGet
  Save results: DLF.@find.SaveResults
  Options: DLF.Options.Show
  Clear: clear
  .-
  Close: window -c $active
  .-
}

alias -l DLF.@find.CopyLines {
  var %lines = $sline($active,0)
  if (!%lines) halt
  var %i = $line($active,0)
  while (%i) {
    cline $color(Normal) $active %i
    dec %i
  }
  clipboard
  var %lines = $line($active,0)
  var %i = 1
  while (%i <= %lines) {
    clipboard -an $gettok($sline($active,%i),1,$asc($space)) $DLF.GetFileName($gettok($sline($active,%i),2-,$asc($space)))
    cline 14 $active $sline($active,%i).ln
    inc %i
  }
  dec %i
  if ($active == @DLF.@find.Results) titlebar $active -=- $line(@DLF.@find.Results,0) results so far -=- %i line(s) copied into clipboard
  else titlebar $active -=- New Releases -=- %i line(s) copied into clipboard
}

alias -l DLF.@find.SendToAutoGet {
  var %lines = $sline($active,0)
  if (!%lines) halt
  if ($fopen(MTlisttowaiting)) .fclose MTlisttowaiting
  .fopen MTlisttowaiting $+(",$remove($script(AutoGet.mrc),Autoget.mrc),AGwaiting.ini,")
  set %MTpath %MTdefaultfolder
  var %i = 1
  var %j = 0
  while (%i <= %lines) {
    var %temp = $MTlisttowaiting($replace($sline($active,%i),$nbsp,$space))
    var %j = $calc(%j + $gettok(%temp,1,$asc($space)))
    if ($sbClient.Online($sline($active,%i)) == 1) cline 10 $active $sline($active,%i).ln
    else cline 6 $active $sline($active,%i).ln
    inc %i
  }
  .fclose MTlisttowaiting
  unset %MTpath
  if (%MTautorequest == 1) MTkickstart $gettok(%temp,2,$asc($space))
  MTwhosinque
  echo -s %MTlogo Added %j File(s) To Waiting List From dlFilter
  if ($active == @DLF.@find.Results) titlebar $active -=- $line($active,0) results so far -=- %j line(s) sent to AutoGet
  else titlebar $active -=- New releases -=- %j line(s) sent to AutoGet
}

alias -l DLF.@find.SendTovPowerGet {
  var %lines = $sline($active,0)
  if (!%lines) halt
  var %i = $line($active,0)
  while (%i) {
    cline $color(Normal) $active %i
    dec %i
  }
  var %i = 1
  while (%i <= %lines) {
    if ($com(vPG.NET,AddFiles,1,bstr,$sline($active,%i)) == 0) {
      echo -s vPG.NET: AddFiles failed
    }
    cline 14 $active $sline($active,%i).ln
    inc %i
  }
  if ($active == @DLF.@find.Results) titlebar $active -=- $line(@DLF.@find.Results,0) results so far -=- $calc(%i - 1) line(s) sent to vPowerGet.NET
  else titlebar $active -=- New releases -=- $calc(%i - 1) line(s) sent to vPowerGet.NET
}

alias -l DLF.@find.SaveResults {
  var %filename = $sfile($mircdir,Save $active contents,Save)
  if (!%filename) haltdef
  %filename = $qt($remove(%filename,.txt) $+ .txt)
  savebuf $active %filename
}

; ========== Menus - oNotice functionality ==========
menu @#* {
  Clear: /clear
  $iif(%DLF.o.timestamp == 1,$style(1)) Timestamp: DLF.Option.Toggle o.timestamp
  $iif(%DLF.o.log == 1,$style(1)) Logging: DLF.Option.Toggle o.log
  Options: DLF.Options.Show
  -
  Close: DLF.oNotice.Close
  -
}

alias -l DLF.oNotice.Send {
  var %chatwindow = @ $+ $chan
  if (!$window(%chatwindow)) {
    window -eg1k1l12mSw %chatwindow
    var %log = $qt($+($logdir,%chatwindow,.log))
    if ((%DLF.o.log == 1) && ($exists(%log))) {
      write %log $crlf
      write %log $sqbr($fulldate) ----- Session started -----
      write %log $crlf
      .loadbuf -r %chatwindow %log
    }
  }
}

alias -l DLF.oNotice.Close {
  var %chatwindow = $active, %log = $qt($+($logdir,%chatwindow,.log))
  if ((%DLF.o.log == 1) && ($exists(%log))) {
    write %log $crlf
    write %log $sqbr($fulldate) ----- Session closed -----
    write %log $crlf
  }
  window -c $active
}

; ============================== DLF Options ==============================
alias DLF.Options.Show dialog $iif($dialog(DLF.Options.GUI),-v,-md) DLF.Options.GUI DLF.Options.GUI
alias DLF.Options.Toggle dialog $iif($dialog(DLF.Options.GUI),-c,-md) DLF.Options.GUI DLF.Options.GUI

dialog -l DLF.Options.GUI {
  ; Main dialog
  title dlFilter v $+ $DLF.SetVersion
  size -1 -1 152 225
  option dbu notheme
  text "", 99, 67 2 82 8, right hide
  check "Enable/disable dlFilter", 5, 2 2 62 8
  tab "Main", 1, 1 10 151 198
  tab "Other", 2
  tab "Custom", 3
  tab "About", 98
  button "Close", 4, 2 211 45 11, ok flat
  check "Show/hide filtered lines", 21, 51 211 100 11, push
  ; tab 1 Main
  text "Channels (comma separated, just # for all):", 7, 4 26 132 8, tab 1
  edit "", 6, 3 34 146 10, tab 1 autohs
  box " General ", 8, 4 45 144 47, tab 1
  check "Ads and announcements", 9, 7 54 133 8, tab 1
  check "Searches and file requests", 10, 7 63 133 8, tab 1
  check "Channel mode changes", 17, 7 72 133 8, tab 1
  check "Requests sent to you in pm (@yournick, !yournick)", 33, 7 81 133 8, tab 1
  box " User events ", 11, 4 93 144 84, tab 1
  check "Joins", 12, 7 102 133 8, tab 1
  check "Parts", 13, 7 111 133 8, tab 1
  check "Quits", 14, 7 120 133 8, tab 1
  check "Nick changes", 15, 7 129 133 8, tab 1
  check "Kicks", 16, 7 138 133 8, tab 1
  check "... but show the above in Status window", 18, 15 147 125 8, tab 1
  check "Away and thank-you messages", 19, 7 156 133 8, tab 1
  check "User mode changes", 20, 7 165 133 8, tab 1
  text "Checking for dlFilter updates...", 56, 5 178 144 8, tab 1
  button "dlFilter website", 67, 4 186 70 10, tab 1 flat
  button "Update dlFilter", 66, 78 186 70 10, tab 1 flat disable
  check "Check for beta versions", 68, 4 198 136 8, tab 1
  ; Tab 2 Other
  box " Windows ", 22, 4 25 144 56, tab 2
  check "Filter server notices to separate window", 23, 7 34 120 8, tab 2
  check "Filter server adverts to separate window", 38, 7 43 138 8, tab 2
  check "Separate filter windows per connection", 39, 7 52 138 8, tab 2
  check "Group @find/@locator results", 24, 7 61 138 8, tab 2
  check "Filter oNotices to separate @#window (OpsTalk)", 61, 7 70 138 8, tab 2
  box " Spam and security ", 26, 4 82 145 114, tab 2
  check "Filter spam on channel", 27, 7 91 138 8, tab 2
  check "... and Notify if you are an op", 28, 15 100 130 8, tab 2
  check "Filter private spam", 29, 7 109 138 8, tab 2
  check "... and Notify if you are op in common channel", 30, 15 118 130 8, tab 2
  check "... and /ignore spammer for 1h (asks confirmation)", 31, 15 127 130 8, tab 2
  check "Don't accept any messages or files from users with whom you do not have a common channel", 32, 7 135 138 16, tab 2 multi
  check "... but accept DCC / query chats", 72, 15 151 130 8, tab 2
  check "Do not accept files from regular users (except mIRC trusted users)", 34, 7 160 138 16, tab 2 multi
  check "... block only potentially dangerous filetypes", 75, 15 176 130 8, tab 2
  check "Do not accept private messages from regulars", 35, 7 185 138 8, tab 2
  check "Color uncolored fileservers in nickname list", 62, 4 198 144 8, tab 2
  ; tab 3 Custom
  check "Enable custom strings", 36, 5 27 100 8, tab 3
  text "Message type:", 42, 5 36 50 8, tab 3
  combo 37, 45 36 65 35, tab 3 drop
  edit "", 41, 4 47 144 12, tab 3 autohs
  button "Add", 46, 5 61 67 12, tab 3 flat disable
  button "Remove", 52, 79 61 68 12, tab 3 flat disable
  list 51, 4 74 144 123, tab 3 hsbar vsbar size sort extsel
  ; tab 98 About
  edit "", 97, 3 25 147 181, multi read vsbar tab 98
}

; Initialise variables
alias -l DLF.Options.Initialise {
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
    %DLF.custom.chantext = $addtok(%DLF.custom.chantext,*example*,$asc($comma))
  }
  if (%DLF.channels == $null) {
    DLF.Channels.Set $hashtag
    DLF.Status Channels set to $c(4,all) $+ .
  }
  if (%DLF.betas == $null) %DLF.betas = 0
  if (%DLF.serverads == $null) %DLF.serverads = 0
  if (%DLF.perconnect == $null) %DLF.perconnect = 1
}

on *:dialog:DLF.Options.GUI:init:0: {
  DLF.SetVersion
  var %ver = $DLF.mIRCversion
  if (%ver != 0) {
    did -b DLF.Options.GUI 5
    did -vo DLF.Options.GUI 99 1 Upgrade to mIRC %ver $+ +
  }
  if (%DLF.enabled == 1) did -c DLF.Options.GUI 5
  if (%DLF.netchans == $null) %DLF.netchans = %DLF.channels
  did -o DLF.Options.GUI 6 1 %DLF.netchans
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
  if (%DLF.serverads == 1) did -c DLF.Options.GUI 38
  if (%DLF.perconnect == 1) did -c DLF.Options.GUI 39
  if (%DLF.searchresults == 1) did -c DLF.Options.GUI 24
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
  if (%DLF.betas == 1) did -c DLF.Options.GUI 68
  did -a DLF.Options.GUI 37 Channel text
  did -a DLF.Options.GUI 37 Channel action
  did -a DLF.Options.GUI 37 Channel notice
  did -a DLF.Options.GUI 37 Channel ctcp
  did -a DLF.Options.GUI 37 Private text
  did -a DLF.Options.GUI 37 Private action
  did -a DLF.Options.GUI 37 Private notice
  did -a DLF.Options.GUI 37 Private ctcp
  did -c DLF.Options.GUI 37 1
  DLF.Options.SetCustomType
  DLF.Update.Run
  DLF.Options.About
}

alias -l DLF.Options.About {
  if ($fopen(dlFilter)) .fclose dlFilter
  .fopen dlFilter $script
  var %line = $fread(dlFilter)
  while ((!$feof) && (!$ferr) && ($left(%line,2) != $+(/,*))) {
    %line = $fread(dlFilter)
  }
  if (($feof) || ($ferr)) DLF.Options.AboutError
  var %i = 0
  %line = $fread(dlFilter)
  while ((!$feof) && (!$ferr) && ($left(%line,2) != $+(*,/))) {
    did -a DLF.Options.GUI 97 %line $+ $crlf
    inc %i
    %line = $fread(dlFilter)
  }
  .fclose dlFilter
}

alias -l DLF.Options.AboutError {
  if ($fopen(dlFilter)) .fclose dlFilter
  DLF.Error Unable to find About text to populate About tab.
}

; Handle all checkbox clicks and save
on *:dialog:DLF.Options.GUI:sclick:4-36,38-45,47-50,53-65,68-999: {
  DLF.Options.LinkedFields 27 28
  DLF.Options.LinkedFields 29 30 31
  DLF.Options.LinkedFields 32 72
  DLF.Options.LinkedFields 34 75
  DLF.Options.Save
  if (%DLF.showfiltered == 0) window -c @DLF.filtered
  if (($did == 68) && (!$sock(DLF.Socket.Update))) DLF.Update.CheckVersions
}

alias -l DLF.Options.LinkedFields {
  if ($did == $1) {
    var %i = $0, %flags = $iif($did($1).state,-e,-ub)
    while (%i > 1) {
      did %flags DLF.Options.GUI $ [ $+ [ %i ] ]
      dec %i
    }
  }
}

alias -l DLF.Options.Save {
  DLF.Options.SaveChannels
  %DLF.showfiltered = $did(21).state
  %DLF.enabled = $did(5).state
  DLF.Groups.Events
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
  %DLF.serverads = $did(38).state
  %DLF.perconnect = $did(39).state
  %DLF.searchresults = $did(24).state
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
  %DLF.betas = $did(68).state
}

; Enable / disable Add custom message button
on *:dialog:DLF.Options.GUI:edit:6: DLF.Options.SaveChannels
alias -l DLF.Options.SaveChannels {
  %DLF.netchans = $did(6).text
  DLF.Channels.Set %DLF.netchans
}

alias -l DLF.Groups.Events {
  if (%DLF.enabled) .enable #dlf_events
  else .disable #dlf_events
}

; Select custom message type
on *:dialog:DLF.Options.GUI:sclick:37: DLF.Options.SetCustomType

alias -l DLF.Options.SetCustomType {
  var %selected = $did(37).seltext
  did -r DLF.Options.GUI 51
  if (%selected == Channel text) didtok DLF.Options.GUI 51 44 %DLF.custom.chantext
  if (%selected == Channel action) didtok DLF.Options.GUI 51 44 %DLF.custom.chanaction
  if (%selected == Channel notice) didtok DLF.Options.GUI 51 44 %DLF.custom.channotice
  if (%selected == Channel ctcp) didtok DLF.Options.GUI 51 44 %DLF.custom.chanctcp
  if (%selected == Private text) didtok DLF.Options.GUI 51 44 %DLF.custom.privtext
  if (%selected == Private action) didtok DLF.Options.GUI 51 44 %DLF.custom.privaction
  if (%selected == Private notice) didtok DLF.Options.GUI 51 44 %DLF.custom.privnotice
  if (%selected == Private ctcp) didtok DLF.Options.GUI 51 44 %DLF.custom.privctcp
}

; Enable / disable Add custom message button
on *:dialog:DLF.Options.GUI:edit:41: DLF.Options.SetAddButton
alias -l DLF.Options.SetAddButton {
  if ($did(41)) did -te DLF.Options.GUI 46
  else {
    did -b DLF.Options.GUI 46
    did -t DLF.Options.GUI 4
  }
}

; Enable / disable Remove custom message button
on *:dialog:DLF.Options.GUI:sclick:51: DLF.Options.SetRemoveButton
alias -l DLF.Options.SetRemoveButton {
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
  var %selected = $did(37).seltext
  if (%selected == Channel text) %DLF.custom.chantext = $addtok(%DLF.custom.chantext,%new,$asc($comma))
  elseif (%selected == Channel action) %DLF.custom.chanaction = $addtok(%DLF.custom.chanaction,%new,$asc($comma))
  elseif (%selected == Channel notice) %DLF.custom.channotice = $addtok(%DLF.custom.channotice,%new,$asc($comma))
  elseif (%selected == Channel ctcp) %DLF.custom.chanctcp = $addtok(%DLF.custom.chanctcp,%new,$asc($comma))
  elseif (%selected == Private text) %DLF.custom.privtext = $addtok(%DLF.custom.privtext,%new,$asc($comma))
  elseif (%selected == Private action) %DLF.custom.privaction = $addtok(%DLF.custom.privaction,%new,$asc($comma))
  elseif (%selected == Private notice) %DLF.custom.privnotice = $addtok(%DLF.custom.privnotice,%new,$asc($comma))
  elseif (%selected == Private ctcp) %DLF.custom.privctcp = $addtok(%DLF.custom.privctcp,%new,$asc($comma))
  else DLF.Error Invalid message type: %selected
  ; Clear edit field, list selection and disable add button
  did -r DLF.Options.GUI 41
  DLF.Options.SetAddButton
  DLF.Options.SetCustomType
}

; Customer filter Remove button clicked or double click in list
on *:dialog:DLF.Options.GUI:sclick:52: DLF.Options.Remove
alias -l DLF.Options.Remove {
  var %i = $did(51,0).sel
  var %selected = $did(37).seltext
  while (%i) {
    var %seltext = $did(51,$did(51,%i).sel).text
    if (%selected == Channel text) %DLF.custom.chantext = $remtok(%DLF.custom.chantext,%seltext,1,$asc($comma))
    elseif (%selected == Channel action) %DLF.custom.chanaction = $remtok(%DLF.custom.chanaction,%seltext,1,$asc($comma))
    elseif (%selected == Channel notice) %DLF.custom.channotice = $remtok(%DLF.custom.channotice,%seltext,1,$asc($comma))
    elseif (%selected == Channel ctcp) %DLF.custom.chanctcp = $remtok(%DLF.custom.chanctcp,%seltext,1,$asc($comma))
    elseif (%selected == Private text) %DLF.custom.privtext = $remtok(%DLF.custom.privtext,%seltext,1,$asc($comma))
    elseif (%selected == Private action) %DLF.custom.privaction = $remtok(%DLF.custom.privaction,%seltext,1,$asc($comma))
    elseif (%selected == Private notice) %DLF.custom.privnotice = $remtok(%DLF.custom.privnotice,%seltext,1,$asc($comma))
    elseif (%selected == Private ctcp) %DLF.custom.privctcp = $remtok(%DLF.custom.privctcp,%seltext,1,$asc($comma))
    else DLF.Error Invalid message type: %selected
    dec %i
  }
  did -b DLF.Options.GUI 52
  DLF.Options.SetCustomType
  DLF.Options.SetRemoveButton
}

; Double click on custom text line removes line but puts it into Add box for editing and re-adding.
; Do not put if statement on ON DIALOG line - for some reason it fails without an error message
on *:dialog:DLF.Options.GUI:dclick:51: {
  if ($did(51,0).sel == 1 ) {
    did -o DLF.Options.GUI 41 1 $did(51,$did(51,1).sel).text
    DLF.Options.Remove
    DLF.Options.SetAddButton
  }
}

; Goto website button
on *:dialog:DLF.Options.GUI:sclick:67: url -a https://github.com/SanderSade/dlFilter

; Download update button
on *:dialog:DLF.Options.GUI:sclick:66: {
  did -b DLF.Options.GUI 66
  DLF.Download.Run
}

alias -l DLF.Options.GUI.Status {
  DLF.Status $1-
  if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 56 1 $1-
}

alias -l DLF.IsChannel {
  if ($findtok(%DLF.netchans,$2,$asc($comma))) return $true
  if ($findtok(%DLF.netchans,$+($1,$2),$asc($comma))) return $true
  return $false
}

; ============================== Event catching ==============================

; Convert network#channel to just #channel for On statements
alias -l DLF.Channels.Set {
  %DLF.netchans = $replace($1-,$space,$comma)
  var %r = $+(/,[^,$comma,#]+,$lbr,?=#[^,$comma,#]*,$rbr,/g)
  %DLF.channels = $regsubex(%DLF.netchans,%r,$null)
}

; Check if channel is set whether it is network#channel or just #channel
alias -l DLF.IsChannelEvent {
  if ($1 == 0) return $false
  if (%DLF.netchans == $hashtag) return $true
  if ($istok(%DLF.netchans,$chan,$asc($comma))) return $true
  if ($istok(%DLF.netchans,$+($network,$chan),$asc($comma))) return $true
  return $false
}

; Check whether non-channel event (quit or nickname) is from a network where we are in a defined channel
alias -l DLF.IsNonChannelEvent {
  if ($1 == 0) return $false
  if (%DLF.netchans == $hashtag) return $true
  var %i = $chan(0)
  while (%i) {
    if ($istok(%DLF.netchans,$chan(%i),$asc($comma))) return $true
    if ($istok(%DLF.netchans,$+($network,$chan(%i)),$asc($comma))) return $true
    dec %i
  }
  return $false
}

; Following is just in case groups get reset to default...
; Primarily for developers when e.g. script is reloaded on change by authors autoreload script
#dlf_bootstrap on
on *:text:*:*: DLF.Groups.Bootstrap
alias -l DLF.Groups.Bootstrap {
  if (%DLF.enabled != $null) DLF.Groups.Events
  .disable #dlf_bootstrap
}
#dlf_bootstrap end

#dlf_events off

; Channel user activity
; join, art, quit, nick changes, kick
on ^*:join:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.joins)) DLF.User.Channel Join $chan $nick $br($address) has joined $chan
on ^*:part:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.parts)) DLF.User.Channel Part $chan $nick $br($address) has left $chan
on ^*:kick:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.kicks)) DLF.User.Channel Kick $chan $knick $br($address($knick,5)) was kicked from $chan by $nick $br($1-)
; TODO check that channel is on correct network
on ^*:nick: if ($DLF.IsNonChannelEvent(%DLF.nicks)) DLF.User.NoChannel $newnick Nick $nick $br($address) is now known as $newnick
on ^*:quit: if ($DLF.IsNonChannelEvent(%DLF.quits)) DLF.User.NoChannel $nick Quit $nick $br($address) Quit $br($1-).

; Channel mode changes
; ban, unban, op, deop, voice, devoice etc.
on ^*:ban:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:unban:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:op:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:deop:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:voice:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:devoice:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:serverop:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:serverdeop:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:servervoice:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:serverdevoice:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.usrmode)) halt
on ^*:mode:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.chmode)) halt
on ^*:servermode:%DLF.channels: if ($DLF.IsChannelEvent(%DLF.chmode)) halt

; Channel messages
on *:input:#: {
  if ($DLF.IsChannelEvent) {
    if (($1 == @find) || ($1 == @locator)) DLF.Channel.FindRequest $1-
    if (($left($1,1) isin !@) && ($right($1,-1) ison $chan)) DLF.Channel.ServerRequest $1-
  }
}
alias -l DLF.Channel.ServerRequest echo -at DLF.Channel.ServerRequest called: $1-
alias -l DLF.Channel.FindRequest echo -at DLF.Channel.FindRequest called: $1-

on ^*:text:*:%DLF.channels: if ($DLF.IsChannelEvent) DLF.Channels.Text $1-
on ^*:action:*:%DLF.channels: if ($DLF.IsChannelEvent) DLF.Channels.Action $1-
on ^*:notice:*:%DLF.channels: if ($DLF.IsChannelEvent) DLF.Channels.Notice $1-
on ^*:notice:*:#: if ($DLF.Channels.IsoNotice) DLF.Channels.oNotice $1-

; Channel ctcp
ctcp *:*ping*:%DLF.channels: if ($DLF.IsChannelEvent) haltdef
ctcp *:*:%DLF.channels: if ($DLF.IsChannelEvent) DLF.Channels.ctcp $1-
ctcp ^*:DCC CHAT:?: DLF.dcc.ChatRequest $1-
ctcp ^*:DCC SEND:?: DLF.dcc.SendRequest $1-
alias -l DLF.dcc.ChatRequest echo -st DLF.dcc.ChatRequest called: $1-
alias -l DLF.dcc.SendRequest echo -st DLF.dcc.SendRequest called: $1-

; Private messages
on ^*:text:*:?: DLF.Private.Text $1-
on ^*:notice:*:?: DLF.Private.Notice $1-
on ^*:action:*:?: DLF.Private.Action $1-

; ctcp replies
on *:CTCPREPLY:*: DLF.ctcp.Reply $1-

; Filter away messages
raw 301:*: DLF.Away.Filter $1-
#dlf_events end

; ========== Event processing code ==========
; Channel user activity
; join, art, quit, nick changes, kick
alias -l DLF.User.Channel {
  if (%DLF.showstatus == 1) echo -stnc $1 $sqbr($2) $star $3-
  DLF.Filter.Text $1-
}

alias -l DLF.User.NoChannel {
  if (%DLF.netchans != #) {
    var %i = $comchan($1,0)
    while (%i) {
      var %chan = $comchan($1,%i)
      if ($DLF.IsChannel($network,%chan) == $false) echo -ct $2 %chan $star $3-
      dec %i
    }
  }
  DLF.User.Channel $2 $hashtag $3-
}

; Since %DLF.custom.x can be empty, this must be called as an identifier
; $DLF.Custom.Check(%DLF.custom.x,colourname,channel,nick,text)
alias -l DLF.Custom.Check {
  if ((%DLF.custom.enabled == 1) && ($1)) {
    var %i = $numtok($1,$asc($comma))
    var %txt = $strip($5-)
    while (%i) {
      if ($gettok($1,%i,$asc($comma)) iswm %txt) DLF.Filter.Text $2 $3 $4 $5-
      dec %i
    }
  }
}

; Channel messages
alias -l DLF.Channels.Text {
  noop $DLF.Custom.Check(%DLF.custom.chantext,Normal,$chan,$nick,$1-)
  var %txt = $strip($1-)
  if ((%DLF.ads == 1) && ($hfind(DLF.text.ads,%txt,1,W))) DLF.Filter.SetNickColour Normal $chan $nick $1-
  if ((%DLF.requests == 1) && ($hfind(DLF.text.cmds,%txt,1,W))) DLF.Filter.Text Normal $chan $nick $1-
  if ((%DLF.away == 1) && ($hfind(DLF.text.away,%txt,1,W))) DLF.Filter.Text Normal $chan $nick $1-
  if ($hfind(DLF.text.always,%txt,1,W)) DLF.Filter.Text Normal $chan $nick $1-
  /*if (%DLF.chspam == 1) {
    ;no channel spam right now
  }
  */
}

alias -l DLF.Channels.Action {
  noop $DLF.Custom.Check(%DLF.custom.chanaction,Action,$chan,$nick,$1-)
  var %DLF.action = $strip($1-)
  if ((%DLF.ads == 1) && ($hfind(DLF.action.ads,%DLF.action,1,W))) DLF.Filter.Text Action $chan $nick $1-
  if ((%DLF.away == 1) && ($hfind(DLF.action.away,%DLF.action,1,W))) DLF.Filter.Text Action $chan $nick $1-
}

alias -l DLF.Channels.Notice {
  noop $DLF.Custom.Check(%DLF.custom.channotice,Notice,$chan,$nick,$1-)
  if ((%DLF.chspam == 1) && ($hfind(DLF.notice.spam,$strip($1-),1,W))) DLF.Channel.SpamFilter $chan $nick $1-
}

alias DLF.Channels.IsoNotice {
  if (%DLF.o.enabled != 1) return 0
  if ($target != $+(@,$chan)) return 0
  if ($me !isop $chan) return 0
  if ($nick !isop $chan) return 0
  return 1
}

alias -l DLF.Channels.oNotice {
  var %chatwindow = @ $+ $chan
  if (!$window(%chatwindow)) {
    window -eg1k1l12mnSw %chatwindow
    if (%DLF.o.log == 1) {
      var %log = $qt($+(logdir,%chatwindow,.log))
      write %log $crlf
      write %log $sqbr($fulldate) ----- Session started -----
      write %log $crlf
      .loadbuf -r %chatwindow %log
    }
  }
  if ($1 == @) var %omsg = $2-
  else var %omsg = $1-
  window -S %chatwindow
  aline -nl $color(nicklist) %chatwindow $nick
  if ($gettok(%omsg,1,$asc($space)) == /me) {
    %omsg = $star $nick $gettok(%omsg,2-,$asc($space))
    if (%DLF.o.timestamp == 1) var %omsg = $timestamp %omsg
    aline -ph $color(action) %chatwindow %omsg
    } else {
    %omsg = $tag($nick) %omsg
    if (%DLF.o.timestamp == 1) var %omsg = $timestamp %omsg
    aline -ph $color(text) %chatwindow %omsg
  }
  if (%DLF.o.log == 1) write $+(",$logdir,%chatwindow,.log,") %omsg
  halt
}

alias -l DLF.Channels.ctcp {
  noop $DLF.Custom.Check(%DLF.custom.chanctcp,Notice,$target,$nick,$1-)
  if ($hfind(DLF.ctcp.spam,$1-,1,W)) {
    DLF.SetNickColour $chan $nick
    haltdef
  }
}

on ^*:open:*: {
  DLF.Private.Text $1-
}

alias -l DLF.Private.Text {
  if ((%DLF.nocomchan.dcc == 1) && (%DLF.accepthis == $target)) return
  if ($+(*,$dollar,decode*) iswm $1-) DLF.Warning Do not paste any messages containing $b($dollar $+ decode) to your mIRC. They are mIRC worms & the people sending them are infected. Instead, please report such messages to the channel ops.

  noop $DLF.Custom.Check(%DLF.custom.privtext,Normal,Private,$nick,$1-)
  var %txt = $strip($1-)
  if ($window(1)) DLF.Check.CommonChan $nick $1-
  if ((%DLF.noregmsg == 1) && ($DLF.Check.RegularUser($nick) == IsRegular)) {
    DLF.Warning Regular user $nick $br($address($nick,0)) tried to: $1-
    if ($window($nick)) window -c $nick
    halt
  }
  if (%DLF.privrequests == 1) {
    if ($nick === $me) return
    var %fword = $strip($1)
    var %nicklist = @ $+ $me
    var %nickfile = ! $+ $me
    if ((%nicklist == %fword) || (%nickfile == %fword) || (%nickfile == $gettok($strip($1),1,$asc($hyphen)))) {
      .msg $1 Please $u(do not request in private) $+ . All commands go to $u(channel).
      .msg $1 You may have to go to $c(2,mIRC options --->> Sounds --->> Requests) and uncheck $qt($c(3,Send '!nick file' as private message))
      if (($window($nick)) && ($line($nick,0) == 0)) .window -c $nick
      halt
    }
  }
  if ((%DLF.privspam == 1) && ($hfind(DLF.priv.spam,%txt,1,W)) && (!$window($1))) DLF.Private.SpamFilter $1-
  if ((%DLF.searchresults == 1) && (%DLF.searchactive == 1)) {
    if ($hfind(DLF.search.headers,%txt,1,W)) DLF.Find.Headers $nick $1-
    if ((*Omen* iswm $1) && ($pling isin $2)) DLF.Find.Results $nick $1-
    if ($pos($1,$pling,1) == 1) DLF.Find.Results $nick $1-
    if (($1 == $colon) && ($pos($2,$pling,1) == 1)) DLF.Find.Results $nick $1-
  }
  if ((%DLF.server == 1) && ($hfind(DLF.priv.spam,%txt,1,W)) DLF.Find.Headers $nick $1-
  if ((%DLF.away == 1)  && ($hfind(DLF.priv.away,%txt,1,W)) DLF.Filter.Text Normal Private $nick $1-
}

alias -l DLF.Private.Notice {
  noop $DLF.Custom.Check(%DLF.custom.privnotice,Notice,Private,$nick,$1-)
  var %txt = $strip($1-)
  DLF.Check.CommonChan $nick %txt
  if ((%DLF.noregmsg == 1) && ($DLF.Check.RegularUser($nick) == IsRegular)) {
    DLF.Warning Regular user $nick $br($address) tried to send you a notice: $1-
    halt
  }
  if ((%DLF.server == 1) && ($hfind(DLF.notice.server,%txt,1,W))) DLF.Filter.Server $nick $1-
  if (*SLOTS My mom always told me not to talk to strangers* iswm %txt) DLF.Filter.Text Notice Notice $nick $1-
  if (*CTCP flood detected, protection enabled* iswm %txt) DLF.Filter.Text Notice Notice $nick $1-
  if ((%DLF.searchresults == 1) && (%DLF.searchactive == 1)) {
    if (No match found for* iswm %txt) DLF.Filter.Server $nick $1-
    if (*I have*match* for*in listfile* iswm %txt) DLF.Filter.Server $nick $1-
    tokenize $asc($space) %txt
    if ($pos($1,$pling,1) == 1) DLF.Find.Results $nick $1-
  }
}

alias -l DLF.Private.Action {
  noop $DLF.Custom.Check(%DLF.custom.privaction,Action,Private,$nick,$1-)
  DLF.Check.CommonChan $nick $1-
  if ((%DLF.noregmsg == 1) && ($DLF.Check.RegularUser($nick) == IsRegular)) {
    DLF.Warning Regular user $nick $br($address) tried to send you an action: $1-
    .window -c $1
    .close -m $1
    halt
  }
}

ctcp *:*:?: {
  if ((%DLF.nocomchan.dcc == 1) && ($1-2 === DCC CHAT)) {
    %DLF.accepthis = $nick
    goto :return
  }
  noop $DLF.Custom.Check(%DLF.custom.privctcp,Notice,Private,$nick,$1-)
  if (%DLF.nocomchan == 1) DLF.Check.CommonChan $nick $1-
  if ((%DLF.askregfile == 1) && (DCC SEND isin $1-)) {
    if ($DLF.Check.RegularUser($nick) == IsRegular) {
      ; Allow files from regular users if nickname is in mIRC DCC trust list
      var %addr = $address($nick,5)
      if (%addr != $null) {
        %rcntr = $trust(0)
        while (%rcntr) {
          echo -s $trust(%rcntr) %addr
          if ($trust(%rcntr) iswm %addr) goto :return
          dec %rcntr
        }
      }
      ; If not in trust list check for dangerous filetypes
      if (%DLF.askregfile.type == 1) {
        var %ext = $right($nopath($filename),4)
        if ($pos(%ext,$period,1) == 2) %ext = $right(%ext,3)
        if ((%ext != .exe) $&
          && (%ext != .com) $&
          && (%ext != .bat) $&
          && (%ext != .scr) $&
          && (%ext != .mrc) $&
          && (%ext != .pif) $&
          && (%ext != .vbs) $&
          && (%ext != .doc) $&
          && (%ext != .js)) goto :return
      }
      DLF.Status $c(3,Regular user $nick $br($address) tried to send you a file $qt($gettok($1-,3-$numtok($1-,$asc($space)), $asc($space))))
      halt
    }
  }
  if ((%DLF.noregmsg == 1) && (($DLF.Check.RegularUser($nick) == IsRegular)) && (DCC send !isin $1-)) {
    DLF.Warning Regular user $nick $br($address) tried to: $1-
    halt
  }
  :return
}

alias -l DLF.Filter.SetNickColour {
  DLF.SetNickColour $1 $2
  DLF.Filter.Text $1-
}

alias -l DLF.Filter.Text {
  if (($1 == Normal) && ($2 == Private) && ($window($3))) .window -c $3
  var %nc = $+($network,$2)
  if (%DLF.filtered.log == 1) write $qt($logdir $+ DLF.Filtered.log) $sqbr($fulldate) $sqbr(%nc) $tag($3) $strip($4-)
  if (%DLF.showfiltered == 1) {
    if (!$window(@DLF.Filtered)) {
      window -k0nwz @DLF.filtered
      titlebar @DLF.filtered -=- Right-click for options
    }
    if ($1 == Normal) var %line = $sqbr(%nc) $tag($3) $4-
    else var %line = $sqbr(%nc) $3-
    if ((%DLF.filtered.limit == 1) && ($line(@DLF.filtered,0) >= 5000)) dline @DLF.Filtered 1-100
    if (%DLF.filtered.timestamp == 1) %line = $timestamp %line
    if (%DLF.filtered.strip == 1) %line = $strip(%line)
    if (%DLF.filtered.wrap == 1) aline -p $color($1) @DLF.filtered %line
    else aline $color($1) @DLF.filtered %line
  }
  halt
}

on *:input:@DLF.Filtered.Search: FilteredSearch $1-

alias -l FilteredSearch {
  window -ealbk0wz @DLF.filtered.search
  var %sstring = $+($star,$1-,$star)
  titlebar @DLF.filtered.search -=- Searching for %sstring
  filter -wwbpc @DLF.filtered @DLF.Filtered.search %sstring
  var %found = $line(@DLF.Filtered.search,0)
  var %matches = $iif(%found == 0,No matches,$iif(%found == 1,One match,%found matches))
  titlebar @DLF.filtered.search -=- Search finished. %matches found for $qt(%sstring)
}

on *:input:@#* {
  if ((/ == $left($1,1)) && ($ctrlenter == $false) && ($1 != /me)) return
  if (($1 != /me) || ($ctrlenter == $true)) {
    var %omsg = $tag($me) $1-
    if (%DLF.o.timestamp == 1) var %omsg = $timestamp %omsg
    aline -p $color(text) $active %omsg
    aline -nl $color(nicklist) $active $me
    window -S $active
    var %ochan = $replace($active,@,$null)
    .onotice %ochan $1-
    if (%DLF.o.log == 1) write $+(",$logdir,$active,.log") %omsg
  }
  else {
    var %omsg = $star $me $2-
    if (%DLF.o.timestamp == 1) var %omsg = $timestamp %omsg
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
    var %log = $qt($+(logdir,%chatwindow,.log))
    write %log $crlf
    write %log $sqbr($fulldate) ----- Session closed -----
    write %log $crlf
  }
}

alias -l DLF.Filter.Server {
  var %line = $tag($1) $2-
  if ($2 == $colon) %line = $remtok(%line,$colon,1,$asc($space))
  if (%DLF.server.log == 1) write $qt($+($logdir,DLF.Server.log) $sqbr($fulldate) $strip(%line)
  if (!$window(@DLF.Server)) {
    window -k0nwz @DLF.Server
    titlebar @DLF.Server -=- Right-click for options
  }
  if ((%DLF.server.limit == 1) && ($line(@DLF.Server,0) >= 5000)) dline @DLF.Server 1-100
  if (%DLF.server.timestamp == 1) %line = $timestamp %line
  if (%DLF.server.strip == 1) %line = $strip(%line)
  if (%DLF.server.wrap == 1) aline -p @DLF.Server %line
  else aline @DLF.Server %line
  halt
}

on *:input:@DLF.Server.Search: ServerSearch $1-

alias -l ServerSearch {
  window -ealbk0wz @DLF.Server.Search
  var %sstring = $star $+ $1- $+ $star
  titlebar @DLF.server.search -=- Searching for %sstring
  filter -wwbpc @DLF.server @DLF.server.search %sstring
  if ($line(@DLF.server.search,0) == 0) titlebar @DLF.server.search -=- Search finished. No matches for " $+ %sstring $+ " found.
  else titlebar @DLF.server.search -=- Search finished. $line(@DLF.server.search,0) matches found for " $+ %sstring $+ ".
}

alias -l DLF.Channel.SpamFilter {
  if ((%DLF.chspam.opnotify == 1) && ($me isop $1)) {
    DLF.Warning $c(4,Channel spam detected:) $sqbr($1) $tag($2) $br($address($2,1)) -->> $c(4,$3-)
  }
  halt
}

alias -l DLF.Private.SpamFilter {
  if ((%DLF.privspam.opnotify == 1) && ($comchan($1,1).op)) {
    DLF.Warning Spam detected: $c(4,15,$tag($1) $br($address($1,1)) -->> $b($2-))
    echo $comchan($1,1) Private spam detected: $c(4,15,$tag($1) $br($address($1,1)) -->> $b($2-))
  }
  if ((%DLF.spam.addignore == 1) && ($input(Spam received from $1 ( $+ $address($1,1) $+ ). Spam was: " $+ $2- $+ ". Add this user to ignore for one hour?,yq,Add spammer to /ignore?) == $true)) /ignore -wu3600 $1 4
  if ($window($1)) .window -c $1
  halt
}

alias -l DLF.Channel.FindRequest {
  .set -u600 %DLF.searchactive 1
}

alias -l DLF.Find.Headers {
  if (($window($1)) && (!$line($1,0))) .window -c $1
  DLF.Filter.Server $1-
  halt
}

alias -l DLF.Find.Results {
  if (($window($1)) && (!$line($1,0))) .window -c $1
  if (!$window(@DLF.@find.Results)) window -slk0wnz @DLF.@find.Results
  var %line = $right($2-,$calc($len($2-) - ($pos($2-,$pling,1) - 1)))
  aline -n @DLF.@find.Results %line
  window -b @DLF.@find.Results
  titlebar @DLF.@find.Results -=- $line(@DLF.@find.Results,0) results so far -=- Right-click for options
  halt
}

alias -l DLF.Check.CommonChan {
  if ((%DLF.accepthis == $1) && (%DLF.nocomchan.dcc == 1)) {
    .unset %DLF.accepthis
    goto networkservs
  }
  if ((!$comchan($1,1)) && (%DLF.nocomchan == 1)) {
    if (($1 == X) || ($1 == ChanServ) || ($1 == NickServ) || ($1 == MemoServ) || ($1 == Global)) goto networkservs
    if (($window($1)) && (!$line($1,0))) {
      DLF.Status $b($1) (no common channel) tried: $c(4,15,$2-)
      .window -c $1
    }
    if (($window($eq $+ $1)) && (%DLF.nocomchan.dcc == 0)) {
      .window -c $eq $+ $1
    }
    halt
  }
  :networkservs
}

alias -l DLF.Check.RegularUser {
  if ($1 == $me) return $1
  if ($1 == ChanServ) return $1
  if ($1 == NickServ) return $1
  if ($1 == MemoServ) return $1
  if ($1 == OperServ) return $1
  if ($1 == BotServ) return $1
  if ($1 == HostServ) return $1
  if ($1 == HelpServ) return $1
  if ($1 == GroupServ) return $1
  if ($1 == InfoServ) return $1
  var %rcntr = $comchan($1,0)
  while (%rcntr) {
    if (($1 isop $comchan($1,%rcntr)) || ($1 isvoice $comchan($1,%rcntr))) return $comchan($1,%rcntr)
    dec %rcntr
  }
  return IsRegular
}

alias -l DLF.GetFileName {
  var %file = $1-
  var %Filetypes = .mp3;.wma;.mpg;.mpeg;.zip;.bz2;.txt;.exe;.rar;.tar;.jpg;.gif;.wav;.aac;.asf;.vqf;.avi;.mov;.mp2;.m3u;.kar;.nfo;.sfv;.m2v;.iso;.vcd;.doc;.lit;.pdf;.r00;.r01;.r02;.r03;.r04;.r05;.r06;.r07;.r08;.r09;.r10;.shn;.md5;.html;.htm;.jpeg;.ace;.png;.c01;.c02;.c03;.c04;.rtf;.wri;.txt
  tokenize $asc($space) $replace($1-,$nbsp,$space)
  var %Temp.Count = 1
  while (%Temp.Count <= $numtok($1-,$asc($period))) {
    var %Temp.Position = $pos($1-,.,%Temp.Count)
    var %Temp.Filetype = $mid($1-,%Temp.Position,5)
    var %Temp.Length = $len(%Temp.Filetype)
    if ($istok(%Filetypes,%Temp.Filetype,$asc($semicolon))) return $left($1-,$calc(%Temp.Position + %Temp.Length))
    inc %Temp.Count
  }
  if ($pos(%file,.,0) == 2) return $mid(%file,1,$calc($pos(%file,.,1) + 4))
  return $1-
}

alias -l DLF.ctcp.Reply {
  if ($hfind(DLF.ctcp.reply,$1-,1,W)) halt
  if (%DLF.nocomchan == 1) DLF.Check.CommonChan $nick $1-
  if ((%DLF.noregmsg == 1) && (($DLF.Check.RegularUser($nick) == IsRegular)) && (DCC send !isin $1-)) {
    DLF.Warning Regular user $nick ( $+ $address $+ ) tried to: $1-
    halt
  }
  noop $DLF.Custom.Check(%DLF.custom.privctcp,Notice,Private,$nick,$1-)
}

alias -l DLF.SetNickColour {
  if ((%DLF.colornicks == 1) && ($nick($1,$2).color == $color(nicklist))) cline 2 $1 $2
}

alias -l DLF.Away.Filter {
  if (%DLF.away == 1) DLF.Filter.Text Notice RawAway $2-
  haltdef
}

; ========== Check version for updates ==========
on *:connect: DLF.Update.Check

; Check once per week for normal releases and once per day if user is wanting betas
alias -l DLF.Update.Check {
  var %days = $calc($int(($ctime - %DLF.LastUpdateCheck) / 60 / 60 / 24))
  if ((%days >= 7) || ((%DLF.betas) && (%days >= 1))) DLF.Update.Run
}

alias -l DLF.Update.Run {
  if ($dialog(DLF.Options.GUI)) did -b DLF.Options.GUI 66
  DLF.Options.GUI.Status Checking for dlFilter updates...
  DLF.Socket.Get Update https://raw.githubusercontent.com/SanderSade/dlFilter/dlFilter-v118/dlFilter.version DLF.Options.GUI 56
}

on *:sockread:DLF.Socket.Update: {
  DLF.Socket.Headers
  var %line, %mark = $sock($sockname).mark
  var %state = $gettok(%mark,1,$asc($space))
  if (%state != Body) DLF.Socket.Error Cannot process response: Still processing %state
  %DLF.version.web =
  %DLF.version.web.mirc =
  %DLF.version.beta =
  %DLF.version.beta.mirc =
  while ($true) {
    sockread %line
    if ($sockerr > 0) DLF.Socket.SockErr sockread:Body
    if ($sockbr == 0) break
    DLF.Update.ProcessLine %line
  }
}

on *:sockclose:DLF.Socket.Update: {
  var %line
  sockread -f %line
  if ($sockerr > 0) DLF.Socket.SockErr sockclose
  if ($sockbr > 0) DLF.Update.ProcessLine %line
  DLF.Update.CheckVersions
}

alias -l DLF.Update.ProcessLine {
  if ($gettok($1-,1,$asc($eq)) == dlFilter) {
    %DLF.version.web = $gettok($1-,2,$asc($eq))
    %DLF.version.web.mirc = $gettok($1-,3,$asc($eq))
    set %DLF.LastUpdateCheck $ctime
  }
  elseif ($gettok($1-,1,$asc($eq)) == dlFilter.beta) {
    %DLF.version.beta = $gettok($1-,2,$asc($eq))
    %DLF.version.beta.mirc = $gettok($1-,3,$asc($eq))
  }
}

alias -l DLF.Update.CheckVersions {
  if ($dialog(DLF.Options.GUI)) did -b DLF.Options.GUI 66
  if (%DLF.version.web) {
    if ((%DLF.betas) $&
      && (%DLF.version.beta) $&
      && (%DLF.version.beta > %DLF.version.web)) {
      if (%DLF.version.beta > $DLF.SetVersion) DLF.Update.DownloadAvailable %DLF.version.beta %DLF.version.beta.mirc beta
      elseif (%DLF.version.web == $DLF.SetVersion) DLF.Options.GUI.Status Running current version of dlFilter beta
      else DLF.Options.GUI.Status Running a newer version $br($DLF.SetVersion) than web beta version $br(%DLF.version.beta)
    }
    elseif (%DLF.version.web > $DLF.SetVersion) DLF.Update.DownloadAvailable %DLF.version.web %DLF.version.web.mirc
    elseif (%DLF.version.web == $DLF.SetVersion) DLF.Options.GUI.Status Running current version of dlFilter
    else DLF.Options.GUI.Status Running a newer version $br($DLF.SetVersion) than website $br(%DLF.version.web)
  }
  else DLF.Socket.Error dlFilter version missing!
}

alias -l DLF.Update.DownloadAvailable {
  var %ver = $iif($3,$3 version,version) $1
  if ($version >= $2) {
    DLF.Options.GUI.Status You can update dlFilter to %ver
    did -e DLF.Options.GUI 66
  }
  else DLF.Options.GUI.Status Upgrade mIRC before you can update to %ver

  var %cid = $cid
  while (%nets) {
    scid $scon(%nets)
    if (%DLF.netchans == #) {
      var %nets = $scon(0)
      var %cnt = $chan(0)
      while (%cnt) {
        DLF.Update.ChanAnnounce $chan(%cnt) $1 $2 $3
        dec %cnt
      }
    }
    else {
      var %cnt = $numtok(%DLF.netchans,$asc($comma))
      while (%cnt) {
        var %chan = $gettok(%DLF.netchans,%cnt,$asc($comma))
        ; Handle network#chans
        if ($chan(%chan)) DLF.Update.ChanAnnounce %chan $1 $2 $3
        dec %cnt
      }
    }
    dec %nets
  }
  scid %cid
}

; Announce new version whenever user joins an enabled channel.
on me:*:join:%DLF.channels: {
  if (%DLF.version.web) {
    if ((%DLF.betas) $&
      && (%DLF.version.beta) $&
      && (%DLF.version.beta > %DLF.version.web) $&
      && (%DLF.version.beta > $DLF.SetVersion)) DLF.Update.ChanAnnounce $chan %DLF.version.beta %DLF.version.beta.mirc beta
    elseif (%DLF.version.web > $DLF.SetVersion) DLF.Update.ChanAnnounce $chan %DLF.version.web %DLF.version.web.mirc
  }
}

alias -l DLF.Update.ChanAnnounce {
  var %ver = $iif($4,$4 version,version) $br($2)
  echo -t $1 $c(1,9,$DLF.logo A new %ver of dlFilter is available.)
  if ($3 > $version) echo -t $1 $c(1,9,$DLF.logo However you need to $c(4,upgrade mIRC) before you can download it.)
  else echo -t $1 $c(1,9,$DLF.logo Use the Update button in dlFilter Options to download and install.)
}

; ========== Download new version ==========
alias -l DLF.Download.Run {
  DLF.Options.GUI.Status Downloading new version of dlFilter...
  var %newscript = $qt($script $+ .new)
  if ($isfile(%newscript)) .remove %newscript
  if ($exists(%newscript)) DLF.Socket.Error Unable to delete old temporary download file.
  DLF.Socket.Get Download https://raw.githubusercontent.com/SanderSade/dlFilter/dlFilter-v118/dlFilter.mrc DLF.Options.GUI 56
}

on *:sockread:DLF.Socket.Download: {
  DLF.Socket.Headers
  var %mark = $sock($sockname).mark
  var %state = $gettok(%mark,1,$asc($space))
  if (%state != Body) DLF.Socket.Error Cannot process response: Still processing %state
  var %newscript = $qt($script $+ .new)
  while ($true) {
    sockread &block
    if ($sockerr > 0) DLF.Socket.SockErr sockread:Body
    if ($sockbr == 0) break
    bwrite %newscript -1 -1 &block
  }
}

on *:sockclose:DLF.Socket.Download: {
  var %newscript = $qt($script $+ .new)
  var %oldscript = $qt($script $+ .v $+ $DLF.SetVersion)
  var %oldsaved = $false
  sockread -f &block
  if ($sockerr > 0) DLF.Socket.SockErr sockclose
  if ($sockbr > 0) bwrite %newscript -1 -1 &block
  if ($isfile(%oldscript)) .remove %oldscript
  if ($exists(%oldscript)) .remove $script
  else {
    .rename $script %oldscript
    %oldsaved = $true
  }
  .rename %newscript $script
  %DLF.version = %DLF.version.web
  DLF.Socket.Status New version of dlFilter downloaded and installed
  if (%oldsaved) DLF.Status Old version of dlFilter.mrc saved as %oldscript in case you need to revert
  signal DLF.Update.Reload
  .reload -rs1 $script
}

on *:signal:DLF.Update.ReLoad: DLF.Initialise

alias -l DLF.Download.Error {
  DLF.Update.ErrorMsg Unable to download new version of dlFilter!
}

; ========== Create dlFilter.gif if needed ==========
alias -l DLF.CreateGif {
  /bset -ta &gif 1 eJxz93SzsEwUYBBg+M4AArpO837sZhgFo2AEAsWfLIwMDP8ZdEAcUJ5g4PBn
  /bset -ta &gif 61 +M8p47Eh4SAD4z9FkwqDh05tzOJ2LSsCGo52S7ByuHQYJLu1yghX7fkR8MiD
  /bset -ta &gif 121 UVWWTWKm0JP9/brycT0SQinu3Syqt2I6Jz86MNOOlYmXy0SBwRoAZQAkYg==
  DLF.CreateBinaryFile &gif $+($nofile($script),dlFilter.gif)
}

; ========== Define message matching hash tables ==========
alias -l DLF.hadd {
  var %h = DLF. $+ $1
  if (!$hget(%h)) hmake %h 10
  var %n = $hget($1, 0)
  hadd %h %n $2-
}

alias -l DLF.CreateHashTables {
  var %matches = 0
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
  inc %matches $hget(DLF.text.ads,0).item

  if ($hget(DLF.text.cmds)) hfree DLF.text.cmds
  DLF.hadd text.cmds !*
  DLF.hadd text.cmds @*
  inc %matches $hget(DLF.text.cmds,0).item

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
  inc %matches $hget(DLF.text.away,0).item

  if ($hget(DLF.text.always)) hfree DLF.text.always
  DLF.hadd text.always 2find *
  DLF.hadd text.always Sign in to turn on 1-Click ordering.
  DLF.hadd text.always ---*KB
  DLF.hadd text.always ---*MB
  DLF.hadd text.always ---*KB*s*
  DLF.hadd text.always ---*MB*s*
  DLF.hadd text.always #find *
  DLF.hadd text.always "find *
  inc %matches $hget(DLF.text.always,0).item

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
  inc %matches $hget(DLF.action.away,0).item

  if ($hget(DLF.action.ads)) hfree DLF.action.ads
  DLF.hadd action.ads *FTP*port*user*pass*
  DLF.hadd action.ads *get AMIP*plug-in at http*amip.tools-for.net*
  inc %matches $hget(DLF.action.ads,0).item

  if ($hget(DLF.notice.server)) hfree DLF.notice.server
  DLF.hadd notice.server *I have added*
  DLF.hadd notice.server *After waiting*min*
  DLF.hadd notice.server *This makes*times*
  DLF.hadd notice.server *is on the way!*
  DLF.hadd notice.server *has been sent sucessfully*
  DLF.hadd notice.server *has been sent successfully*
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
  inc %matches $hget(DLF.notice.server,0).item

  if ($hget(DLF.notice.spam)) hfree DLF.notice.spam
  DLF.hadd notice.spam *WWW.TURKSMSBOT.CJB.NET*
  DLF.hadd notice.spam *free-download*
  inc %matches $hget(DLF.notice.spam,0).item

  if ($hget(DLF.ctcp.reply)) hfree DLF.ctcp.reply
  DLF.hadd ctcp.reply *SLOTS*
  DLF.hadd ctcp.reply *ERRMSG*
  DLF.hadd ctcp.reply *MP3*
  inc %matches $hget(DLF.ctcp.reply,0).item

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
  inc %matches $hget(DLF.priv.spam,0).item

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
  inc %matches $hget(DLF.search.headers,0).item

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
  inc %matches $hget(DLF.priv.server,0).item

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
  inc %matches $hget(DLF.priv.away,0).item

  if ($hget(DLF.ctcp.spam)) hfree DLF.ctcp.spam
  DLF.hadd ctcp.spam *SLOTS*
  DLF.hadd ctcp.spam *OmeNServE*
  DLF.hadd ctcp.spam *RAR*
  DLF.hadd ctcp.spam *WMA*
  DLF.hadd ctcp.spam *ASF*
  DLF.hadd ctcp.spam *SOUND*
  DLF.hadd ctcp.spam *MP*
  inc %matches $hget(DLF.ctcp.spam,0).item

  DLF.Status Added %matches wildcard templates
}

; ========== Extend $regml to handle empty groups correctly
alias -l DLF.regml {
  var %reg = $iif($2,$1,), %n = $iif($2,$2,$1)
  var %cnt = $iif(%reg,$regml(%reg,0),$regml(0))
  while (%cnt) {
    var %grp = $iif(%reg,$regml(%reg,%cnt).group,$regml(%cnt).group)
    if (%n == 0) return %grp
    if (%grp == %n) return $iif(%reg,$regml(%reg,%cnt),$regml(%cnt))
    dec %cnt
  }
}

; ========== Status and error messages ==========
alias -l DLF.logo return $rev([dlFilter])
alias -l DLF.Status echo -ts $c(1,9,$DLF.logo $1-)
alias -l DLF.Warning echo -tas $c(1,9,$DLF.logo $1-)
alias -l DLF.Error DLF.Warning $c(4,$b(Error:)) $1-

; ========== Identifiers instead of $chr(xx) - more readable ==========
alias -l space returnex $chr(32)
alias -l nbsp return $chr(160)
alias -l amp return $chr(38)
alias -l star return $chr(42)
alias -l hashtag returnex $chr(35)
alias -l dollar return $chr(36)
alias -l comma return $chr(44)
alias -l hyphen return $chr(45)
alias -l colon return $chr(58)
alias -l semicolon return $chr(59)
alias -l pling return $chr(33)
alias -l period return $chr(46)
alias -l lcurly return $chr(123)
alias -l rcurly return $chr(125)
alias -l lsquare return $chr(91)
alias -l rsquare return $chr(93)
alias -l sqbr return $+($lsquare,$1-,$rsquare)
alias -l lbr return $chr(40)
alias -l rbr return $chr(41)
alias -l br return $+($lbr,$1-,$rbr)
alias -l eq return $chr(61)
alias -l lt return $chr(60)
alias -l gt return $chr(62)
alias -l tag return $+($lt,$1-,$gt)

; ========== Control Codes using aliases ==========
; Color, bold, underline, italic, reverse e.g.
; echo 1 This line has $b(bold) $+ , $i(italic) $+ , $u(underscored) $+ , $c(4,red) $+ , and $rev(reversed) text.
; Calls can be nested e.g. echo 1 $c(12,$u(https://github.com/SanderSade/dlFilter))
alias -l b return $+($chr(2),$1-,$chr(2))
alias -l u return $+($chr(31),$1-,$chr(31))
alias -l i return $+($chr(29),$1-,$chr(29))
alias -l rev return $+($chr(22),$1-,$chr(22))
alias -l c {
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

; ========== Socket utilities ==========
; Modified version of https://www.rosettacode.org/wiki/HTTP/MIRC_Scripting_Language
; Example:
;     DLF.Socket.Get sockname http://www.example.com/somefile.txt [dialog id]
;     on *:SOCKREAD:DLF.Socket.sockname: {
;        DLF.Socket.Headers
;        while ($true) {
;          sockread %line
;          sockread %line
;          if ($sockerr > 0) DLF.Socket.SockErr sockread:Body
;          if ($sockbr == 0) break
;          your code to process body
;        }
;     }
; "on SOCKOPEN" is not needed

alias -l DLF.Socket.Get DLF.Socket.Open $+(DLF.Socket.,$1) $2-

alias -l DLF.Socket.Open {
  var %socket = $1
  var %url = $2
  var %dialog = $3
  var %dialogid = $4

  ; Regular expression to parse the url:
  var %re = ^(?:(https?)(?:://)?)?([^\s/]+)(.*)
  if ($regex(DLF.Socket.Get,$2,%re) !isnum 1-) DLF.Socket.Error Invalid url: %2

  var %protocol = $DLF.regml(DLF.Socket.Get,1)
  var %hostport = $DLF.regml(DLF.Socket.Get,2)
  var %path = $DLF.regml(DLF.Socket.Get,3)
  var %host = $gettok(%hostport,1,$asc($colon))
  var %port = $gettok(%hostport,2,$asc($colon))

  if (%protocol == $null) %protocol = http
  if (%path == $null) %path = /
  if (%port == $null) %port = $iif(%protocol == https,443,80)
  if (%port == 443) %protocol = https
  %hostport = $+(%host,$colon,$port)

  if ($sock(%socket)) sockclose %socket
  sockopen $iif(%protocol == https,-e) %socket %host %port
  sockmark %socket Opening %host %path %dialog %dialogid
}

on *:sockopen:DLF.Socket.*:{
  if ($sockerr) DLF.Socket.SockErr connecting

  ; Mark: Opening %host %path %dialog %dialogid
  var %line, %mark = $sock($sockname).mark
  var %state = $gettok(%mark,1,$asc($space))
  var %host = $gettok(%mark,2,$asc($space))
  var %path = $gettok(%mark,3,$asc($space))
  if (%state != Opening) DLF.Socket.Error Socket Open status invalid: %state
  sockmark $sockname $puttok(%mark,Requested,1,$asc($space))

  var %sw = sockwrite -tn $sockname
  %sw GET %path HTTP/1.1
  %sw Host: %host
  %sw Connection: Close
  %sw $crlf
}

alias -l DLF.Socket.Headers {
  if ($sockerr) DLF.Socket.SockErr sockread

  var %line, %mark = $sock($sockname).mark
  var %state = $gettok(%mark,1,$asc($space))
  ; if on SOCKREAD called for second time, then return immediately
  if (%state == Body) return

  while ($true) {
    sockread %line
    if ($sockerr) DLF.Socket.SockErr sockread
    if ($sockbr == 0) DLF.Socket.Error Server response empty or truncated

    if (%state == Requested) {
      ; Requested: Process first header line which is Status code
      ; HTTP/1.x status-code status-reason
      var %version = $gettok(%line,1,$asc($space))
      var %code = $gettok(%line,2,$asc($space))
      var %reason = $gettok(%line,3-,$asc($space))
      if (2?? iswm %code) {
        ; 2xx codes indicate it went ok
        %state = Headers
        sockmark $sockname $puttok(%mark,%state,1,$asc($space))
      }
      elseif (3?? iswm %code) {
        ; 3xx codes indicate redirection
        %state = Redirect
        sockmark $sockname $puttok(%mark,%state,1,$asc($space))
      }
      else DLF.Socket.Error $sockname get failed with status code %code $+ : %reason
    }
    elseif (%state == Redirect) {
      ; No Location header ?
      if ($len(%line) == 0) DLF.Socket.Error $sockname redirect failed: no redirect URL in headers
      var %header = $gettok(%line,1,$asc($colon))
      if (%header == Location) {
        var %sockname = $sockname
        sockclose $sockname
        DLF.Socket.Open %sockname $gettok(%line,2-,$asc($colon)) $gettok(%mark,4-,$asc($space))
        halt
      }
    }
    elseif (%state == Headers) {
      if ($len(%line) == 0) {
        sockmark $sockname $puttok(%mark,Body,1,$asc($space))
        return
      }
    }
  }
}

alias -l DLF.Socket.SockErr DLF.Socket.Error $1: $sock($sockname).wserr $sock($sockname).wsmsg

alias -l DLF.Socket.Error {
  if ($sockname) {
    var %mark = $sock($sockname).mark
    DLF.Error $+($sockname,: http,$iif($sock($sockname).ssl,s),://,$gettok(%mark,2,$asc($space)),$gettok(%mark,3,$asc($space)),:) $1-
    if ($numtok(%mark,$asc($space)) >= 4) {
      var %dialog = $gettok(%mark,4,$asc($space))
      var %dialogid = $gettok(%mark,5,$asc($space))
      if ($dialog(%dialog)) did -o %dialog %dialogid 1 $1-
    }
    sockclose $sockname
  }
  else DLF.Error $1-
  halt
}

alias -l DLF.Socket.Status {
  DLF.Status $1-
  if ($sockname) {
    var %mark = $sock($sockname).mark
    if ($numtok(%mark,$asc($space)) >= 4) {
      var %dialog = $gettok(%mark,4,$asc($space))
      var %dialogid = $gettok(%mark,5,$asc($space))
      if ($dialog(%dialog)) did -o %dialog %dialogid 1 $1-
    }
  }
}

; ========== Binary file encode/decode ==========
alias -l DLF.CreateBinaryFile {
  if (($0 < 2) || (!$regex($1,/^&[^ ]+$/))) DLF.Error DLF.CreateBinaryFile: Invalid parameters: $1-
  var %len = $decode($1,mb)
  if ($decompress($1,b) == 0) DLF.error Error decompressing $2-
  ; Check if file exists and is identical to avoid rewriting it every time
  if ($isfile($2-)) {
    if ($sha256($1,1) == $sha256($2-,2)) {
      DLF.Status Checked: $2-
      return
    }
  }
  if ($isfile($2-)) {
    .remove $qt($2-)
    DLF.Status Updating: $2-
  }
  else DLF.Status Creating: $2-
  if ($exists($2-)) DLF.Error Cannot remove existing $2-
  bwrite -a $qt($2-) -1 -1 $1
  DLF.Status Created: $2-
}

alias DLF.GenerateBinaryFile {
  if (($0 < 1) || (!$regex($1,/^&[^ ]+$/))) DLF.Error DLF.GenerateBinaryFile: Invalid parameters: $1-
  var %fn = $qt($1-)
  ;var %ofn = $+(%ifn,.mrc)
  ;if ($isfile(%ofn)) .remove $qt(%ofn)

  bread $qt(%fn) 0 $file(%fn).size &file
  noop $compress(&file,b)
  var %enclen = $encode(&file,mb)

  echo 1 $crlf
  echo 1 $rev(To recreate the file, copy and paste the following lines into the mrc script:)
  var %i = 1
  while (%i <= %enclen) {
    echo bset -ta &create %i $bvar(&file,%i,60).text
    /bset -ta &create %i $bvar(&file,%i,60).text
    if ($bvar(&file,%i,60).text != $bvar(&create,%i,60).text) {
      echo 1 Old: $bvar(&file,1,$bvar(&file,0))
      echo 1 New: $bvar(&create,1,$bvar($create,0))
      DLF.Error Mismatch @ %i !!
    }
    inc %i 60
  }
  echo 1 DLF.CreateBinaryFile & $+ create $1-
  echo 1 $rev(That's all folks!)
}

; ========== DLF.debug ==========
; Run this with //DLF.debug only if you are asked to
; by someone providing dlFilter support.
alias DLF.debug {
  echo 14 -s [dlFilter] Debug started.
  if ($show) echo 14 -s [dlFilter] Creating dlFilter.debug.txt
  write -c dlFilter.debug.txt --- Start of debug info --- $fulldate ---
  write -i dlFilter.debug.txt
  write dlFilter.debug.txt Executing $script from $scriptdir
  write dlFilter.debug.txt dlFilter version %DLF.version
  write dlFilter.debug.txt mIRC version $version $iif($portable,portable)
  write dlFilter.debug.txt Running Windows $os
  write dlFilter.debug.txt Host: $host
  write dlFilter.debug.txt IP: $ip
  write -i dlFilter.debug.txt
  write -i dlFilter.debug.txt
  var %cs = $scon(0)
  if ($show) echo 14 -s [dlFilter] %cs servers
  write dlFilter.debug.txt --- Servers --- %cs servers
  write -i dlFilter.debug.txt
  var %i = 1
  while (%i <= %cs) {
    var %st = $scon(%i).status
    if (%st == connected) %st = $iif($scon(%i).ssl,securely) %st to $+($scon(%i).server,$chr(40),$scon(%i).serverip,:,$scon(%i).port,$chr(41)) as $scon(%i).me
    if ($show) echo 14 -s [dlFilter] Server %i is $scon(%i).servertarget $+ : %st
    write dlFilter.debug.txt Server %i is $scon(%i).servertarget $+ : %st
    if (%st != disconnected) {
      write dlFilter.debug.txt $chr(9) ChanTypes= $+ $scon(%i).chantypes $+ , ChanModes= $+ [ $+ $scon(%i).chanmodes $+ ], Modespl= $+ $scon(%i).modespl $+ , Nickmode= $+ $scon(%i).nickmode $+ , Usermode= $+ $scon(%i).usermode
      var %cid = $cid
      scid $scon(%i)
      var %nochans = $chan(0)
      var %chans = $null
      while (%nochans) {
        if ($chan(%nochans).cid == $cid) %chans = $addtok(%chans,$chan(%nochans) $+([,$chan(%nochans).mode,]),44)
        dec %nochans
      }
      scid %cid
      %chans = $sorttok(%chans,44)
      write dlFilter.debug.txt $chr(9) Channels: $replace(%chans,$chr(44),$chr(44) $+ $chr(32))
    }
    inc %i
  }
  write -i dlFilter.debug.txt
  write -i dlFilter.debug.txt
  var %scripts = $script(0)
  if ($show) echo 14 -s [dlFilter] %scripts scripts loaded
  write dlFilter.debug.txt --- Scripts --- %scripts scripts loaded
  write -i dlFilter.debug.txt
  var %i = 1
  while (%i <= %scripts) {
    if ($show) echo 14 -s [dlFilter] Script %i is $script(%i)
    write dlFilter.debug.txt Script %i is $script(%i) and is $lines($script(%i)) lines and $file($script(%i)).size bytes
    inc %i
  }
  write -i dlFilter.debug.txt
  write -i dlFilter.debug.txt
  var %vars = $var(*,0)
  var %DLFvars = $var(DLF.*,0)
  if ($show) echo 14 -s [dlFilter] Found %vars variables, of which %DLFvars are dlFilter variables.
  write dlFilter.debug.txt --- dlFilter Variables --- %vars variables, of which %DLFvars are dlFilter variables.
  write -i dlFilter.debug.txt
  var %vars = $null
  while (%DLFvars) {
    %vars = $addtok(%vars,$var(DLF.*,%DLFvars),44)
    dec %DLFvars
  }
  var %vars = $sorttok(%vars,44,r)
  var %DLFvars = $numtok(%vars,44)
  while (%DLFvars) {
    var %v = $gettok(%vars,%DLFvars,44)
    write dlFilter.debug.txt %v = $var($right(%v,-1),1).value
    dec %DLFvars
  }
  write -i dlFilter.debug.txt
  write -i dlFilter.debug.txt
  var %grps = $group(0)
  if ($show) echo 14 -s [dlFilter] %grps group(s) found
  write dlFilter.debug.txt --- Groups --- %grps group(s) found
  write -i dlFilter.debug.txt
  var %i = 1
  while (%i <= %grps) {
    write dlFilter.debug.txt Group %i $iif($group(%i).status == on,on: $+ $chr(160),off:) $group(%i) from $group(%i).fname
    inc %i
  }
  write -i dlFilter.debug.txt
  write -i dlFilter.debug.txt
  var %hs = $hget(0)
  if ($show) echo 14 -s [dlFilter] %hs hash table(s) found
  write dlFilter.debug.txt --- Hash tables --- %hs hash table(s) found
  write -i dlFilter.debug.txt
  var %i = 1
  while (%i <= %hs) {
    write dlFilter.debug.txt Table %i $+ : $hget(%i) $+ , items $hget(%i, 0).item $+ , slots $hget(%i).size
    inc %i
  }
  write -i dlFilter.debug.txt
  write dlFilter.debug.txt --- End of debug info --- $fulldate ---
  echo 14 -s [dlFilter] Debug ended.
}
