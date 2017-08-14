/*
DLFILTER -=- Firewall, anti-spam for mIRC
and message filter for file sharing channels.
Authors: DukeLupus and Sophist

Annoyed by advertising messages from the various file serving bots? Fed up with endless channel messages from other users searching for and requesting files? Are the responses to your own requests getting lost in the crowd?

This script filters out the crud, leaving only the useful messages displayed in the channel. By default, the filtered messages are thrown away, but you can direct them to custom windows if you wish. Functions include:

• Filter other peoples messages, server adverts and spam
• Collect @find results into a custom window
• Auto-accept requested files but reject any other files
• Stop chat windows opening without your consent
• Harden your mIRC security settings
• If you are a channel op, provide oNotice chat windows

This version is a significant upgrade from the previous major release 1.16 with significant new functionality. Feedback is appreciated.

Download: https://github.com/SanderSade/dlFilter/releases - update regularly to handle new forms of message.
Feedback: https://github.com/SanderSade/dlFilter/issues

To load: use /load -rs dlFilter.mrc

Note that dlFilter loads itself automatically as a first script (or second if you are also running sbClient). This avoids problems where other scripts halt events preventing this scripts events from running.

Acknowledgements
================
dlFilter uses the following code from other people:

• GetFileName based on code from TipiTunes' OS-Quicksearch
• automatic version check based on code developed for dlFilter by TipiTunes
• Support for AG6 & 7 by TipiTunes
• Some of the spam definitions are from HugHug's SoftSnow filter.
• Vadi wrote special function to vPowerGet dll that allows sending files from DLF.@find.Results window to vPowerGet.
*/

/* CHANGE LOG

  Immediate TODO
        Add comment support to versions file
        Test location and filename for oNotice log files
        Make FilterSearch dynamic i.e. new lines which match are added.
        Remove window limits and use mIRC native functionality instead.

  Ideas for possible future enhancements
        Implement toolbar functionality with right click menu
        Check mIRC security settings not too lax
        Manage filetype ignore list like trust list i.e. temp add for requested filetypes.
        Advertising for sbClient for @search + option (await sbClient remediation).
        Better icon file
        Right click channel line menu-items for adding to custom filter (if possible since not a list window)
        More menu options equivalent to dialog options
        Make it work on AdiIRC and update version check handle AdiIRC.

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
          New Ops tab
          New About tab
          Channels / custom filters list - double click to edit.
        Menu and events broken out into aliases
        Added extra options for windows for Server Ads and per connection
        Added extra option to check @find result trigger matches nickname sending them
        Added extra option to auto-accept requested files
        Added option to auto-resend the file request up to 3 times if the send was incomplete.
        Added option to rename file back to original name if server has changed it (unless mIRC DCC Get Options will run a command on the file).
        Added option to filter any line from regular user containing control codes (as likely to be unknown spam)
        Added option to filter lines without alphabetics
        Removed New Release filters
        Improved DLF.Debug code
        Created toolbar gif file from embedded data without needing to download it.
          (And code to turn gif into compressed encoded embedded data.)
        Double-click in find results window to download the file
        Search in Filter window now retains line colours
        Restricted ctcp Version responses to people in common channel or PM
        DLF.Watch now displays custom debug window filtered to dlF channels with halt reasons
        Only add *'s around custom filters if user hasn't explicitly included a *
        Multi-server support - option for for custom windows per connection.
        Use hash tables for custom filters
        Colour server nicks now overrides colours set using generic colouring rules which are not based on user modes etc.
        Added window description to title bar for all custom windows.
        @find windows per connection.
        Handle @find results from normal users rather than give error.
        Own file requests are tracked and matching DCC Sends not halted regardless of whether server is regular user or not.
        Added dynamic titlebar to show channel dlF filtering statistics
        Added Ops channel advertising option - an op can advertise dlFilter once every x minutes.
        Added Ops private advertising option which:
          Version checks users as they join and if they are a mIRC user reminds them to install or upgrade dlF.
          Send advert to users doing @find.
        @find results from ps2 are treated as server responses and no longer give regular user warnings
        Lines in @find / Ads windows change colour as servers join/part the channel.
        "Regular user tried to" warning messages sent to appropriate channels
        Resend requests if server rejoins the channel (in case it has been restarted and request was lost).
        Block channel-wide ctcp requests for VERSION, FINGER, TIME & PING if not from op.
          (Channel-wide ctcp requests are not sensible, and could be for hacking purposes to see who is vulnerable.)
        Added option to block private Finger requests which are not commonly used and could leak personal information.
        Auto-accept @+user / @search response files if they are:
          1. File type .txt or .zip or .rar, and filename starts-with sending nick; and
          2. Either sending nick matches trigger (or if trigger has hyphen up to hyphen).
        DCC Send/Get functionality now acts like firewall - with blocking rules.
        Move ignore spammer functionality to timer because error on $input because it can't run in event
        Added option to accept private messages from user with a query window open.
        Chanserv channel welcome notices now directed to correct window.
        Added filtering of topic changes

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
  ; mirc - We need regex /F first implemented in 7.44
  elseif ($version >= 7.44) return 0
  %DLF.enabled = 0
  return mIRC 7.44
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
  DLF.StatusAll Loading complete.
  return

  :error
  DLF.Error During load: $qt($error)
}

alias -l DLF.LoadCheck {
  var %sbc = $iif(sbClient.* iswm $nopath($script(1)) || sbClient.* iswm $nopath($script(2)),$true,$false)
  if (($script == $script(1)) && (%sbc == $false)) return
  if (($script == $script(2)) && (%sbc)) return
  $1 $iif(%sbc,-rs2,-rs1) $qt($script)
}

alias -l DLF.RenameVar {
  if ($($+(%,DLF.,$2),2) == $null) return
  .set $($+(%,DLF.,$1),1) $($+(%,DLF.,$2),2)
  .unset $($+(%,DLF.,$2),1)
}

on *:signal:DLF.Initialise: { DLF.Initialise $1- }
alias DLF.Initialise {
  ; Handle obsolete variables
  .unset %DLF.custom.selected
  .unset %DLF.newreleases
  .unset %DLF.ptext
  .unset %DLF.showstatus
  ; Make variables more consistent
  if (%DLF.netchans == $null) %DLF.netchans = %DLF.channels
  DLF.RenameVar dccsend.dangerous askregfile.type
  DLF.RenameVar dccsend.nocomchan nocomchan.dcc
  DLF.RenameVar dccsend.untrusted askregfile
  DLF.RenameVar filter.ads ads
  DLF.RenameVar filter.aways away
  DLF.RenameVar filter.joins joins
  DLF.RenameVar filter.kicks kicks
  DLF.RenameVar filter.modeschan chmode
  DLF.RenameVar filter.modesuser usrmode
  DLF.RenameVar filter.modesuser usrmode
  DLF.RenameVar filter.nicks nicks
  DLF.RenameVar filter.parts parts
  DLF.RenameVar filter.quits quits
  DLF.RenameVar filter.requests requests
  DLF.RenameVar filter.spamchan chspam
  DLF.RenameVar filter.spampriv privspam
  DLF.RenameVar opwarning.spamchan chspam.opnotify
  DLF.RenameVar opwarning.spampriv privspam.opnotify
  DLF.RenameVar private.nocomchan nocomchan
  DLF.RenameVar private.regular noregmsg
  DLF.RenameVar private.requests privrequests
  DLF.RenameVar serverwin server
  DLF.RenameVar update.betas betas
  DLF.RenameVar win-filter.limit filtered.limit
  DLF.RenameVar win-filter.log filtered.log
  DLF.RenameVar win-filter.strip filtered.strip
  DLF.RenameVar win-filter.timestamp filtered.timestamp
  DLF.RenameVar win-filter.wrap filtered.wrap
  DLF.RenameVar win-onotice.enabled o.enabled
  DLF.RenameVar win-onotice.log o.log
  DLF.RenameVar win-onotice.timestamp o.timestamp
  DLF.RenameVar win-server.limit server.limit
  DLF.RenameVar win-server.log server.log
  DLF.RenameVar win-server.strip server.strip
  DLF.RenameVar win-server.timestamp server.timestamp
  DLF.RenameVar win-server.wrap server.wrap

  if ($script(onotice.mrc)) .unload -rs onotice.mrc
  if ($script(onotice.txt)) .unload -rs onotice.txt
  DLF.StatusAll $iif(%DLF.JustLoaded,Loading,Starting) $c(4,version $DLF.SetVersion) by DukeLupus & Sophist.
  DLF.StatusAll Please check dlFilter homepage $br($c(12,9,$u(https://github.com/SanderSade/dlFilter/issues))) for help.
  ;DLF.CreateGif
  hfree -w DLF.*
  DLF.CreateHashTables
  DLF.Options.Initialise
  DLF.Groups.Events
  DLF.Ops.AdvertsEnable
  var %ver = $DLF.mIRCversion
  if (%ver != 0) DLF.Error dlFilter requires %ver $+ +. dlFilter disabled until mIRC is updated.
}

on *:unload: {
  DLF.Watch.Unload
  var %keepvars = $?!="Do you want to keep your dlFilter configuration?"
  DLF.StatusAll Unloading $c(4,9,version $DLF.SetVersion) by DukeLupus & Sophist.
  if (%keepvars == $false) {
    DLF.StatusAll Unsetting variables..
    .unset %DLF.*
  }
  DLF.StatusAll Closing open dlFilter windows
  if ($dialog(DLF.Options.GUI)) .dialog -x DLF.Options.GUI DLF.Options.GUI
  close -a@ @dlF.Filter.*
  close -a@ @dlF.FilterSearch.*
  close -a@ @dlF.Server.*
  close -a@ @dlF.ServerSearch.*
  close -a@ @dlF.@find.*
  close -a@ @dlF.Ads.*
  close -a@ @#*
  DLF.StatusAll Unloading complete.
  DLF.StatusAll $space
  DLF.StatusAll To reload run /load -rs1 $qt($script)
  DLF.StatusAll $space
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
  $iif($me !isop $chan, $style(2)) Send oNotice: DLF.oNotice.Open
  -
  dlFilter
  ..$iif($DLF.Chan.IsDlfChan($chan,$false),Remove this channel from,Add this channel to) filtering: DLF.Chan.AddRemove
  ..$iif(%DLF.netchans == $hashtag, $style(3)) Set filtering to all channels: {
    DLF.Chan.Set $hashtag
    DLF.StatusAll $c(6,Channels set to $c(4,$hashtag))
  }
  ..-
  ..$iif(%DLF.showfiltered,Hide,Show) filter window(s): DLF.Options.ToggleShowFilter
  ..Options: DLF.Options.Show
}

; ============================== Event catching ==============================

; ========= Always events ==========
ctcp ^*:FINGER*:#: { DLF.ctcpBlock.Chan $1- }
ctcp ^*:TIME*:#: { DLF.ctcpBlock.Chan $1- }
ctcp ^*:PING*:#: { DLF.ctcpBlock.Chan $1- }
ctcp ^*:VERSION*:#: {
  if (($nick isop $chan) && ($DLF.Chan.IsDlfChan($chan))) DLF.ctcpVersion.Reply $chan
  else DLF.ctcpBlock.Chan $1-
}

alias -l DLF.ctcpBlock.Chan {
  if ($nick isop $chan) return
  DLF.Win.Echo Blocked $chan $nick Channel ctcp $1 from $nick
  if ($DLF.Chan.IsDlfChan($chan)) {
    DLF.Stats.Count $chan Total
    DLF.Win.Log Filter ctcp $chan $nick $1-
  }
  DLF.Halt Channel $1-2 blocked
}

ctcp ^*:FINGER*:?: { DLF.ctcpBlock.Priv $1- }
ctcp ^*:TIME*:?: { DLF.ctcpBlock.Priv $1- }
ctcp ^*:PING*:?: { DLF.ctcpBlock.Priv $1- }
ctcp ^*:VERSION*:?: { DLF.ctcpBlock.Priv $1- }

alias -l DLF.ctcpBlock.Priv {
  DLF.Win.Log Filter ctcp Private $nick $1-
  var %comchan = $comchan($nick,0)
  ; Block finger requests
  if (($1 == FINGER) && (%DLF.nofingers == 1)) {
    while (%comchan) {
      DLF.Win.Echo Blocked $comchan($nick,%i) $nick ctcp finger
      dec %comchan
    }
    DLF.Status Blocked: ctcp finger from $nick
    DLF.Halt Halted: ctcp finger blocked
  }
  ; dlFilter ctcp response only to people who are in a common channel or in chat
  if (($query($nick)) || ($chat($nick,0) || (%comchan > 0)) {
    if ($1 == VERSION) DLF.ctcpVersion.Reply Private
    return
  }
  DLF.Watch.Log Blocked: ctcp $1 from $nick with no common dlF channel or chat
  DLF.Win.Filter $1-
}

alias -l DLF.ctcpVersion.Reply {
  var %msg = $nick VERSION $c(1,9,$DLF.logo Version $DLF.SetVersion by DukeLupus & Sophist.) $+ $c(1,15,$space $+ Get it from $c(12,15,$u(https://github.com/SanderSade/dlFilter/releases)))
  .ctcpreply %msg
  DLF.Win.Log Filter ctcpsend $1 $nick %msg
}

on *:close:@#*: { DLF.oNotice.Close $target }

#dlf_events off

; Channel user activity
; join, part, quit, nick changes, kick
on me:*:join:#: {
  DLF.@find.ColourLines 3
  if ($DLF.Chan.IsDlfChan($chan)) {
    DLF.Ads.ColourLines 3
    DLF.Update.Announce
  }
}

on ^*:join:#: {
  DLF.@find.ColourLines 3
  if ($DLF.Chan.IsChanEvent) {
    DLF.Ads.ColourLines 3
    DLF.DccSend.Rejoin
    ; Wait for 1 sec for user's modes to be applied to avoid checking ops
    if ((%DLF.ops.advertpriv) && ($me isop $chan)) .timer 1 1 .signal DLF.Ops.RequestVersion $nick
    if (%DLF.filter.joins) DLF.User.Channel $chan $iif($shortjoinsparts,Joins:) $nick $br($address) $iif(!$shortjoinsparts,has joined $chan)
  }
}

on me:*:part:#: {
  DLF.@find.ColourLines 15
  if ($DLF.Chan.IsDlfChan($chan)) DLF.Ads.ColourLines 14
}

on ^*:part:#: {
  DLF.@find.ColourLines 15
  if ($DLF.Chan.IsChanEvent) {
    DLF.Ads.ColourLines 15
    if (%DLF.filter.parts) DLF.User.Channel $chan $iif($shortjoinsparts,Parts:) $nick $br($address) $iif(!$shortjoinsparts,has left $chan) $iif($1-,$br($1-))
  }
}

on ^*:kick:#: {
  DLF.@find.ColourLines 14
  if ($DLF.Chan.IsChanEvent) {
    DLF.Ads.ColourLines 14
    if (%DLF.filter.kicks == 1) DLF.User.Channel $chan $knick $iif(!$shortjoinsparts,$br($address($knick,5))) was kicked $iif(!$shortjoinsparts,from $chan ) by $nick $br($1-)
  }
}

on ^*:nick: {
  DLF.Ads.NickChg
  if ($DLF.Chan.IsUserEvent(%DLF.filter.nicks)) DLF.User.NoChannel $newnick $nick $iif(!$shortjoinsparts,$br($address($knick,5))) is now known as $newnick
}

on me:*:quit: {
  DLF.@find.ColourLines 15
  DLF.Ads.ColourLines 14
}

on *:disconnect: {
  DLF.@find.ColourLines 15
  DLF.Ads.ColourLines 14
  DLF.Raw005.Reset
}

on ^*:quit: {
  DLF.@find.ColourLines 14
  if ($DLF.Chan.IsUserEvent) {
    DLF.Ads.ColourLines 14
    if (%DLF.filter.quits) DLF.User.NoChannel $nick $iif($shortjoinsparts,Quits:) $nick $br($address) $iif(!$shortjoinsparts,Quit) $br($1-)
  }
}

; User mode changes
; ban, unban, op, deop, voice, devoice etc.
on ^*:ban:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$bnick)) DLF.Chan.Mode $1- }
on ^*:unban:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$bnick)) DLF.Chan.Mode $1- }
on ^*:op:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$opnick)) DLF.Chan.Mode $1- }
on ^*:deop:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$opnick)) DLF.Chan.Mode $1- }
on ^*:voice:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$vnick)) DLF.Chan.Mode $1- }
on ^*:devoice:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$vnick)) DLF.Chan.Mode $1- }
on ^*:serverop:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$opnick)) DLF.Chan.Mode $1- }
on ^*:serverdeop:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$opnick)) DLF.Chan.Mode $1- }
on ^*:servervoice:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$vnick)) DLF.Chan.Mode $1- }
on ^*:serverdevoice:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modesuser,$vnick)) DLF.Chan.Mode $1- }
on ^*:mode:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modeschan)) DLF.Chan.Mode $1- }
on ^*:servermode:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.modeschan)) DLF.Chan.Mode $1- }
on ^*:topic:%DLF.channels: { if ($DLF.Chan.IsChanEvent(%DLF.filter.topic)) DLF.Win.Filter $nick changes topic to: $sqt($1-) }
raw 332:*: { if (($DLF.Chan.IsDlfChan($2)) && (%DLF.filter.topic == 1)) DLF.Win.Filter Topic is: $sqt($1-) }
raw 333:*: { if (($DLF.Chan.IsDlfChan($2)) && (%DLF.filter.topic == 1)) DLF.Win.Filter Set by $1 on $asctime($3,ddd mmm dd HH:nn:ss yyyy) }

; Trigger processing
on *:input:%DLF.channels: {
  if ($DLF.Chan.IsDlfChan($chan)) {
    if (($1 == @find) || ($1 == @locator)) DLF.@find.Request $1-
    elseif (($left($1,1) isin !@) && ($len($1) > 1)) DLF.DccSend.Request $1-
  }
}

on *:filercvd:*: DLF.DccSend.FileRcvd $1-
on *:getfail:*: DLF.DccSend.GetFailed $1-

; Channel messages
on ^*:text:*:%DLF.channels: { if ($DLF.Chan.IsChanEvent) DLF.Chan.Text $1- }
on ^*:action:*:%DLF.channels: { if ($DLF.Chan.IsChanEvent) DLF.Chan.Action $1- }
on ^*:notice:*:%DLF.channels: { if ($DLF.Chan.IsChanEvent) DLF.Chan.Notice $1- }
on ^@*:notice:*:#: { if ($DLF.oNotice.IsoNotice) DLF.oNotice.Channel $1- }
on *:input:@#* { DLF.oNotice.Input $1- }

; Private messages
on ^*:text:*$decode*:?: { DLF.Priv.DollarDecode $1- }
on ^*:notice:*$decode*:?: { DLF.Priv.DollarDecode $1- }
on ^*:action:*$decode*:?: { DLF.Priv.DollarDecode $1- }
on ^*:open:?:*$decode*: { DLF.Priv.DollarDecode $1- }

on ^*:text:*:?: { DLF.Priv.Text $1- }
on ^*:notice:DCC CHAT *:?: { DLF.DccChat.ChatNotice $1- }
on ^*:notice:DCC SEND *:?: { DLF.DccSend.SendNotice $1- }
on ^*:notice:*:?: { DLF.Priv.Notice $1- }
on ^*:action:*:?: { DLF.Priv.Action $1- }
on ^*:open:?:*: { DLF.Priv.Text $1- }

; ctcp
ctcp *:PING *:%DLF.channels: { if ($DLF.Chan.IsChanEvent) DLF.Halt Halted: ping in dlF channel }
ctcp *:DCC CHAT*:?: { DLF.DccChat.Chat $1- }
ctcp *:DCC SEND*:?: { DLF.DccSend.Send $1- }
ctcp *:*:?: { DLF.Priv.ctcp $1- }
ctcp *:*:%DLF.channels: { if ($DLF.Chan.IsChanEvent) DLF.Chan.ctcp $1- }
on *:ctcpreply:VERSION *: {
  if (%DLF.ops.advertpriv) DLF.Ops.VersionReply $1-
  else DLF.Priv.ctcpReply $1-
}
on *:ctcpreply:*: { DLF.Priv.ctcpReply $1- }
; We should not need to handle the open event because unwanted dcc chat requests have been halted.
;on ^*:open:=: { DLF.DccChat.Open $1- }

; RPL_ISUPPORT 005 CNOTICE / CPRIVMSG to avoid 439 Target change too frequently message
raw 005:*: { DLF.Raw005.Check $1- }

; Filter away messages
raw 301:*: { DLF.Away.Filter $1- }

; Show Unknown Command messages in active window (rather than hidden in status)
raw 421:*: {
  echo -a $2-
  halt
}

; Adjust titlebar on window change
on *:active:*: { DLF.Stats.Active }
on *:connect: { DLF.Update.Check }

#dlf_events end

; Following is just in case groups get reset to default...
; Primarily for developers when e.g. script is reloaded on change by authors autoreload script
#dlf_bootstrap on
on *:text:*:*: { DLF.Groups.Bootstrap }
alias -l DLF.Groups.Bootstrap {
  if (%DLF.enabled != $null) DLF.Groups.Events
  .disable #dlf_bootstrap
}
#dlf_bootstrap end

alias -l DLF.Groups.Events {
  DLF.Stats.Titlebar
  if (%DLF.enabled) .enable #dlf_events
  else .disable #dlf_events
}

; ========== Event processing code ==========
; Channel user activity
; join, part, kick
alias -l DLF.User.Channel {
  DLF.Watch.Called DLF.User.Channel
  if ($nick == $me) return
  DLF.Win.Log Filter $event $1 $nick $2-
  halt
}

; Non-channel user activity
; nick changes, quit
alias -l DLF.User.NoChannel {
  DLF.Watch.Called DLF.User.NoChannel
  var %dlfchan = $false
  if (%DLF.netchans != $hashtag) {
    var %i = $comchan($1,0)
    while (%i) {
      var %chan = $comchan($1,%i)
      if (($nick == $me) || ($DLF.Chan.IsDlfChan(%chan) == $false)) echo -tc $event %chan $star $2-
      else {
        DLF.Stats.Count %chan Total
        %dlfchan = $true
      }
      dec %i
    }
  }
  if (%dlfchan) DLF.Win.Log Filter $event $hashtag $nick $2-
  else DLF.Watch.Log Echoed to non-DLF channels
  halt
}

; Channel & User mode changes
; ban, unban, op, deop, voice, devoice etc.
; ban unban voice devoice etc.
alias -l DLF.Chan.Mode {
  DLF.Watch.Called DLF.Chan.Mode
  if ($nick == $me) return
  DLF.Win.Log Filter Mode $chan $nick $nick sets mode: $1-
  halt
}

; ===== Channel messages =====
alias -l DLF.Chan.AddRemove {
  if (!$DLF.Chan.IsDlfChan($chan,$false)) DLF.Chan.Add $chan $network
  else DLF.Chan.Remove $chan $network
  if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 6 1 %DLF.netchans
  DLF.StatusAll $c(6,Channels set to $c(4,%DLF.netchans))
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
  var %r = /[^,#]+(?=#[^,#]*)/gF
  %DLF.channels = $regsubex(%DLF.netchans,%r,$null)
  %DLF.channels = $uniquetok(%DLF.channels,$asc($comma))
}

; Check if channel is set whether it is network#channel or just #channel
alias -l DLF.Chan.IsChanEvent {
  if ($DLF.Chan.IsDlfChan($chan) == $false) return $false
  if ($nick == $me) return $false
  if ($2 == $me) return $false
  DLF.Stats.Count $chan Total
  if ($1 == 0) return $false
  return $true
}

alias -l DLF.Chan.IsDlfChan {
  if (($2 != $false) && (%DLF.netchans == $hashtag)) return $true
  if ($istok(%DLF.netchans,$1,$asc($comma))) return $true
  if ($istok(%DLF.netchans,$+($network,$1),$asc($comma))) return $true
  return $false
}

; Check whether non-channel event (quit or nickname) is from a network where we are in a defined channel
alias -l DLF.Chan.IsUserEvent {
  if ($1 == 0) return $false
  if (%DLF.netchans == $hashtag) return $true
  var %i = $len($chantypes), %ln = - $+ $len($network)
  while (%i) {
    var %match = $+($network,$mid($chantypes,%i,1),*)
    var %j = $wildtok(%DLF.netchans,%match,0,$asc($comma))
    while (%j) {
      var %chan = $right($wildtok(%DLF.netchans,%match,%j,$asc($comma)),%ln)
      if ($me ison %chan) return $true
      dec %j
    }
    dec %i
  }
  return $false
}

alias -l DLF.Chan.Text {
  DLF.Watch.Called DLF.Chan.Text
  ; Remove leading and double spaces
  tokenize $asc($space) $replace($1-,$nbsp,$space)
  var %txt = $strip($1-)
  if ($hiswm(chantext.dlf,%txt)) {
    ; Someone else is sending channel ads - reset timer to prevent multiple ops flooding the channel
    set $+(-eu,$calc(%DLF.ops.advertchan.period * 60)) [ [ $+(%,DLF.opsnochanads.,$network,$chan) ] ] 1
    DLF.Win.Ads $1-
  }
  if (($me isop $chan) && (%DLF.ops.advertpriv == 1) && (@find * iswm %txt)) DLF.Ops.Advert@find $1-
  elseif (($me isop $chan) && (%DLF.ops.advertpriv == 1) && ($left(%txt,1) == @) $&
    && ($left(%txt,7) == @search)) DLF.Ops.Advert@search $1-
  elseif (($me isop $chan) && (%DLF.ops.advertpriv == 1) && ($left(%txt,1) == @) $&
    && ($numtok(%txt,$asc($space)) == 1) && ($right($gettok(%txt,1,$asc(-)),-1) ison $chan)) DLF.Ops.Advert@search $1-

  DLF.Custom.Filter $1-
  if ($hiswm(chantext.always,%txt)) DLF.Win.Filter $1-
  if ((%DLF.filter.ads == 1) && ($hiswm(chantext.ads,%txt))) DLF.Win.Ads $1-
  if ((%DLF.filter.ads == 1) && ($hiswm(chantext.announce,%txt))) DLF.Win.Filter $1-
  /*if (%DLF.filter.spamchan == 1) {
    ;no channel spam right now
  }
  */
  if ((%DLF.filter.requests == 1) && ($DLF.Chan.IsCmd(%txt))) DLF.Win.Filter $1-
  DLF.Chan.ControlCodes $1-
  DLF.Chan.NonAlpha $1-
}

alias -l DLF.Chan.Action {
  DLF.Watch.Called DLF.Chan.Action
  DLF.Custom.Filter $1-
  var %action = $strip($1-)
  if ((%DLF.filter.ads == 1) && ($hiswm(chanaction.spam,%action))) DLF.Win.Filter $1-
  if ((%DLF.filter.aways == 1) && ($hiswm(chanaction.away,%action))) DLF.Win.Filter $1-
  DLF.Chan.ControlCodes $1-
  DLF.Chan.NonAlpha $1-
}

alias -l DLF.Chan.Notice {
  DLF.Watch.Called DLF.Chan.Notice
  DLF.Custom.Filter $1-
  if ((%DLF.filter.spamchan == 1) && ($hiswm(channotice.spam,$strip($1-)))) DLF.Chan.SpamFilter $1-
}

alias -l DLF.Chan.ctcp {
  DLF.Watch.Called DLF.Chan.ctcp
  DLF.Custom.Filter $1-
  if ($hiswm(chanctcp.spam,$1-)) DLF.Win.Filter $1-
  if ($hiswm(chanctcp.server,$1-)) DLF.Win.Server $1-
}

alias -l DLF.Chan.IsCmd {
  tokenize $asc($space) $1-
  if ($0 == 0) return $true
  if ($hiswm(chantext.cmds,$1-)) return $true
  ; Filter a common mistype adding a word preceding the command
  if ($hiswm(chantext.cmds,$2-)) return $true
  ; Handle mistyped !nick, @search or @nick with incorrect/without trigger character
  var %fn = $DLF.GetFileName($2-)
  if (%fn) {
    ; Missed ! on file get
    if ($1 ison $chan) return $true
    ; Mistyped !  on file get
    if ($right($1,-1) ison $chan) return $true
  }
  elseif ($0 == 1) {
    ; Missed @ on server list
    if ($1 ison $chan) return $true
    ; Mistyped @ on server list
    if ($right($1,-1) ison $chan) return $true
  }
  else {
    ; Missed @ on search
    if (($left($1,6) == search) && ($1 ison $chan)) return $true
    ; Mistyped @ with search
    if (($mid($1,2,6) == search) && ($right($1,-1) ison $chan)) return $true
  }
  return $false
}

alias -l DLF.Chan.ControlCodes {
  if ((%DLF.filter.controlcodes == 1) && ($strip($1-) != $1-)) {
    DLF.Watch.Log Filtered: Contains control codes
    DLF.Win.Filter $1-
  }
}

alias -l DLF.Chan.NonAlpha {
  if ((%DLF.filter.nonalpha == 1) && ($upper($1-) === $lower($1-))) {
    DLF.Watch.Log Filtered: Non-alphabetic line
    DLF.Win.Filter $1-
  }
}

alias -l DLF.Chan.SetNickColour {
  if (%DLF.colornicks == 1) {
    var %chans
    if ($left(%chans,1) isin $chantypes) %chans = $chan
    else {
      var %i = $comchan($nick,0)
      while (%i) {
        %chans = %chans $comchan($nick,%i)
        dec %i
      }
    }
    var %i = $numtok(%chans,$asc($space))
    while (%i) {
      var %chan = $gettok(%chans,%i,$asc($space))
      dec %i
      var %pnick = $nick(%chan,$nick).pnick
      var %cnick = $cnick(%pnick,1)
      var %nickrule = $true
      if ((%cnick == 0) || ($enablenickcolors == $false)) var %colour = $color(Listbox)
      elseif ($cnick(%cnick).method == 1) var %colour = $color(Listbox)
      else {
        var %colour = $cnick(%cnick,1).color
        ; There is no way to check whether a colour rule is for a specific nick
        ; so we assume that it is not for a specific nick if there is another setting which we can check
        %nickrule = $false
        %nickrule = $iif($cnick(%cnick).modes != $null,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).levels != $null,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).anymode,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).nomode,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).ignore,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).op,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).voice,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).protect,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).notify,$true,%nickrule)
        %nickrule = $iif($cnick(%cnick).idle,$true,%nickrule)
      }
      if ((%nickrule) && ($nick(%chan,$nick).color == %colour)) cline 4 %chan $nick
    }
  }
}

alias -l DLF.Chan.GetMsgNick {
  if ($1 == Private) return $2
  var %pnick = $DLF.Chan.pNick($1,$2)
  var %cnick = $cnick(%pnick)
  if ((%cnick == 0) || ($enablenickcolors == $false)) var %colour = $color(Listbox)
  elseif ($cnick(%cnick).method == 2) var %colour = $color(Listbox)
  else var %colour = $cnick(%cnick).color
  if (%colour == 0) %colour = 1
  var %nick = $iif(($showmodeprefix) && ($left($1,1) isin $chantypes),%pnick,$2)
  if (%colour != $null) %nick = $c(%colour,%nick)
  return %nick
}

alias -l DLF.Chan.pNick return $nick($1,$2).pnick

alias -l DLF.Chan.EditSend {
  ; Done with timers to allow messages to be sent before doing the next one.
  var %delta = 1
  var %t = $+(DLF.editsend.,$network,$1)
  if ($timer(%t)) {
    var %secs = $timer(%t).secs
    var %existing = $gettok($timer(%t).com,3-,$asc($space))
  }
  else {
    var %secs = 0
    var %existing = $editbox($1)
  }
  .timer 1 %secs editbox -n $1-
  inc %secs %delta
  [ $+(.timer,%t) ] 1 %secs editbox $1 %existing
}

; ===== Titlebar Name & Stats =====
alias -l DLF.Stats.Count { if (($1 != Private) && ($1 != $hashtag)) hinc -m DLF.stats $+($network,$1,|,$2) }
alias -l DLF.Stats.Get { return $hget(DLF.stats,$+($network,$1,|,$2)) }
alias -l DLF.Stats.TitleText { return $+(dlFilter efficiency:,$space,$1,%) }

alias -l DLF.Stats.Active {
  ; titlebar = window -=- existing text -=- dlF stats
  ; so window name appears in taskbar button
  var %total = $DLF.Stats.Get($active,Total)
  var %filter = $DLF.Stats.Get($active,Filter)
  if (($DLF.Chan.IsDlfChan($active)) && (%total != $null) && (%filter != $null)) {
    var %percent = $calc(%filter / %total * 100)
    if (%percent < 99) %percent = $round(%percent,1)
    elseif ((%percent < 100) && ($regex(DLF.Stats.Display,%percent,/([0-9]*\.9*[0-8])/) > 0)) %percent = $regml(DLF.Stats.Display,1)
    DLF.Stats.Titlebar $active $DLF.Stats.TitleText(%percent)
  }
  else DLF.Stats.Titlebar
}

alias -l DLF.Stats.Titlebar {
  var %tb = $titlebar
  var %re = $+(/(-=-\s+)?(#\S*\s+)?,$replace($DLF.Stats.TitleText([0-9.]+),$space,\s+),/F)
  ; Can't use $1- directly in $regsubex because it uses these internally
  var %txt = $1-
  if ($regex(DLF.Stats.Titlebar,%tb,%re) > 0) %tb = $regsubex(DLF.Stats.Titlebar,%tb,%re,$null)
  if (%DLF.titlebar.stats == 1) %tb = %tb -=- %txt
  while ($gettok(%tb,1,$asc($space)) == -=-) %tb = $deltok(%tb,1,$asc($space))
  while ($gettok(%tb,-1,$asc($space)) == -=-) %tb = $deltok(%tb,-1,$asc($space))
  titlebar %tb
}

; ===== Private messages =====
alias -l DLF.Priv.Text {
  DLF.Watch.Called DLF.Priv.Text
  DLF.@find.Response $1-
  DLF.Priv.Request $1-
  DLF.Priv.QueryOpen $1-
  DLF.Custom.Filter $1-
  DLF.Priv.CommonChan $1-
  DLF.Priv.RegularUser Normal $1-
  var %txt = $strip($1-)
  if ((%DLF.filter.spampriv == 1) && ($hiswm(privtext.spam,%txt)) && (!$window($1))) DLF.Priv.SpamFilter $1-
  if ($hiswm(privtext.server,%txt)) DLF.Win.Server $1-
  if ((%DLF.filter.aways == 1) && ($hiswm(privtext.away,%txt))) DLF.Win.Filter $1-
  DLF.Priv.OpsUser $1-
}

alias -l DLF.Priv.Notice {
  DLF.Watch.Called DLF.Priv.Notice
  DLF.Priv.NoticeChanserv $1-
  DLF.Priv.QueryOpen $1-
  DLF.@find.Response $1-
  if ($DLF.DccSend.IsTrigger) DLF.Win.Server $1-
  DLF.Custom.Filter $1-
  DLF.Priv.QueryOpen $1-
  var %txt = $strip($1-)
  if ($hiswm(privnotice.dnd,%txt)) DLF.Win.Filter $1-
  if ($hiswm(privnotice.server,%txt)) DLF.Win.Server $1-
  DLF.Priv.CommonChan $1-
  DLF.Priv.RegularUser Notice $1-
}

alias -l DLF.Priv.NoticeChanserv {
  if ($nick != ChanServ) return
  if (($left($1,2) != [#) || ($right($1,1) != ])) return
  var %chan = $left($right($1,-1),-1)
  DLF.Win.Echo Notice %chan $nick $1-
  halt
}

alias -l DLF.Priv.Action {
  DLF.Watch.Called DLF.Priv.Action
  DLF.Priv.QueryOpen $1-
  DLF.Custom.Filter $1-
  DLF.Priv.CommonChan $1-
  DLF.Priv.RegularUser Action $1-
}

alias -l DLF.Priv.Request {
  if (%DLF.private.requests == 1) {
    if ($nick === $me) return
    var %trigger = $strip($1)
    var %nicklist = @ $+ $me
    var %nickfile = ! $+ $me
    if ((%nicklist == %trigger) || (%nickfile == %trigger) || (%nickfile == $gettok($strip($1),1,$asc(-)))) {
      .msg $nick Please $u(do not make requests in private) $+ . All commands need to go to $u(channel).
      .msg $nick You may have to go to $c(2,mIRC options -> Sounds -> Requests) and uncheck $qt($c(3,Send '!nick file' as private message))
      if (($window($nick)) && ($line($nick,0) != 0)) .window -c $nick
      DLF.Win.Filter Blocked: $1-
    }
  }
}

alias -l DLF.Priv.SpamFilter {
  if (%DLF.opwarning.spampriv == 0) return
  var %i = $comchan($nick,0)
  if (%DLF.spam.addignore == 1) [ $+(.timerDLFSpamIgnore,$DLF.TimerAddress) ] 1 0 .signal DLF.Priv.SpamIgnore $nick $1-
  DLF.Win.Log Filter Blocked Private $nick Spam from user $iif(%i,in common channel(s):,not in common channel:) $c(4,15,$tag($nick) $br($address($nick,5)) -> $b($1-))
  DLF.Win.Filter $1-
}

on *:signal:DLF.Priv.SpamIgnore: { DLF.Priv.SpamIgnore $1- }
alias -l DLF.Priv.SpamIgnore {
  var %addr = $address($1,6)
  var %who = $1
  if (%addr) var %who = %who $br(%addr)
  else %addr = %who
  var %ignore = $input($&
    $+(Spam received from ,%who,.,$crlf,$crlf,Spam: $qt($2-),.,$crlf,$crlf,Add this user to ignore for one hour?),$&
    yq,Add spammer to /ignore?)
  if (%ignore == $true) {
    .ignore on
    ignore -u3600 %addr $network
  }
}

alias -l DLF.Priv.CommonChan {
  if (%DLF.private.nocomchan != 1) return
  if ($DLF.IsRegularUser($nick) == $false) return
  if ($comchan($nick,0) == 0) {
    DLF.Watch.Log Blocked: Private $event from regular user
    DLF.Status Blocked: Private $event from $nick with no common channel
    DLF.Win.Log Filter Blocked Private $nick Private $event from user with no common channel:
    DLF.Win.Filter $1-
  }
}

alias -l DLF.Priv.QueryOpen {
  if ((%DLF.private.query == 1) && ($query($nick)) && ($event != open)) {
    DLF.Win.Echo $event $nick $nick $1-
    DLF.Halt Echoed to query window
  }
}

alias -l DLF.Priv.DollarDecode {
  DLF.Win.Echo Warning Private $nick Messages containing $b($ $+ decode) are often malicious mIRC virus trying to infect your mIRC, and $nick is likely already infected with it. Please report this to the channel ops.
  DLF.Win.Echo Warning Private $nick $1-
  DLF.Halt Halted: Probable mIRC worm infection attempt.
}

alias -l DLF.Priv.ctcp {
  DLF.Watch.Called DLF.Priv.ctcp
  DLF.Custom.Filter $1-
  DLF.Priv.QueryOpen $1-
  DLF.Priv.CommonChan $1-
  DLF.Priv.RegularUser ctcp $1-
}

alias -l DLF.Priv.ctcpReply {
  DLF.Watch.Called DLF.Priv.ctcpReply
  if ($1 == VERSION) {
    DLF.Win.Echo $event Private $nick $1-
    DLF.Halt Echoed
  }
  if ($hiswm(ctcp.reply,$1-)) DLF.Win.Filter $1-
  DLF.Priv.QueryOpen $1-
  DLF.Priv.CommonChan $1-
  DLF.Priv.RegularUser ctcpreply $1-
}

alias -l DLF.Priv.RegularUser {
  if ($DLF.IsRegularUser($nick)) {
    if (%DLF.private.regular == 1) {
      var %type = $lower($replace($1,-,$space))
      if (%type == normal) %type = message
      DLF.Watch.Log Blocked: Private %type from regular user
      DLF.Status Blocked: Private %type from regular user $nick $br($address)
      DLF.Win.Log Filter Blocked Private $nick Private %type from regular user $nick $br($address) $+ :
      DLF.Win.Filter $2-
    }
  }
  else {
    DLF.Win.Echo $event Private $nick $2-
    halt
  }
}

; ===== away responses =====
alias -l DLF.Away.Filter {
  DLF.Watch.Called DLF.Away.Filter
  if (%DLF.filter.aways == 1) DLF.Win.Filter $3-
}

; ========== Ops advertising ==========
alias -l DLF.Ops.AdvertsEnable {
  if (%DLF.ops.advertchan == 1) .timerDLF.Adverts -o 0 300 .signal DLF.Ops.AdvertChan
  else .timerDLF.Adverts off
}

alias -l DLF.Ops.Advert@search {
}

alias -l DLF.Ops.Advert@find {
  var %idx = $+($network,@,$nick)
  if (!$hfind(DLF.ops.verRequested,%idx)) DLF.Ops.RequestVersion $nick
  elseif ((!$hfind(DLF.ops.advert@find,%idx)) $&
    && ($hfind(DLF.ops.mirc@find,%idx)) $&
    && (!$hfind(DLF.ops.dlfVersion,%idx))) {
    hadd -mz DLF.ops.advert@find %idx $DLF.RequestPeriod
    %msg = $c(1,9,$DLF.logo Make @find easier to use by installing the dlFilter mIRC script which collects the results together into a single window. Download it from $u($c(2,https://github.com/SanderSade/dlFilter/releases)) $+ .)
    DLF.notice $nick %msg
    DLF.Win.Log Filter notice $chan $nick %msg
  }
}

on *:signal:DLF.Ops.AdvertChan: { DLF.Ops.AdvertChan $1- }
alias -l DLF.Ops.AdvertChan {
  var %cid = $cid
  var %i = $scon(0)
  while (%i) {
    scid $scon(%i)
    var %j = $chan(0)
    while (%j) {
      var %c = $chan(%j)
      ; skip advertising if another user has advertised in the channel
      if ([ [ $+(%,DLF.opsnochanads.,$network,$chan) ] ] != $null) {
        unset [ $+(%,DLF.opsnochanads.,$network,$chan) ]
        continue
      }
      if ((($istok(%DLF.netchans,$+($network,%c),$asc($space))) || ($istok(%DLF.netchans,%c,$asc($space)))) $&
        && ($me isop %c)) {
        var %msg = $c(1,9,$DLF.logo Are the responses to your requests getting lost in the crowd? Are your @find responses spread about? If you are using mIRC as your IRC client, then download dlFilter from $u($c(2,https://github.com/SanderSade/dlFilter/releases)) and make your time in %c less stressful.)
        DLF.msg %c %msg
        DLF.Win.Log Filter text %c $me %msg
      }
      dec %j
    }
    dec %i
  }
}

on *:signal:DLF.Ops.RequestVersion: { DLF.Ops.RequestVersion $1- }
alias -l DLF.Ops.RequestVersion {
  if ($1 == $me) return
  if ($DLF.IsRegularUser($1) == $false) return
  DLF.Watch.Called DLF.Ops.RequestVersion
  if (%DLF.ops.advertpriv == 0) return
  var %idx = $+($network,@,$1)
  if ($hfind(DLF.ops.verRequested,%idx)) DLF.Watch.Log dlF status already checked
  elseif ($hfind(DLF.ops.mircUsers,%idx)) DLF.Watch.log SPOOKY: mircUsers without verRequested
  elseif ($hfind(DLF.ops.dlfUsers,%idx)) DLF.Watch.log SPOOKY: dlfUsers without verRequested
  elseif ($hfind(DLF.ops.sbcUsers,%idx)) DLF.Watch.log SPOOKY: sbcUsers without verRequested
  else {
    hadd -mz DLF.ops.verRequested %idx $DLF.RequestPeriod
    DLF.ctcp $1 VERSION
    DLF.Win.Log Filter ctcpsend Private $1 VERSION
  }
}

alias -l DLF.Ops.VersionReply {
  DLF.Watch.Called DLF.Ops.VersionReply
  var %idx = $+($network,@,$nick)
  var %re = /(?:^|\s)(?:v|ver|version)\s*([0-9.]+)(?:\s|$)/F
  var %mod = $strip($2)
  var %regex = $regex(DLF.Ops.VersionReply,$3-,%re)
  if (%regex > 0) var %ver = $regml(DLF.Ops.VersionReply,1)
  else var %ver = ?
  if ((%mod == $strip($DLF.Logo)) && (%ver isnum)) {
    if (!$hfind(DLF.ops.dlfUsers,%idx)) {
      hadd -mu86340 DLF.ops.dlfUsers %idx %ver
      DLF.Watch.Log dlf version added
    }
    else DLF.Watch.Log dlf version already known
  }
  elseif ((%mod == sbClient) && (%ver isnum)) {
    if (!$hfind(DLF.ops.sbcUsers,%idx)) {
      hadd -mu86340 DLF.ops.sbcUsers %idx %ver
      DLF.Watch.Log sbc version added
    }
    else DLF.Watch.Log sbc version already known
  }
  elseif (%mod == mIRC) {
    if (!$hfind(DLF.ops.mircUsers,%idx)) {
      hadd -mu86340 DLF.ops.mircUsers %idx %ver
      ; Wait 1s for advertising to allow for any more version messages
      .timer 1 1 .signal DLF.Ops.AdvertPrivDLF $nick
      DLF.Watch.Log mirc version added
    }
    else DLF.Watch.Log mirc version already known
  }
  DLF.Win.Filter $1-
}

on *:signal:DLF.Ops.AdvertPrivDLF: { DLF.Ops.AdvertPrivDLF $1- }
alias -l DLF.Ops.AdvertPrivDLF {
  DLF.Watch.Called DLF.Ops.AdvertPrivDLF
  var %idx = $+($network,@,$1)
  if ($hfind(DLF.ops.privateAd,%idx)) return
  hadd -mu86340 DLF.ops.privateAd %idx $ctime
  var %mircVer = $hget(DLF.ops.mircUsers,%idx)
  var %dlfVer = $hget(DLF.ops.dlfUsers,%idx)
  var %sbcVer = $hget(DLF.ops.sbcUsers,%idx)
  var %msg
  if (%mircVer != $null) {
    if (%mircVer >= %DLF.version.web.mirc) var %mircupgr = $null
    else var %mircupgr = You will need to upgrade to mIRC version %DLF.version.web.mirc or higher to use it.
    var %dl = from $u($c(2,https://github.com/SanderSade/dlFilter/releases)) $+ .
    if (%dlfVer == $null) {
      ; mIRC but no dlF
      %msg = I see you are running mIRC. Have you considered running the dlFilter script to hide everyone else's searches and file requests, and improve your @file requests? %mircupgr You can download dlFilter %dl
      DLf.Watch.Log Advertised dlF via notice.
    }
    elseif (%dlfVer < %DLF.version.web) {
      if (%dlfVer < 1.17) var %downmeth = which you can download %dl
      else var %downmeth = by clicking on the Update button in the dlFilter Options dialog.
      %msg = I see you are running dlFilter. This notice is to let you know that a newer version is available %downmeth %mircupgr
      DLF.Watch.Log Advertised dlF upgrade via notice.
    }
    if (%msg) {
      %msg = $c(1,9,$DLF.logo %msg)
      DLF.notice $1 %msg
      DLF.Win.Log Filter notice Private $1 %msg
    }
    if (($false) && (%sbcVer == $null) && ($nopath($script(1) != sbclient.mrc)) {
      DLF.Watch.Log Advertised sbc via notice.
      if (%msg == $null) %msg = I see you are running mIRC. Have you considered
      else %msg = You may also want to consider
      %msg = %msg running the sbClient script to make processing @search and server file-list results easier. You can download sbClient from $u($c(2,https://github.com/SanderSade/sbClient/releases)) $+ .
      DLF.notice $1 %msg
      DLF.Win.Log Filter notice Private $1 %msg
    }
  }
}

; ========== DCC Send ==========
alias -l DLF.DccSend.Request {
  DLF.Watch.Called DLF.DccSend.Request : $1-
  var %trig = $strip($1)
  var %fn = $replace($strip($2-),$tab $+ $space,$space,$tab,$null)
  hadd -mz DLF.dccsend.requests $+($network,|,$chan,|,%trig,|,$replace(%fn,$space,_),|,$encode(%fn)) $DLF.RequestPeriod
  DLF.Watch.Log Request recorded: %trig %fn
}

alias -l DLF.DccSend.GetRequest {
  var %fn = $replace($noqt($DLF.GetFileName($strip($1-))),$space,_)
  var %req = $hfind(DLF.dccsend.requests,$+($network,|#*|!,$nick,|,%fn,|*),1,w).item
  if (%req) return %req
  var %req = $hfind(DLF.dccsend.requests,$+($network,|#*|@,$nick,|*|*),1,w).item
  if (%req) return %req
  return $hfind(DLF.dccsend.requests,$+($network,|#*|@,$nick,-*|*|*),1,w).item
}

alias -l DLF.DccSend.IsRequest {
  var %fn = $noqt($DLF.GetFileName($strip($1-)))
  var %req = $DLF.DccSend.GetRequest(%fn)
  if (%req == $null) return $false
  var %trig = $gettok(%req,3,$asc(|))
  if (($left(%trig,1) == !) && ($right(%trig,-1) != $nick)) return $false
  if ($left(%trig,1) == @) {
    if (($right(%trig,-1) != $nick) && ($right($gettok(%trig,1,$asc(-)),-1) != $nick)) return $false
    if ($nick !isin %fn) return $false
    if ($gettok(%fn,-1,$asc(.)) !isin txt zip rar) return $false
  }
  DLF.Watch.Log File request found: %trig $1-
  return $true
}

alias -l DLF.DccSend.IsTrigger {
  var %srch = $+($network,|#*|*,$nick,|*|*)
  var %i = $hfind(DLF.dccsend.requests,%srch,0,w).item
  if (%i == 0) return $false
  while (%i) {
    var %req = $hfind(DLF.dccsend.requests,%srch,%i,w).item
    var %chan = $gettok(%req,2,$asc(|))
    var %user = $gettok($right($gettok(%req,3,$asc(|)),-1),1,$asc(-))
    if ((%user == $nick) && ($nick(%chan,$nick) != $null)) {
      DLF.Watch.Log User request found: %user
      return $true
    }
    dec %i
  }
  return $false
}

alias -l DLF.DccSend.Rejoin {
  var %i = $hget(DLF.dccsend.requests,0).item
  while (%i) {
    var %item = $hget(DLF.dccsend.requests,%i).item
    dec %i
    var %net = $gettok(%item,1,$asc(|))
    if (%net != $network) continue
    var %chan = $gettok(%item,2,$asc(|))
    if (%chan != $chan) continue
    var %trig = $gettok(%item,3,$asc(|))
    if ($right(%trig,-1) != $nick) continue
    var %fn = $decode($gettok(%item,5,$asc(|)))
    DLF.Chan.EditSend %chan %trig %fn
    DLF.Watch.Log $nick rejoined $chan: Request resent: %trig %fn
  }
}

alias -l DLF.DccSend.SendNotice {
  DLF.Watch.Called DLF.DccSend.SendNotice
  var %req = $DLF.DccSend.GetRequest($3-)
  if (%req == $null) return
  var %chan = $gettok(%req,2,$asc(|))
  DLF.Win.Log Server Notice %chan $nick $1-
  halt
}

alias -l DLF.DccSend.Send {
  DLF.Watch.Called DLF.DccSend.Send
  var %fn = $DLF.GetFilename($3-)
  if ($chr(8238) isin %fn) {
    DLF.Win.Echo Blocked Private $nick DCC Send - filename contains malicious unicode U+8238
    DLF.Halt Blocked: DCC Send - filename contains malicious unicode U+8238
  }
  var %trusted = $DLF.DccSend.IsTrusted($nick)
  if ($DLF.DccSend.IsRequest(%fn)) {
    if ((%DLF.dccsend.autoaccept == 1) && (!%trusted)) DLF.DccSend.TrustAdd
    DLF.DccSend.Receiving %fn
    DLF.Watch.Log Accepted: DCC Send - user requested this file from this server
    return
  }
  elseif (%DLF.dccsend.requested == 1) DLF.DccSend.Block the file was not requested
  if (%DLF.dccsend.dangerous == 1) {
    var %ext = $nopath($filename)
    var %ext = $right(%ext,$calc(- $pos(%ext,.,$pos(%ext,.,0))))
    var %bad = exe pif application gadget msi msp com scr hta cpl msc jar bat cmd vb vbs vbe js jse ws wsf mrc doc wsc wsh ps1 ps1xml ps2 ps2xml psc1 psc2 msh msh1 msh2 mshxml msh1xml msh2xml scf lnk inf reg doc xls ppt docm dotm xlsm xltm xlam pptm potm ppam ppsm sldm
    if ($istok(%bad,%ext,$asc($space))) DLF.DccSend.Block dangerous filetype
  }
  if ((%DLF.dccsend.nocomchan == 1) && ($comchan($nick,0) == 0)) DLF.DccSend.Block the user is not in a common channel
  if ((%DLF.dccsend.trusted == 1) && (!%trusted)) DLF.DccSend.Block the user is not in your DCC Get trust list
  if ((%DLF.dccsend.regular == 1) && ($DLF.IsRegularUser($nick)) DLF.DccSend.Block the user is a regular user
  DLF.Watch.Log DCC Send accepted
  DLF.DccSend.Receiving %fn
  return
}

alias -l DLF.DccSend.Block {
  dcc reject
  DLF.Watch.Log Blocked: dcc send from $nick - $1-
  DLF.Status Blocked: DCC Send from $nick $br($address) because $1- $+ : $filename
  DLF.Win.Log Filter Blocked Private $nick DCC Send from $nick $br($address) because $1- $+ :
  DLF.Win.Filter DCC SEND $filename
}

alias -l DLF.DccSend.Receiving {
  var %req = $DLF.DccSend.GetRequest($1-)
  if (%req == $null) return
  var %chan = $gettok(%req,2,$asc(|))
  var %origfn = $decode($gettok(%req,5,$asc(|)))
  if (%origfn == $null) %origfn = $1-
  var %secs = $calc($DLF.RequestPeriod - $hget(DLF.dccsend.requests,%req))
  DLF.Win.Log Server ctcp %chan $nick DCC Get of $qt(%origfn) from $nick starting $br(waited $duration(%secs,3))
}

alias -l DLF.DccSend.Taskbar {
  ;if ($gettok($titlebar,1-2,$asc($space)) == Get $get(-1)) titlebar $gettok($titlebar,3-,$asc($space))
}

alias -l DLF.DccSend.FileRcvd {
  DLF.DccSend.Taskbar
  var %fn = $nopath($filename)
  DLF.Watch.Called DLF.DccSend.FileRcvd: %fn
  var %req = $DLF.DccSend.GetRequest(%fn)
  if (%req == $null) return
  .hdel -s DLF.dccsend.requests %req
  var %chan = $gettok(%req,2,$asc(|))
  var %dur = $get(-1).secs
  var %trig = $gettok(%req,3,$asc(|))
  var %origfn = $decode($gettok(%req,5,$asc(|)))
  if (%origfn == $null) %origfn = %fn
  var %hash = $encode(%trig %origfn)
  if ($hget(DLF.dccsend.retries,%hash)) .hdel DLF.dccsend.retries %hash
  DLF.Win.Log Server ctcp %chan $nick DCC Get of $qt(%origfn) from $nick complete $br($duration(%dur,3) $bytes($calc($get(-1).rcvd / %dur)).suf $+ /Sec)
  ; Some servers change spaces to underscores
  ; But we cannot rename if Options / DCC / Folders / Command is set
  ; because it would run after this using the wrong filename
  if ((%origfn != $null) $&
   && (%fn != %origfn) $&
   && ($DLF.DccSend.IsNotGetCommand(%fn))) $&
    rename $filename $qt($+($noqt($nofile($filename)),%origfn))
}

; Check that there is no mIRC Options / DCC / Folders / Command for the file
alias -l DLF.DccSend.IsNotGetCommand {
  var %i = -1
  while ($true) {
    inc %i
    var %get = $DLF.mIRCini(extensions,%i)
    if (%get == $null) break
    var %p = $poscs(%get,EXTCOM:,0)
    if (%p == 0) continue
    var %p = $poscs(%get,EXTDIR:,1)
    if (%p == $null) continue
    var %match = $left(%get,$calc(%p - 1))
    var %j = $numtok(%match,$asc($comma))
    while (%j) {
      if ($gettok(%match,%j,$asc($comma)) iswm $1-) return $false
      dec %j
    }
  }
  return $true
}

alias -l DLF.DccSend.GetFailed {
  DLF.DccSend.Taskbar
  var %fn = $nopath($filename)
  DLF.Watch.Called DLF.DccSend.GetFailed : %fn
  var %req = $DLF.DccSend.GetRequest(%fn)
  if (%req == $null) return
  .hdel -s DLF.dccsend.requests %req
  var %chan = $gettok(%req,2,$asc(|))
  var %trig = $gettok(%req,3,$asc(|))
  if (%origfn == $null) %origfn = %fn
  var %hash = $encode(%trig %origfn)
  var %retry = %DLF.serverretry
  if (%retry) {
    var %attempts = $hget(DLF.dccsend.retries,%hash)
    if (%attempts == $null) {
      ; First retry
      .hadd -m DLF.dccsend.retries %hash 1
    }
    elseif (%attempts == 3) {
      .hdel DLF.dccsend.retries %hash
      %retry = $false
    }
    else {
      .hinc DLF.dccsend.retries %hash
    }
  }
  DLF.Win.Log Server ctcp %chan $nick DCC Get of %origfn from $nick incomplete $br($duration(%dur,3) $bytes($calc($get(-1).rcvd / $get(-1).secs)).suf $+ /Sec) $iif(%retry,- $c(3,retrying))
  if (%retry) DLF.Chan.EditSend %chan %trig $decode($gettok(%req,5,$asc(|)))
}

alias -l DLF.DccSend.TrustAdd {
  var %addr = $DLF.TimerAddress
  var %desc = $nick
  if (%addr != $nick) %desc = %desc $br(%addr)
  [ $+(.timer,$DLF.DccSend.TrustTimer) ] 1 10 .signal DLF.DccSend.TrustRemove %addr %desc
  .dcc trust %addr
  DLF.Watch.Log Trust: Added %desc
}

on *:signal:DLF.DccSend.TrustRemove: DLF.DccSend.TrustRemove $1-
alias -l DLF.DccSend.TrustRemove {
  .dcc trust -r $1
  DLF.Watch.Log Trust: Removed $2-
}

alias -l DLF.DccSend.TrustTimer { return DLFRemoveTrust $+ $DLF.TimerAddress }

alias -l DLF.DccSend.IsTrusted {
  if ($timer($DLF.DccSend.TrustTimer) != $null) return $false
  var %addr = $address($1,5)
  if (%addr == $null) return $false
  var %i = $trust(0)
  while (%i) {
    if ($trust(%i) iswm %addr) return $true
    dec %i
  }
  return $false
}

alias DLF.DccSend.List {
  echo -a $crlf
  echo -a dlFilter: Current file requests:
  echo -a --------------------------------
  var %i = $hget(DLF.dccsend.requests,0).item
  if (%i == 0) {
    echo -a No requests
    return
  }
  var %list
  while (%i) {
    var %secs = $hget(DLF.dccsend.requests,%i).data
    var %item = $hget(DLF.dccsend.requests,%i).item
    var %trig = $gettok(%item,3,$asc(|))
    var %file = $decode($gettok(%item,5,$asc(|)))
    %list = $addtok(%list,%secs %trig %file,$asc(|))
    dec %i
  }
  %list = $sorttok(%list,$asc(|),nr)
  %i = $numtok(%list,$asc(|))
  while (%i) {
    %item = $gettok(%list,%i,$asc(|))
    echo -a $asctime($calc($ctime - $DLF.RequestPeriod + $gettok(%item,1,$asc($space))),$timestampfmt) $gettok(%item,2-,$asc($space))
    dec %i
  }
}

alias -l DLF.DccChat.ChatNotice {
  DLF.Watch.Called DLF.DccChat.ChatNotice
  if ((%DLF.private.nocomchan == 1) && ($comchan($nick,0) == 0)) {
    DLF.Watch.Log DCC CHAT will be blocked: No common channel
    DLF.Win.Log Filter Warning Private $nick DCC Chat will be blocked because user is not in a common channel:
    DLF.Win.Filter $1-
  }
  DLF.Priv.RegularUser DCC-Chat-Notice $1-
}

alias -l DLF.DccChat.Chat {
  DLF.Watch.Called DLF.DccChat.Chat
  if ((%DLF.private.nocomchan == 1) && ($comchan($nick,0) == 0)) {
    DLF.Watch.Log Blocked: DCC CHAT from $nick - No common channel
    DLF.Status Blocked: DCC CHAT from $nick - No common channel
    DLF.Win.Log Filter Blocked Private $nick DCC Chat because user is not in a common channel:
    DLF.Win.Filter $1-
  }
  DLF.Priv.RegularUser DCC-CHAT $1-
}

; Hopefully handling a dcc chat open event is unnecessary because he have halted unwanted requests
alias -l DLF.DccChat.Open {
  DLF.Watch.Called DLF.DccChat.Open
  echo -stf DLF.DccChat.Open called: target $target nick $nick args $1-
}

; ========== Custom Filters ==========
alias -l DLF.Custom.Filter {
  var %filt = $iif($left($chan,1) isin $chantypes,chan,priv) $+ $event
  var %hash = $+(DLF.custfilt.,%filt)
  if ($hget(%hash) == $null) DLF.Custom.CreateHash $1
  if ($hfind(%hash,$1-,1,W)) {
    DLF.Watch.Log Matched in custom. $+ %filt $+ : $event
    DLF.Win.Filter $1-
  }
}

alias -l DLF.Custom.Add {
  var %type = $replace($1,$nbsp,$space)
  var %new = $regsubex($2-,$+(/[][!#$%&()/:;<=>.|,$comma,$lcurly,$rcurly,]+/g),$star)
  %new = $regsubex(%new,/[*] *[*]+/g,$star)
  if (%new == *) return
  if (%type == Channel text) DLF.Custom.Set chantext $addtok(%DLF.custom.chantext,%new,$asc($comma))
  elseif (%type == Channel action) DLF.Custom.Set chanaction $addtok(%DLF.custom.chanaction,%new,$asc($comma))
  elseif (%type == Channel notice) DLF.Custom.Set channotice $addtok(%DLF.custom.channotice,%new,$asc($comma))
  elseif (%type == Channel ctcp) DLF.Custom.Set chanctcp $addtok(%DLF.custom.chanctcp,%new,$asc($comma))
  elseif (%type == Private text) DLF.Custom.Set privtext $addtok(%DLF.custom.privtext,%new,$asc($comma))
  elseif (%type == Private action) DLF.Custom.Set privaction $addtok(%DLF.custom.privaction,%new,$asc($comma))
  elseif (%type == Private notice) DLF.Custom.Set privnotice $addtok(%DLF.custom.privnotice,%new,$asc($comma))
  elseif (%type == Private ctcp) DLF.Custom.Set privctcp $addtok(%DLF.custom.privctcp,%new,$asc($comma))
  else DLF.Error DLF.Custom.Add Invalid message type: %type
}

alias -l DLF.Custom.Remove {
  var %type = $replace($1,$nbsp,$space)
  if (%type == Channel text) DLF.Custom.Set chantext $remtok(%DLF.custom.chantext,$2-,1,$asc($comma))
  elseif (%type == Channel action) DLF.Custom.Set chanaction $remtok(%DLF.custom.chanaction,$2-,1,$asc($comma))
  elseif (%type == Channel notice) DLF.Custom.Set channotice $remtok(%DLF.custom.channotice,$2-,1,$asc($comma))
  elseif (%type == Channel ctcp) DLF.Custom.Set chanctcp $remtok(%DLF.custom.chanctcp,$2-,1,$asc($comma))
  elseif (%type == Private text) DLF.Custom.Set privtext $remtok(%DLF.custom.privtext,$2-,1,$asc($comma))
  elseif (%type == Private action) DLF.Custom.Set privaction $remtok(%DLF.custom.privaction,$2-,1,$asc($comma))
  elseif (%type == Private notice) DLF.Custom.Set privnotice $remtok(%DLF.custom.privnotice,$2-,1,$asc($comma))
  elseif (%type == Private ctcp) DLF.Custom.Set privctcp $remtok(%DLF.custom.privctcp,$2-,1,$asc($comma))
  else DLF.Error DLF.Custom.Remove Invalid message type: %type
}

alias -l DLF.Custom.Set {
  var %var = $+(%,DLF.custom.,$1)
  [ [ %var ] ] = $2-
  DLF.Custom.CreateHash $1
}

alias -l DLF.Custom.CreateHash {
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
alias -l DLF.Win.Filter {
  DLF.Win.Log Filter $event $DLF.chan $nick $1-
  halt
}

alias -l DLF.Win.Server {
  DLF.Win.Log Server $event $DLF.chan $nick $1-
  halt
}

alias -l DLF.Win.Log {
  if (($window($4)) && ($event == open)) .window -c $4
  elseif ($dqwindow & 4) close -d
  var %type = $1
  if ($1 == Filter) {
    if ($3 != $hashtag) DLF.Stats.Count $3 Filter
    else {
      var %i = $comchan($4,0)
      while (%i) {
        var %chan = $comchan($4,%i)
        if ($DLF.Chan.IsDlfChan(%chan)) DLF.Stats.Count %chan Filter
        dec %i
      }
    }
  }
  elseif ($1 == Server) {
    DLF.Chan.SetNickColour
    if (%DLF.serverwin == 0) {
      DLF.Win.Echo $2-
      return
    }
  }
  else DLF.Error DLF.Win.Log: Invalid window name: $1
  var %log   = $iif(%type == Server,%DLF.win-server.log,%DLF.win-filter.log)
  var %limit = $iif(%type == Server,%DLF.win-server.limit,%DLF.win-filter.limit)
  var %ts    = $iif(%type == Server,%DLF.win-server.timestamp,%DLF.win-filter.timestamp)
  var %strip = $iif(%type == Server,%DLF.win-server.strip,%DLF.win-filter.strip)
  var %wrap  = $iif(%type == Server,%DLF.win-server.wrap,%DLF.win-filter.wrap)

  var %line = $DLF.Win.LineFormat($2-)
  var %col = $DLF.Win.Colour($2)
  if (%log == 1) write $DLF.Win.LogName($DLF.Win.WinName(%type)) $sbr($logstamp) $strip(%line)
  if ((%type = Filter) && (%DLF.showfiltered == 0)) {
    DLF.Watch.Log Dropped: Options set to not show filters
    return
  }

  if (%type == Filter) var %tb = Filtered
  elseif (%type == Server) var %tb = Server response
  var %win = $DLF.Win.WinOpen(%type,-k0nw,%log,%limit,%tb $DLF.Win.TbMsg)

  if ((%limit == 1) && ($line(%win,0) >= 1500)) dline %win $+(1-,$calc($line(%win,0) - 3900))
  if (%ts == 1) %line = $timestamp %line
  if (%strip == 1) %line = $strip(%line)
  if (%wrap == 1) aline -pi %col %win %line
  else aline %col %win %line
  DLF.Watch.Log Filtered: To %win
}

alias -l DLF.Win.Ads {
  DLF.Chan.SetNickColour
  if (%DLF.serverads == 1) DLF.Win.AdsShow $1-
  DLF.Win.Filter $1-
}

alias -l DLF.Win.AdsShow {
  var %tb = server advertising $DLF.Win.TbMsg
  if (%DLF.perconnect == 1) var %tabs = -t20,40
  else var %tabs = -t30,55
  var %win = $DLF.Win.WinOpen(Ads,-k0nwl %tabs,0,0,0 %tb)
  if ($line(%win,0) == 0) {
    aline -n 6 %win This window shows adverts from servers describing how many files they have and how to get a list of their files.
    aline -n 2 %win However you will probably find it easier to use "@search search words" (or "@find search words") to locate files you want.
    aline -n 2 %win If you use @search, consider installing the sbClient script to make processing @search results easier.
    aline -n 4 %win You can double-click to have the request for the list of files sent for you.
    aline -n 1 %win $crlf
  }
  var %line = $DLF.Win.LineFormat($event $chan $nick $replace($strip($1-),$tab,$null,$+($space,$space),$space))
  var %ad = $replace($gettok(%line,3-,$asc($space)),$&
    $+($chr(149),$space),$space,$chr(149),$space,$+($chr(144),$space),$null,$chr(144),$null,$+($chr(8226),$space),$null,$chr(8226),$null,$+($space,$space),$space)
  while ($left(%ad,1) == $space) %ad = $right(%ad,-1)
  while (($left(%ad,1) !isletter) || ($asc($left(%ad,1)) >= 192)) %ad = $deltok(%ad,1,$asc($space))
  while ($wildtok(%ad,@*,0,$asc($space))) {
    var %tok = $wildtok(%ad,@*,1,$asc($space))
    %ad = $reptok(%ad,%tok,$u(%tok),$asc($space))
  }
  while ($wildtok(%ad,!*,0,$asc($space))) {
    var %tok = $wildtok(%ad,!*,1,$asc($space))
    %ad = $reptok(%ad,%tok,$u(%tok),$asc($space))
  }
  %line = $gettok(%line,1,$asc($space)) $tab $+ $gettok(%line,2,$asc($space)) $tab $+ %ad
  var %srch = $replace($gettok($strip(%line),1-7,$asc($space)),$tab,$null)
  %srch = $puttok(%srch,$DLF.Win.NickFromTag($gettok(%srch,2,$asc($space))),2,$asc($space))
  var %ln = $calc($line(%win,0) + 1)
  var %match = $+([,$iif(%DLF.perconnect == 0,$network),$chan,]*,$tag($DLF.Chan.GetMsgNick($chan,$nick)),*)
  var %i = $fline(%win,%match,0)
  if (%i == 0) {
    %match = $+([,$iif(%DLF.perconnect == 0,$network),$chan,]*)
    %i = $fline(%win,%match,0)
  }
  if (%i == 0) {
    %match = [*]*
    %i = $fline(%win,%match,0)
  }
  while (%i) {
    var %ln = $fline(%win,%match,%i)
    var %l = $gettok($strip($replace($line(%win,%ln),$tab,$null)),1-7,$asc($space))
    %l = $puttok(%l,$DLF.Win.NickFromTag($gettok(%l,2,$asc($space))),2,$asc($space))
    if (%l == %srch) {
      if ($gettok(%line,3-,$asc($space)) != $gettok($line(%win,%ln),3-,$asc($space))) $&
        rline $iif($line(%win,%ln).state,-a) 3 %win %ln %line
      DLF.Watch.Log Advert: $nick replaced
      break
    }
    elseif (%l < %srch) {
      inc %ln
      iline 3 %win %ln %line
      DLF.Watch.Log Advert: $nick inserted
      break
    }
    dec %i
  }
  if (%i == 0) {
    iline 3 %win %ln %line
    DLF.Watch.Log Advert: $nick prepended
  }
  window -b %win
  DLF.Win.TitleBar %win %tb
}

alias -l DLF.Win.AdsGet {
  var %line = $strip($line($active,$1))
  if (list of !isin %line) return
  var %re = /[[]([^]]+)[]]\s+<[&@%+]*([^>]+?)>.*?\W(@\S+)\s+/Fi
  if ($regex(DLF.Win.AdsGet,%line,%re) > 0) {
    var %chan = $regml(DLF.Win.AdsGet,1)
    var %nick = $regml(DLF.Win.AdsGet,2)
    var %trig = $regml(DLF.Win.AdsGet,3)
    if ((%trig = @find) || ($left(%trig,7) == @search)) return
    var %c = $left(%chan,1)
    if (%c isin $chantypes) {
      var %net = $gettok(%chan,1,$asc(%c))
      %chan = %c $+ $gettok(%chan,2,$asc(%c))
    }
    else var %net = $network
    if ((%net) && (%chan) && (%nick) && (%trig)) {
      var %cid = $cid
      var %i = $scon(0)
      while (%i) {
        if ($scon(%i).network == %net) {
          scid $scon(%i)
          ; Use editbox not msg so other scripts (like sbClient) get On Input event
          if (%nick ison %chan) DLF.Chan.EditSend %chan %trig
          break
        }
        dec %i
      }
      scid %cid
    }
  }
}

menu @dlF.Ads.* {
  dclick: DLF.Win.AdsGet $1
  $iif($sline($active,0) == $null,$style(2)) Get list of files from selected servers: {
    var %i = $sline($active,0)
    while (%i) {
      DLF.Win.AdsGet $sline($active,%i).ln
      dec %i
    }
  }
  -
  Clear: clear
  Options: DLF.Options.Show
  Disable: {
    %DLF.serverads = 0
    close -@ @DLF.Ads*.*
  }
  -
}

alias -l DLF.Ads.NickChg {
  if ($query($nick)) queryrn $nick $newnick
  if ($chat($nick)) dcc nick -c $nick $newnick
  var %win = $DLF.Win.WinName(Ads)
  if (!$window(%win)) return
  var %match = $+([,$iif(%DLF.perconnect == 0,$network),*]*<*,$nick,>*)
  var %i = $fline(%win,%match,0)
  while (%i) {
    var %l = $strip($fline(%win,%match,%i).text)
    if (%l == $crlf) break
    var %netchan = $left($right($gettok(%l,1,$asc($space)),-1),-1)
    var %nick = $DLF.Win.NickFromTag($gettok(%l,2,$asc($space)))
    var %nl = $len($network)
    if (($left(%nc,%nl) == $network) && ($left($right(%nc,- $+ %nl),1) isin $chantypes) && (%nick == $nick)) {
      var %ln = $fline(%win,%match,%i)
      var %l = $line(%win,%ln)
      rline 3 %win %ln $puttok(%l,$replace($gettok(%l,2,$asc($space)),$nick,$newnick),2,$asc($space))
    }
    dec %i
  }
}

alias -l DLF.Win.NickFromTag {
  var %nick = $replace($1,$tab,$null)
  if ($left(%nick,1) == $lt) %nick = $right(%nick,-1)
  if ($right(%nick,1) == $gt) %nick = $left(%nick,-1)
  while ($left(%nick,1) isin $prefix) %nick = $right(%nick,-1)
  return %nick
}

alias -l DLF.Ads.ColourLines {
  var %win = $DLF.Win.WinName(Ads)
  if (!$window(%win)) return
  if (($event == quit) || ($event == disconnect)) var %match = $+([,$iif(%DLF.perconnect == 0,$network),*]*)
  else var %match = $+([,$iif(%DLF.perconnect == 0,$network),$chan,]*)
  if ($nick != $me) %match = $+(%match,<*,$nick,>*)
  var %i = $fline(%win,%match,0)
  var %ctpos = $iif(%DLF.perconnect == 0,$calc($len($network) + 2),2)
  while (%i) {
    var %l = $strip($fline(%win,%match,%i).text)
    var %ln = $fline(%win,%match,%i)
    dec %i
    var %chantype = $mid($gettok(%l,1,$asc($space)),%ctpos,1)
    if (%chantype !isin $chantypes) continue
    var %nick = $DLF.Win.NickFromTag($gettok(%l,2,$asc($space)))
    if (($event == disconnect) || (%nick == $nick) || ($me == $nick)) cline $1 %win %ln
  }
}

alias -l DLF.@find.ColourLines {
  var %win = @dlF.@find. $+ $network
  if (!$window(%win)) return
  if ($nick == $me) DLF.@find.DoColourLines $1 %win *
  elseif ($comchan($nick,0) == 0) {
    DLF.@find.DoColourLines $1 %win $+(?,$nick, *)
    DLF.@find.DoColourLines $1 %win $+(*:: Received from ,$nick)
  }
}

alias -l DLF.@find.DoColourLines {
  var %i = $fline($2,$3-,0)
  while (%i) {
    var %l = $strip($fline($2,$3-,%i).text)
    if (%l == $crlf) return
    cline $1 $2 $fline($2,$3-,%i)
    dec %i
  }
}

alias -l DLF.Win.TbMsg return messages from $iif(%DLF.perconnect,the $network network,all networks) -=- Right-click for options
alias -l DLF.Win.WinName return $+(@dlF.,$1,.,$iif(%DLF.perconnect,$network,All))
alias -l DLF.Win.LogName {
  var %lfn = $mklogfn($1)
  if (%DLF.perconnect == 0) %lfn = $nopath(%lfn)
  return $qt($+($logdir,%lfn))
}

; %winname = $DLF.Win.WinOpen(type,switches,log,limit,title)
alias -l DLF.Win.WinOpen {
  var %win = $DLF.Win.WinName($1)
  if ($window(%win)) return %win
  var %lfn = $DLF.Win.LogName(%win)
  var %switches = $2
  if (%DLF.perconnect == 0) %switches = $puttok(%switches,$gettok(%switches,1,$asc($space)) $+ z,1,$asc($space))
  window %switches %win
  if (($3) && ($isfile(%lfn))) loadbuf $iif($4,3900) -p %win %lfn
  if ($5- != $null) titlebar %win -=- $5-
  return %win
}

alias -l DLF.Win.LineFormat {
  tokenize $asc($space) $1-
  var %nc = $null
  if (%DLF.perconnect == 0) %nc = $network
  if (($left($2,1) == $hashtag) && ($2 != $hashtag)) %nc = %nc $+ $2
  if (%nc != $null) %nc = $sbr(%nc)
  return %nc $DLF.Win.Format($1-)
}

alias -l DLF.Win.MsgType return $replace($1,ctcpsend,ctcp,ctcpreply,ctcp,text,normal)
alias -l DLF.Win.Colour return $color($DLF.Win.MsgType($1))

alias -l DLF.Win.Format {
  tokenize $asc($space) $1-
  if (($1 isin Normal Text) && ($3 == $me) && ($prefixown == 0)) return $4-
  elseif ($1 isin Normal Text) return $tag($DLF.Chan.GetMsgNick($2,$3)) $4-
  elseif ($1 == Notice) return $+(-,$3,-) $4-
  elseif (($1 == ctcp) && ($4 == DCC)) return $4-
  elseif ($1 == ctcp) return $sbr($3 $+ $iif(($2 != Private) && ($2 != $3),: $+ $2) $4) $5-
  elseif ($1 == ctcpreply) return $sbr($3 $+ $iif($2 != Private,: $+ $2) $4 reply) $5-
  elseif ($1 == ctcpsend) return -> $sbr($3 $+ $iif($2 != Private,: $+ $2) $upper($4)) $5-
  elseif ($1 == warning) return $c(1,9,$DLF.logo Warning: $4-)
  elseif ($1 == blocked) return $c(1,9,$DLF.logo Blocked: $4-)
  else return * $4-
}

alias -l DLF.Win.Echo {
  var %line = $DLF.Win.Format($1-)
  var %col = $DLF.Win.Colour($1)
  if ($2 !isin Private @find $hashtag) {
    echo %col -t $2 %line
    DLF.Watch.Log Echoed: To $2
  }
  else {
    if ($1 != ctcpreply) %line = $2 $+ : %line
    var %sent = $null
    var %i = $comchan($3,0)
    while (%i) {
      var %chan = $comchan($3,%i)
      if ($DLF.Chan.IsDlfChan(%chan)) {
        echo %col -t %chan %line
        %sent = $addtok(%sent,%chan,$asc($comma))
      }
      dec %i
    }
    if (%sent != $null) DLF.Watch.Log Echoed: To common channels %sent
    else {
      echo %col -at Private: %line
      DLF.Watch.Log Echoed: To active channel $active
    }
  }
}

menu @dlF.Filter.* {
  Search: DLF.Win.Search $menu $?="Enter search string"
  -
  $iif(%DLF.win-filter.timestamp == 1,$style(1)) Timestamp: DLF.Options.ToggleOption filtered.timestamp
  $iif(%DLF.win-filter.strip == 1,$style(1)) Strip codes: DLF.Options.ToggleOption filtered.strip
  $iif(%DLF.win-filter.wrap == 1,$style(1)) Wrap lines: DLF.Options.ToggleOption filtered.wrap
  $iif(%DLF.win-filter.limit == 1,$style(1)) Limit number of lines: DLF.Options.ToggleOption filtered.limit
  $iif(%DLF.win-filter.log == 1,$style(1)) Log: DLF.Options.ToggleOption filtered.log
  -
  Clear: clear
  Options: DLF.Options.Show
  Hide filter window: {
    %DLF.showfiltered = 0
    close -@ @dlF.Filter*.*
  }
  -
}

menu @dlF.Server.* {
  Search: DLF.Win.Search $menu $?="Enter search string"
  -
  $iif(%DLF.win-server.timestamp == 1,$style(1)) Timestamp: DLF.Options.ToggleOption server.timestamp
  $iif(%DLF.win-server.strip == 1,$style(1)) Strip codes: DLF.Options.ToggleOption server.strip
  $iif(%DLF.win-server.wrap == 1,$style(1)) Wrap lines: DLF.Options.ToggleOption server.wrap
  $iif(%DLF.win-server.limit == 1,$style(1)) Limit number of lines: DLF.Options.ToggleOption server.limit
  $iif(%DLF.win-server.log == 1,$style(1)) Log: DLF.Options.ToggleOption server.log
  -
  Clear: clear
  Options: DLF.Options.Show
  Disable: {
    %DLF.serverwin = 0
    close -@ @DLF.Server*.*
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
  var %wf = $gettok($1,2,$asc(.))
  if ($right(%wf,6) != Search) %ws = $+(%wf,Search)
  else {
    %ws = %wf
    %wf = $left(%wf,-6)
  }
  var %wf = $puttok($1,%wf,2,$asc(.))
  var %ws = $puttok($1,%ws,2,$asc(.))
  window $iif($gettok($1,-1,$asc(.)) == All,-eabk0z,-eabk0) %ws
  var %sstring = $+($star,$2-,$star)
  titlebar %ws -=- Searching for %sstring in %wf
  filter -wwcbzph4 %wf %ws %sstring
  var %matches = $iif($filtered == 0,No matches,$iif($filtered == 1,One match,$filtered matches))
  titlebar %ws -=- Search finished. -=- %matches found for $qt(%sstring) in %wf
}

; ========== @find ==========
menu @dlF.@find.* {
  dclick: DLF.@find.Get $1
  $iif($sline($active,0) == $null,$style(2)) Get selected files: {
    var %i = $sline($active,0)
    while (%i) {
      DLF.@find.Get $sline($active,%i).ln
      dec %i
    }
  }
  Copy line(s): DLF.@find.CopyLines
  $iif(!$script(AutoGet.mrc), $style(2)) Send to AutoGet: DLF.@find.SendToAutoGet
  $iif(!$script(vPowerGet.net.mrc), $style(2)) Send to vPowerGet.NET: DLF.@find.SendTovPowerGet
  Save results: DLF.@find.SaveResults
  -
  Options: DLF.Options.Show
  Clear: clear
  -
  Close: window -c $active
  -
}

alias -l DLF.@find.Request {
  hadd -mz DLF.@find.requests $+($network,$chan) 900
}

alias -l DLF.@find.IsResponse {
  var %net = $network $+ #*
  var %n = $hfind(DLF.@find.requests,%net,0,w).item
  while (%n) {
    var %netchan = $hfind(DLF.@find.requests,%net,%n,w).item
    var %net = $gettok(%netchan,1,$asc($hashtag))
    if (%net == $null) %net = $network
    var %chan = $hashtag $+ $gettok(%netchan,2,$asc($hashtag))
    if ((%net == $network) && ($nick ison %chan)) {
      DLF.Watch.Log @find.IsResponse: %chan
      return $true
    }
    dec %n
  }
  return $false
}

alias -l DLF.@find.Response {
  if ($DLF.@find.IsResponse) {
    var %txt = $strip($1-)
    DLF.@find.OnlyPartial $1-
    if ($hiswm(find.header,%txt)) {
      if (%DLF.searchresults == 1) DLF.Win.Log Filter $event @find $nick $1-
      else DLF.Win.Log Server $event @find $nick $1-
      halt
    }
    if ($hiswm(find.fileserv,%txt)) {
      DLF.Win.Log Server $event @find $nick $1-
      halt
    }
    if ($hiswm(find.result,%txt)) {
      if (%DLF.searchresults == 1) {
        DLF.Win.Log Filter $event @find $nick $1-
        DLF.@find.Results $1-
      }
      else DLF.Win.Log Server $event @find $nick $1-
      halt
    }
    if ((*Omen* iswm $strip($1)) && ($left($strip($2),1) == !)) {
      if (%DLF.searchresults == 1) {
        DLF.Win.Log Filter $event @find $nick $1-
        DLF.@find.Results $2-
      }
      else DLF.Win.Log Server $event @find $nick $2-
      halt
    }
  }
}

alias -l DLF.@find.OnlyPartial {
  var %txt = $strip($1-)
  if ($left(%txt,1) == !) return
  var %re = $hfind(DLF.find.headregex,%txt,1,R).item
  if (%re == $null) return

  var %r = $DLF.@find.Regex(%re,$hget(DLF.find.headregex,%re),%txt)
  if (%r == $null) return

  var %list = $gettok(%r,1,$asc(:))
  var %found = $gettok(%r,2,$asc(:))
  var %displayed = $gettok(%r,3,$asc(:))
  var %search = $gettok(%r,4,$asc(:))
  if (%found == %displayed) return
  DLF.Chan.SetNickColour
  if (%DLF.searchresults == 0) DLF.Win.Log Server $event @find $nick $1-
  else DLF.@find.Results %list $iif(%search,For $qt(%search) found,Found) %found $+ , but displaying only %displayed $c(14,:: Double click here to get the server's full list)
}

alias -l DLF.@find.Regex {
  if ($regex(DLF.@find.Regex,$3-,$1) !isnum 1-) return
  var %n = $numtok($2,$asc($space))
  var %result = $null
  while (%n) {
    %result = $regml(DLF.@find.Regex,$gettok($2,%n,$asc($space))) $+ : $+ %result
    dec %n
  }
  return %result
}

alias -l DLF.@find.Results {
  ;if (($window($nick)) && (!$line($nick,0))) .window -c $nick
  var %trig = $strip($1)
  var %rest = $2-
  if ($left(%trig,1) = !) {
    var %rest = $strip(%rest)
    var %fn = $DLF.GetFilename(%rest)
    %rest = $right(%rest,$calc(- $len(%fn) - 1))
    if ($gettok(%rest,1,$asc($space)) == ::INFO::) {
      %rest = :: Size: $gettok(%rest,2-,$asc($space))
      if ($pos(%rest,+,0) > 0) $&
        %rest = $left(%rest,$calc($pos(%rest,+,1) - 1))
      %rest = %fn $c(14,%rest)
    }
  }
  var %msg = %trig $tab $+ %rest
  if ((%trig != $+(!,$nick)) && (%trig != $+(@,$nick))) {
    %msg = %msg $c(4,0,:: Received from $nick)
  }
  var %win = $+(@dlF.@find.,$network)
  if (!$window(%win)) window -lk0wn -t15 %win
  if ($line(%win,0) == 0) {
    aline -n 6 %win This window shows @find results as received individually from various servers.
    aline -n 2 %win In the future you might want to use @search instead of @find as it is quicker and more efficicent.
    aline -n 2 %win If you use @search, consider installing the sbClient script to make processing @search results easier.
    aline -n 4 %win You can select lines and copy and paste them into the channel to get files,
    aline -n 4 %win or double-click to have the file request sent for you.
    aline -n 1 %win $crlf
  }
  var %i = $line(%win,0)
  var %smsg = $left(%msg,1)
  if (%smsg == !) %smsg = %smsg $+ $gettok(%msg,2-,$asc($tab))
  elseif (%smsg == @) %smsg = %msg
  else return
  while (%i) {
    var %l = $line(%win,%i)
    if (%l == $crlf) break
    if ($left(%l,1) == !) %l = $left(%l,1) $+ $gettok(%l,2-,$asc($tab))
    if (%l == %smsg) DLF.Halt @find result: Result for %trig added to %win
    if (%l < %smsg) break
    dec %i
  }
  inc %i
  iline -hn $iif($left(%msg,1) == @,2,3) %win %i %msg
  window -b %win
  DLF.Win.TitleBar %win @find results from $network so far -=- Right-click for options or double-click to download
  DLF.Halt @find result: Result for %trig added to %win
}

alias -l DLF.Win.TitleBar {
  var %i = $line($1,0)
  while (%i) {
    if ($line($1,%i) = $crlf) break
    dec %i
  }
  var %i = $calc($line($1,0) - %i)
  titlebar $1 -=- %i $2-
}

alias -l DLF.@find.Get {
  var %line = $replace($line($active,$1),$tab,$space)
  var %trig = $gettok(%line,1,$asc($space))
  var %type = $left(%trig,1)
  if (%type !isin !@) return
  var %nick = $right(%trig,-1)
  if (%type == @) var %fn = $null
  else var %fn = $DLF.GetFileName($gettok(%line,2-,$asc($space)))
  ; Find common channels for trigger nickname and issue the command in the channel
  var %i = $comchan(%nick,0)
  while (%i) {
    var %chan = $comchan(%nick,%i)
    if ($DLF.Chan.IsDlfChan(%chan)) {
      ; Use editbox not msg so other scripts (like sbClient) get On Input event
      DLF.Chan.EditSend %chan %trig %fn
      cline 15 $active $1
      return
    }
    dec %i
  }
}

alias -l DLF.@find.CopyLines {
  var %lines = $sline($active,0)
  if (!%lines) halt
  DLF.@find.ClearColours
  clipboard
  var %lines = $line($active,0)
  var %i = 1
  while (%i <= %lines) {
    clipboard -an $gettok($sline($active,%i),1,$asc($space)) $DLF.GetFileName($gettok($sline($active,%i),2-,$asc($space)))
    cline 3 $active $sline($active,%i).ln
    inc %i
  }
  dec %i
  DLF.Win.TitleBar $active %i line(s) copied into clipboard
}

alias -l DLF.@find.ClearColours {
  var %i = $line($active,0)
  while (%i) {
    if ($line($active,%i).color != 15) cline $color(Normal) $active %i
    dec %i
  }
}

alias -l DLF.@find.SendToAutoGet {
  var %win = $active
  var %lines = $sline(%win,0)
  if (!%lines) halt
  if ($fopen(MTlisttowaiting)) .fclose MTlisttowaiting
  .fopen MTlisttowaiting $+(",$remove($script(AutoGet.mrc),Autoget.mrc),AGwaiting.ini,")
  set %MTpath %MTdefaultfolder
  var %i = 1
  var %j = 0
  while (%i <= %lines) {
    var %temp = $MTlisttowaiting($replace($sline(%win,%i),$nbsp,$space))
    var %j = $calc(%j + $gettok(%temp,1,$asc($space)))
    if ($sbClient.Online($sline($active,%i)) == 1) cline 10 $active $sline($active,%i).ln
    else cline 6 $active $sline($active,%i).ln
    inc %i
  }
  dec %i
  .fclose MTlisttowaiting
  unset %MTpath
  if (%MTautorequest == 1) MTkickstart $gettok(%temp,2,$asc($space))
  MTwhosinque
  echo -st %MTlogo Added %j File(s) To Waiting List From dlFilter
  DLF.Win.TitleBar %win %j line(s) sent to AutoGet
}

alias -l DLF.@find.SendTovPowerGet {
  var %win = $active
  var %lines = $sline(%win,0)
  if (!%lines) halt
  DLF.@find.ClearColours
  var %i = 1
  while (%i <= %lines) {
    if ($com(vPG.NET,AddFiles,1,bstr,$sline(%win,%i)) == 0) {
      echo -st vPG.NET: AddFiles failed
    }
    cline 3 $active $sline($active,%i).ln
    inc %i
  }
  dec %i
  DLF.Win.TitleBar %win %i line(s) sent to vPowerGet.NET
}

alias -l DLF.@find.SaveResults {
  var %fn = $sfile($sysdir(downloads),Save @find results as a text file,Save)
  if (!%fn) return
  %fn = $qt($gettok(%fn,$+(1-,$calc($numtok(%fn,$asc(.)) - 1)),$asc(.)) $+ .txt)
  savebuf $active %fn
}

; ========== oNotice ==========
menu @#* {
  Clear: clear
  $iif(%DLF.win-onotice.timestamp == 1,$style(1)) Timestamp: DLF.Options.ToggleOption win-onotice.timestamp
  $iif(%DLF.win-onotice.log == 1,$style(1)) Logging: DLF.Options.ToggleOption win-onotice.log
  Options: DLF.Options.Show
  -
  Close: DLF.oNotice.Close $active
  -
}

alias -l DLF.oNotice.IsoNotice {
  if (%DLF.win-onotice.enabled != 1) return $false
  ;if ($target != $+(@,$chan)) return $false
  if ($me !isop $chan) return $false
  if ($nick !isop $chan) return $false
  return $true
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
  if (%DLF.win-onotice.timestamp == 1) var %omsg = $timestamp %omsg
  DLF.oNotice.Log %win $gettok(%omsg,2-,$asc($space))
  DLF.Halt Halted: oNotice sent to %win
}

alias -l DLF.oNotice.Open {
  if ($me !isop $chan) return
  var %win = @ $+ $chan
  if (!$window(%win)) {
    DLF.oNotice.Log %win ----- Session started -----
    window $+(-eg1k1l12mSw,$iif($1 == 0,n)) %win
    var %log = $DLF.oNotice.LogFile(%win)
    if ((%DLF.win-onotice.log == 1) && ($isfile(%log))) .loadbuf -r %win %log
  }
  return %win
}

alias -l DLF.oNotice.Input {
  var %ochan = $right($active,-1)
  if (($left($1,1) == /) && ($ctrlenter == $false) && ($1 != /me)) return
  if (($1 != /me) || ($ctrlenter == $true)) var %omsg = $iif($prefixown == 1,$tag($me) $+ $space) $+ $1-
  else var %omsg = $star $me $2-
  if (%DLF.win-onotice.timestamp == 1) var %omsg = $timestamp %omsg
  echo $iif($1 != /me,$color(Normal),$color(Action)) -st $active %omsg
  aline -nl $color(nicklist) $active $me
  window -S $active
  if ($me !isop %ochan) {
    echo 4 -t %ochan oNotice not sent: You are no longer an op in %ochan
    return
  }
  .onotice %ochan $1-
  DLF.oNotice.Log $active %omsg
}

alias -l DLF.oNotice.Close {
  DLF.oNotice.Log $1 ----- Session closed -----
  close -@ $1
}

alias -l DLF.oNotice.Log {
  if (%DLF.win-onotice.log == 1) {
    var %log = %DLF.oNotice.LogFile($1)
    write -m1 %log $sbr($logstamp) $2-
  }
}

alias -l DLF.oNotice.LogFile return $+($logdir,$mklogfn($1))

; ========== mIRC options check ==========
; IRC / Catcher / Chat links; Confirm requests checked.
; IRC / Flood / Flood protection on (plus optimum settings?)
; IRC / Flood / What is being limited?
; IRC / Flood / Queue own messages?
; IRC / Sounds / Requests / Accept sound requests? not set
; IRC / Sounds / Requests / Listen for !nick file not set
; DCC / On Send / Trusted / Limit Auto-Get to trusted users set
; Other / Enable Sendmessage Server
; Other / Confirm / Command that may run a script


; ============================== DLF Options ==============================
alias DLF.Options.Show dialog $iif($dialog(DLF.Options.GUI),-v,-md) DLF.Options.GUI DLF.Options.GUI
alias DLF.Options.Toggle dialog $iif($dialog(DLF.Options.GUI),-c,-md) DLF.Options.GUI DLF.Options.GUI

dialog -l DLF.Options.GUI {
  title dlFilter v $+ $DLF.SetVersion
  size -1 -1 168 218
  option dbu notheme
  text "", 20, 67 2 98 7, right hide
  check "&Enable/disable dlFilter", 10, 2 2 62 8
  tab "Channels", 100, 1 9 166 193
  tab "Filters", 300
  tab "Other", 500
  tab "Ops", 700
  tab "Custom", 800
  tab "About", 900
  button "Close", 30, 2 205 67 11, ok default flat
  check "Show/hide filtered lines", 40, 74 205 92 11, push
  ; tab Channels
  text "List the channels you want dlFilter to operate on. Use # by itself to make dlFilter work on all networks and channels.",105, 5 25 160 12, tab 100 multi
  text "Channel to add (select dropdown / type #chan or net#chan):", 110, 5 40 160 7, tab 100
  combo 120, 4 48 160 6, tab 100 drop edit
  button "Add", 130, 5 61 76 11, tab 100 flat disable
  button "Remove", 135, 86 61 76 11, tab 100 flat disable
  list 140, 4 74 160 83, tab 100 vsbar size sort extsel
  box " Update ", 150, 4 158 160 41, tab 100
  text "Checking for dlFilter updates...", 160, 7 166 135 8, tab 100
  button "dlFilter website", 170, 7 175 74 11, tab 100 flat
  button "Update dlFilter", 180, 86 175 74 11, tab 100 flat disable
  check "Check for &beta versions", 190, 7 189 136 6, tab 100
  ; tab Filters
  box " General ", 305, 4 23 160 127, tab 300
  check "Filter other users Search / File requests", 310, 7 32 155 6, tab 300
  check "Filter adverts and announcements", 315, 7 41 155 6, tab 300
  check "Show adverts and announcements in a separate window", 320, 7 50 155 6, tab 300
  check "Filter channel mode changes (e.g. user limits)", 325, 7 59 155 6, tab 300
  check "Filter channel spam", 330, 7 68 155 6, tab 300
  check "Filter private spam", 335, 7 77 155 6, tab 300
  check "... and /ignore spammer for 1h (asks confirmation)", 340, 15 86 146 6, tab 300
  check "Filter channel messages with control codes (usually a bot)", 345, 7 95 155 6, tab 300
  check "Filter messages without alphabetics", 350, 7 104 155 6, tab 300
  check "Filter channel topic messages", 355, 7 113 155 6, tab 300
  check "Filter responses to my requests to separate window", 360, 7 122 155 6, tab 300
  check "Filter requests to you in PM (@yournick, !yournick)", 365, 7 131 155 6, tab 300
  check "Separate dlF windows per connection", 370, 7 140 155 6, tab 300
  box " Filter user events ", 375, 4 151 160 48, tab 300
  check "Joins ...", 380, 7 161 53 6, tab 300
  check "Parts ...", 382, 61 161 53 6, tab 300
  check "Quits ...", 384, 115 161 53 6, tab 300
  check "Nick changes ...", 386, 7 170 53 6, tab 300
  check "Kicks ...", 388, 61 170 53 6, tab 300
  check "Away and thank-you messages", 390, 7 179 155 6, tab 300
  check "User mode changes", 395, 7 188 155 6, tab 300
  ; Tab Other
  box " Extra functions ", 505, 4 23 160 37, tab 500
  check "Collect @find/@locator results into a single window", 510, 7 32 155 6, tab 500
  check "Display dlFilter channel efficiency in title bar", 525, 7 41 155 6, tab 500
  check "Colour uncoloured fileservers in nickname list", 530, 7 50 155 6, tab 500
  box " File requests ", 535, 4 61 160 73, tab 500
  check "Auto accept files you have specifically requested", 540, 7 70 155 6, tab 500
  check "Block ALL files you have NOT specifically requested. Or:", 545, 7 79 155 6, tab 500
  check "Block potentially dangerous filetypes", 550, 15 88 146 6, tab 500
  check "Block files from users not in a common channel", 555, 15 97 146 6, tab 500
  check "Block files from users not in your mIRC DCC trust list", 560, 15 106 146 6, tab 500
  check "Block files from regular users", 565, 15 115 146 6, tab 500
  check "Retry incomplete file requests (up to 3 times)", 570, 7 124 155 6, tab 500
  box " mIRC-wide ", 605, 4 135 160 64, tab 500
  check "Check mIRC settings are secure (future enhancement)", 610, 7 144 155 6, tab 500 disable
  check "Allow private messages from users with open query window", 615, 7 153 155 6, tab 500
  check "Block private messages from users not in a common channel", 620, 7 162 155 6, tab 500
  check "Block private messages from regular users", 625, 7 171 155 6, tab 500
  check "Block channel CTCP requests unless from an op", 655, 7 180 155 6, tab 500
  check "Block IRC Finger requests (which share personal information)", 660, 7 189 155 6, tab 500
  ; tab Ops
  text "These options are only enabled if you are an op on a filtered channel.", 705, 4 25 160 12, tab 700 multi
  box " Channel Ops ", 710, 4 38 160 38, tab 700
  check "Filter oNotices to separate @#window (OpsTalk)", 715, 7 48 155 6, tab 700
  check "On channel spam, oNotify if you are an op", 725, 7 57 155 6, tab 700
  check "On private spam, oNotify if you are op in a common channel", 730, 7 66 155 6, tab 700
  box " dlFilter promotion ", 755, 4 77 160 29, tab 700
  check "Advertise dlFilter in channels every", 760, 7 87 93 6, tab 700
  edit "60", 765, 101 85 12 10, tab 700 right
  text "mins", 770, 115 86 47 7, tab 700
  check "Prompt individual existing dlFilter users to upgrade", 780, 7 96 155 6, tab 700
  ; tab Custom
  check "Enable custom filters", 810, 5 28 100 6, tab 800
  text "Message type:", 820, 74 27 50 7, tab 800
  combo 830, 114 25 50 10, tab 800 drop
  edit "", 840, 4 37 160 10, tab 800 autohs
  button "Add", 850, 5 51 76 11, tab 800 flat disable
  button "Remove", 860, 86 51 76 11, tab 800 flat disable
  list 870, 4 64 160 135, tab 800 hsbar vsbar size sort extsel
  ; tab About
  edit "", 920, 3 25 162 175, multi read vsbar tab 900
}

alias -l DLF.Options.SetLinkedFields {
  DLF.Options.LinkedFields 335 340
  DLF.Options.LinkedFields -545 550 555 560 565
}

; Initialise dialog
on *:dialog:DLF.Options.GUI:init:0: DLF.Options.Init
; Channel text box typed or clicked - Enable / disable Add channel button
on *:dialog:DLF.Options.GUI:edit:120: DLF.Options.SetAddChannelButton
on *:dialog:DLF.Options.GUI:sclick:120: DLF.Options.SetAddChannelButton
; Channel Add button clicked
on *:dialog:DLF.Options.GUI:sclick:130: DLF.Options.AddChannel
; Channel Remove button clicked
on *:dialog:DLF.Options.GUI:sclick:135: DLF.Options.RemoveChannel
; Channel list clicked - Enable / disable Remove channel button
on *:dialog:DLF.Options.GUI:sclick:140: DLF.Options.SetRemoveChannelButton
; Channel list double click - Remove channel and put in text box for editing and re-adding.
on *:dialog:DLF.Options.GUI:dclick:140: DLF.Options.EditChannel
; Per-Server options clicked
on *:dialog:DLF.Options.GUI:sclick:370: DLF.Options.PerConnection
; Titlebar options clicked
on *:dialog:DLF.Options.GUI:sclick:525: DLF.Options.Titlebar
; Select custom message type
on *:dialog:DLF.Options.GUI:sclick:830: DLF.Options.SetCustomType
; Enable / disable Add custom message button
on *:dialog:DLF.Options.GUI:edit:840: DLF.Options.SetAddCustomButton
; Customer filter Add button clicked
on *:dialog:DLF.Options.GUI:sclick:850: DLF.Options.AddCustom
; Customer filter Remove button clicked or double click in list
on *:dialog:DLF.Options.GUI:sclick:860: DLF.Options.RemoveCustom
; Enable / disable Remove custom message button
on *:dialog:DLF.Options.GUI:sclick:870: DLF.Options.SetRemoveCustomButton
; Double click on custom text line removes line but puts it into Add box for editing and re-adding.
on *:dialog:DLF.Options.GUI:dclick:870: DLF.Options.EditCustom
; Goto website button
on *:dialog:DLF.Options.GUI:sclick:170: url -a https://github.com/SanderSade/dlFilter
; Download update button
on *:dialog:DLF.Options.GUI:sclick:180: DLF.Options.DownloadUpdate
; Handle all other checkbox clicks and save
; Should go last so that sclick for specific fields take precedence
on *:dialog:DLF.Options.GUI:sclick:1-999: DLF.Options.ClickOption

; Initialise variables
alias -l DLF.Options.Initialise {
  ; Options Dialog variables in display order

  ; All tabs
  DLF.Options.InitOption enabled 1
  DLF.Options.InitOption showfiltered = 1

  ; Channels tab
  if (%DLF.netchans == $null) {
    DLF.Chan.Set $hashtag
    DLF.StatusAll Channels set to $c(4,all) $+ .
  }
  else DLF.Chan.Set %DLF.netchans

  ; Channels tab - Check for updates
  DLF.Options.InitOption update.betas 0

  ; Filter tab
  ; Filter tab General box
  DLF.Options.InitOption filter.requests 1
  DLF.Options.InitOption filter.ads 1
  DLF.Options.InitOption serverads 1
  DLF.Options.InitOption filter.modeschan 1
  DLF.Options.InitOption filter.spamchan 1
  DLF.Options.InitOption filter.spampriv 1
  DLF.Options.InitOption spam.addignore 0
  DLF.Options.InitOption filter.controlcodes 1
  DLF.Options.InitOption filter.nonalpha 1
  DLF.Options.InitOption filter.topic 0
  DLF.Options.InitOption serverwin 0
  DLF.Options.InitOption private.requests 1
  DLF.Options.InitOption perconnect 1
  ; Filter tab User events box
  DLF.Options.InitOption filter.joins 1
  DLF.Options.InitOption filter.parts 1
  DLF.Options.InitOption filter.quits 1
  DLF.Options.InitOption filter.nicks 1
  DLF.Options.InitOption filter.kicks 1
  DLF.Options.InitOption filter.aways 1
  DLF.Options.InitOption filter.modesuser 1

  ; Other tab
  ; Other tab Extra Functions box
  DLF.Options.InitOption searchresults 1
  DLF.Options.InitOption titlebar.stats 1
  DLF.Options.InitOption colornicks 1
  ; Other tab File requests box
  DLF.Options.InitOption dccsend.autoaccept 1
  DLF.Options.InitOption dccsend.requested 1
  DLF.Options.InitOption dccsend.dangerous 1
  DLF.Options.InitOption dccsend.nocomchan 1
  DLF.Options.InitOption dccsend.untrusted 1
  DLF.Options.InitOption dccsend.regular 1
  DLF.Options.InitOption serverretry 1
  ; Other tab mIRC-wide box
  DLF.Options.InitOption checksecurity 1
  DLF.Options.InitOption private.query 1
  DLF.Options.InitOption private.nocomchan 1
  DLF.Options.InitOption private.regular 1
  DLF.Options.InitOption chanctcp 1
  DLF.Options.InitOption nofingers 1

  ; Ops tab
  DLF.Options.InitOption win-onotice.enabled 1
  DLF.Options.InitOption opwarning.spamchan 1
  DLF.Options.InitOption opwarning.spampriv 1
  DLF.Options.InitOption ops.advertchan 0
  DLF.Options.InitOption ops.advertchan.period 5
  DLF.Options.InitOption ops.advertpriv 0

  ; Custom tab
  DLF.Options.InitOption custom.enabled 1
  DLF.Options.InitOption custom.chantext $addtok(%DLF.custom.chantext,$replace(*this is an example custom filter*,$space,$nbsp),$asc($comma))

  ; Options only available in menu not options
  ; TODO Consider adding these as options
  DLF.Options.InitOption win-filter.limit 1
  DLF.Options.InitOption win-filter.log 0
  DLF.Options.InitOption win-filter.timestamp 1
  DLF.Options.InitOption win-filter.wrap 1
  DLF.Options.InitOption win-filter.strip 0
  DLF.Options.InitOption win-server.limit 1
  DLF.Options.InitOption win-server.log 0
  DLF.Options.InitOption win-server.timestamp 1
  DLF.Options.InitOption win-server.wrap 1
  DLF.Options.InitOption win-server.strip 0
  DLF.Options.InitOption win-onotice.timestamp 1
  DLF.Options.InitOption win-onotice.log 1
}

alias -l DLF.Options.InitOption {
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
  var %newval = $iif([ [ %var ] ],0,1)
  [ [ %var ] ] = %newval
  if (($2 != $null) && ($dialog(DLF.Options.GUI))) did $iif(%newval,-c,-u) DLF.Options.GUI $2
  DLF.StatusAll Option $1 $iif(%newval,set,cleared)
}

alias -l DLF.Options.Init {
  ; Disable Ops tab
  DLF.Options.OpsTab

  ; Disable enabling and show msg if mIRC version too low
  var %ver = $DLF.mIRCversion
  if (%ver != 0) {
    did -b DLF.Options.GUI 10
    did -vo DLF.Options.GUI 20 1 Upgrade to %ver $+ +
  }
  if (%DLF.enabled == 1) did -c DLF.Options.GUI 10
  if (%DLF.showfiltered == 1) did -c DLF.Options.GUI 40
  if (%DLF.update.betas == 1) did -c DLF.Options.GUI 190
  if (%DLF.filter.requests == 1) did -c DLF.Options.GUI 310
  if (%DLF.filter.ads == 1) did -c DLF.Options.GUI 315
  if (%DLF.serverads == 1) did -c DLF.Options.GUI 320
  if (%DLF.filter.modeschan == 1) did -c DLF.Options.GUI 325
  if (%DLF.filter.spamchan == 1) did -c DLF.Options.GUI 330
  if (%DLF.filter.spampriv == 1) did -c DLF.Options.GUI 335
  else %DLF.spam.addignore = 0
  if (%DLF.spam.addignore == 1) did -c DLF.Options.GUI 340
  if (%DLF.filter.controlcodes == 1) did -c DLF.Options.GUI 345
  if (%DLF.filter.nonalpha == 1) did -c DLF.Options.GUI 350
  if (%DLF.filter.topic == 1) did -c DLF.Options.GUI 355
  if (%DLF.serverwin == 1) did -c DLF.Options.GUI 360
  if (%DLF.private.requests == 1) did -c DLF.Options.GUI 365
  if (%DLF.perconnect == 1) did -c DLF.Options.GUI 370
  if (%DLF.filter.joins == 1) did -c DLF.Options.GUI 380
  if (%DLF.filter.parts == 1) did -c DLF.Options.GUI 382
  if (%DLF.filter.quits == 1) did -c DLF.Options.GUI 384
  if (%DLF.filter.nicks == 1) did -c DLF.Options.GUI 386
  if (%DLF.filter.kicks == 1) did -c DLF.Options.GUI 388
  if (%DLF.filter.aways == 1) did -c DLF.Options.GUI 390
  if (%DLF.filter.modesuser == 1) did -c DLF.Options.GUI 395
  if (%DLF.searchresults == 1) did -c DLF.Options.GUI 510
  if (%DLF.titlebar.stats == 1) did -c DLF.Options.GUI 525
  if (%DLF.colornicks == 1) did -c DLF.Options.GUI 530
  if (%DLF.dccsend.autoaccept == 1) did -c DLF.Options.GUI 540
  if (%DLF.dccsend.requested == 1) {
    did -c DLF.Options.GUI 545
    %DLF.dccsend.dangerous = 1
    %DLF.dccsend.nocomchan = 1
    %DLF.dccsend.untrusted = 1
    %DLF.dccsend.regular = 1
  }
  if (%DLF.dccsend.dangerous == 1) did -c DLF.Options.GUI 550
  if (%DLF.dccsend.nocomchan == 1) did -c DLF.Options.GUI 555
  if (%DLF.dccsend.untrusted == 1) did -c DLF.Options.GUI 560
  if (%DLF.dccsend.regular == 1) did -c DLF.Options.GUI 565
  if (%DLF.serverretry == 1) did -c DLF.Options.GUI 570
  if (%DLF.checksecurity == 1) did -c DLF.Options.GUI 610
  if (%DLF.private.query == 1) did -c DLF.Options.GUI 615
  if (%DLF.private.nocomchan == 1) did -c DLF.Options.GUI 620
  if (%DLF.private.regular == 1) did -c DLF.Options.GUI 625
  if (%DLF.chanctcp == 1) did -c DLF.Options.GUI 655
  if (%DLF.nofingers == 1) did -c DLF.Options.GUI 660
  if (%DLF.win-onotice.enabled == 1) did -c DLF.Options.GUI 715
  if (%DLF.opwarning.spamchan == 1) did -c DLF.Options.GUI 725
  if (%DLF.opwarning.spampriv == 1) did -c DLF.Options.GUI 730
  if (%DLF.ops.advertchan == 1) did -c DLF.Options.GUI 760
  did -ra DLF.Options.GUI 765 %DLF.ops.advertchan.period
  if (%DLF.ops.advertpriv == 1) did -c DLF.Options.GUI 780
  if (%DLF.custom.enabled == 1) did -c DLF.Options.GUI 810
  DLF.Options.InitChannelList
  DLF.Options.InitCustomList
  DLF.Options.SetLinkedFields
  DLF.Update.Run
  DLF.Options.About
}

alias -l DLF.Options.LinkedFields {
  var %state = $did($abs($1)).state
  if ($1 > 0) var %flags = $iif(%state,-e,-ub)
  else var %flags = $iif(%state,-cb,-e)
  var %ctrls = $replace($2-,$space,$comma)
  did %flags DLF.Options.GUI %ctrls
}

alias -l DLF.Options.Save {
  DLF.Chan.Set %DLF.netchans
  %DLF.enabled = $did(10).state
  DLF.Groups.Events
  %DLF.showfiltered = $did(40).state
  %DLF.update.betas = $did(190).state
  %DLF.filter.requests = $did(310).state
  %DLF.filter.ads = $did(315).state
  %DLF.serverads = $did(320).state
  %DLF.filter.modeschan = $did(325).state
  %DLF.filter.spamchan = $did(330).state
  %DLF.filter.spampriv = $did(335).state
  %DLF.spam.addignore = $did(340).state
  %DLF.filter.controlcodes = $did(345).state
  %DLF.filter.nonalpha = $did(350).state
  %DLF.filter.topic = $did(355).state
  %DLF.serverwin = $did(360).state
  %DLF.private.requests = $did(365).state
  %DLF.perconnect = $did(370).state
  %DLF.filter.joins = $did(380).state
  %DLF.filter.parts = $did(382).state
  %DLF.filter.quits = $did(384).state
  %DLF.filter.nicks = $did(386).state
  %DLF.filter.kicks = $did(388).state
  %DLF.filter.aways = $did(390).state
  %DLF.filter.modesuser = $did(395).state
  %DLF.searchresults = $did(510).state
  %DLF.titlebar.stats = $did(525).state
  %DLF.colornicks = $did(530).state
  %DLF.dccsend.autoaccept = $did(540).state
  %DLF.dccsend.requested = $did(550).state
  %DLF.dccsend.dangerous = $did(550).state
  %DLF.dccsend.nocomchan = $did(555).state
  %DLF.dccsend.untrusted = $did(560).state
  %DLF.dccsend.regular = $did(565).state
  %DLF.serverretry = $did(570).state
  %DLF.checksecurity = $did(610).state
  %DLF.private.query = $did(615).state
  %DLF.private.nocomchan = $did(620).state
  %DLF.private.regular = $did(625).state
  %DLF.chanctcp = $did(655).state
  %DLF.nofingers = $did(660).state
  %DLF.win-onotice.enabled = $did(715).state
  %DLF.opwarning.spamchan = $did(725).state
  %DLF.opwarning.spampriv = $did(730).state
  %DLF.ops.advertchan = $did(760).state
  %DLF.ops.advertchan.period = $did(765)
  %DLF.ops.advertpriv = $did(780).state
  DLF.Ops.AdvertsEnable
  %DLF.custom.enabled = $did(810).state
  DLF.Options.SetLinkedFields
  saveini
}

alias -l DLF.Options.OpsTab {
  ; Disable Ops Tab if all ops options are off and not ops in any dlF channels
  did $iif($DLF.Options.IsOp,-e,-b) DLF.Options.GUI 715,725,730,760,765,770,780
}

alias -l DLF.Options.IsOp {
  var %cid = $cid
  var %i = $Scon(0)
  while (%i) {
    scid $scon(%i)
    var %j = $chan(0)
    while (%j) {
      if ($me isop $chan(%j)) {
        scid %cid
        return $true
      }
      dec %j
    }
    dec %i
  }
  scid %cid
  return $false
}

alias -l DLF.Options.PerConnection {
  close -a@ @dlF.Filter.*
  close -a@ @dlF.FilterSearch.*
  close -a@ @dlF.Server.*
  close -a@ @dlF.ServerSearch.*
  close -a@ @dlF.Ads.*
  DLF.Options.Save
  DLF.Stats.Active
}

alias -l DLF.Options.Titlebar {
  DLF.Options.Save
  DLF.Stats.Active
}

alias -l DLF.Options.ClickOption {
  DLF.Options.Save
  if (%DLF.showfiltered == 0) close -@ @dlF.Filter*.*
  if (($did == 190) && (!$sock(DLF.Socket.Update))) DLF.Update.CheckVersions
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
  did -r DLF.Options.GUI 120
  DLF.Options.SetAddChannelButton
  var %numchans = $numtok(%netchans,$asc($space)), %i = 1
  while (%i <= %numchans) {
    var %netchan = $gettok(%netchans,%i,$asc($space))
    if ($istok(%DLF.netchans,%netchan,$asc($comma)) == $false) {
      if (%onenet) %netchan = $+($hashtag,$gettok(%netchan,2,$asc($hashtag)))
      did -a DLF.Options.GUI 120 %netchan
    }
    inc %i
  }

  ; Populate list of filtered channels
  did -r DLF.Options.GUI 140
  var %numchans = $numtok(%DLF.netchans,$asc($comma)), %i = 1
  while (%i <= %numchans) {
    var %netchan = $gettok(%DLF.netchans,%i,$asc($comma))
    if ($left(%netchan,1) == $hashtag) var %chan = %netchan
    else var %chan = $iif(%onenet,$+($hashtag,$gettok(%netchan,2,$asc($hashtag))),%netchan)
    did -a DLF.Options.GUI 140 %chan
    inc %i
  }
}

alias -l DLF.Options.SetAddChannelButton {
  if ($did(120)) did -te DLF.Options.GUI 130
  else {
    did -b DLF.Options.GUI 130
    did -t DLF.Options.GUI 30
  }
}

alias -l DLF.Options.SetRemoveChannelButton {
  if ($did(140,0).sel > 0) did -te DLF.Options.GUI 135
  else {
    did -b DLF.Options.GUI 135
    DLF.Options.SetAddChannelButton
  }
}

alias -l DLF.Options.AddChannel {
  var %chan = $did(120).text
  if ($pos(%chan,$hashtag,0) == 0) %chan = $hashtag $+ %chan
  if (($scon(0) == 1) && ($left(%chan,1) == $hashtag)) %chan = $network $+ %chan
  DLF.Chan.Add %chan
  ; Clear edit field, list selection and disable add button
  DLF.Options.InitChannelList
}

alias -l DLF.Options.RemoveChannel {
  var %i = $did(140,0).sel
  while (%i) {
    DLF.Chan.Remove $did(140,$did(140,%i).sel).text
    dec %i
  }
  did -b DLF.Options.GUI 135
  DLF.Options.InitChannelList
}

alias -l DLF.Options.EditChannel {
  if ($did(140,0).sel == 1 ) {
    var %chan = $did(140,$did(140,1).sel).text
    DLF.Options.RemoveChannel
    DLF.Options.InitChannelList
    did -o DLF.Options.GUI 120 0 %chan
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

alias -l DLF.Options.SetAddCustomButton {
  if ($did(840)) did -te DLF.Options.GUI 850
  else {
    did -b DLF.Options.GUI 850
    did -t DLF.Options.GUI 30
  }
}

alias -l DLF.Options.SetRemoveCustomButton {
  if ($did(870,0).sel > 0) did -te DLF.Options.GUI 860
  else {
    did -b DLF.Options.GUI 860
    DLF.Options.SetAddCustomButton
  }
}

alias -l DLF.Options.AddCustom {
  var %selected = $did(830).seltext
  var %new = $did(840).text
  if (* !isin %new) var %new = $+(*,%new,*)
  DLF.Custom.Add %selected %new
  ; Clear edit field, list selection and disable add button
  did -r DLF.Options.GUI 840
  DLF.Options.SetAddCustomButton
  DLF.Options.SetCustomType
}

alias -l DLF.Options.RemoveCustom {
  var %selected = $did(830).seltext
  var %i = $did(870,0).sel
  while (%i) {
    DLF.Custom.Remove %selected $did(870,$did(870,%i).sel).text
    dec %i
  }
  did -b DLF.Options.GUI 860
  DLF.Options.SetCustomType
  DLF.Options.SetRemoveButton
}

alias -l DLF.Options.EditCustom {
  if ($did(870,0).sel == 1 ) {
    did -o DLF.Options.GUI 840 1 $did(870,$did(870,1).sel).text
    DLF.Options.RemoveCustom
    DLF.Options.SetAddCustomButton
  }
}

alias -l DLF.Options.DownloadUpdate {
  did -b DLF.Options.GUI 180
  DLF.Download.Run
}

alias -l DLF.Options.Status {
  if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 160 1 $1-
  DLF.StatusAll $1-
}

alias -l DLF.Options.Error {
}

; ========== Check version for updates ==========
; Check once per week for normal releases and once per day if user is wanting betas
alias -l DLF.Update.Check {
  var %days = $calc($int(($ctime - %DLF.update.lastcheck) / 60 / 60 / 24))
  if ((%days >= 7) || ((%DLF.update.betas) && (%days >= 1))) DLF.Update.Run
}

alias -l DLF.Update.Run {
  if ($dialog(DLF.Options.GUI)) did -b DLF.Options.GUI 180
  DLF.Options.Status Checking for dlFilter updates...
  DLF.Socket.Get Update https://raw.githubusercontent.com/SanderSade/dlFilter/master/dlFilter.version
}

on *:sockread:DLF.Socket.Update: {
  DLF.Socket.Headers
  var %line, %mark = $sock($sockname).mark
  var %state = $gettok(%mark,1,$asc($space))
  if (%state != Body) DLF.Socket.Error Cannot process response: Still processing %state
  unset %DLF.version.web
  unset %DLF.version.web.mirc
  unset %DLF.version.beta
  unset %DLF.version.beta.mirc
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
    set %DLF.update.lastcheck $ctime
  }
  elseif ($gettok($1-,1,$asc($eq)) == dlFilter.beta) {
    %DLF.version.beta = $gettok($1-,2,$asc($eq))
    %DLF.version.beta.mirc = $gettok($1-,3,$asc($eq))
  }
}

alias -l DLF.Update.CheckVersions {
  if ($dialog(DLF.Options.GUI)) did -b DLF.Options.GUI 180
  if (%DLF.version.web) {
    if ((%DLF.update.betas) $&
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
    did -e DLF.Options.GUI 180
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
        var %netchan = $gettok(%DLF.netchans,%cnt,$asc($comma))
        var %net = $gettok(%netchan,1,$asc($hashtag))
        if (%net == $null) var %chan = %netchan
        else var %chan = $hashtag $+ $gettok(%netchan,2,$asc($hashtag))
        if (((%net == $null) || (%net == $network)) && ($chan(%chan))) DLF.Update.ChanAnnounce %chan $1 $2 $3
        dec %cnt
      }
    }
    dec %nets
  }
  scid %cid
}

; Announce new version whenever user joins an enabled channel.
alias -l DLF.Update.Announce {
  DLF.Watch.Called DLF.Update.Announce
  if (%DLF.version.web) {
    if ((%DLF.update.betas) $&
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
  var %branch = master
  if ((%DLF.update.betas == 1) && (%DLF.version.beta > %DLF.version.web)) %branch = beta
  DLF.Socket.Get Download $+(https:,//raw.githubusercontent.com/SanderSade/dlFilter/,%branch,/dlFilter.mrc)
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
  if (%oldsaved) DLF.StatusAll Old version of dlFilter.mrc saved as %oldscript in case you need to revert
  signal DLF.Initialise
  .reload -rs1 $script
}

alias -l DLF.Download.Error {
  DLF.Update.ErrorMsg Unable to download new version of dlFilter!
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
  var %re = /^(?:(https?)(?::\/\/))?([^\s\/]+)(.*)$/F
  if ($regex(DLF.Socket.Get,$2,%re) !isnum 1-) DLF.Socket.Error Invalid url: %2

  var %protocol = $regml(DLF.Socket.Get,1)
  var %hostport = $regml(DLF.Socket.Get,2)
  var %path = $regml(DLF.Socket.Get,3)
  var %host = $gettok(%hostport,1,$asc(:))
  var %port = $gettok(%hostport,2,$asc(:))

  if (%protocol == $null) %protocol = http
  if (%path == $null) %path = /
  if (%port == $null) %port = $iif(%protocol == https,443,80)
  if (%port == 443) %protocol = https
  %hostport = $+(%host,:,$port)

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
      var %header = $gettok(%line,1,$asc(:))
      if (%header == Location) {
        var %sockname = $sockname
        sockclose $sockname
        DLF.Socket.Open %sockname $gettok(%line,2-,$asc(:)) $gettok(%mark,4-,$asc($space))
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

alias -l DLF.Socket.SockErr DLF.Socket.Error $1: $sock($sockname).wsmsg

alias -l DLF.Socket.Error {
  if ($sockname) {
    var %mark = $sock($sockname).mark
    var %msg = $+($sockname,: http,$iif($sock($sockname).ssl,s),://,$gettok(%mark,2,$asc($space)),$gettok(%mark,3,$asc($space)),:) $1-
    sockclose $sockname
    if ($dialog(DLF.Options.GUI)) did -o DLF.Options.GUI 160 1 Communications error whilst $1-
    DLF.Error %msg
  }
  else DLF.Error $1-
}

; ========== Create dlFilter.gif if needed ==========
alias -l DLF.CreateGif {
  bset -ta &gif 1 eJxz93SzsEwUYBBg+M4AArpO837sZhgFo2AEAsWfLIwMDP8ZdEAcUJ5g4PBn
  bset -ta &gif 61 +M8p47Eh4SAD4z9FkwqDh05tzOJ2LSsCGo52S7ByuHQYJLu1yghX7fkR8MiD
  bset -ta &gif 121 UVWWTWKm0JP9/brycT0SQinu3Syqt2I6Jz86MNOOlYmXy0SBwRoAZQAkYg==
  DLF.CreateBinaryFile &gif $+($nofile($script),dlFilter.gif)
}

; ========== Define message matching hash tables ==========
alias -l hiswm {
  var %h = DLF. $+ $1
  if (!$hget(%h)) {
    DLF.Warning Hash table %h does not exist - attempting to recreate it...
    DLF.CreateHashTables
  }
  var %result = $hfind(%h,$2,1,W).data
  if (%result) %result = $hget(%h,%result)
  ; There is no case sensitive hfind wildcard search, so we need to check that it matches case sensitively.
  ; if ((%result) && (%result !iswmcs $2)) %result = $null
  if (%result) DLF.Watch.Log Matched in $1 by $qt(%result)
  return %result
}

alias -l DLF.hadd {
  var %h = DLF. $+ $1
  if (!$hget(%h)) hmake %h 10
  var %n = $hget(%h, 0).item
  inc %n
  hadd %h i $+ %n $2-
}

alias -l DLF.CreateHashTables {
  var %matches = 0

  if ($hget(DLF.chantext.cmds)) hfree DLF.chantext.cmds
  DLF.hadd chantext.cmds !*
  DLF.hadd chantext.cmds @*
  ; mistypes
  DLF.hadd chantext.cmds quit
  DLF.hadd chantext.cmds exit
  DLF.hadd chantext.cmds :quit
  DLF.hadd chantext.cmds :exit
  inc %matches $hget(DLF.chantext.cmds,0).item

  if ($hget(DLF.chantext.ads)) hfree DLF.chantext.ads
  DLF.hadd chantext.ads * CSE Fact *
  DLF.hadd chantext.ads *@*DragonServe*
  DLF.hadd chantext.ads *@*Finålity*
  DLF.hadd chantext.ads *@*SDFind*
  DLF.hadd chantext.ads *Enter @*to see the menu*
  DLF.hadd chantext.ads *Escribe*!*
  DLF.hadd chantext.ads *Escribe*@*
  DLF.hadd chantext.ads *File Server Online*Triggers*Sends*Queues*
  DLF.hadd chantext.ads *File Servers Online*Polaris*
  DLF.hadd chantext.ads *File Servers Online*Trigger*Accessed*Served*
  DLF.hadd chantext.ads *Files In List*slots open*Queued*Next Send*
  DLF.hadd chantext.ads *Files*free Slots*Queued*Speed*Served*
  DLF.hadd chantext.ads *For my list of * files type*@*
  DLF.hadd chantext.ads *For my list*files*type @*
  DLF.hadd chantext.ads *For My Top Download Hit-chart, type @*
  DLF.hadd chantext.ads *Type*@* for my list*
  DLF.hadd chantext.ads *Type*@* to get my list*
  DLF.hadd chantext.ads *FTP service*FTP*port*bookz*
  DLF.hadd chantext.ads *FTP*address*port*login*password*
  DLF.hadd chantext.ads *I have sent a total of*files and leeched a total of*since*
  DLF.hadd chantext.ads *I have spent a total time of*sending files and a total time of*recieving files*
  DLF.hadd chantext.ads List*@*
  DLF.hadd chantext.ads Search: * Mode:*
  DLF.hadd chantext.ads *Statistici 1*by Un_DuLciC*
  DLF.hadd chantext.ads *Tape*@*
  DLF.hadd chantext.ads *Tapez*Pour avoir ce Fichier*
  DLF.hadd chantext.ads *Tapez*Pour*Ma Liste De*Fichier En Attente*
  DLF.hadd chantext.ads *Tasteazã*@*
  DLF.hadd chantext.ads *Teclea: @*
  DLF.hadd chantext.ads *Total Offered*Files*Total Sent*Files*Total Sent Today*Files*
  DLF.hadd chantext.ads *Trigger*@*
  DLF.hadd chantext.ads *Trigger*ctcp*
  DLF.hadd chantext.ads *Total*File Transfer in Progress*slot*empty*
  DLF.hadd chantext.ads *Type @* list of *
  DLF.hadd chantext.ads *[BWI]*@*
  DLF.hadd chantext.ads @ * is now open via ftp @*
  DLF.hadd chantext.ads @ --*
  DLF.hadd chantext.ads @ Use @*
  DLF.hadd chantext.ads *QNet Advanced DCC File Server*Sharing *B of stuff!*
  inc %matches $hget(DLF.chantext.ads,0).item

  if ($hget(DLF.chantext.announce)) hfree DLF.chantext.announce
  DLF.hadd chantext.announce *§ÐfíñÐ âÐÐ-øñ§*
  DLF.hadd chantext.announce *« Ë×Çü®§îöñ »*
  DLF.hadd chantext.announce *away*since*pager*
  DLF.hadd chantext.announce *Back*Duration*
  DLF.hadd chantext.announce *BJFileTracker V06 by BossJoe*
  DLF.hadd chantext.announce *Combined channel status:*
  DLF.hadd chantext.announce *DCC Send Failed of*to*Starting next in Que*
  DLF.hadd chantext.announce *get - from*at*cps*complete*
  DLF.hadd chantext.announce *HêåvêñlyAway*
  DLF.hadd chantext.announce *has just received*for a total of*
  DLF.hadd chantext.announce *have just finished recieving*from*I have leeched a total*
  DLF.hadd chantext.announce *I am AWAY*Reason*I have been Away for*
  DLF.hadd chantext.announce *I am AWAY*Reason*To page me*
  DLF.hadd chantext.announce *I have just finished receiving*from*
  DLF.hadd chantext.announce *I have just finished sending * to *
  DLF.hadd chantext.announce *I have just finished receiving*from*have now received a total*
  DLF.hadd chantext.announce *I have just received*from*for a total of*KeepTrack*
  DLF.hadd chantext.announce *I have just received*from*leeched since*
  DLF.hadd chantext.announce *Je viens juste de terminer de recevoir*de*Prenez-en un vite*
  DLF.hadd chantext.announce *Just Sent To*Filename*Slots Free*Queued*
  DLF.hadd chantext.announce *KeepTrack*by*^OmeN*
  DLF.hadd chantext.announce *KeepTrack*de adisoru*
  DLF.hadd chantext.announce *KiLLJarX*channel policy is that we are a*
  DLF.hadd chantext.announce *Leaving*reason*auto away after*
  DLF.hadd chantext.announce *Message*SysReset*
  DLF.hadd chantext.announce *MisheBORG*SendStat*v.*
  DLF.hadd chantext.announce *mp3 server detected*
  DLF.hadd chantext.announce *rßPLåY2.0*
  DLF.hadd chantext.announce *rbPlay20.mrc*
  DLF.hadd chantext.announce *Receive Successful*Thanks for*
  DLF.hadd chantext.announce *Received*From*Size*Speed*Time*since*
  DLF.hadd chantext.announce *ROLL TIDE*Now Playing*mp3*
  DLF.hadd chantext.announce *sent*to*at*total sent*files*yesterday*files*today*files*
  DLF.hadd chantext.announce *sets away*auto idle away*since*
  DLF.hadd chantext.announce *Thank You*for serving in*
  DLF.hadd chantext.announce *Thanks for the +v*
  DLF.hadd chantext.announce *Thanks for the @*
  DLF.hadd chantext.announce *Thanks*for Supplying an server in*
  DLF.hadd chantext.announce *Thanks*For The*@*
  DLF.hadd chantext.announce *Thanks*For*The*Voice*
  DLF.hadd chantext.announce * to * just got timed out*slot*Empty*
  DLF.hadd chantext.announce *Tocmai am primit*KeepTrack*
  DLF.hadd chantext.announce *Total Received*Files*Total Received Today*Files*
  DLF.hadd chantext.announce *Tx TIMEOUT*
  DLF.hadd chantext.announce Type*!*.* To Get This *
  DLF.hadd chantext.announce *WaS auTo-VoiCeD THaNX FoR SHaRiNG HeRe iN*
  DLF.hadd chantext.announce *We have just finished receiving*From The One And Only*
  DLF.hadd chantext.announce *Welcome back to #* operator*.*
  DLF.hadd chantext.announce *YAY* Another brave soldier in the war to educate the masses*Onward Comrades*
  DLF.hadd chantext.announce *[Away]*SysReset*
  DLF.hadd chantext.announce *[F][U][N]*
  DLF.hadd chantext.announce Request * —I-n-v-i-s-i-o-n—
  DLF.hadd chantext.announce *Tape*!*.mp3*
  DLF.hadd chantext.announce *Tape*!*MB*
  DLF.hadd chantext.announce *!*.mp3*SpR*
  DLF.hadd chantext.announce *!*MB*Kbps*Khz*
  DLF.hadd chantext.announce *Sent*to*OS-Limits v*
  DLF.hadd chantext.announce *<><><*><><>*
  DLF.hadd chantext.announce *~*~SpR~*~*
  DLF.hadd chantext.announce *I have just finished recieving*from*I have now recieved a total of*
  DLF.hadd chantext.announce *I have just finished sending*.mp3 to*
  DLF.hadd chantext.announce *I have just finished sending*I have now sent a total of*files since*
  DLF.hadd chantext.announce *I have just finished sending*to*Empty*
  DLF.hadd chantext.announce *Random Play * Now Activated*
  DLF.hadd chantext.announce *-SpR-*
  DLF.hadd chantext.announce *SPr*!*.mp3*
  DLF.hadd chantext.announce *SpR*[*mp3*]*
  DLF.hadd chantext.announce *Tape*!* Pour Voir Vos Statistiques*
  DLF.hadd chantext.announce *Type*!* To Get This*
  DLF.hadd chantext.announce *Welcome * person No* to join*
  DLF.hadd chantext.announce *'s current status * Points this WEEK * Points this MONTH*
  DLF.hadd chantext.announce *- ??/??/????  *  Ajouté par *
  DLF.hadd chantext.announce *Mode: Normal*
  DLF.hadd chantext.announce ø
  DLF.hadd chantext.announce *Je Vient Juste De Reçevoir * De La Pars De * Pour Un Total De * Fichier(s)*
  DLF.hadd chantext.announce *The fastest Average Send Speeds captured last hour are*
  DLF.hadd chantext.announce *Todays Most Popular Servers - as of *
  DLF.hadd chantext.announce *Todays Top Leechers - as of *
  DLF.hadd chantext.announce *I have just voiced * for being kewl And sharing*
  DLF.hadd chantext.announce *I-n-v-i-s-i-o-n*
  DLF.hadd chantext.announce *¥*Mp3s*¥*
  DLF.hadd chantext.announce *§*DCC Send Failed*to*§*
  DLF.hadd chantext.announce *§kÎn§*ßy*§hådõ*
  DLF.hadd chantext.announce *©§©*
  DLF.hadd chantext.announce *« * » -*
  DLF.hadd chantext.announce *«Scøøp MP3»*
  DLF.hadd chantext.announce *±*
  DLF.hadd chantext.announce *» Port «*»*
  DLF.hadd chantext.announce *- DCC Transfer Status -*
  DLF.hadd chantext.announce *--PepsiScript--*
  DLF.hadd chantext.announce *-SpR skin used by PepsiScript*
  DLF.hadd chantext.announce *.mp3*t×PLåY6*
  DLF.hadd chantext.announce *a recu*pour un total de*fichiers*
  DLF.hadd chantext.announce *Bandwith*Usage*Current*Record*
  DLF.hadd chantext.announce *Control*IRC Client*CTCPSERV*
  DLF.hadd chantext.announce *DCC GET COMPLETE*from*slot*open*
  DLF.hadd chantext.announce *DCC SEND COMPLETE*to*slot*
  DLF.hadd chantext.announce *DCC Send Failed of*to*
  DLF.hadd chantext.announce *Download this exciting book*
  DLF.hadd chantext.announce *failed*DCC Send Failed of*to*failed*
  DLF.hadd chantext.announce *I am opening up*more slot*Taken*
  DLF.hadd chantext.announce *I am using*SpR JUKEBOX*http://spr.darkrealms.org*
  DLF.hadd chantext.announce *is playing*info*secs*
  DLF.hadd chantext.announce *Je viens juste de terminer l'envoi de*Prenez-en un vite*
  DLF.hadd chantext.announce *just left*Sending file Aborted*
  DLF.hadd chantext.announce *left irc and didn't return in*min. Sending file Aborted*
  DLF.hadd chantext.announce *left*and didn't return in*mins. Sending file Aborted*
  DLF.hadd chantext.announce *Now Sending*QwIRC*
  DLF.hadd chantext.announce *OmeNServE*©^OmeN^*
  DLF.hadd chantext.announce *Proofpack Server*Looking for new scans to proof*@proofpack for available proofing packs*
  DLF.hadd chantext.announce *rßP£a*sk*n*
  DLF.hadd chantext.announce *rßPLåY*
  DLF.hadd chantext.announce *Random Play MP3 filez Now Plugged In*
  DLF.hadd chantext.announce *Random Play MP3*Now Activated*
  DLF.hadd chantext.announce *Rank*~*x*~*
  DLF.hadd chantext.announce *send - to*at*cps*complete*left*
  DLF.hadd chantext.announce *sent*to*size*speed*time*sent*
  DLF.hadd chantext.announce *Softwind*Softwind*
  DLF.hadd chantext.announce *SpR JUKEBOX*filesize*
  DLF.hadd chantext.announce *Successfully*Tx.Track*
  DLF.hadd chantext.announce *tìnkërßëll`s collection*Love Quotes*
  DLF.hadd chantext.announce *The Dcc Transfer to*has gone under*Transfer*
  DLF.hadd chantext.announce *There is a Slot Opening*Grab it Fast*
  DLF.hadd chantext.announce *There is a*Open*Say's Grab*
  DLF.hadd chantext.announce *To serve and to be served*@*
  DLF.hadd chantext.announce *User Slots*Sends*Queues*Next Send Available*¤UControl¤*
  DLF.hadd chantext.announce *vient d'etre interrompu*Dcc Libre*
  DLF.hadd chantext.announce *Welcome to #*, we have * detected servers online to serve you*
  DLF.hadd chantext.announce *Wireless*mb*br*
  DLF.hadd chantext.announce *[Fserve Active]*
  DLF.hadd chantext.announce *[Mp3xBR]*
  inc %matches $hget(DLF.chantext.announce,0).item

  if ($hget(DLF.chantext.always)) hfree DLF.chantext.always
  DLF.hadd chantext.always "find *
  DLF.hadd chantext.always #find *
  DLF.hadd chantext.always quit
  DLF.hadd chantext.always exit
  DLF.hadd chantext.always *- *.?? K
  DLF.hadd chantext.always *- *.?? M
  DLF.hadd chantext.always *- *.?? KB
  DLF.hadd chantext.always *- *.?? MB
  DLF.hadd chantext.always *- *.? KB
  DLF.hadd chantext.always *- *.? MB
  DLF.hadd chantext.always ---*KB*s*
  DLF.hadd chantext.always ---*MB*s*
  DLF.hadd chantext.always 2find *
  DLF.hadd chantext.always Sign in to turn on 1-Click ordering.
  DLF.hadd chantext.always * ::INFO:: *.*KB
  DLF.hadd chantext.always * ::INFO:: *.*MB
  inc %matches $hget(DLF.chantext.always,0).item

  if ($hget(DLF.chantext.dlf)) hfree DLF.chantext.dlf
  DLF.hadd chantext.dlf $strip($DLF.logo) *
  inc %matches $hget(DLF.chantext.dlf,0).item

  if ($hget(DLF.chanaction.away)) hfree DLF.chanaction.away
  DLF.hadd chanaction.away *asculta*
  DLF.hadd chanaction.away *Avertisseur*Journal*
  DLF.hadd chanaction.away *está away*pager*
  DLF.hadd chanaction.away *has returned from*I was gone for*
  DLF.hadd chanaction.away *has stumbled to the channel couch*Couch v*by Kavey*
  DLF.hadd chanaction.away *has taken a seat on the channel couch*Couch v*by Kavey*
  DLF.hadd chanaction.away *I Have Send My List*Times*Files*Times*
  DLF.hadd chanaction.away *I-n-v-i-s-i-o-n*
  DLF.hadd chanaction.away *is AWAY*auto-away*
  DLF.hadd chanaction.away *is away*Reason*since*
  DLF.hadd chanaction.away *is BACK from*away*
  DLF.hadd chanaction.away *is back from*Gone*
  DLF.hadd chanaction.away *is currently boogying away to*
  DLF.hadd chanaction.away *is gone. Away after*minutes of inactivity*
  DLF.hadd chanaction.away *is listening to*Kbps*KHz*
  DLF.hadd chanaction.away *Now*Playing*Kbps*KHz*
  DLF.hadd chanaction.away *sets away*Auto Idle Away after*
  DLF.hadd chanaction.away *Type Or Copy*Paste*To Get This Song*
  DLF.hadd chanaction.away *uses cracked software*I will respond to the following commands*
  DLF.hadd chanaction.away *way*since*pager*
  DLF.hadd chanaction.away *[Backing Up]*
  inc %matches $hget(DLF.chanaction.away,0).item

  if ($hget(DLF.chanaction.spam)) hfree DLF.chanaction.spam
  DLF.hadd chanaction.spam *FTP*port*user*pass*
  DLF.hadd chanaction.spam *get AMIP*plug-in at http*amip.tools-for.net*
  inc %matches $hget(DLF.chanaction.spam,0).item

  if ($hget(DLF.channotice.spam)) hfree DLF.channotice.spam
  DLF.hadd channotice.spam *free-download*
  DLF.hadd channotice.spam *WWW.TURKSMSBOT.CJB.NET*
  inc %matches $hget(DLF.channotice.spam,0).item

  if ($hget(DLF.chanctcp.spam)) hfree DLF.chanctcp.spam
  DLF.hadd chanctcp.spam *ASF*
  DLF.hadd chanctcp.spam *MP*
  DLF.hadd chanctcp.spam *RAR*
  DLF.hadd chanctcp.spam *SOUND*
  DLF.hadd chanctcp.spam *WMA*
  DLF.hadd chanctcp.spam *SLOTS*
  inc %matches $hget(DLF.chanctcp.spam,0).item

  if ($hget(DLF.chanctcp.server)) hfree DLF.chanctcp.server
  DLF.hadd chanctcp.server *OmeNServE*
  inc %matches $hget(DLF.chanctcp.server,0).item

  if ($hget(DLF.privtext.spam)) hfree DLF.privtext.spam
  DLF.hadd privtext.spam *http*sex*
  DLF.hadd privtext.spam *http*xxx*
  DLF.hadd privtext.spam *porn*http*
  DLF.hadd privtext.spam *sex*http*
  DLF.hadd privtext.spam *sex*www*
  DLF.hadd privtext.spam *www*sex*
  DLF.hadd privtext.spam *www*xxx*
  DLF.hadd privtext.spam *xxx*http*
  DLF.hadd privtext.spam *xxx*www*
  inc %matches $hget(DLF.privtext.spam,0).item

  if ($hget(DLF.privtext.server)) hfree DLF.privtext.server
  DLF.hadd privtext.server *Empieza transferencia*IMPORTANTE*dccallow*
  DLF.hadd privtext.server *I don't have*Please check your spelling or get my newest list by typing @* in the channel*
  DLF.hadd privtext.server *Petición rechazada*DragonServe*
  DLF.hadd privtext.server *Please standby for acknowledgement. I am using a secure query event*
  DLF.hadd privtext.server *Queue Status*File*Position*Waiting Time*OmeNServE*
  DLF.hadd privtext.server *Request Denied*OmeNServE*
  DLF.hadd privtext.server *Request Denied*Reason: *DragonServe*
  DLF.hadd privtext.server *Sorry for cancelling this send*OmeNServE*
  DLF.hadd privtext.server *Sorry, I'm too busy to send my list right now, please try later*
  DLF.hadd privtext.server After * min(s) in my * queue, * is *
  DLF.hadd privtext.server You already have * in my queue*
  DLF.hadd privtext.server You have * files in my * queue*
  DLF.hadd privtext.server I have successfully sent you*OS*
  DLF.hadd privtext.server Lo Siento, no te puedo enviar mi lista ahora, intenta despues*
  DLF.hadd privtext.server Lo siento, pero estoy creando una nueva lista ahora*
  DLF.hadd privtext.server Sorry, I'm making a new list right now, please try later*
  inc %matches $hget(DLF.privtext.server,0).item

  if ($hget(DLF.privtext.away)) hfree DLF.privtext.away
  DLF.hadd privtext.away *AFK, auto away after*minutes. Gone*
  DLF.hadd privtext.away *automated msg*
  DLF.hadd privtext.away *Away*Reason*Auto Away*
  DLF.hadd privtext.away *Away*Reason*Duration*
  DLF.hadd privtext.away *Away*Reason*Gone for*Pager*
  DLF.hadd privtext.away *Away*SysReset*
  DLF.hadd privtext.away *Dacia Script v1.2*
  DLF.hadd privtext.away *If i didn't know any better*I would have thought you were flooding me*
  DLF.hadd privtext.away *Message's from strangers are Auto-Rejected*
  DLF.hadd privtext.away *^Auto-Thanker^*
  inc %matches $hget(DLF.privtext.away,0).item

  if ($hget(DLF.privnotice.server)) hfree DLF.privnotice.server
  DLF.hadd privnotice.server *«OmeN»*
  DLF.hadd privnotice.server *«SoftServe»*
  DLF.hadd privnotice.server *«[RDC]»*
  DLF.hadd privnotice.server *±*
  DLF.hadd privnotice.server *AFK, auto away after*minutes*
  DLF.hadd privnotice.server After * min(s) in my * queue, *
  DLF.hadd privnotice.server After waiting*min*
  DLF.hadd privnotice.server *Ahora has recibido*DragonServe*
  DLF.hadd privnotice.server *archivos, Disfrutalo*
  DLF.hadd privnotice.server *DCC Get of*FAILED Please Re-Send file*
  DLF.hadd privnotice.server *de mi lista de espera*
  DLF.hadd privnotice.server *Después de esperar*min*
  DLF.hadd privnotice.server *Empieza transferencia*DragonServe*
  DLF.hadd privnotice.server *Envío completo*DragonServe*
  DLF.hadd privnotice.server *Enviando*(*)*
  DLF.hadd privnotice.server *Envio cancelado*
  DLF.hadd privnotice.server *esta en camino!*
  DLF.hadd privnotice.server *file not located*
  DLF.hadd privnotice.server *File Transfer of*
  DLF.hadd privnotice.server *Gracias*Ahora he recibido*DragonServe*
  DLF.hadd privnotice.server *Has Been Placed In The Priority Queue At Position*Omenserve*
  DLF.hadd privnotice.server *has been sent successfully*
  DLF.hadd privnotice.server *has been sent sucessfully*
  DLF.hadd privnotice.server *I don't have the file*
  DLF.hadd privnotice.server *I have added*
  DLF.hadd privnotice.server *I'm currently away*your message has been logged*
  DLF.hadd privnotice.server *If your message is urgent, you may page me by typing*PAGE*
  DLF.hadd privnotice.server *is not found*
  DLF.hadd privnotice.server *is on it's way!*
  DLF.hadd privnotice.server *is on its way*
  DLF.hadd privnotice.server *is on the way!*
  DLF.hadd privnotice.server *Keeptrack*omen*
  DLF.hadd privnotice.server *Le Transfert de*Est Completé*
  DLF.hadd privnotice.server *Now I have received*DragonServe*
  DLF.hadd privnotice.server *OmeNServE v*
  DLF.hadd privnotice.server *on its way*
  DLF.hadd privnotice.server *OS-Limites V*t×PLåY*
  DLF.hadd privnotice.server *OS-Limits*
  DLF.hadd privnotice.server *Please make a resume request!*
  DLF.hadd privnotice.server *Please reinitiate File-transfer!*
  DLF.hadd privnotice.server *Query refused*in*seconds*
  DLF.hadd privnotice.server *rßPLåY2*
  DLF.hadd privnotice.server *Request Accepted*File*Queue position*
  DLF.hadd privnotice.server *Request Accepted*List Has Been Placed In The Priority Queue At Position*
  DLF.hadd privnotice.server Request Accepted*Has Been Placed In The Priority Queue At Position*
  DLF.hadd privnotice.server *Request Denied*
  DLF.hadd privnotice.server *request for*acknowledged*send will be initiated as soon as possible*
  DLF.hadd privnotice.server *Requested File's*
  DLF.hadd privnotice.server *Send Complete*File*Sent*times*
  DLF.hadd privnotice.server *Send Failed*at*Please make a resume request*
  DLF.hadd privnotice.server *send will be initiated as soon as possible*
  DLF.hadd privnotice.server *Sent*Files Allowed per day*User Class*BWI-Limits*
  DLF.hadd privnotice.server *Starting Transfer*DragonServe*
  DLF.hadd privnotice.server *t×PLÅY*
  DLF.hadd privnotice.server *t×PLåY*
  DLF.hadd privnotice.server *Thank You*I have now received*file*from you*for a total of*
  DLF.hadd privnotice.server *Thanks For File*It is File*That I have recieved*
  DLF.hadd privnotice.server *Thanks*for sharing*with me*
  DLF.hadd privnotice.server *This makes*times*
  DLF.hadd privnotice.server *Transfer Complete*I have successfully sent*QwIRC
  DLF.hadd privnotice.server *Transfer Complete*sent*
  DLF.hadd privnotice.server *Transfer Started*File*
  DLF.hadd privnotice.server *Transmision de*finalizada*
  DLF.hadd privnotice.server *U Got A File From Me*files since*
  DLF.hadd privnotice.server *Unable to locate any files with*associated within them*
  DLF.hadd privnotice.server *veces que env*
  DLF.hadd privnotice.server *veces que he enviado*
  DLF.hadd privnotice.server *You Are Downloader Number*Overall Downloader Number*
  DLF.hadd privnotice.server *You are in*
  DLF.hadd privnotice.server *You are the successful downloader number*
  DLF.hadd privnotice.server You have * files in my * queue
  DLF.hadd privnotice.server *You have now received*from me*for a total of*sent since*
  DLF.hadd privnotice.server *Your send of*was successfully completed*
  DLF.hadd privnotice.server *zip va en camino*
  DLF.hadd privnotice.server Thank you for*.*!
  inc %matches $hget(DLF.privnotice.server,0).item

  if ($hget(DLF.privnotice.dnd)) hfree DLF.privnotice.dnd
  DLF.hadd privnotice.dnd *CTCP flood detected, protection enabled*
  DLF.hadd privnotice.dnd *SLOTS My mom always told me not to talk to strangers*
  inc %matches $hget(DLF.privnotice.dnd,0).item

  if ($hget(DLF.Priv.ctcpReply)) hfree DLF.Priv.ctcpReply
  DLF.hadd ctcp.reply *ERRMSG*
  DLF.hadd ctcp.reply *MP3*
  DLF.hadd ctcp.reply *SLOTS*
  inc %matches $hget(DLF.Priv.ctcpReply,0).item

  if ($hget(DLF.find.header)) hfree DLF.find.header
  DLF.hadd find.header *«SoftServe»*
  DLF.hadd find.header *@Find Results*SysReset*
  DLF.hadd find.header *End of @Find*
  DLF.hadd find.header *Fichier* Correspondant pour*Copie*
  DLF.hadd find.header *From list*found*displaying*
  DLF.hadd find.header *I have found*file*for your query*Displaying*
  DLF.hadd find.header *I have*match* for*in listfile*
  DLF.hadd find.header *I have*match*for*Copy and Paste*
  DLF.hadd find.header *I have*match*for*in listfile*
  DLF.hadd find.header *I have*matches for*You might want to get my list by typing*
  DLF.hadd find.header *J'ai Trop de Résultats Correspondants*@*
  DLF.hadd find.header *List trigger:*Slots*Next Send*CPS in use*CPS Record*
  DLF.hadd find.header *Matches for*Copy and paste in channel*
  DLF.hadd find.header *Note*Hey look at what i found!*
  DLF.hadd find.header *Note*MP3-MP3*
  DLF.hadd find.header *OmeN*Search Result*ServE*
  DLF.hadd find.header *Résultat De Recherche*OmeNServE*
  DLF.hadd find.header *Resultado Da Busca*Arquivos*Pegue A Minha Lista De*@*
  DLF.hadd find.header *Resultados De Busqueda*OmenServe*
  DLF.hadd find.header *Resultados de la búsqueda*DragonServe*
  DLF.hadd find.header *Results for your search*DragonServe*
  DLF.hadd find.header *search for*returned*results on list*
  DLF.hadd find.header *Search Result*Matches For*Copy And Paste*
  DLF.hadd find.header *Search Result*Matches For*Get My List Of*Files By Typing @*
  DLF.hadd find.header *Search Result*OmeNServE*
  DLF.hadd find.header *Search Result*Too many files*Type*
  DLF.hadd find.header *Search Results*Found*matches for*Type @*to download my list*
  DLF.hadd find.header *Search Results*QwIRC*
  DLF.hadd find.header *Searched*files and found*matching*To get a file, copy !*
  DLF.hadd find.header *SoftServe*Search result*
  DLF.hadd find.header *Tengo*coincidencia* para*
  DLF.hadd find.header *Tengo*resultado*slots*
  DLF.hadd find.header *Too many results*@*
  DLF.hadd find.header *Total de*fichier*Trouvé*
  DLF.hadd find.header *Total*files found*
  DLF.hadd find.header Found * matching files. Using: Findbot *
  DLF.hadd find.header No match found for*
  inc %matches $hget(DLF.find.header,0).item

  ; ps fileserv special responses
  if ($hget(DLF.find.fileserv)) hfree DLF.find.fileserv
  DLF.hadd find.fileserv *@find·* Searching For..::*::..
  DLF.hadd find.fileserv *found * matches* on my fserve*
  DLF.hadd find.fileserv [*] Matches found in [*] Trigger..::/ctcp *
  DLF.hadd find.fileserv *: (* *.*B)
  inc %matches $hget(DLF.find.fileserv,0).item

  if ($hget(DLF.find.headregex)) hfree DLF.find.headregex
  hmake DLF.find.headregex 10
  hadd DLF.find.headregex ^\s*From\s+list\s+(@\S+)\s+found\s+([0-9,]+),\s+displaying\s+([0-9]+):$ 1 2 3
  hadd DLF.find.headregex ^\s*Resultlimit\s+by\W+([0-9,]+)\s+reached\.\s+Download\s+my\s+list\s+for\s+more,\s+by\s+typing\s+(@\S+) 2 1 1
  hadd DLF.find.headregex ^\s*Search\s+Result\W+More\s+than\s+([0-9,]+)\s+Matches\s+For\s+(.*?)\W+Get\s+My\s+List\s+Of\s+[0-9\54]+\s+Files\s+By\s+Typing\s+(@\S+)\s+In\s+The\s+Channel\s+Or\s+Refine\s+Your\s+Search.\s+Sending\s+first\s+([0-9\54]+)\s+Results\W+OmenServe 3 1 4 2
  hadd DLF.find.headregex ^\s*Search\s+Result\W+([0-9\54]+)\s+Matches\s+For\s+(.*?)\s+Get\s+My\s+List\s+Of\s+[0-9\54]+\s+Files\s+By\s+Typing\s+(@\S+)\s+In\s+The\s+Channel\s+Or\s+Refine\s+Your\s+Search.\s+Sending\s+first\s+([0-9\54]+)\s+Results\W+OmenServe 3 1 4 2
  hadd DLF.find.headregex ^\s*Search\s+Result\s+\+\s+More\s+than\s+([0-9\54]+)\s+Matches\s+For\s+(.*?)\s+\+\s+Get\s+My\s+List\s+Of\s+[0-9\54]+\s+Files\s+By\s+Typing\s+(@\S+)\s+In\s+The\s+Channel\s+Or\s+Refine\s+Your\s+Search\.\s+Sending\s+first\s+([0-9\54]+)\s+Results 3 1 4 2
  inc %matches $hget(DLF.find.headregex,0).item

  if ($hget(DLF.find.result)) hfree DLF.find.result
  DLF.hadd find.result !*
  DLF.hadd find.result : !*
  inc %matches $hget(DLF.find.result,0).item

  DLF.StatusAll Added %matches wildcard templates
}

; ========== Status and error messages ==========
alias -l DLF.logo return $rev([dlFilter])
alias -l DLF.StatusAll {
  var %cid = $cid, %i = $scon(0)
  while (%i) {
    scid $scon(%i) DLF.Status $1-
    dec %i
  }
  scid %cid
}
alias -l DLF.Status echo -tsf $c(1,9,$DLF.logo $1-)
alias -l DLF.Warning {
  echo -taf $c(1,9,$DLF.logo Warning: $1-)
  DLF.StatusAll Warning: $1-
}
alias -l DLF.Error {
  echo -tabf $c(1,9,$DLF.logo $c(4,$b(Error:)) $1-)
  DLF.StatusAll $c(4,$b(Error:)) $1-
  halt
}

alias DLF.Run {
  DLF.Watch.Log Executing: run $1-
  run $1-
}

alias -l DLF.chan return $iif($chan != $null,$chan,Private)

alias -l DLF.TimerAddress {
  ; Use $address(nick,6) because $address(nick,5) fails if user name is >10 characters
  var %addr = $ial($nick)
  if (%addr == $null) %addr = $address($nick,6)
  if (%addr == $null) %addr = $nick
  return %addr
}

alias -l DLF.IsRegularUser {
  ;if ($1 == $me) return $false
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
    var %chan = $comchan($1,%i)
    if ($1 isop %chan) return $false
    if ($1 ishop %chan) return $false
    ; Voice only indicates non-regular user in non-moderated channels
    if (($1 isvoice %chan) && (m !isin $chan(%chan).mode)) return $false
    dec %i
  }
  return $true
}

alias -l DLF.IsOpCommon {
  var %i = $comchan($1,0)
  while (%i) {
    if ($comchan($1,%i).op) return $comchan($1,%i)
    dec %i
  }
  return $false
}

alias -l DLF.GetFileName {
  ; common (OmenServe) response has filename followed by e.g. ::INFO::
  ; and colons are not allowable characters in file names
  var %txt = $gettok($replace($strip($1-),$nbsp,$space,$tab $+ $space,$space,$tab,$null),1,$asc(:))
  var %n = $numtok(%txt,$asc($space))
  ; delete trailing info: CRC(*) or (*)
  while ($numtok(%txt,$asc($space))) {
    var %last = $gettok(%txt,-1,$asc($space))
    if (($+($lbr,*,$rbr) iswm %last) $&
     || ($+(CRC,$lbr,*,$rbr) iswm %last) $&
     || (%last isnum)) %txt = $deltok(%txt,-1,$asc($space))
    else break
  }
  %txt = $noqt(%txt)
  var %dots = $numtok(%txt,$asc(.))
  while (%dots) {
    var %type = $gettok($gettok(%txt,%dots,$asc(.)),1,$asc($space))
    if (%type isalnum) {
      var %name = $gettok(%txt,$+(1-,$calc(%dots - 1)),$asc(.))
      return $+(%name,.,%type)
    }
    dec %dots
  }
  return $null
}

alias -l DLF.RequestPeriod return 86400

; ========== mIRC extension identifiers ==========
alias -l IdentifierCalledAsAlias {
  echo $colour(Info) -s * Identifier $+($iif($left($1,1) != $,$),$1) called as alias in $nopath($script)
  halt
}

alias -l uniquetok {
  if (!$isid) IdentifierCalledAsAlias uniquetok
  var %i = $numtok($1,$2)
  if (%i < 2) return $1
  var %tok = $1
  while (%i >= 2) {
    if ($istok($gettok(%tok,$+(1-,$calc(%i - 1)),$2),$gettok(%tok,%i,$2),$2)) %tok = $deltok(%tok,%i,$2)
    dec %i
  }
  return %tok
}

alias -l min {
  tokenize $asc($space) $1-
  var %i = $0
  var %res = $1
  while (%i > 1) {
    var %val = [ [ $+($,%i) ] ]
    if (%val < %res) %res = %val
    dec %i
  }
  return %res
}

alias -l max {
  tokenize $asc($space) $1-
  var %i = $0
  var %res = $1
  while (%i > 1) {
    var %val = [ [ $+($,%i) ] ]
    if (%val > %res) %res = %val
    dec %i
  }
  return %res
}

; Generate and run an identifier call from identifier name, parameters and property
alias -l func {
  if (!$isid) return
  var %p = $lower($2)
  var %i = 3
  while (%i <= $0) {
    %p = %p $+ , $+ $($+($,%i),2)
    inc %i
  }
  if (%p != $null) %p = $+($,$1,$lbr,%p,$rbr) $+ $iif($prop,. $+ $prop)
  else %p = $ $+ $1
  return $(%p,2)
}

; ========== Identifiers instead of $chr(xx) - more readable ==========
alias -l tab returnex $chr(9)
alias -l space returnex $chr(32)
alias -l nbsp return $chr(160)
alias -l hashtag returnex $chr(35)
alias -l lbr return $chr(40)
alias -l rbr return $chr(41)
alias -l star return $chr(42)
alias -l comma return $chr(44)
alias -l lt return $chr(60)
alias -l eq return $chr(61)
alias -l gt return $chr(62)
alias -l lsquare return $chr(91)
alias -l rsquare return $chr(93)
alias -l lcurly return $chr(123)
alias -l rcurly return $chr(125)
alias -l sbr return $+($lsquare,$1-,$rsquare)
alias -l br return $+($lbr,$1-,$rbr)
alias -l tag return $+($lt,$1-,$gt)
alias -l sqt return $+(',$1-,')

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
  if ($0 < 2) DLF.Error $ $+ c: Insufficient parameters to colour text
  elseif ($1 !isnum 0-15) DLF.Error $ $+ c: Colour value invalid: $1
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

; ========== Binary file encode/decode ==========
alias -l DLF.CreateBinaryFile {
  if (($0 < 2) || (!$regex($1,/^&[^ ]+$/))) DLF.Error DLF.CreateBinaryFile: Invalid parameters: $1-
  var %len = $decode($1,mb)
  if ($decompress($1,b) == 0) DLF.error Error decompressing $2-
  ; Check if file exists and is identical to avoid rewriting it every time
  if ($isfile($2-)) {
    if ($sha256($1,1) == $sha256($2-,2)) {
      DLF.StatusAll Checked file: $2-
      return
    }
  }
  if ($isfile($2-)) {
    .remove $qt($2-)
    DLF.StatusAll Updating file: $2-
  }
  else DLF.StatusAll Creating file: $2-
  if ($exists($2-)) DLF.Error Cannot remove existing $2-
  bwrite -a $qt($2-) -1 -1 $1
  DLF.StatusAll Created file: $2-
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
    bset -ta &create %i $bvar(&file,%i,60).text
    if ($bvar(&file,%i,60).text != $bvar(&create,%i,60).text) {
      echo 1 Old: $bvar(&file,1,$bvar(&file,0))
      echo 1 New: $bvar(&create,1,$bvar($create,0))
      DLF.Error DLF.GenerateBinaryFile: Incorrect code generated @ %i !!
    }
    inc %i 60
  }
  echo 1 DLF.CreateBinaryFile & $+ create $1-
  echo 1 $rev(That's all folks!)
}

; ========== CPRIVMSG / CNOTICE support ==========
; to avoid ops hitting limits on changing target (of msgs) too frequently when an op
alias -l DLF.Raw005.Check {
  ; Capture CPRIVMSG/CNOTICE in 005 messages
  var %v = $+(%,DLF.Ops005.,$network)
  if ([ [ %v ] ] == $null) {
    set -ez [ [ %v ] ] 10
    set -e [ [ $DLF.Raw005.Name ] ] 0
  }
  if ((CPRIVMSG isin $1-) || (CNOTICE isin $1-)) set -e [ [ $DLF.Raw005.Name ] ] 1
}

alias -l DLF.Raw005.Reset {
  unset [ $DLF.Raw005.Name ]
  unset [ $+(%,DLF.Ops005.,$network) ]
}

alias -l DLF.Raw005.hasCops {
  var %v = $DLF.Raw005.Name
  if ($left($1,1) == $hashtag) return $false
  return $iif(([ [ %v ] ] == $null) || ([ [ %v ] ] == 0),$false,$true)
}

alias -l DLF.Raw005.Name { return $+(%,DLF.TargetLimited.,$network) }

alias -l DLF.msg {
  var %c = $DLF.IsOpCommon($1)
  if (($DLF.Raw005.hasCops($1)) && (%c)) CPRIVMSG %c $1-
  else msg $1-
}
alias -l DLF.describe { DLF.ctcp $1 Action $2- }

alias -l DLF.notice {
  var %c = $DLF.IsOpCommon($1)
  if (($DLF.Raw005.hasCops($1)) && (%c)) CNOTICE %c $1-
  else notice $1-
}

alias -l DLF.ctcp {
  var %c = $DLF.IsOpCommon($1)
  if (($DLF.Raw005.hasCops($1)) && (%c)) CPRIVMSG %c $1 $DLF.ctcpEncode($upper($2) $3-)
  else ctcp $1-
}

alias -l DLF.ctcpreply {
  var %c = $DLF.IsOpCommon($1)
  if (($DLF.Raw005.hasCops($1)) && (%c)) CNOTICE %c $1 $DLF.ctcpEncode($2-)
  else ctcpreply $1-
}

alias -l DLF.ctcpEncode {
  var %s = $1-
  var %s = $replace(%s,$chr(16),$+($chr(16),$chr(16)))
  var %s = $replace($1-,$chr(0),$+($chr(16),$chr(48)))
  var %s = $replace($1-,$chr(10),$+($chr(16),$chr(110)))
  var %s = $replace($1-,$chr(13),$+($chr(16),$chr(114)))
  return $+($chr(1),%s,$chr(1))
}

; ========== mIRC Options ==========
; Get mIRC options not available through a standard identifier
alias -l prefixown return $DLF.mIRCini(options,0,23)
alias -l showmodeprefix return $DLF.mIRCini(options,2,30)
alias -l enablenickcolors return $DLF.mIRCini(options,0,32)
alias -l shortjoinsparts return $DLF.mIRCini(options,2,19)

alias -l DLF.mIRCini {
  var %item = $iif($2 isnum,n) $+ $2
  var %ini = $readini($mircini,n,$1,%item)
  if ($3 == $null) return %ini
  return $gettok(%ini,$3,$asc($comma))
}

; ========== DLF.Watch.* ==========
; Routines to help developers by providing a filtered debug window
alias DLF.Watch {
  if ((($0 == 0) && ($debug)) || ($1- == off)) debug off
  else {
    if (($0 == 0) || ($1 == on)) {
      var %target = @dlF.Watch. $+ $network
      if ($window(%target) == $null) {
        window -k0mx %target
        titlebar %target -=- Watch irc messages on $network and dlF's handling of them.
      }
    }
    else var %target = $qt($1-)
    debug -ipt %target DLF.Watch.Filter
  }
}

alias DLF.Watch.Filter {
  ; This identifier should return $1- if it is a line dlF reacts to else $null
  ; In practice this means returning $null iff it is a channel message and not a dlF channel.
  var %text = $1-
  tokenize $asc($space)) $1-
  if ($left($2,1) == :) {
    var %user = $right($2,-1)
    tokenize $asc($space)) $1 $3-
  }
  if ($1 == ->) {
    var %server = $2
    tokenize $asc($space)) $1 $3-
  }
  if (($2 == PING) || ($2 == PONG)) return $null
  if (($left($3,1) == $hashtag) && (!$DLF.Chan.IsDlfChan($3))) return $null
  DLF.Watch.Log %text
  return $null
}

alias -l DLF.Watch.Called {
  DLF.Watch.Log ON $upper($event) called $1-
}

alias -l DLF.Watch.Log {
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

alias -l DLF.Watch.Unload {
  var %i = $scon(0)
  while (%i) {
    scid $scon(%i) debug off
    dec %i
  }
}

alias -l DLF.Halt {
  if ($0) DLF.Watch.Log $1-
  else DLF.Watch.Log Halted: No details available
  halt
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
