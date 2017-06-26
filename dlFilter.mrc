/*
dlFilter.mrc
Filter out messages on file sharing channels
Authors: DukeLupus and Sophist

Annoyed by advertising messages from the various file serving bots? Fed up with endless channel messages by other users searching for and requesting files? Are the responses to your own requests getting lost in the crowd?

This script filters out the crud, leaving only the useful messages displayed in the channel. By default, the filtered messages are thrown away, but you can direct them to custom windows if you wish.

Download from https://github.com/SanderSade/dlFilter/releases
Update regularly to handle new forms of message.

To load: use /load -rs dlFilter.mrc

Note that dlFilter loads itself automatically as a first script (or second if you are also running sbClient). This avoids problems where other scripts halt events preventing this scripts events from running.

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
  1.18  Further code cleanup
        Self-update improvements
          Option to update to beta versions
          Track minimum mIRC version for web update and not offer update if mirc needs upgrade
          dlFilter reinitialised after update.
          On download of new version, rename old version to .vxxx so user can recover if they have issues with the new version.
          Disable rather than unload script if mIRC version is too low
        Support for multi-server access
          Channel names can now be network#channel as well as #channel (any network)
        Further dialog improvements
          All dialog option changes now take effect immediately
          Subsidiary check-boxes now enable / disable with parent
          New Channels tab using list rather than edit box with ability to select from list of joined channels
          New About tab.
          Channels / custom filters list - double click to edit.
        Menu and events broken out into aliases
        Added extra options for windows for Server Ads and per connection
        Added extra option to check @find result trigger matches nickname sending them
        Removed New Release filters
        Improved DLF.debug code
        Created toolbar gif file from embedded data without needing to download it.
          (And code to turn gif into compressed encoded embedded data.)
        Double-click in find results window to download the file
        Search in Filter window now retains line colours
        Restricted ctcp Version responses to people in common channel or PM
        DLF.Debug.DLF now displays custom debug window filtered to dlF channels with halt reasons
        Only add *'s around custom filters if user hasn't explicitly included a *
        Option for extra windows for fileserver ads
        Multi-server support - option for for custom windows per connection.
        Use hash tables for custom filters

      TODO
        Better icon file
        Implement toolbar functionality with right click menu
        Right click menu items for changing options base on line clicked
        Right click menu items for adding to custom filters
        More menu options equivalent to dialog options
        More menu options for adding custom filters
        Somehow send us details of user adding custom filters for our own analysis (privacy issues?)
        Use CTCP halt to stop DCC CHAT and SEND rather than convoluted ctcp/open processing
        Rewrite anti-chat code
        Separate CTCP event processing for DCC Chat, DCC Send and other ctcp messages.
        Track requests in channels and allow DCC Sends regardless of whether server is regular user or not. Also automatically reissue the command if the file send is incomplete.
        Can we automate a. offering to cancel a file request before sending if the file already exists in the correct directory and is the right size, and to automate the overwrite or resume options if it is the wrong size?
        @find windows per connection.
        Send to... menus - do they work?
        Make it work on AdiIRC.

  1.17  Update opening comments and add change log
        Use custom identifiers for creating bold, colour etc.
        Use custom identifiers instead of $chr(xx)
        Use alias for status messages
        Hash tables for message matching instead of lists of ifs
        Options dialog layout improvements
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
        Most aliases and dialogs local (-l flag)
*/

alias -l DLF.SetVersion {
  %DLF.version = 1.18
  return %DLF.version
}

ctcp ^*:VERSION:#: { DLF.Halt Halted: ctcp VERSION in any channel }
ctcp ^*:VERSION:?: {
  ; dlFilter version response only to people who are in a common dlFilter channel
  var %i = $comchan($nick,0)
  while (%i) {
    var %chan = $comchan($nick,%i)
    if ($DLF.Chan.IsDlfChan($network,%chan)) {
      .ctcpreply $nick VERSION $c(1,9,$DLF.logo Version $DLF.SetVersion by DukeLupus & Sophist.) $+ $c(1,15,$space $+ Get it from $c(12,15,$u(https://github.com/SanderSade/dlFilter/releases)))
      break
    }
    dec %i
  }
  ; Other script VERSION responses only to people who are in a common channel or PM
  if ($comchan($nick,0)) return
  if ($window($nick)) return
  if ($window($+(=,$nick)) return
  DLF.Halt Halted: ctcp VERSION in private from someone not in common dlF channel or chat
}

alias -l DLF.mIRCversion {
  var %app = $nopath($mircexe)
  ; AdiIRC - not sure what version is specifically needed
  ; 2.8 is the version at the time of starting to think about AdiIRC support.
  if ($left(%app,6) == AdiIRC) {
    if ($version >= 2.8) return 0
    %DLF.enabled = 0
    return AidIRC 2.8
  }
  ; mirc - We need returnex first implemented in 6.17
  ; mirc - We currently need regml.group first implemented in 7.44 - but it is probably possible to work around this.
  elseif ($version >= 7.44) return 0
  %DLF.enabled = 0
  return mirc 7.44
}

; ==================== Initialisation / Termination ====================
on *:start: {
  ; Reload script if needed to be first to execute
  DLF.LoadCheck .reload
  if (%DLF.JustLoaded) return
  DLF.Initialise
  return

  :error
  DLF.Error During start: $qt($error)
}

on *:load: {
  ; Reload script if needed to be first to execute
  DLF.LoadCheck .load

  set -u1 %DLF.JustLoaded 1
  DLF.Initialise
  DLF.Options.Show
  DLF.Status Loading complete.
  return

  :error
  DLF.Error During load: $qt($error)
}

alias DLF.LoadCheck {
  var %sbc = $iif(sbClient.* iswm $nopath($script(1)) || sbClient.* iswm $nopath($script(2)),$true,$false)
  if (($script == $script(1)) && (%sbc == $false)) return
  if (($script == $script(2)) && (%sbc)) return
  $1 $iif(%sbc,-rs2,-rs1) $qt($script)
}

on *:signal:DLF.Update.ReLoad: DLF.Initialise

alias DLF.Initialise {
  ; Delete obsolete variables
  .unset %DLF.custom.selected
  .unset %DLF.newreleases
  .unset %DLF.ptext

  if ($script(onotice.mrc)) .unload -rs onotice.mrc
  if ($script(onotice.txt)) .unload -rs onotice.txt
  DLF.Status $iif(%DLF.JustLoaded,Loading,Starting) $c(4,version $DLF.SetVersion) by DukeLupus & Sophist.
  DLF.Status Please check dlFilter homepage $br($c(12,9,$u(https://github.com/SanderSade/dlFilter/issues))) for help.
  DLF.CreateGif
  hfree -w DLF.*
  DLF.CreateHashTables
  DLF.Options.Initialise
  var %ver = $DLF.mIRCversion
  if (%ver != 0) DLF.Error dlFilter requires %ver $+ +. dlFilter disabled until mIRC is updated.
  DLF.Groups.Events
}

on *:unload: {
  DLF.Debug.Unload
  var %keepvars = $?!="Do you want to keep your dlFilter configuration?"
  DLF.Status Unloading $c(4,9,version $DLF.SetVersion) by DukeLupus & Sophist.
  if (%keepvars == $false) {
    DLF.Status Unsetting variables..
    .unset %DLF.*
  }
  DLF.Status Closing open dlFilter windows
  if ($dialog(DLF.Options.GUI)) .dialog -x DLF.Options.GUI DLF.Options.GUI
  close -a@ @dlF.Filter.*
  close -a@ @dlF.FilterSearch.*
  close -a@ @dlF.Server.*
  close -a@ @dlF.ServerSearch.*
  close -a@ @dlF.@find.*
  close -a@ @#*
  DLF.Status Unloading complete.
  DLF.Status $space
  DLF.Status To reload run /load -rs1 $qt($script)
  DLF.Status $space
}

; ========== Main popup menus ==========
menu menubar {
  dlFilter
  .$iif(%DLF.showfiltered,Hide,Show) filter window(s): DLF.Options.ToggleShowFilter
  .Options: DLF.Options.Show
  .Visit filter website: .url -a https://github.com/SanderSade/dlFilter
  .-
  .Unload dlFilter: if ($?!="Do you want to unload dlFilter?" == $true) .unload -rs $qt($script)
}

menu channel {
  -
  ;$iif($me !isop $chan, $style(2)) Send oNotice: DLF.oNotice.Open
  Send oNotice: DLF.oNotice.Open
  -
  dlFilter
  ..$iif($DLF.Chan.IsDlfChan($network,$chan,$false),Remove this channel from,Add this channel to) filtering: DLF.Chan.AddRemove
  ..$iif(%DLF.netchans == $hashtag, $style(3)) Set filtering to all channels: {
    DLF.Chan.Set $hashtag
    DLF.Status $c(6,Channels set to $c(4,$hashtag))
  }
  ..-
  ..$iif(%DLF.showfiltered,Hide,Show) filter window(s): DLF.Options.ToggleShowFilter
  ..Options: DLF.Options.Show
}

; ============================== Event catching ==============================

; Following is just in case groups get reset to default...
; Primarily for developers when e.g. script is reloaded on change by authors autoreload script
#dlf_bootstrap on
on *:text:*:*: DLF.Groups.Bootstrap
alias -l DLF.Groups.Bootstrap {
  if (%DLF.enabled != $null) DLF.Groups.Events
  .disable #dlf_bootstrap
}
#dlf_bootstrap end

alias -l DLF.Groups.Events {
  if (%DLF.enabled) .enable #dlf_events
  else .disable #dlf_events
}

;#dlf_events off
#dlf_events on

; Channel user activity
; join, art, quit, nick changes, kick
on ^*:join:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.joins)) DLF.User.Channel Join $chan $nick $br($address) has joined $chan }
on ^*:part:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.parts)) DLF.User.Channel Part $chan $nick $br($address) has left $chan }
on ^*:kick:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.kicks)) DLF.User.Channel Kick $chan $knick $br($address($knick,5)) was kicked from $chan by $nick $br($1-) }
on ^*:nick: { if ($DLF.Chan.IsUserEvent(%DLF.nicks)) DLF.User.NoChannel $newnick Nick $nick $br($address) is now known as $newnick }
on ^*:quit: { if ($DLF.Chan.IsUserEvent(%DLF.quits)) DLF.User.NoChannel $nick Quit $nick $br($address) Quit $br($1-). }

; Channel mode changes
; ban, unban, op, deop, voice, devoice etc.
on ^*:ban:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode ban in dlF channel }
on ^*:unban:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode unban in dlF channel }
on ^*:op:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode op in dlF channel }
on ^*:deop:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode deop in dlF channel }
on ^*:voice:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode voice in dlF channel }
on ^*:devoice:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode devoice in dlF channel }
on ^*:serverop:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode serverop in dlF channel }
on ^*:serverdeop:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode serverdeop in dlF channel }
on ^*:servervoice:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode servervoice in dlF channel }
on ^*:serverdevoice:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.usrmode)) DLF.Halt Halted: usermode severdevoice in dlF channel }
on ^*:mode:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.chmode)) DLF.Halt Halted: chanmode in dlF channel }
on ^*:servermode:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan,%DLF.chmode)) DLF.Halt Halted: serverchanmode in dlF channel }

; Channel inputs
on *:input:%DLF.channels: {
  if ($DLF.Chan.IsChanEvent($chan)) {
    if (($1 == @find) || ($1 == @locator)) DLF.@find.Request $1-
    if (($left($1,1) isin !@) && ($right($1,-1) ison $chan)) DLF.Chan.ServerRequest $1-
  }
}

; Channel messages
on ^*:text:*:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan)) DLF.Chan.Text $1- }
on ^*:action:*:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan)) DLF.Chan.Action $1- }
on ^*:notice:*:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan)) DLF.Chan.Notice $1- }
on ^*:notice:*:#: { if ($DLF.oNotice.IsoNotice) DLF.oNotice.Channel $1- }

; Private messages
on ^*:text:*:?: { DLF.Priv.Text $1- }
on ^*:notice:*:?: { DLF.Priv.Notice $1- }
on ^*:action:*:?: { DLF.Priv.Action $1- }
on ^*:open:*: {
  echo -s ON OPEN $target $nick $1-
  DLF.Priv.Text $1-
}

; ctcp
ctcp *:*ping*:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan)) DLF.Halt Halted: ping in dlF channel }
ctcp *:*:%DLF.channels: { if ($DLF.Chan.IsChanEvent($chan)) DLF.Chan.ctcp $1- }
ctcp ^*:DCC CHAT:?: { DLF.ctcp.ChatRequest $1- }
ctcp ^*:DCC SEND:?: { DLF.ctcp.SendRequest $1- }
ctcp *:*:?: { DLF.ctcp.Private $1- }
on *:CTCPREPLY:*: { DLF.ctcp.Reply $1- }

; Filter away messages
raw 301:*: { DLF.Away.Filter $1- }
#dlf_events end

; ========== Event processing code ==========
; Channel user activity
; join, part, kick
alias -l DLF.User.Channel {
  if ($3 == $me) return
  if (%DLF.showstatus == 1) echo -stnc $1 $sqbr($2) $star $3-
  DLF.Win.Filter $1-
}

; Non-channel user activity
; nick changes, quit
alias -l DLF.User.NoChannel {
  if (%DLF.netchans != #) {
    var %i = $comchan($1,0)
    while (%i) {
      var %chan = $comchan($1,%i)
      if ($DLF.Chan.IsDlfChan($network,%chan) == $false) echo -ct $2 %chan $star $3-
      dec %i
    }
  }
  DLF.User.Channel $2 $hashtag $3-
}

; Channel messages
alias -l DLF.Chan.AddRemove {
  if (!$DLF.Chan.IsDlfChan($network,$chan,$false)) DLF.Chan.Add $chan $network
  else DLF.Chan.Remove $chan $network
  if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 6 1 %DLF.netchans
  DLF.Status $c(6,Channels set to $c(4,%DLF.netchans))
}

alias -l DLF.Chan.Add {
  var %netchan = $iif($1,$+($2,$1),$+($network,$chan))
  %DLF.netchans = $remtok(%DLF.netchans,$chan,$asc($comma))
  if (%DLF.netchans != $hashtag) DLF.Chan.Set $addtok(%DLF.netchans,%netchan,$asc($comma))
  else DLF.Chan.Set %netchan
}

alias -l DLF.Chan.Remove {
  var %net = $iif($0 >= 2,$2,$network)
  var %chan = $iif($0 >= 1,$1,$chan)
  var %netchan = $+(%net,%chan)
  if ($istok(%DLF.netchans,%netchan,$asc($comma))) DLF.Chan.Set $remtok(%DLF.netchans,$+(%net,%chan),1,$asc($comma))
  else DLF.Chan.Set $remtok(%DLF.netchans,%chan,1,$asc($comma))
}

; Convert network#channel to just #channel for On statements
alias -l DLF.Chan.Set {
  %DLF.netchans = $replace($1-,$space,$comma)
  var %r = $+(/,[^,$comma,#]+,$lbr,?=#[^,$comma,#]*,$rbr,/g)
  %DLF.channels = $regsubex(%DLF.netchans,%r,$null)
}

; Check if channel is set whether it is network#channel or just #channel
alias -l DLF.Chan.IsChanEvent {
  if ($2 == 0) return $false
  return $DLF.Chan.IsDlfChan($network,$1)
}

alias -l DLF.Chan.IsDlfChan {
  if (($3 != $false) && (%DLF.netchans == $hashtag)) return $true
  if ($istok(%DLF.netchans,$2,$asc($comma))) return $true
  if ($istok(%DLF.netchans,$+($1,$2),$asc($comma))) return $true
  return $false
}

; Check whether non-channel event (quit or nickname) is from a network where we are in a defined channel
alias -l DLF.Chan.IsUserEvent {
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

alias -l DLF.Chan.Text {
  DLF.CustFilt.Check chantext Normal $chan $nick $1-
  var %txt = $strip($1-)
  if ((%DLF.requests == 1) && ($hiswm(chantext.cmds,%txt))) DLF.Win.Filter Normal $chan $nick $1-
  if ((%DLF.ads == 1) && ($hiswm(chantext.ads,%txt))) DLF.Chan.NickColour Ads Normal $chan $nick $1-
  if ((%DLF.ads == 1) && ($hiswm(chantext.spam,%txt))) DLF.Win.Filter Normal $chan $nick $1-
  if ($hiswm(chantext.always,%txt)) DLF.Win.Filter Normal $chan $nick $1-
  /*if (%DLF.chspam == 1) {
    ;no channel spam right now
  }
  */
}

alias -l DLF.Chan.Action {
  DLF.CustFilt.Check chanaction Action $chan $nick $1-
  var %DLF.action = $strip($1-)
  if ((%DLF.ads == 1) && ($hiswm(chanaction.spam,%DLF.action))) DLF.Win.Filter Action $chan $nick $1-
  if ((%DLF.away == 1) && ($hiswm(chanaction.away,%DLF.action))) DLF.Win.Filter Action $chan $nick $1-
}

alias -l DLF.Chan.Notice {
  DLF.CustFilt.Check channotice Notice $chan $nick $1-
  if ((%DLF.chspam == 1) && ($hiswm(channotice.spam,$strip($1-)))) DLF.Chan.SpamFilter $chan $nick $1-
}

alias -l DLF.Chan.ctcp {
  DLF.CustFilt.Check chanctcp Notice $target $nick $1-
  if ($hiswm(chanctcp.spam,$1-)) {
    DLF.Chan.NickColour Filter ctcp $chan $nick
    DLF.Halt Dropped: ctcp spam in dlF channel
  }
}

alias -l DLF.Chan.SpamFilter {
  if ((%DLF.chspam.opnotify == 1) && ($me isop $1)) {
    DLF.Warning $c(4,Channel spam detected:) $sqbr($1) $tag($2) $br($address($2,1)) -->> $c(4,$3-)
  }
  DLF.Halt Halted: spam in dlF channel
}

alias -l DLF.Chan.NickColour {
  if ((%DLF.colornicks == 1) && ($nick($3,$4).color == $color(nicklist))) cline 6 $3 $4
  if ($5 != $null) DLF.Win.Log $1-
}

alias -l DLF.Chan.ServerRequest {
  echo -at DLF.Chan.ServerRequest called: $1-
}

; Private messages
alias -l DLF.Priv.Text {
  if ((%DLF.nocomchan.dcc == 1) && (%DLF.accepthis == $target)) return
  if ($+(*,$dollar,decode*) iswm $1-) DLF.Warning Do not paste any messages containing $b($dollar $+ decode) to your mIRC. They are mIRC worms & the people sending them are infected. Instead, please report such messages to the channel ops.

  DLF.CustFilt.Check privtext Normal Private $nick $1-
  var %txt = $strip($1-)
  if ($DLF.@find.IsResponse) {
    if ($hiswm(findtext.header,%txt)) DLF.@find.PrivHeaders $nick $1-
    if ($hiswm(find.result,%txt)) DLF.@find.Results Normal Private $nick $1-
    if ((*Omen* iswm $strip($1)) && ($left($strip($2),1) == $pling)) DLF.@find.Results Normal Private $nick $2-
  }
  DLF.Priv.CommonChan $nick $1-
  if ((%DLF.noregmsg == 1) && ($DLF.Priv.IsRegularUser($nick))) {
    DLF.Warning Regular user $nick $br($address($nick,0)) tried to: $1-
    if ($window($nick)) window -c $nick
    DLF.Halt Halted: private text from regular user
  }
  if (%DLF.privrequests == 1) {
    if ($nick === $me) return
    var %trigger = $strip($1)
    var %nicklist = @ $+ $me
    var %nickfile = ! $+ $me
    if ((%nicklist == %trigger) || (%nickfile == %trigger) || (%nickfile == $gettok($strip($1),1,$asc($hyphen)))) {
      .msg $1 Please $u(do not request in private) $+ . All commands go to $u(channel).
      .msg $1 You may have to go to $c(2,mIRC options --->> Sounds --->> Requests) and uncheck $qt($c(3,Send '!nick file' as private message))
      if (($window($nick)) && ($line($nick,0) == 0)) .window -c $nick
      DLF.Halt Halted: server request to me in private text
    }
  }
  if ((%DLF.privspam == 1) && ($hiswm(privtext.spam,%txt)) && (!$window($1))) DLF.Priv.SpamFilter $1-
  if ($hiswm(privtext.server,%txt)) DLF.Win.Server $nick $1-
  if ((%DLF.away == 1)  && ($hiswm(privtext.away,%txt))) DLF.Win.Filter Normal Private $nick $1-
}

alias -l DLF.Priv.Notice {
  DLF.CustFilt.Check privnotice Notice Private $nick $1-
  var %txt = $strip($1-)
  DLF.Priv.CommonChan $nick %txt
  if ((%DLF.noregmsg == 1) && ($DLF.Priv.IsRegularUser($nick))) {
    DLF.Warning Regular user $nick $br($address) tried to send you a notice: $1-
    DLF.Halt Halted: private notice from regular user
  }
  if ($hiswm(privnotice.dnd,%txt)) DLF.Win.Filter Notice Private $nick $1-
  if ($hiswm(findnotice.header,%txt)) DLF.Win.Server $nick $1-
  if ($DLF.@find.IsResponse) {
    if ($hiswm(find.result,%txt)) DLF.@find.Results Notice Private $nick $1-
  }
  if ($hiswm(privnotice.server,%txt)) DLF.Win.Server $nick $1-
}

alias -l DLF.Priv.Action {
  DLF.CustFilt.Check privaction Action Private $nick $1-
  DLF.Priv.CommonChan $nick $1-
  if ((%DLF.noregmsg == 1) && ($DLF.Priv.IsRegularUser($nick))) {
    DLF.Warning Regular user $nick $br($address) tried to send you an action: $1-
    .window -c $1
    .close -m $1
    DLF.Halt Halted: private action (/me) from regular user
  }
}

alias -l DLF.Priv.SpamFilter {
  if ((%DLF.privspam.opnotify == 1) && ($comchan($1,1).op)) {
    DLF.Warning Spam detected: $c(4,15,$tag($1) $br($address($1,1)) -->> $b($2-))
    echo $comchan($1,1) Private spam detected: $c(4,15,$tag($1) $br($address($1,1)) -->> $b($2-))
  }
  if ((%DLF.spam.addignore == 1) && ($input(Spam received from $1 ( $+ $address($1,1) $+ ). Spam was: " $+ $2- $+ ". Add this user to ignore for one hour?,yq,Add spammer to /ignore?) == $true)) /ignore -wu3600 $1 4
  DLF.Win.Filter Normal Private $1-
}

alias -l DLF.Priv.CommonChan {
  if ((%DLF.accepthis == $1) && (%DLF.nocomchan.dcc == 1)) {
    .unset %DLF.accepthis
    return
  }
  if ($DLF.Priv.IsRegularUser($1) == $false) return
  if (($comchan($1,0) == 0) && (%DLF.nocomchan == 1)) {
    if (($window($1)) && (!$line($1,0))) {
      DLF.Status $b($1) (no common channel) tried: $c(4,15,$2-)
      .window -c $1
    }
    if (($window($eq $+ $1)) && (%DLF.nocomchan.dcc == 0)) {
      .window -c $eq $+ $1
    }
    DLF.Halt Halted: private message from user with no common channel
  }
}

alias -l DLF.Priv.IsRegularUser {
  if ($1 == $me) return $false
  if ($1 == ChanServ) return $false
  if ($1 == NickServ) return $false
  if ($1 == MemoServ) return $false
  if ($1 == OperServ) return $false
  if ($1 == BotServ) return $false
  if ($1 == HostServ) return $false
  if ($1 == HelpServ) return $false
  if ($1 == GroupServ) return $false
  if ($1 == InfoServ) return $false
  var %i = $comchan($1,0)
  while (%i) {
    if (($1 isop $comchan($1,%i)) || ($1 isvoice $comchan($1,%i))) return $false
    dec %i
  }
  return $true
}

alias -l DLF.ctcp.ChatRequest echo -st DLF.ctcp.ChatRequest called: $1-

alias -l DLF.ctcp.SendRequest echo -st DLF.ctcp.SendRequest called: $1-

alias -l DLF.ctcp.Private {
  if ((%DLF.nocomchan.dcc == 1) && ($1-2 === DCC CHAT)) {
    %DLF.accepthis = $nick
    return
  }
  DLF.CustFilt.Check privctcp Notice Private $nick $1-
  if (%DLF.nocomchan == 1) DLF.Priv.CommonChan $nick $1-
  if ((%DLF.askregfile == 1) && (DCC SEND isin $1-)) {
    if ($DLF.Priv.IsRegularUser($nick)) {
      ; Allow files from regular users if nickname is in mIRC DCC trust list
      var %addr = $address($nick,5)
      if (%addr != $null) {
        var %i = $trust(0)
        while (%i) {
          echo -s $trust(%i) %addr
          if ($trust(%i) iswm %addr) {
            DLF.Debug.Log DCC Send accepted - user in trust list
            return
          }
          dec %i
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
          && (%ext != .js)) {
            DLF.Debug.Log DCC Send accepted - filetype acceptable
            return
          }
      }
      DLF.Status $c(3,Regular user $nick $br($address) tried to send you a file $qt($gettok($1-,3-$numtok($1-,$asc($space)), $asc($space))))
      DLF.Halt Halted: dcc send from regular user
    }
  }
  if ((%DLF.noregmsg == 1) && ($DLF.Priv.IsRegularUser($nick)) && (DCC send !isin $1-)) {
    DLF.Warning Regular user $nick $br($address) tried to: $1-
    DLF.Halt Halted: private ctcp from regular user
  }
  DLF.Debug.Log dcc send from op/voice user accepted.
}

alias -l DLF.ctcp.Reply {
  if ($hiswm(ctcp.reply,$1-)) DLF.Halt Halted:
  if (%DLF.nocomchan == 1) DLF.Priv.CommonChan $nick $1-
  if ((%DLF.noregmsg == 1) && ($DLF.Priv.IsRegularUser($nick)) && (DCC send !isin $1-)) {
    DLF.Warning Regular user $nick ( $+ $address $+ ) tried to: $1-
    DLF.Halt Halted: private ctcp reply from regular user
  }
  DLF.CustFilt.Check privctcp Notice Private $nick $1-
}

alias -l DLF.Away.Filter {
  if (%DLF.away == 1) DLF.Win.Filter Notice RawAway $2-
  DLF.Halt Halted: away message
}

; ========== Custom Filters ==========

; DLF.CustFilt.Check x colourname channel nick text
; where x = chan/priv $+ text/action/notice/ctcp
alias -l DLF.CustFilt.Check {
  var %hash = $+(DLF.custfilt.,$1)
  if ($hget(%hash) == $null) DLF.CustFilt.CreateHash $1
  if ($hfind(%hash,$5-,1,W)) {
    DLF.Debug.Log Matched in custom. $+ $1 $+ : $2
    DLF.Win.Filter $2-
  }
  return

  ; OBSOLETE PENDING TESTING
  var %custom = [ % $+ DLF.custom. [ $+ [ $1 ] ] ]
  if ((%DLF.custom.enabled == 1) && (%custom != $null)) {
    var %i = $numtok(%custom,$asc($comma))
    var %txt = $replace($strip($5-),$nbsp,$space)
    while (%i) {
      if ($gettok(%custom,%i,$asc($comma)) iswm %txt) DLF.Win.Filter $2-
      dec %i
    }
  }
}

alias -l DLF.CustFilt.Add {
  var %type = $replace($1,$nbsp,$space)
  %new = $regsubex($2-,$+(/[][!#$%&()/:;<=>.|,$comma,$lcurly,$rcurly,]+/g),$star)
  %new = $regsubex(%new,/[*] *[*]+/g,$star)
  if (%new == *) return
  if (%type == Channel text) DLF.CustFilt.Set chantext $addtok(%DLF.custom.chantext,%new,$asc($comma))
  elseif (%type == Channel action) DLF.CustFilt.Set chanaction $addtok(%DLF.custom.chanaction,%new,$asc($comma))
  elseif (%type == Channel notice) DLF.CustFilt.Set channotice $addtok(%DLF.custom.channotice,%new,$asc($comma))
  elseif (%type == Channel ctcp) DLF.CustFilt.Set chanctcp $addtok(%DLF.custom.chanctcp,%new,$asc($comma))
  elseif (%type == Private text) DLF.CustFilt.Set privtext $addtok(%DLF.custom.privtext,%new,$asc($comma))
  elseif (%type == Private action) DLF.CustFilt.Set privaction $addtok(%DLF.custom.privaction,%new,$asc($comma))
  elseif (%type == Private notice) DLF.CustFilt.Set privnotice $addtok(%DLF.custom.privnotice,%new,$asc($comma))
  elseif (%type == Private ctcp) DLF.CustFilt.Set privctcp $addtok(%DLF.custom.privctcp,%new,$asc($comma))
  else DLF.Error DLF.CustFilt.Add Invalid message type: %type
}

alias -l DLF.CustFilt.Remove {
  var %type = $replace($1,$nbsp,$space)
  if (%type == Channel text) DLF.CustFilt.Set chantext $remtok(%DLF.custom.chantext,$2-,1,$asc($comma))
  elseif (%type == Channel action) DLF.CustFilt.Set chanaction $remtok(%DLF.custom.chanaction,$2-,1,$asc($comma))
  elseif (%type == Channel notice) DLF.CustFilt.Set channotice $remtok(%DLF.custom.channotice,$2-,1,$asc($comma))
  elseif (%type == Channel ctcp) DLF.CustFilt.Set chanctcp $remtok(%DLF.custom.chanctcp,$2-,1,$asc($comma))
  elseif (%type == Private text) DLF.CustFilt.Set privtext $remtok(%DLF.custom.privtext,$2-,1,$asc($comma))
  elseif (%type == Private action) DLF.CustFilt.Set privaction $remtok(%DLF.custom.privaction,$2-,1,$asc($comma))
  elseif (%type == Private notice) DLF.CustFilt.Set privnotice $remtok(%DLF.custom.privnotice,$2-,1,$asc($comma))
  elseif (%type == Private ctcp) DLF.CustFilt.Set privctcp $remtok(%DLF.custom.privctcp,$2-,1,$asc($comma))
  else DLF.Error Invalid message type: %type
}

alias -l DLF.CustFilt.Set {
  var %var = $+(%,DLF.custom.,$1)
  [ [ %var ] ] = $2-
  DLF.CustFilt.CreateHash $1
}

alias -l DLF.CustFilt.CreateHash {
  var %hash = $+(DLF.custfilt.,$1)
  var %filt = [ [ $+(%,DLF.custom.,$1) ] ]
  if ($hget(%hash)) hfree %hash
  hmake %hash 10
  var %i = $numtok(%filt,$asc($comma))
  while (%i) {
    hadd %hash %i $gettok(%filt,%i,$asc($comma))
    dec %i
  }
}

; ========== Custom Window handling ==========
; DLF.Win.Log type
alias -l DLF.Win.Log {
  if ($istok(Filter Ads Server,$1,$asc($space)) == $false) DLF.Error Invalid window name: $1
  if (($1 $3 == Filter Private) && ($window($4))) .window -c $4
  var %win = $+(@dlF.,$1,.,$iif(%DLF.perconnect,$network,All))
  var %vars = $iif($1 == Server,DLF.server.,DLF.filtered.)
  var %lfn = $mklogfn(%win)
  if (%DLF.perconnect == 0) %lfn = $nopath(%lfn)
  %lfn = $qt($+($logdir,%lfn))
  var %log   = [ [ $+(%,%vars,log) ] ]
  var %limit = [ [ $+(%,%vars,limit) ] ]
  var %ts    = [ [ $+(%,%vars,timestamp) ] ]
  var %strip = [ [ $+(%,%vars,strip) ] ]
  var %wrap  = [ [ $+(%,%vars,wrap) ] ]

  if (%DLF.perconnect == 0) var %nc = $sqbr($+($network,$3))
  else var %nc = $iif($3 != $hashtag,$sqbr($3))
  if ($2 == Normal) var %line = %nc $tag($4) $5-
  else var %line = %nc $4-

  if (%log == 1) write %lfn $sqbr($logstamp) %nc $tag($3) $strip($4-)
  if (($1 == Filter) && (%DLF.showfiltered == 0)) DLF.halt Halted: Options set to not show filters

  if (!$window(%win)) {
    window $iif(%DLF.perconnect,-k0nw,-k0nwz) %win
    titlebar %win -=- Right-click for options
    if (%log) loadbuf $iif(%limit,4850) -p %win %lfn
  }

  if ((%limit == 1) && ($line(%win,0) >= 5000)) dline %win $+(1-,$calc($line(%win,0) - 4850))
  if (%ts == 1) %line = $timestamp %line
  if (%strip == 1) %line = $strip(%line)
  if (%wrap == 1) aline -pi $color($2) %win %line
  else aline $color($2) %win %line
  DLF.Halt Filtered: To %win
}

alias -l DLF.Win.Filter {
  DLF.Win.Log Filter $1-
}

alias -l DLF.Win.Server {
  if (%DLF.server == 0) return
  DLF.Win.Log Server $1-
}

alias -l DLF.Win.Ads {
  if (%DLF.serverads) DLF.Win.Log Ads $1-
  else DLF.Win.Log Filter $1-
}

menu @dlF.Filter.* {
  Search: DLF.Win.Search $menu $?="Enter search string"
  -
  $iif(%DLF.filtered.timestamp == 1,$style(1)) Timestamp: DLF.Options.ToggleOption filtered.timestamp
  $iif(%DLF.filtered.strip == 1,$style(1)) Strip codes: DLF.Options.ToggleOption filtered.strip
  $iif(%DLF.filtered.wrap == 1,$style(1)) Wrap lines: DLF.Options.ToggleOption filtered.wrap
  $iif(%DLF.filtered.limit == 1,$style(1)) Limit number of lines: DLF.Options.ToggleOption filtered.limit
  $iif(%DLF.filtered.log == 1,$style(1)) Log: DLF.Options.ToggleOption filtered.log
  -
  Clear: clear
  Options: DLF.Options.Show
  Hide filter window: {
    %DLF.showfiltered = 0
    close -@ @dlF.Filter*.*
  }
  -
}

menu @dlF.Server.*,@dlF.Ads.* {
  Search: DLF.Win.Search $menu $?="Enter search string"
  -
  $iif(%DLF.server.timestamp == 1,$style(1)) Timestamp: DLF.Options.ToggleOption server.timestamp
  $iif(%DLF.server.strip == 1,$style(1)) Strip codes: DLF.Options.ToggleOption server.strip
  $iif(%DLF.server.wrap == 1,$style(1)) Wrap lines: DLF.Options.ToggleOption server.wrap
  $iif(%DLF.server.limit == 1,$style(1)) Limit number of lines: DLF.Options.ToggleOption server.limit
  $iif(%DLF.server.log == 1,$style(1)) Log: DLF.Options.ToggleOption server.log
  -
  Clear: clear
  Options: DLF.Options.Show
  Disable: {
    %DLF.server = 0
    close -@ DLF.Server*.*
  }
  -
}

menu @dlF.*Search.* {
  Copy line: {
    .clipboard
    .clipboard $sline($active,1)
    cline 14 $active $sline($active,1).ln
  }
  Clear: clear
  Close: window -c $active
  Options: DLF.Options.Show
}

on *:input:@dlF.*Search.*: DLF.Win.Search $target $1-

alias -l DLF.Win.Search {
  if ($2 == $null) return
  var %wf = $gettok($1,2,$asc($period))
  if ($right(%wf,6) != Search) %ws = $+(%wf,Search)
  else {
    %ws = %wf
    %wf = $left(%wf,-6)
  }
  var %wf = $puttok($1,%wf,2,$asc($period))
  var %ws = $puttok($1,%ws,2,$asc($period))
  var %flags = $+(-eabk0,$iif($gettok($1,-1,$asc($period)) == All,z))
  window %flags %ws
  var %sstring = $+($star,$2-,$star)
  titlebar %ws -=- Searching for %sstring
  filter -wwcbzph4 %wf %ws %sstring
  var %matches = $iif($filtered == 0,No matches,$iif($filtered == 1,One match,$filtered matches))
  titlebar %ws -=- Search finished. %matches found for $qt(%sstring)
}

; ========== @find ==========
menu @dlF.@find.Results {
  dclick: DLF.@find.Get $1
  .-
  .Copy line(s): DLF.@find.CopyLines
  $iif(!$script(AutoGet.mrc), $style(2)) Send to AutoGet: DLF.@find.SendToAutoGet
  $iif(!$script(vPowerGet.net.mrc), $style(2)) Send to vPowerGet.NET: DLF.@find.SendTovPowerGet
  Save results: DLF.@find.SaveResults
  .-
  Options: DLF.Options.Show
  Clear: clear
  .-
  Close: window -c $active
  .-
}

alias -l DLF.@find.Request {
  .set -u600 %DLF.@find.active $addtok(%DLF.@find.active,$network $+ $chan,$asc($space))
}

alias -l DLF.@find.IsResponse {
  if (%DLF.searchresults == 0) return $false
  var %net = $network $+ #*
  var %n = $wildtok(%DLF.@find.active,%net,0,$asc($space))
  while (%n) {
    var %netchan = $wildtok(%DLF.@find.active,%net,%n,$asc($space))
    var %chan = $hashtag $+ $gettok(%netchan,2,$asc($hashtag))
    if ($nick ison %chan) return $true
    dec %n
  }
  return $false
}

alias -l DLF.@find.PrivHeaders {
  if (($window($1)) && (!$line($1,0))) .window -c $1
  DLF.Win.Server $1-
}

alias -l DLF.@find.Results {
  if (($window($3)) && (!$line($3,0))) .window -c $3
  var %msg = $5-
  if($strip($4) != $+($pling,$3)) {
    if (%DLF.searchspam) DLF.Win.Filter $1-
    else %msg = %msg $c(4,0,!! Received from $nick !!)
  }
  if (!$window(@dlF.@find.Results)) window -slk0wnz @dlF.@find.Results
  aline -n @dlF.@find.Results $strip($4) $5-
  window -b @dlF.@find.Results
  titlebar @dlF.@find.Results -=- $line(@dlF.@find.Results,0) results so far -=- Right-click for options or double-click to download
  DLF.Halt Halted: @find result line added to @dlF.@find.Results
}

alias -l DLF.@find.Get {
  ; Check not already requested
  if ($line($active,$1).color == 15) return
  var %line = $line($active,$1)
  var %trig = $gettok(%line,1,$asc($space))
  if ($left(%trig,1) != $pling) return
  var %nick = $right(%trig,-1)
  var %fn = $DLF.@find.FileName($gettok(%line,2-,$asc($space)))
  ; Find common channels for trigger nickname and issue the command in the channel
  var %cid = $cid
  var %nets = $scon(0)
  while (%nets) {
    var %i = $comchan(%nick,0)
    while (%i) {
      var %chan = $comchan(%nick,%i)
      echo -s $network %chan $DLF.Chan.IsDlfChan($network,%chan)
      if ($DLF.Chan.IsDlfChan($network,%chan)) {
        ; Use editbox not msg so other scripts (like sbClient) get On Input event
        editbox -n %chan %trig %fn
        scid %cid
        cline 15 $active $1
        return
      }
      dec %i
    }
  }
  scid %cid
}

alias -l DLF.@find.CopyLines {
  var %lines = $sline($active,0)
  if (!%lines) halt
  DLF.@find.ClearColours
  clipboard
  var %lines = $line($active,0)
  var %i = 1
  while (%i <= %lines) {
    clipboard -an $gettok($sline($active,%i),1,$asc($space)) $DLF.@find.FileName($gettok($sline($active,%i),2-,$asc($space)))
    cline 3 $active $sline($active,%i).ln
    inc %i
  }
  dec %i
  if ($active == @dlF.@find.Results) titlebar $active -=- $line(@dlF.@find.Results,0) results so far -=- %i line(s) copied into clipboard
  else titlebar $active -=- New Releases -=- %i line(s) copied into clipboard
}

alias -l DLF.@find.ClearColours {
  var %i = $line($active,0)
  while (%i) {
    if ($line($active,%i).color != 15) cline $color(Normal) $active %i
    dec %i
  }
}

alias -l DLF.@find.FileName {
  var %exts = mp3 wma mpg mpeg zip bz2 txt exe rar tar jpg gif wav aac asf vqf avi mov mp2 m3u kar nfo sfv m2v iso vcd doc lit pdf r00 r01 r02 r03 r04 r05 r06 r07 r08 r09 r10 shn md5 html htm jpeg ace png c01 c02 c03 c04 rtf wri txt

  ; common (OmenServe) response has filename followed by e.g. ::INFO::
  ; and colons are not allowable characters in file names
  var %fn = $gettok($replace($strip($1-),$nbsp,$space),1,$asc($colon))

  ; look for known types
  var %dots = $numtok(%fn,$asc($period))
  var %i = 2
  while (%i <= %dots) {
    var %ft = $gettok($gettok(%fn,%i,$asc($period)),1,$asc($space))
    if ($istok(%exts,%ft,$asc($space))) return $+($gettok(%fn,$+(1-,$calc(%i - 1)),$asc($period)),.,%ft)
    inc %i
  }

  ; Not a known filetype - so try filename = up to first period and then to next space
  if (%dots >= 2) return $+($gettok(%fn,1,$asc($period)),.,$gettok($gettok(%fn,2,$asc($period)),1,$asc($space)))

  ; No period - leave as-is
  return %fn
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
  if ($active == @dlF.@find.Results) titlebar $active -=- $line($active,0) results so far -=- %j line(s) sent to AutoGet
  else titlebar $active -=- New releases -=- %j line(s) sent to AutoGet
}

alias -l DLF.@find.SendTovPowerGet {
  var %lines = $sline($active,0)
  if (!%lines) halt
  DLF.@find.ClearColours
  var %i = 1
  while (%i <= %lines) {
    if ($com(vPG.NET,AddFiles,1,bstr,$sline($active,%i)) == 0) {
      echo -s vPG.NET: AddFiles failed
    }
    cline 3 $active $sline($active,%i).ln
    inc %i
  }
  if ($active == @dlF.@find.Results) titlebar $active -=- $line(@dlF.@find.Results,0) results so far -=- $calc(%i - 1) line(s) sent to vPowerGet.NET
  else titlebar $active -=- New releases -=- $calc(%i - 1) line(s) sent to vPowerGet.NET
}

alias -l DLF.@find.SaveResults {
  var %fn = $sfile($sysdir(downloads),Save @find results as a text file,Save)
  if (!%fn) return
  %fn = $qt($gettok(%fn,$+(1-,$calc($numtok(%fn,$asc($period)) - 1)),$asc($period)) $+ .txt)
  savebuf $active %fn
}

; ========== oNotice ==========
menu @#* {
  Clear: clear
  $iif(%DLF.o.timestamp == 1,$style(1)) Timestamp: DLF.Options.ToggleOption o.timestamp
  $iif(%DLF.o.log == 1,$style(1)) Logging: DLF.Options.ToggleOption o.log
  Options: DLF.Options.Show
  -
  Close: DLF.oNotice.Close $active
  -
}

on *:close:@#*: DLF.oNotice.Close $target

alias DLF.oNotice.IsoNotice {
  if (%DLF.o.enabled != 1) return 0
  if ($target != $+(@,$chan)) return 0
  if ($me !isop $chan) return 0
  if ($nick !isop $chan) return 0
  return 1
}

alias -l DLF.oNotice.Channel {
  var %win = $DLF.oNotice.Open(0)
  if ($1 == @) var %omsg = $2-
  else var %omsg = $1-
  aline -nl $color(nicklist) %win $nick
  window -S %win
  if ($gettok(%omsg,1,$asc($space)) != /me) %omsg = $color(text) %win $tag($nick) %omsg
  else %omsg = $color(action) %win $star $nick $gettok(%omsg,2-,$asc($space))
  aline -ph %omsg
  ;if (%DLF.o.timestamp == 1) var %omsg = $timestamp %omsg
  DLF.oNotice.Log %win $gettok(%omsg,2-,$asc($space))
  DLF.Halt Halted: oNotice sent to %win
}

alias -l DLF.oNotice.Open {
  var %win = @ $+ $chan
  if (!$window(%win)) {
    DLF.oNotice.Log %win ----- Session started -----
    window $+(-eg1k1l12mSw,$iif($1 == 0,n)) %win
    var %log = %DLF.oNotice.LogFile(%chatwin)
    if ((%DLF.o.log == 1) && ($exists(%log))) .loadbuf -r %win %log
    timestamp $iif(%DLF.o.timestamp,on,off) %win
  }
  return %win
}

on *:input:@#* {
  if (($left($1,1) == /) && ($ctrlenter == $false) && ($1 != /me)) return
  if (($1 != /me) || ($ctrlenter == $true)) var %omsg = $color(Normal) $active $tag($me) $1-
  else var %omsg = $color(action) $active $star $me $2-
  if (%DLF.o.timestamp == 1) var %omsg = $timestamp %omsg
  aline -p %iif(%DLF.o.timestamp,$timestamp ) $+ %omsg
  aline -nl $color(nicklist) $active $me
  window -S $active
  var %ochan = $replace($active,@,$null)
  .onotice %ochan $1-
  DLF.oNotice.Log $active %omsg
}

alias -l DLF.oNotice.Close {
  DLF.oNotice.Log $1 ----- Session closed -----
  close -@ $1
}

alias -l DLF.oNotice.Log {
  if (%DLF.o.log == 1) {
    var %log = %DLF.oNotice.LogFile($1)
    write %log $sqbr($logstamp) $2-
  }
}

alias -l DLF.oNotice.LogFile return $+($logdir,$mklogfn($1))

; ============================== DLF Options ==============================
alias DLF.Options.Show dialog $iif($dialog(DLF.Options.GUI),-v,-md) DLF.Options.GUI DLF.Options.GUI
alias DLF.Options.Toggle dialog $iif($dialog(DLF.Options.GUI),-c,-md) DLF.Options.GUI DLF.Options.GUI

dialog -l DLF.Options.GUI {
  title dlFilter v $+ $DLF.SetVersion
  size -1 -1 152 209
  option dbu notheme
  text "", 20, 67 2 82 8, right hide
  check "Enable/disable dlFilter", 10, 2 2 62 8
  tab "Channels", 200, 1 9 150 184
  tab "Filters", 400
  tab "Other", 600
  tab "Custom", 800
  tab "About", 900
  button "Close", 30, 2 196 50 11, ok default flat
  check "Show/hide filtered lines", 40, 58 196 92 11, push
  ; tab Channels
  text "Channel to add: (type or select from dropdown)", 210, 5 25 144 8, tab 200
  combo 220, 4 33 144 6, tab 200 drop edit
  button "Add", 230, 5 46 67 11, tab 200 flat disable
  button "Remove", 240, 79 46 68 11, tab 200 flat disable
  list 250, 4 59 144 89, tab 200 vsbar size sort extsel
  box " Update ", 500, 4 149 144 41, tab 200
  text "Checking for dlFilter updates...", 510, 7 157 140 8, tab 200
  button "dlFilter website", 520, 7 166 65 11, tab 200 flat
  button "Update dlFilter", 530, 79 166 65 11, tab 200 flat disable
  check "Check for beta versions", 540, 7 179 136 8, tab 200
  ; tab Main
  box " General ", 405, 4 23 144 74, tab 400
  check "Filter adverts and announcements", 410, 7 32 133 8, tab 400
  check "... but filter to separate window", 415, 15 41 125 8, tab 400
  check "Filter other users Search / File requests", 420, 7 50 133 8, tab 400
  check "Filter responses to my requests to separate window", 425, 7 59 133 8, tab 400
  check "Filter Channel mode changes", 430, 7 68 133 8, tab 400
  check "Filter requests to you in PM (@yournick, !yournick)", 435, 7 77 133 8, tab 400
  check "Separate filter windows per connection", 440, 7 86 133 8, tab 400
  box " Filter user events ", 450, 4 98 144 92, tab 400
  check "Joins", 455, 7 107 133 8, tab 400
  check "Parts", 460, 7 116 133 8, tab 400
  check "Quits", 465, 7 125 133 8, tab 400
  check "Nick changes", 470, 7 134 133 8, tab 400
  check "Kicks", 475, 7 143 133 8, tab 400
  check "... but show the above in Status window", 480, 15 152 125 8, tab 400
  check "Away and thank-you messages", 485, 7 161 133 8, tab 400
  check "User mode changes", 490, 7 170 133 8, tab 400
  check "Colour uncoloured fileservers in nickname list", 495, 7 179 133 8, tab 400
  ; Tab Other
  box " Extra functions ", 605, 4 23 144 38, tab 600
  check "Group @find/@locator results", 610, 7 32 138 8, tab 600
  check "... and check trigger matches server nickname", 615, 15 41 130 8, tab 600
  check "Filter oNotices to separate @#window (OpsTalk)", 620, 7 50 138 8, tab 600
  box " Spam and security ", 640, 4 62 144 114, tab 600
  check "Filter spam on channel", 645, 7 71 138 8, tab 600
  check "... and Notify if you are an op", 650, 15 80 130 8, tab 600
  check "Filter private spam", 655, 7 89 138 8, tab 600
  check "... and Notify if you are op in common channel", 660, 15 98 130 8, tab 600
  check "... and /ignore spammer for 1h (asks confirmation)", 665, 15 107 130 8, tab 600
  check "Don't accept any messages or files from users with whom you do not have a common channel", 670, 7 115 138 16, tab 600 multi
  check "... but accept DCC / query chats", 675, 15 131 130 8, tab 600
  check "Do not accept files from regular users (except mIRC trusted users)", 680, 7 140 138 16, tab 600 multi
  check "... block only potentially dangerous filetypes", 685, 15 156 130 8, tab 600
  check "Do not accept private messages from regular users", 690, 7 165 138 8, tab 600
  ; tab Custom
  check "Enable custom filters", 810, 5 26 100 8, tab 800
  text "Message type:", 820, 5 38 50 8, tab 800
  combo 830, 45 36 65 35, tab 800 drop
  edit "", 840, 4 48 144 12, tab 800 autohs
  button "Add", 850, 5 62 67 11, tab 800 flat disable
  button "Remove", 860, 79 62 68 11, tab 800 flat disable
  list 870, 4 75 144 115, tab 800 hsbar vsbar size sort extsel
  ; tab About
  edit "", 920, 3 25 146 166, multi read vsbar tab 900
}

; Initialise variables
alias -l DLF.Options.Initialise {
  ; Options Dialog variables in display order

  ; All tabs
  DLF.Options.InitOption enabled 1
  DLF.Options.InitOption showfiltered = 1

  ; Main tab
  if (%DLF.channels == $null) {
    DLF.Chan.Set $hashtag
    DLF.Status Channels set to $c(4,all) $+ .
  }
  elseif (%DLF.netchans == $null) %DLF.netchans = %DLF.channels
  ; Main tab General box
  DLF.Options.InitOption ads 1
  DLF.Options.InitOption requests 1
  DLF.Options.InitOption chmode 1
  DLF.Options.InitOption privrequests 1
  ; Main tab User events box
  DLF.Options.InitOption joins 0
  DLF.Options.InitOption parts 0
  DLF.Options.InitOption quits 0
  DLF.Options.InitOption nicks 0
  DLF.Options.InitOption kicks 0
  DLF.Options.InitOption showstatus 0
  DLF.Options.InitOption away 1
  DLF.Options.InitOption usrmode 0
  ; Main tab Check for updates
  DLF.Options.InitOption betas 0

  ; Other tab
  ; Other tab Windows box
  DLF.Options.InitOption server 1
  DLF.Options.InitOption serverads 0
  DLF.Options.InitOption perconnect 1
  DLF.Options.InitOption searchresults 1
  DLF.Options.InitOption searchspam 1
  DLF.Options.InitOption o.enabled 1
  ; Other tab Spam and Security box
  DLF.Options.InitOption chspam 1
  DLF.Options.InitOption chspam.opnotify 0
  DLF.Options.InitOption privspam 1
  DLF.Options.InitOption privspam.opnotify 0
  DLF.Options.InitOption spam.addignore 0
  DLF.Options.InitOption nocomchan 1
  DLF.Options.InitOption nocomchan.dcc 0
  DLF.Options.InitOption askregfile 1
  DLF.Options.InitOption askregfile.type 0
  DLF.Options.InitOption noregmsg 0
  ; Other tab - no box
  DLF.Options.InitOption colornicks 0

  ; Custom tab
  DLF.Options.InitOption custom.enabled 1
  DLF.Options.InitOption custom.chantext $addtok(%DLF.custom.chantext,$replace(*this is an example custom filter*,$space,$nbsp),$asc($comma))

  ; Options only available in menu not options
  ; TODO Consider adding these as options
  DLF.Options.InitOption filtered.limit 1
  DLF.Options.InitOption filtered.timestamp 1
  DLF.Options.InitOption filtered.wrap 1
  DLF.Options.InitOption filtered.strip 0
  DLF.Options.InitOption server.limit 1
  DLF.Options.InitOption server.timestamp 1
  DLF.Options.InitOption server.wrap 1
  DLF.Options.InitOption server.strip 0
  DLF.Options.InitOption o.timestamp 1
  DLF.Options.InitOption o.log 1
}

alias DLF.Options.InitOption {
  var %var = $+(%,DLF.,$1)
  if ( [ [ %var ] ] != $null) return
  [ [ %var ] ] = $2
}

alias -l DLF.Options.ToggleShowFilter {
  DLF.Options.ToggleOption showfiltered 40
  if (%DLF.showfiltered == 0) close -@ @dlF.Filter*
}

alias -l DLF.Options.ToggleOption {
  var %var = $+(%,DLF.,$1)
  var %newval = $iif([ %var ],0,1)
  [ [ %var ] ] = %newval
  if (($2 != $null) && ($dialog(DLF.Options.GUI))) did $iif(%newval,-c,-u) DLF.Options.GUI $2
  DLF.Status Option $1 $iif(%newval,set,cleared)
}

on *:dialog:DLF.Options.GUI:init:0: {
  DLF.SetVersion
  var %ver = $DLF.mIRCversion
  if (%ver != 0) {
    did -b DLF.Options.GUI 10
    did -vo DLF.Options.GUI 20 1 Upgrade to %ver $+ +
  }
  if (%DLF.enabled == 1) did -c DLF.Options.GUI 10
  if (%DLF.showfiltered == 1) did -c DLF.Options.GUI 40
  if (%DLF.netchans == $null) %DLF.netchans = %DLF.channels
  if (%DLF.ads == 1) did -c DLF.Options.GUI 410
  if (%DLF.requests == 1) did -c DLF.Options.GUI 420
  if (%DLF.chmode == 1) did -c DLF.Options.GUI 430
  if (%DLF.privrequests == 1) did -c DLF.Options.GUI 435
  if (%DLF.joins == 1) did -c DLF.Options.GUI 455
  if (%DLF.parts == 1) did -c DLF.Options.GUI 460
  if (%DLF.quits == 1) did -c DLF.Options.GUI 465
  if (%DLF.nicks == 1) did -c DLF.Options.GUI 470
  if (%DLF.kicks == 1) did -c DLF.Options.GUI 475
  if (%DLF.showstatus == 1) did -c DLF.Options.GUI 480
  if (%DLF.away == 1) did -c DLF.Options.GUI 485
  if (%DLF.usrmode == 1) did -c DLF.Options.GUI 490
  if (%DLF.betas == 1) did -c DLF.Options.GUI 540
  if (%DLF.server == 1) did -c DLF.Options.GUI 425
  if (%DLF.serverads == 1) did -c DLF.Options.GUI 415
  if (%DLF.perconnect == 1) did -c DLF.Options.GUI 440
  if (%DLF.searchresults == 1) did -c DLF.Options.GUI 610
  if (%DLF.searchspam == 1) did -c DLF.Options.GUI 615
  if (%DLF.chspam == 1) did -c DLF.Options.GUI 645
  else %DLF.chspam.opnotify = 0
  if (%DLF.chspam.opnotify == 1) did -c DLF.Options.GUI 650
  if (%DLF.privspam == 1) did -c DLF.Options.GUI 655
  else {
    %DLF.privspam.opnotify = 0
    %DLF.spam.addignore = 0
  }
  if (%DLF.privspam.opnotify == 1) did -c DLF.Options.GUI 660
  if (%DLF.spam.addignore == 1) did -c DLF.Options.GUI 665
  if (%DLF.nocomchan == 1) did -c DLF.Options.GUI 670
  else %DLF.nocomchan.dcc = 0
  if (%DLF.nocomchan.dcc == 1) did -c DLF.Options.GUI 675
  if (%DLF.askregfile == 1) did -c DLF.Options.GUI 680
  else %DLF.askregfile.type = 0
  if (%DLF.askregfile.type == 1) did -c DLF.Options.GUI 685
  if (%DLF.noregmsg == 1) did -c DLF.Options.GUI 690
  if (%DLF.colornicks == 1) did -c DLF.Options.GUI 495
  if (%DLF.o.enabled == 1) did -c DLF.Options.GUI 620
  if (%DLF.custom.enabled == 1) did -c DLF.Options.GUI 810
  DLF.Options.InitChannelList
  DLF.Options.InitCustomList
  DLF.Update.Run
  DLF.Options.About
}

alias -l DLF.Options.SetLinkedFields {
  DLF.Options.LinkedFields 410 415
  DLF.Options.LinkedFields 610 615
  DLF.Options.LinkedFields 645 650
  DLF.Options.LinkedFields 655 660 665
  DLF.Options.LinkedFields 670 675
  DLF.Options.LinkedFields 680 685
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

alias -l DLF.Options.InitChannelList {
  ; List connected networks and channels
  var %cid = $cid
  var %i = $scon(0)
  var %nets = $null
  var %netchans = $null
  while (%i) {
    scid $scon(%i)
    %nets = $addtok(%nets,$network,$asc($space))
    var %j = $chan(0)
    while (%j) {
      %netchans = $addtok(%netchans,$+($network,$chan(%j)),$asc($space))
      dec %j
    }
    dec %i
  }
  scid %cid
  %netchans = $sorttok(%netchans,$asc($space))

  ; Add networks in filtered channel list
  var %i = $numtok(%DLF.netchans,$asc($comma))
  while (%i) {
    var %netchan = $gettok(%DLF.netchans,%i,$asc($comma))
    if ($left(%netchan,1) == $hashtag) var %net = $null
    else var %net = $gettok(%netchan,1,$asc($hashtag))
    if (%net) %nets = $addtok(%nets,%net,$asc($space))
    dec %i
  }
  var %onenet = $iif($numtok(%nets,$asc($space)) <= 1,$true,$false)

  ; Populate dropdown of possible channels to add
  did -r DLF.Options.GUI 220
  DLF.Options.SetAddChannelButton
  var %numchans = $numtok(%netchans,$asc($space)), %i = 1
  while (%i <= %numchans) {
    var %netchan = $gettok(%netchans,%i,$asc($space))
    if ($istok(%DLF.netchans,%netchan,$asc($comma)) == $false) {
      if (%onenet) %netchan = $+($hashtag,$gettok(%netchan,2,$asc($hashtag)))
      did -a DLF.Options.GUI 220 %netchan
    }
    inc %i
  }

  ; Populate list of filtered channels
  did -r DLF.Options.GUI 250
  var %numchans = $numtok(%DLF.netchans,$asc($comma)), %i = 1
  while (%i <= %numchans) {
    var %netchan = $gettok(%DLF.netchans,%i,$asc($comma))
    if ($left(%netchan,1) == $hashtag) var %chan = %netchan
    else var %chan = $iif(%onenet,$+($hashtag,$gettok(%netchan,2,$asc($hashtag))),%netchan)
    did -a DLF.Options.GUI 250 %chan
    inc %i
  }
}

; Enable / disable Add channel button
on *:dialog:DLF.Options.GUI:edit:220: DLF.Options.SetAddChannelButton
on *:dialog:DLF.Options.GUI:sclick:220: DLF.Options.SetAddChannelButton
alias -l DLF.Options.SetAddChannelButton {
  if ($did(220)) did -te DLF.Options.GUI 230
  else {
    did -b DLF.Options.GUI 230
    did -t DLF.Options.GUI 30
  }
}

; Enable / disable Remove channel button
on *:dialog:DLF.Options.GUI:sclick:250: DLF.Options.SetRemoveChannelButton
alias -l DLF.Options.SetRemoveChannelButton {
  if ($did(250,0).sel > 0) did -te DLF.Options.GUI 240
  else {
    did -b DLF.Options.GUI 240
    DLF.Options.SetAddChannelButton
  }
}

; Channel Add button clicked
on *:dialog:DLF.Options.GUI:sclick:230: {
  var %chan = $did(220).text
  if ($pos(%chan,$hashtag,0) == 0) %chan = $hashtag $+ %chan
  if (($scon(0) == 1) && ($left(%chan,1) == $hashtag)) %chan = $network $+ %chan
  DLF.Chan.Add %chan
  ; Clear edit field, list selection and disable add button
  DLF.Options.InitChannelList
}

; Channel Remove button clicked or double click in list
on *:dialog:DLF.Options.GUI:sclick:240: DLF.Options.RemoveChannel
alias -l DLF.Options.RemoveChannel {
  var %i = $did(250,0).sel
  while (%i) {
    DLF.Chan.Remove $did(250,$did(250,%i).sel).text
    dec %i
  }
  did -b DLF.Options.GUI 240
  DLF.Options.InitChannelList
}

; Double click on custom text line removes line but puts it into Add box for editing and re-adding.
on *:dialog:DLF.Options.GUI:dclick:250: {
  if ($did(250,0).sel == 1 ) {
    var %chan = $did(250,$did(250,1).sel).text
    DLF.Options.RemoveChannel
    DLF.Options.InitChannelList
    did -o DLF.Options.GUI 220 0 %chan
    DLF.Options.SetAddChannelButton
  }
}

alias -l DLF.Options.InitCustomList {
  did -r DLF.Options.GUI 830
  did -a DLF.Options.GUI 830 $+(Channel,$nbsp,text)
  did -a DLF.Options.GUI 830 $+(Channel,$nbsp,action)
  did -a DLF.Options.GUI 830 $+(Channel,$nbsp,notice)
  did -a DLF.Options.GUI 830 $+(Channel,$nbsp,ctcp)
  did -a DLF.Options.GUI 830 $+(Private,$nbsp,text)
  did -a DLF.Options.GUI 830 $+(Private,$nbsp,action)
  did -a DLF.Options.GUI 830 $+(Private,$nbsp,notice)
  did -a DLF.Options.GUI 830 $+(Private,$nbsp,ctcp)
  did -c DLF.Options.GUI 830 1
  DLF.Options.SetCustomType
}

alias -l DLF.Options.About {
  did -r DLF.Options.GUI 920
  if ($fopen(dlFilter)) .fclose dlFilter
  .fopen dlFilter $script
  var %line = $fread(dlFilter)
  while ((!$feof) && (!$ferr) && ($left(%line,2) != $+(/,*))) {
    %line = $fread(dlFilter)
  }
  if (($feof) || ($ferr)) {
    if ($fopen(dlFilter)) .fclose dlFilter
    did -a DLF.Options.GUI 920 Unable to populate About tab.
    return
  }
  var %i = 0
  %line = $fread(dlFilter)
  while ((!$feof) && (!$ferr) && ($left(%line,2) != $+(*,/))) {
    did -a DLF.Options.GUI 920 %line $+ $crlf
    inc %i
    %line = $fread(dlFilter)
  }
  .fclose dlFilter
}

; Handle all checkbox clicks and save
on *:dialog:DLF.Options.GUI:sclick:10,40,540,410-495,455-490,425-620,645-690,810: {
  DLF.Options.SetLinkedFields
  DLF.Options.Save
  if (%DLF.showfiltered == 0) close -@ @dlF.Filter*.*
  if (($did == 540) && (!$sock(DLF.Socket.Update))) DLF.Update.CheckVersions
}

; Select custom message type
on *:dialog:DLF.Options.GUI:sclick:830: DLF.Options.SetCustomType

alias -l DLF.Options.SetCustomType {
  var %selected = $replace($did(830).seltext,$nbsp,$space)
  did -r DLF.Options.GUI 870
  if (%selected == Channel text) didtok DLF.Options.GUI 870 44 %DLF.custom.chantext
  elseif (%selected == Channel action) didtok DLF.Options.GUI 870 44 %DLF.custom.chanaction
  elseif (%selected == Channel notice) didtok DLF.Options.GUI 870 44 %DLF.custom.channotice
  elseif (%selected == Channel ctcp) didtok DLF.Options.GUI 870 44 %DLF.custom.chanctcp
  elseif (%selected == Private text) didtok DLF.Options.GUI 870 44 %DLF.custom.privtext
  elseif (%selected == Private action) didtok DLF.Options.GUI 870 44 %DLF.custom.privaction
  elseif (%selected == Private notice) didtok DLF.Options.GUI 870 44 %DLF.custom.privnotice
  elseif (%selected == Private ctcp) didtok DLF.Options.GUI 870 44 %DLF.custom.privctcp
  else DLF.Error DLF.Options.SetCustomType Invalid message type: %selected
}

; Enable / disable Add custom message button
on *:dialog:DLF.Options.GUI:edit:840: DLF.Options.SetAddCustomButton
alias -l DLF.Options.SetAddCustomButton {
  if ($did(840)) did -te DLF.Options.GUI 850
  else {
    did -b DLF.Options.GUI 850
    did -t DLF.Options.GUI 30
  }
}

; Enable / disable Remove custom message button
on *:dialog:DLF.Options.GUI:sclick:870: DLF.Options.SetRemoveCustomButton
alias -l DLF.Options.SetRemoveCustomButton {
  if ($did(870,0).sel > 0) did -te DLF.Options.GUI 860
  else {
    did -b DLF.Options.GUI 860
    DLF.Options.SetAddCustomButton
  }
}

; Customer filter Add button clicked
on *:dialog:DLF.Options.GUI:sclick:850: {
  var %selected = $did(830).seltext
  var %new = $did(840).text
  if (* !isin %new) var %new = $+(*,%new,*)
  DLF.CustFilt.Add %selected %new
  ; Clear edit field, list selection and disable add button
  did -r DLF.Options.GUI 840
  DLF.Options.SetAddCustomButton
  DLF.Options.SetCustomType
}

; Customer filter Remove button clicked or double click in list
on *:dialog:DLF.Options.GUI:sclick:860: DLF.Options.RemoveCustom
alias -l DLF.Options.RemoveCustom {
  var %selected = $did(830).seltext
  var %i = $did(870,0).sel
  while (%i) {
    DLF.CustFilt.Remove %selected $did(870,$did(870,%i).sel).text
    dec %i
  }
  did -b DLF.Options.GUI 860
  DLF.Options.SetCustomType
  DLF.Options.SetRemoveButton
}

; Double click on custom text line removes line but puts it into Add box for editing and re-adding.
on *:dialog:DLF.Options.GUI:dclick:870: {
  if ($did(870,0).sel == 1 ) {
    did -o DLF.Options.GUI 840 1 $did(870,$did(870,1).sel).text
    DLF.Options.RemoveCustom
    DLF.Options.SetAddCustomButton
  }
}

; Goto website button
on *:dialog:DLF.Options.GUI:sclick:520: url -a https://github.com/SanderSade/dlFilter

; Download update button
on *:dialog:DLF.Options.GUI:sclick:530: {
  did -b DLF.Options.GUI 530
  DLF.Download.Run
}

alias -l DLF.Options.Status {
  DLF.Status $1-
  if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 510 1 $1-
}

alias -l DLF.Options.Error {
  DLF.Error $1-
  if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 510 1 $1-
}

alias -l DLF.Options.Save {
  DLF.Chan.Set %DLF.netchans
  %DLF.showfiltered = $did(40).state
  %DLF.enabled = $did(10).state
  DLF.Groups.Events
  %DLF.ads = $did(410).state
  %DLF.requests = $did(420).state
  %DLF.joins = $did(455).state
  %DLF.parts = $did(460).state
  %DLF.quits = $did(465).state
  %DLF.nicks = $did(470).state
  %DLF.kicks = $did(475).state
  %DLF.chmode = $did(430).state
  %DLF.showstatus = $did(480).state
  %DLF.away = $did(485).state
  %DLF.usrmode = $did(490).state
  %DLF.privrequests = $did(435).state
  %DLF.server = $did(425).state
  %DLF.serverads = $did(415).state
  %DLF.perconnect = $did(440).state
  %DLF.searchresults = $did(610).state
  %DLF.searchspam = $did(615).state
  %DLF.chspam = $did(645).state
  %DLF.chspam.opnotify = $did(650).state
  %DLF.privspam = $did(655).state
  %DLF.privspam.opnotify = $did(660).state
  %DLF.spam.addignore = $did(665).state
  %DLF.nocomchan = $did(670).state
  %DLF.nocomchan.dcc = $did(675).state
  %DLF.askregfile = $did(680).state
  %DLF.askregfile.type = $did(685).state
  if (%DLF.askregfile.type == 1) %DLF.askregfile = 1
  %DLF.noregmsg = $did(690).state
  %DLF.colornicks = $did(495).state
  %DLF.o.enabled = $did(620).state
  %DLF.custom.enabled = $did(810).state
  %DLF.betas = $did(540).state
}

; ========== Check version for updates ==========
on *:connect: DLF.Update.Check

; Check once per week for normal releases and once per day if user is wanting betas
alias -l DLF.Update.Check {
  var %days = $calc($int(($ctime - %DLF.LastUpdateCheck) / 60 / 60 / 24))
  if ((%days >= 7) || ((%DLF.betas) && (%days >= 1))) DLF.Update.Run
}

alias -l DLF.Update.Run {
  if ($dialog(DLF.Options.GUI)) did -b DLF.Options.GUI 530
  DLF.Options.Status Checking for dlFilter updates...
  DLF.Socket.Get Update https://raw.githubusercontent.com/SanderSade/dlFilter/dlFilter-v118/dlFilter.version
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
  if ($dialog(DLF.Options.GUI)) did -b DLF.Options.GUI 530
  if (%DLF.version.web) {
    if ((%DLF.betas) $&
      && (%DLF.version.beta) $&
      && (%DLF.version.beta > %DLF.version.web)) {
      if (%DLF.version.beta > $DLF.SetVersion) DLF.Update.DownloadAvailable %DLF.version.beta %DLF.version.beta.mirc beta
      elseif (%DLF.version.web == $DLF.SetVersion) DLF.Options.Status Running current version of dlFilter beta
      else DLF.Options.Status Running a newer version $br($DLF.SetVersion) than web beta version $br(%DLF.version.beta)
    }
    elseif (%DLF.version.web > $DLF.SetVersion) DLF.Update.DownloadAvailable %DLF.version.web %DLF.version.web.mirc
    elseif (%DLF.version.web == $DLF.SetVersion) DLF.Options.Status Running current version of dlFilter
    else DLF.Options.Status Running a newer version $br($DLF.SetVersion) than website $br(%DLF.version.web)
  }
  else DLF.Socket.Error dlFilter version missing!
}

alias -l DLF.Update.DownloadAvailable {
  var %ver = $iif($3,$3 version,version) $1
  if ($version >= $2) {
    DLF.Options.Status You can update dlFilter to %ver
    did -e DLF.Options.GUI 530
  }
  else DLF.Options.Status Upgrade mIRC before you can update to %ver

  var %cid = $cid
  var %nets = $scon(0)
  while (%nets) {
    scid $scon(%nets)
    if (%DLF.netchans == #) {
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
        var %net = $gettok(%chan,1,$asc($hash))
        if (((%net == $null) || (%net == $network)) && ($chan(%chan))) DLF.Update.ChanAnnounce %chan $1 $2 $3
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
  DLF.Options.Status Downloading new version of dlFilter...
  var %newscript = $qt($script $+ .new)
  if ($isfile(%newscript)) .remove %newscript
  if ($exists(%newscript)) DLF.Socket.Error Unable to delete old temporary download file.
  DLF.Socket.Get Download https://raw.githubusercontent.com/SanderSade/dlFilter/dlFilter-v118/dlFilter.mrc
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
  DLF.Options.Status New version of dlFilter downloaded and installed
  if (%oldsaved) DLF.Status Old version of dlFilter.mrc saved as %oldscript in case you need to revert
  signal DLF.Update.Reload
  .reload -rs1 $script
}

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
alias -l hiswm {
  var %h = DLF. $+ $1
  if (!$hget(%h)) {
    DLF.Warning Hash table %h does not exist - attempting to recreate it...
    DLF.CreateHashTables
  }
  var %result = $hfind(%h,$2,1,W)
  if (%result) DLF.Debug.Log Matched in $1 $+ : $2
  return %result
}

alias -l DLF.hadd {
  var %h = DLF. $+ $1
  if (!$hget(%h)) hmake %h 10
  var %n = $hget($1, 0)
  hadd %h %n $2-
}

alias -l DLF.CreateHashTables {
  var %matches = 0
  if ($hget(DLF.chantext.ads)) hfree DLF.chantext.ads
  DLF.hadd chantext.ads *Type*@*
  DLF.hadd chantext.ads *Trigger*@*
  DLF.hadd chantext.ads *List*@*
  DLF.hadd chantext.ads *Type*!*to get this*
  DLF.hadd chantext.ads *[BWI]*@*
  DLF.hadd chantext.ads *Trigger*ctcp*
  DLF.hadd chantext.ads *@*Finålity*
  DLF.hadd chantext.ads *@*SDFind*
  DLF.hadd chantext.ads *I have just finished sending*to*Empty*
  DLF.hadd chantext.ads *§kÎn§*ßy*§hådõ*
  DLF.hadd chantext.ads *-SpR-*
  DLF.hadd chantext.ads *Escribe*@*
  DLF.hadd chantext.ads *±*
  DLF.hadd chantext.ads *Escribe*!*
  DLF.hadd chantext.ads *-SpR skin used by PepsiScript*
  DLF.hadd chantext.ads *Type*!*.*
  DLF.hadd chantext.ads *Empty! Grab one fast!*
  DLF.hadd chantext.ads *Random Play MP3*Now Activated*
  DLF.hadd chantext.ads *The Dcc Transfer to*has gone under*Transfer*
  DLF.hadd chantext.ads *just left*Sending file Aborted*
  DLF.hadd chantext.ads *has just received*for a total of*
  DLF.hadd chantext.ads *There is a Slot Opening*Grab it Fast*
  DLF.hadd chantext.ads *Tapez*Pour avoir ce Fichier*
  DLF.hadd chantext.ads *Tapez*Pour Ma Liste De*Fichier En Attente*
  DLF.hadd chantext.ads *left irc and didn't return in*min. Sending file Aborted*
  DLF.hadd chantext.ads *FTP*address*port*login*password*
  DLF.hadd chantext.ads *I have sent a total of*files and leeched a total of*since*
  DLF.hadd chantext.ads *I have just finished sending*I have now sent a total of*files since*
  DLF.hadd chantext.ads *I have just finished recieving*from*I have now recieved a total of*
  DLF.hadd chantext.ads *Proofpack Server*Looking for new scans to proof*@proofpack for available proofing packs*
  DLF.hadd chantext.ads *SpR JUKEBOX*filesize*
  DLF.hadd chantext.ads *I have spent a total time of*sending files and a total time of*recieving files*
  DLF.hadd chantext.ads *Tape*@*
  DLF.hadd chantext.ads *Tape*!*MB*
  DLF.hadd chantext.ads *Tape*!*.mp3*
  DLF.hadd chantext.ads *§*DCC Send Failed*to*§*
  DLF.hadd chantext.ads *Wireless*mb*br*
  DLF.hadd chantext.ads *Sent*OS-Limits V*
  DLF.hadd chantext.ads *File Servers Online*Polaris*
  DLF.hadd chantext.ads *There is a*Open*Say's Grab*
  DLF.hadd chantext.ads *left*and didn't return in*mins. Sending file Aborted*
  DLF.hadd chantext.ads *to*just got timed out*slot*Empty*
  DLF.hadd chantext.ads *Softwind*Softwind*
  DLF.hadd chantext.ads *Statistici 1*by Un_DuLciC*
  DLF.hadd chantext.ads *tìnkërßëll`s collection*Love Quotes*
  DLF.hadd chantext.ads *I-n-v-i-s-i-o-n*
  DLF.hadd chantext.ads *DCC SEND COMPLETE*to*slot*
  DLF.hadd chantext.ads *« * » -*
  DLF.hadd chantext.ads *¥*Mp3s*¥*
  DLF.hadd chantext.ads *DCC GET COMPLETE*from*slot*open*
  DLF.hadd chantext.ads *Je viens juste de terminer l'envoi de*Prenez-en un vite*
  DLF.hadd chantext.ads *Random Play MP3 filez Now Plugged In*
  DLF.hadd chantext.ads *a recu*pour un total de*fichiers*
  DLF.hadd chantext.ads *vient d'etre interrompu*Dcc Libre*
  DLF.hadd chantext.ads *failed*DCC Send Failed of*to*failed*
  DLF.hadd chantext.ads *is playing*info*secs*
  DLF.hadd chantext.ads *--PepsiScript--*
  DLF.hadd chantext.ads *«Scøøp MP3»*
  DLF.hadd chantext.ads *~*~SpR~*~*
  DLF.hadd chantext.ads *SpR*[*mp3*]*
  DLF.hadd chantext.ads *©§©*
  DLF.hadd chantext.ads *I am opening up*more slot*Taken*
  DLF.hadd chantext.ads *.mp3*t×PLåY6*
  DLF.hadd chantext.ads *!*.mp3*SpR*
  DLF.hadd chantext.ads *SPr*!*.mp3*
  DLF.hadd chantext.ads *Successfully*Tx.Track*
  DLF.hadd chantext.ads *[Mp3xBR]*
  DLF.hadd chantext.ads *OmeNServE*©^OmeN^*
  DLF.hadd chantext.ads *@*DragonServe*
  DLF.hadd chantext.ads *Now Sending*QwIRC*
  DLF.hadd chantext.ads *sent*to*size*speed*time*sent*
  DLF.hadd chantext.ads *Bandwith*Usage*Current*Record*
  DLF.hadd chantext.ads *Files In List*slots open*Queued*Next Send*
  DLF.hadd chantext.ads *Rank*~*x*~*
  DLF.hadd chantext.ads *Total Offered*Files*Total Sent*Files*Total Sent Today*Files*
  DLF.hadd chantext.ads *Control*IRC Client*CTCPSERV*
  DLF.hadd chantext.ads *Download this exciting book*
  DLF.hadd chantext.ads *» Port «*»*
  DLF.hadd chantext.ads *Tasteazã*@*
  DLF.hadd chantext.ads *File Servers Online*Trigger*Accessed*Served*
  DLF.hadd chantext.ads *- DCC Transfer Status -*
  DLF.hadd chantext.ads *Enter @*to see the menu*
  DLF.hadd chantext.ads *User Slots*Sends*Queues*Next Send Available*¤UControl¤*
  DLF.hadd chantext.ads *Total*File Transfer in Progress*slot*empty*
  DLF.hadd chantext.ads *!*MB*Kbps*Khz*
  DLF.hadd chantext.ads *I have just finished sending*.mp3 to*
  DLF.hadd chantext.ads *Files*free Slots*Queued*Speed*Served*
  DLF.hadd chantext.ads *I am using*SpR JUKEBOX*http://spr.darkrealms.org*
  DLF.hadd chantext.ads *FTP service*FTP*port*bookz*
  DLF.hadd chantext.ads *<><><*><><>*
  DLF.hadd chantext.ads *To serve and to be served*@*
  DLF.hadd chantext.ads *send - to*at*cps*complete*left*
  DLF.hadd chantext.ads *DCC Send Failed of*to*
  DLF.hadd chantext.ads *[Fserve Active]*
  DLF.hadd chantext.ads *File Server Online*Triggers*Sends*Queues*
  DLF.hadd chantext.ads *Teclea: @*
  DLF.hadd chantext.ads *rßP£a*sk*n*
  DLF.hadd chantext.ads *rßPLåY*
  DLF.hadd chantext.ads *<*>*!*
  DLF.hadd chantext.ads @ * is now open via ftp @*
  DLF.hadd chantext.ads @ Use @*
  DLF.hadd chantext.ads * CSE Fact *    CHANGING the way you search *
  inc %matches $hget(DLF.chantext.ads,0).item

  if ($hget(DLF.chantext.cmds)) hfree DLF.chantext.cmds
  DLF.hadd chantext.cmds !*
  DLF.hadd chantext.cmds @*
  inc %matches $hget(DLF.chantext.cmds,0).item

  if ($hget(DLF.chantext.spam)) hfree DLF.chantext.spam
  DLF.hadd chantext.spam *KeepTrack*de adisoru*
  DLF.hadd chantext.spam *Leaving*reason*auto away after*
  DLF.hadd chantext.spam *I am AWAY*Reason*To page me*
  DLF.hadd chantext.spam *sets away*auto idle away*since*
  DLF.hadd chantext.spam *away*since*pager*
  DLF.hadd chantext.spam *Thanks for the +v*
  DLF.hadd chantext.spam *I have just finished receiving*from*
  DLF.hadd chantext.spam *We have just finished receiving*From The One And Only*
  DLF.hadd chantext.spam *Thank You*for serving in*
  DLF.hadd chantext.spam *Thanks for the @*
  DLF.hadd chantext.spam *Thanks*For*The*Voice*
  DLF.hadd chantext.spam *I am AWAY*Reason*I have been Away for*
  DLF.hadd chantext.spam *HêåvêñlyAway*
  DLF.hadd chantext.spam *[F][U][N]*
  DLF.hadd chantext.spam *Tx TIMEOUT*
  DLF.hadd chantext.spam *Receive Successful*Thanks for*
  DLF.hadd chantext.spam *Thanks*for Supplying an server in*
  DLF.hadd chantext.spam *have just finished recieving*from*I have leeched a total*
  DLF.hadd chantext.spam *DCC Send Failed of*to*Starting next in Que*
  DLF.hadd chantext.spam *KeepTrack*by*^OmeN*
  DLF.hadd chantext.spam *Message*SysReset*
  DLF.hadd chantext.spam *YAY* Another brave soldier in the war to educate the masses*Onward Comrades*
  DLF.hadd chantext.spam *WaS auTo-VoiCeD THaNX FoR SHaRiNG HeRe iN*
  DLF.hadd chantext.spam *I have just received*from*leeched since*
  DLF.hadd chantext.spam *mp3 server detected*
  DLF.hadd chantext.spam *KiLLJarX*channel policy is that we are a*
  DLF.hadd chantext.spam *rbPlay20.mrc*
  DLF.hadd chantext.spam *rßPLåY2.0*
  DLF.hadd chantext.spam *I have just finished receiving*from*have now received a total*
  DLF.hadd chantext.spam *ROLL TIDE*Now Playing*mp3*
  DLF.hadd chantext.spam *Tocmai am primit*KeepTrack*
  DLF.hadd chantext.spam *Total Received*Files*Total Received Today*Files*
  DLF.hadd chantext.spam *BJFileTracker V06 by BossJoe*
  DLF.hadd chantext.spam *Just Sent To*Filename*Slots Free*Queued*
  DLF.hadd chantext.spam *Received*From*Size*Speed*Time*since*
  DLF.hadd chantext.spam *I have just received*from*for a total of*KeepTrack*
  DLF.hadd chantext.spam *« Ë×Çü®§îöñ »*
  DLF.hadd chantext.spam *Thanks*For The*@*
  DLF.hadd chantext.spam *get - from*at*cps*complete*
  DLF.hadd chantext.spam *Je viens juste de terminer de recevoir*de*Prenez-en un vite*
  DLF.hadd chantext.spam *§ÐfíñÐ âÐÐ-øñ§*
  DLF.hadd chantext.spam *Welcome back to #* operator*.*
  DLF.hadd chantext.spam *[Away]*SysReset*
  DLF.hadd chantext.spam *Back*Duration*
  DLF.hadd chantext.spam *MisheBORG*SendStat*v.*
  inc %matches $hget(DLF.chantext.spam,0).item

  if ($hget(DLF.chantext.always)) hfree DLF.chantext.always
  DLF.hadd chantext.always 2find *
  DLF.hadd chantext.always Sign in to turn on 1-Click ordering.
  DLF.hadd chantext.always ---*KB
  DLF.hadd chantext.always ---*MB
  DLF.hadd chantext.always ---*KB*s*
  DLF.hadd chantext.always ---*MB*s*
  DLF.hadd chantext.always #find *
  DLF.hadd chantext.always "find *
  inc %matches $hget(DLF.chantext.always,0).item

  if ($hget(DLF.chanaction.away)) hfree DLF.chanaction.away
  DLF.hadd chanaction.away *has taken a seat on the channel couch*Couch v*by Kavey*
  DLF.hadd chanaction.away *has stumbled to the channel couch*Couch v*by Kavey*
  DLF.hadd chanaction.away *has returned from*I was gone for*
  DLF.hadd chanaction.away *is gone. Away after*minutes of inactivity*
  DLF.hadd chanaction.away *is away*Reason*since*
  DLF.hadd chanaction.away *is BACK from*auto-away*
  DLF.hadd chanaction.away *is back*From*Gone for*
  DLF.hadd chanaction.away *sets away*Auto Idle Away after*
  DLF.hadd chanaction.away *is back from*Gone*
  DLF.hadd chanaction.away *is BACK from*Away*
  DLF.hadd chanaction.away *asculta*
  DLF.hadd chanaction.away *is AWAY*auto-away*
  DLF.hadd chanaction.away *Avertisseur*Journal*
  DLF.hadd chanaction.away *I-n-v-i-s-i-o-n*
  DLF.hadd chanaction.away *is back*from*Auto IdleAway*
  DLF.hadd chanaction.away *way*since*pager*
  DLF.hadd chanaction.away *[Backing Up]*
  DLF.hadd chanaction.away *está away*pager*
  DLF.hadd chanaction.away *uses cracked software*I will respond to the following commands*
  DLF.hadd chanaction.away *I Have Send My List*Times*Files*Times*
  DLF.hadd chanaction.away *Type Or Copy*Paste*To Get This Song*
  DLF.hadd chanaction.away *is currently boogying away to*
  DLF.hadd chanaction.away *is listening to*Kbps*KHz*
  DLF.hadd chanaction.away *Now*Playing*Kbps*KHz*
  inc %matches $hget(DLF.chanaction.away,0).item

  if ($hget(DLF.chanaction.spam)) hfree DLF.chanaction.spam
  DLF.hadd chanaction.spam *FTP*port*user*pass*
  DLF.hadd chanaction.spam *get AMIP*plug-in at http*amip.tools-for.net*
  inc %matches $hget(DLF.chanaction.spam,0).item

  if ($hget(DLF.channotice.spam)) hfree DLF.channotice.spam
  DLF.hadd channotice.spam *WWW.TURKSMSBOT.CJB.NET*
  DLF.hadd channotice.spam *free-download*
  inc %matches $hget(DLF.channotice.spam,0).item

  if ($hget(DLF.chanctcp.spam)) hfree DLF.chanctcp.spam
  DLF.hadd chanctcp.spam *SLOTS*
  DLF.hadd chanctcp.spam *OmeNServE*
  DLF.hadd chanctcp.spam *RAR*
  DLF.hadd chanctcp.spam *WMA*
  DLF.hadd chanctcp.spam *ASF*
  DLF.hadd chanctcp.spam *SOUND*
  DLF.hadd chanctcp.spam *MP*
  inc %matches $hget(DLF.chanctcp.spam,0).item

  if ($hget(DLF.privtext.spam)) hfree DLF.privtext.spam
  DLF.hadd privtext.spam *www*sex*
  DLF.hadd privtext.spam *www*xxx*
  DLF.hadd privtext.spam *http*sex*
  DLF.hadd privtext.spam *http*xxx*
  DLF.hadd privtext.spam *sex*www*
  DLF.hadd privtext.spam *xxx*www*
  DLF.hadd privtext.spam *sex*http*
  DLF.hadd privtext.spam *xxx*http*
  DLF.hadd privtext.spam *porn*http*
  inc %matches $hget(DLF.privtext.spam,0).item

  if ($hget(DLF.privtext.server)) hfree DLF.privtext.server
  DLF.hadd privtext.server Sorry, I'm making a new list right now, please try later*
  DLF.hadd privtext.server *Request Denied*OmeNServE*
  DLF.hadd privtext.server *Sorry for cancelling this send*OmeNServE*
  DLF.hadd privtext.server Lo Siento, no te puedo enviar mi lista ahora, intenta despues*
  DLF.hadd privtext.server Lo siento, pero estoy creando una nueva lista ahora*
  DLF.hadd privtext.server I have successfully sent you*OS*
  DLF.hadd privtext.server *Petición rechazada*DragonServe*
  DLF.hadd privtext.server *I don't have*Please check your spelling or get my newest list by typing @* in the channel*
  DLF.hadd privtext.server *you already have*in my queue*has NOT been added to my queue*
  DLF.hadd privtext.server *You already have*in my queue*Type @*-help for more info*
  DLF.hadd privtext.server *Request Denied*Reason: *DragonServe*
  DLF.hadd privtext.server *You already have*requests in my queue*is not queued*
  DLF.hadd privtext.server *Queue Status*File*Position*Waiting Time*OmeNServE*
  DLF.hadd privtext.server *Empieza transferencia*IMPORTANTE*dccallow*
  DLF.hadd privtext.server *Sorry, I'm too busy to send my list right now, please try later*
  DLF.hadd privtext.server *Please standby for acknowledgement. I am using a secure query event*
  inc %matches $hget(DLF.privtext.server,0).item

  if ($hget(DLF.privtext.away)) hfree DLF.privtext.away
  DLF.hadd privtext.away *AFK, auto away after*minutes. Gone*
  DLF.hadd privtext.away *Away*Reason*Auto Away*
  DLF.hadd privtext.away *Away*Reason*Duration*
  DLF.hadd privtext.away *Away*Reason*Gone for*Pager*
  DLF.hadd privtext.away *^Auto-Thanker^*
  DLF.hadd privtext.away *If i didn't know any better*I would have thought you were flooding me*
  DLF.hadd privtext.away *Message's from strangers are Auto-Rejected*
  DLF.hadd privtext.away *Dacia Script v1.2*
  DLF.hadd privtext.away *Away*SysReset*
  DLF.hadd privtext.away *automated msg*
  inc %matches $hget(DLF.privtext.away,0).item

  if ($hget(DLF.privnotice.server)) hfree DLF.privnotice.server
  DLF.hadd privnotice.server *I have added*
  DLF.hadd privnotice.server *After waiting*min*
  DLF.hadd privnotice.server *This makes*times*
  DLF.hadd privnotice.server *is on the way!*
  DLF.hadd privnotice.server *has been sent sucessfully*
  DLF.hadd privnotice.server *has been sent successfully*
  DLF.hadd privnotice.server *send will be initiated as soon as possible*
  DLF.hadd privnotice.server *«SoftServe»*
  DLF.hadd privnotice.server *You are the successful downloader number*
  DLF.hadd privnotice.server *You are in*
  DLF.hadd privnotice.server *Request Denied*
  DLF.hadd privnotice.server *OmeNServE v*
  DLF.hadd privnotice.server *«OmeN»*
  DLF.hadd privnotice.server *is not found*
  DLF.hadd privnotice.server *file not located*
  DLF.hadd privnotice.server *I don't have the file*
  DLF.hadd privnotice.server *is on its way*
  DLF.hadd privnotice.server *±*
  DLF.hadd privnotice.server *Transfer Started*File*
  DLF.hadd privnotice.server *is on it's way!*
  DLF.hadd privnotice.server *Requested File's*
  DLF.hadd privnotice.server *Please make a resume request!*
  DLF.hadd privnotice.server *File Transfer of*
  DLF.hadd privnotice.server *Please reinitiate File-transfer!*
  DLF.hadd privnotice.server *on its way*
  DLF.hadd privnotice.server *OS-Limits*
  DLF.hadd privnotice.server *Transfer Complete*I have successfully sent*QwIRC
  DLF.hadd privnotice.server *Request Accepted*File*Queue position*
  DLF.hadd privnotice.server *Le Transfert de*Est Completé*
  DLF.hadd privnotice.server *Query refused*in*seconds*
  DLF.hadd privnotice.server *Keeptrack*omen*
  DLF.hadd privnotice.server *U Got A File From Me*files since*
  DLF.hadd privnotice.server *Transfer Complete*sent*
  DLF.hadd privnotice.server *Transmision de*finalizada*
  DLF.hadd privnotice.server *Send Failed*at*Please make a resume request*
  DLF.hadd privnotice.server *t×PLåY*
  DLF.hadd privnotice.server *OS-Limites V*t×PLåY*
  DLF.hadd privnotice.server *rßPLåY2*
  DLF.hadd privnotice.server Request Accepted*Has Been Placed In The Priority Queue At Position*
  DLF.hadd privnotice.server *esta en camino!*
  DLF.hadd privnotice.server *Envio cancelado*
  DLF.hadd privnotice.server *de mi lista de espera*
  DLF.hadd privnotice.server *Después de esperar*min*
  DLF.hadd privnotice.server *veces que he enviado*
  DLF.hadd privnotice.server *archivos, Disfrutalo*
  DLF.hadd privnotice.server Thank you for*.*!
  DLF.hadd privnotice.server *veces que env*
  DLF.hadd privnotice.server *zip va en camino*
  DLF.hadd privnotice.server *Enviando*(*)*
  DLF.hadd privnotice.server *Unable to locate any files with*associated within them*
  DLF.hadd privnotice.server *Has Been Placed In The Priority Queue At Position*Omenserve*
  DLF.hadd privnotice.server *Thanks*for sharing*with me*
  DLF.hadd privnotice.server *«[RDC]»*
  DLF.hadd privnotice.server *Your send of*was successfully completed*
  DLF.hadd privnotice.server *AFK, auto away after*minutes*
  DLF.hadd privnotice.server *Envío completo*DragonServe*
  DLF.hadd privnotice.server *Empieza transferencia*DragonServe*
  DLF.hadd privnotice.server *Ahora has recibido*DragonServe*
  DLF.hadd privnotice.server *Starting Transfer*DragonServe*
  DLF.hadd privnotice.server *You have now received*from me*for a total of*sent since*
  DLF.hadd privnotice.server *Thanks For File*It is File*That I have recieved*
  DLF.hadd privnotice.server *Thank You*I have now received*file*from you*for a total of*
  DLF.hadd privnotice.server *You Are Downloader Number*Overall Downloader Number*
  DLF.hadd privnotice.server *DCC Get of*FAILED Please Re-Send file*
  DLF.hadd privnotice.server *request for*acknowledged*send will be initiated as soon as possible*
  DLF.hadd privnotice.server *file not located*
  DLF.hadd privnotice.server *t×PLÅY*
  DLF.hadd privnotice.server *I'm currently away*your message has been logged*
  DLF.hadd privnotice.server *If your message is urgent, you may page me by typing*PAGE*
  DLF.hadd privnotice.server *Gracias*Ahora he recibido*DragonServe*
  DLF.hadd privnotice.server *Request Accepted*List Has Been Placed In The Priority Queue At Position*
  DLF.hadd privnotice.server *Send Complete*File*Sent*times*
  DLF.hadd privnotice.server *Sent*Files Allowed per day*User Class*BWI-Limits*
  DLF.hadd privnotice.server *Now I have received*DragonServe*
  inc %matches $hget(DLF.privnotice.server,0).item

  if ($hget(DLF.privnotice.dnd)) hfree DLF.privnotice.dnd
  DLF.hadd privnotice.dnd *SLOTS My mom always told me not to talk to strangers*
  DLF.hadd privnotice.dnd *CTCP flood detected, protection enabled*
  inc %matches $hget(DLF.privnotice.dnd,0).item

  if ($hget(DLF.ctcp.reply)) hfree DLF.ctcp.reply
  DLF.hadd ctcp.reply *SLOTS*
  DLF.hadd ctcp.reply *ERRMSG*
  DLF.hadd ctcp.reply *MP3*
  inc %matches $hget(DLF.ctcp.reply,0).item

  if ($hget(DLF.findtext.header)) hfree DLF.findtext.header
  DLF.hadd findtext.header *Search Result*OmeNServE*
  DLF.hadd findtext.header *OmeN*Search Result*ServE*
  DLF.hadd findtext.header *Matches for*Copy and paste in channel*
  DLF.hadd findtext.header *Total*files found*
  DLF.hadd findtext.header *Search Results*QwIRC*
  DLF.hadd findtext.header *Search Result*Too many files*Type*
  DLF.hadd findtext.header *@Find Results*SysReset*
  DLF.hadd findtext.header *End of @Find*
  DLF.hadd findtext.header *I have*match*for*in listfile*
  DLF.hadd findtext.header *SoftServe*Search result*
  DLF.hadd findtext.header *Tengo*coincidencia* para*
  DLF.hadd findtext.header *I have*match*for*Copy and Paste*
  DLF.hadd findtext.header *Too many results*@*
  DLF.hadd findtext.header *Tengo*resultado*slots*
  DLF.hadd findtext.header *I have*matches for*You might want to get my list by typing*
  DLF.hadd findtext.header *Résultat De Recherche*OmeNServE*
  DLF.hadd findtext.header *Resultados De Busqueda*OmenServe*
  DLF.hadd findtext.header *Total de*fichier*Trouvé*
  DLF.hadd findtext.header *Fichier* Correspondant pour*Copie*
  DLF.hadd findtext.header *Search Result*Matches For*Copy And Paste*
  DLF.hadd findtext.header *Resultados de la búsqueda*DragonServe*
  DLF.hadd findtext.header *Results for your search*DragonServe*
  DLF.hadd findtext.header *«SoftServe»*
  DLF.hadd findtext.header *search for*returned*results on list*
  DLF.hadd findtext.header *List trigger:*Slots*Next Send*CPS in use*CPS Record*
  DLF.hadd findtext.header *Searched*files and found*matching*To get a file, copy !*
  DLF.hadd findtext.header *Note*Hey look at what i found!*
  DLF.hadd findtext.header *Note*MP3-MP3*
  DLF.hadd findtext.header *Search Result*Matches For*Get My List Of*Files By Typing @*
  DLF.hadd findtext.header *Resultado Da Busca*Arquivos*Pegue A Minha Lista De*@*
  DLF.hadd findtext.header *J'ai Trop de Résultats Correspondants*@*
  DLF.hadd findtext.header *Search Results*Found*matches for*Type @*to download my list*
  DLF.hadd findtext.header *I have found*file*for your query*Displaying*
  DLF.hadd findtext.header *From list*found*displaying*
  inc %matches $hget(DLF.findtext.header,0).item

  if ($hget(DLF.findnotice.header)) hfree DLF.findnotice.header
  DLF.hadd findnotice.header No match found for*
  DLF.hadd findnotice.header *I have*match* for*in listfile*
  inc %matches $hget(DLF.findnotice.header,0).item

  if ($hget(DLF.find.result)) hfree DLF.find.result
  DLF.hadd find.result !*
  DLF.hadd find.result : !*
  inc %matches $hget(DLF.find.result,0).item

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
alias -l DLF.Warning echo -tas $c(1,9,$DLF.logo Warning: $1-)
alias -l DLF.Error echo -tas $c(1,9,$DLF.logo $c(4,$b(Error:)) $1-)

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
; Colour, bold, underline, italic, reverse e.g.
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
    DLF.Error Colour value invalid: $1
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
    var %msg = $+($sockname,: http,$iif($sock($sockname).ssl,s),://,$gettok(%mark,2,$asc($space)),$gettok(%mark,3,$asc($space)),:) $1-
    sockclose $sockname
    DLF.Options.Error %msg
  }
  else DLF.Error $1-
  halt
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

; ========== DLF.Debug.* ==========
; Routines to help developers by providing a filtered debug window
alias -l DLF.Halt {
  if ($0) DLF.Debug.Log $1-
  else DLF.Debug.Log Halted: No details available
  halt
}

alias DLF.Debug.DLF {
  if ((($0 == 0) && ($debug)) || ($1- == off)) debug off
  else {
    if (($0 == 0) || ($1 == on)) {
      var %target = @dlF.Debug. $+ $network
      if ($window(%target) == $null) window -k0mx %target
    }
    else var %target = $qt($1-)
    debug -ipt %target DLF.Debug.Filter
  }
}

alias DLF.Debug.Filter {
  ; This identifier should return $1- if it is a line dlF reacts to else $null
  ; In practice this means returning $null iff it is a channel message and
  var %text = $1-
  tokenize $asc($space)) $1-
  if ($left($2,1) == $colon) {
    var %user = $right($2,-1)
    tokenize $asc($space)) $1 $3-
  }
  if ($1 == ->) {
    var %server = $2
    tokenize $asc($space)) $1 $3-
  }
  if (($2 == PING) || ($2 == PONG)) return $null
  if (($1 != <-) $&
    || ($2 != PRIVMSG) $&
    || ($left($3,1) != $hashtag) $&
    || ($DLF.Chan.IsDlfChan($network,$3))) DLF.Debug.Log %text
  return $null
}

alias -l DLF.Debug.Log {
  if ($debug == $null) return
  if ($0 == 0) return
  if ($left($debug,1) != @) write $debug $1-
  else {
    var %c
    if ($1 == <-) %c = 1
    elseif ($1 == ->) %c = 12
    elseif ($1 == Halted:) %c = 4
    else %c = 3
    aline -ip %c $debug $timestamp $1-
  }
}

alias -l DLF.Debug.Unload {
  var %i = $scon(0)
  while (%i) {
    scid $scon(%i) debug off
    dec %i
  }
}

; ========== DLF.Debug ==========
; Run this with //DLF.Debug only if you are asked to
; by someone providing dlFilter support.
alias DLF.Debug {
  var %file = $qt($+($sysdir(downloads),dlFilter.debug.txt))
  echo 14 -s [dlFilter] Debug started.
  if ($show) echo 14 -s [dlFilter] Creating %file
  write -c %file --- Start of debug info --- $logstamp ---
  write -i %file
  write %file Executing $script from $scriptdir
  write %file dlFilter version %DLF.version
  write %file mIRC version $version $iif($portable,portable)
  write %file Running Windows $os
  write %file Host: $host
  write %file IP: $ip
  write -i %file
  write -i %file
  var %cs = $scon(0)
  if ($show) echo 14 -s [dlFilter] %cs servers
  write %file --- Servers --- %cs servers
  write -i %file
  var %i = 1
  while (%i <= %cs) {
    var %st = $scon(%i).status
    if (%st == connected) %st = $iif($scon(%i).ssl,securely) %st to $+($scon(%i).server,$chr(40),$scon(%i).serverip,:,$scon(%i).port,$chr(41)) as $scon(%i).me
    if ($show) echo 14 -s [dlFilter] Server %i is $scon(%i).servertarget $+ : %st
    write %file Server %i is $scon(%i).servertarget $+ : %st
    if (%st != disconnected) {
      write %file $chr(9) ChanTypes= $+ $scon(%i).chantypes $+ , ChanModes= $+ [ $+ $scon(%i).chanmodes $+ ], Modespl= $+ $scon(%i).modespl $+ , Nickmode= $+ $scon(%i).nickmode $+ , Usermode= $+ $scon(%i).usermode
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
      write %file $chr(9) Channels: $replace(%chans,$chr(44),$chr(44) $+ $chr(32))
    }
    inc %i
  }
  write -i %file
  write -i %file
  var %scripts = $script(0)
  if ($show) echo 14 -s [dlFilter] %scripts scripts loaded
  write %file --- Scripts --- %scripts scripts loaded
  write -i %file
  var %i = 1
  while (%i <= %scripts) {
    if ($show) echo 14 -s [dlFilter] Script %i is $script(%i)
    write %file Script %i is $script(%i) and is $lines($script(%i)) lines and $file($script(%i)).size bytes
    inc %i
  }
  write -i %file
  write -i %file
  var %vars = $var(*,0)
  var %DLFvars = $var(DLF.*,0)
  if ($show) echo 14 -s [dlFilter] Found %vars variables, of which %DLFvars are dlFilter variables.
  write %file --- dlFilter Variables --- %vars variables, of which %DLFvars are dlFilter variables.
  write -i %file
  var %vars = $null
  while (%DLFvars) {
    %vars = $addtok(%vars,$var(DLF.*,%DLFvars),44)
    dec %DLFvars
  }
  var %vars = $sorttok(%vars,44,r)
  var %DLFvars = $numtok(%vars,44)
  while (%DLFvars) {
    var %v = $gettok(%vars,%DLFvars,44)
    write %file %v = $var($right(%v,-1),1).value
    dec %DLFvars
  }
  write -i %file
  write -i %file
  var %grps = $group(0)
  if ($show) echo 14 -s [dlFilter] %grps group(s) found
  write %file --- Groups --- %grps group(s) found
  write -i %file
  var %i = 1
  while (%i <= %grps) {
    write %file Group %i $iif($group(%i).status == on,on: $+ $chr(160),off:) $group(%i) from $group(%i).fname
    inc %i
  }
  write -i %file
  write -i %file
  var %hs = $hget(0)
  if ($show) echo 14 -s [dlFilter] %hs hash table(s) found
  write %file --- Hash tables --- %hs hash table(s) found
  write -i %file
  var %i = 1
  while (%i <= %hs) {
    write %file Table %i $+ : $hget(%i) $+ , items $hget(%i, 0).item $+ , slots $hget(%i).size
    inc %i
  }
  write -i %file
  write %file --- End of debug info --- $logstamp ---
  echo 14 -s [dlFilter] Debug ended.
}
