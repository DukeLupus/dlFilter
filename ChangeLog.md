# dlFilter Change Log

### 1.17
* Interim version of significant new functionality
* Update opening comments and add change log
* Use custom identifiers for creating bold, colour etc.
* Use custom identifiers instead of $chr(xx)
* Use alias for status messages
* Hash tables for message matching instead of lists of `if` statements.
(Performance is not believed to be an issue but this should be significantly faster.)
* Options dialog improvements
  - Layout
  - Enable / disable now global
  - Custom filter Add / Remove button enable / disable
  - Custom filter list multi-select
* Menu code cleanup
* Add generic sockets code
* Use GitHub for version check
* Download button to update from GitHub
* Use script groups to enable / disable DLF event handling
* Allow msgs from Chanserv etc. and self
* Cleanup menu code
* Files now always accepted from Regular users who are in DCC Trust List
* Allow user to choose whether to delete configuration variables on unload
* Limit load/start/connect update check to once per 7 days.
(Options update check still runs every time options dialog is loaded.)
* All aliases and dialogs local (-l flag)

### 1.16
* Website change

### 1.15
* Fixed two issues with OpsTalk - it still had a bug with logging when mIRC folder had a space in the path 
(thanks to zippy1 and SpankyDan for reporting that)
* Fixed issue with URL's not showing in @#channel window.

### 1.14 
* *bonga*, *agnob* and *meep* now auto-added to custom filters (hello EBrarian and waterbaby)
* Custom filters now enabled by default. 
* Fixed/updated handling of the socket errors (used in version check routine).
* Lots of mp3 play messages added to filters - enabled when "..away and thank you messages" filter is enabled. 
* Some other minor tweaking.

### 1.12 
* Updated links and version checks to point to the new web page

### 1.11
Added vPowerServe @find result headers

## 1.1 Major update
* You can now log @DLF.Filtered and @DLF.Server messages - select item "Log" in the right-click menu. 
Logging is separate, log files will be in your logs folder with the names dlf.filtered.log and dlf.server.log.
Note that logging is enabled even after you close respective windows, only way to disable it is to open the window and uncheck menu item. 
* Fixed several bad errors in on quit routine. 
* If you filter and send user-related messages (quits, joins, parts, nick changes, kicks) to status window, 
it no longer highlights status window button.
* Removed definitions and commented out channel text spam - spamnets using any standard messages note seen for a while
* As always, more spam definitions. 

Note: While I didn't add *#*#*#*#*, you might want to add it to custom filters yourself (#chan #chan #chan #chan type spams).

### 1.05
* Filtering quits is no longer channel-specific (thanks, meelWORM).
* Some new spam definitions.

### 1.03
* Updated spam definitions.
* Warning when when you get $decode in private message: 
`[dlFilter] Do not paste any messages containg $decode to your mIRC. They are mIRC worms, people sending them are infected. Report such messages to channel ops.` 
* Removed my ctcp DLX thingy.

### 1.02
* Updated spam definitions.

### 1.01
* Switch to two decimal places in version numbers
* "Send to AutoGet" now works if AG is not in main mIRC folder.
* Old logs are now loaded to oNotice window if logging is enbled (and old logs exist).
* Removed some very old spam definitions and added new to get spammers plagueing #bookz and #mp3servers. 
* String will be automatically bracketed by '*' when adding definitions to custom filters
* Script is now smaller and more compact thanks to ScriptCleaner.

### 1.009
* Spam definitions added to cope with a flood of spammers attacking #mp3servers.

### 1.008
* Very minor fixes that I forgot to include into previous public version. 
* Updated some filter definitions again.

### 1.005
* Just updated definitions, mostly spam - lots of it lately.

### 1.004
* When filtering away/thank you messages, RAW 301 is now also filtered. 
* Improved "junk" removal from filename when copying to clipboard (experimental). 
* Added lots of spam messages and ads to definitons.
* Added ertl's second "new release" message, improved new release capturing somewhat.

### 1.003
* When channels were set to all and nick change filtering was on, DLFilter still echoed it to channel (thanks to the r00ted for noticing it).
* When the web site was unavailable while opening options dialog, it occasionally caused DLFilter to lose some of its settings
* Added some definitions.

### 1.002
* Added lots of rare ads & some spams.
* Improved adding custom strings.

### 1.001
* Changed "Send to AutoGet" into "Send to AutoGet 7"
* Added support for latest beta of AG7.

# 1.000
* Formal release of Version 1
* Few minor changes

### 0.986
* Added support for vPowerGet.NET and AutoGet 7 (older versions of both are no longer supported).
* File names not copied correctly to clipboard from @find and new releases windows
* Variables were not correctly initialized (socket collision) if you had one mIRC with DLFilter running
and you started another mIRC from another installation and loaded DLFilter.

### 0.985
* Very rarely version check used older version number (happened only on first connect after update, if /reload was used for updating).
* /me onotice didn't work in Undernet
* Sorted ads and away/thank you messages.
* Improved nick coloring.
* More filter definitions.

### 0.984
* Fixed bug that gave error when sending wrapped /me line to DLF.Filtered window (thanks to fost for noticing it).
* Lines now displayed in user's current action color.
* Fixed minor bug in DLF.debug (amount of DLFilter variables was larger then it really was).
* Added channel text definitions suggested by vadi.
* Few spam and other definitions added.

### 0.983
* dlFilter now automatically loaded as a first script.
* Added alias DLF.debug (has to be called manually), which creates DLF.debug.txt.

### 0.982
* oNotice window now uses user's current nicklist, text and action colors for displaying responding events.
* Few very minor changes.

### 0.981
* Fixed bug that caused "Send to AutoGet" not to work from DLF.NewReleases window.
* @find result headers filtering occasionally disn't display name correctly in the DLF.server window.
* Some more minor tinkering.

### 0.980
* Improved saving of @find results window.
* Changes to script initialization.

### 0.979
* Few minor fixes:
  * Capturing onotice /me was displaying wrong
  * Some server messages sent as private text were displayed as "<Request> denied... " instead of "<nick> Request denied..." in DLF.server window.
* Made multiple copy/Send to AG/Send to vPG available in DLF.New.Releases (actually just made script use same menu as for DLF.@find.results window).

### 0.978
* Improved @find reply catching - added support for a strange version of OmenServe.
* Fixed onkick $address() displaying issue (thanks to MollyKate for noticing that)
* Fixed small issue with query windows when no common channel.

### 0.977
* Fixed query windows being closed when other user left all common channels - thanks to AK3D for reporting the bug.
* Some spam filter definitions added.

### 0.976
* DLFilter will no longer block queries (/msg) from users with whom you don't have common channel if you typed first line to that window. 
* Added "FOR MATRIX 2 DOWNLOAD..." worm to spam definitions.

### 0.975
* Fixed minor bug in displaying kicks in status window. 
* At the reqest of TipiTunes added special private spam catcher (in style "*www*xxx*" first line of private message). 
* Few more filter definitions.

### 0.974
* Moved 100+ private notice events to one event and made relevant changes. 
* Added new sub-option: "block only potentially dangerous filetypes" to "Do not accept files from regular users". 
* Few mode definitions added.

### 0.973
* Updated some filter definitions.
* @find results headers from SoftServe script weren't filtered, same for S343. 
* Some away messages added.

### 0.972 
* Added version check to on connect event.
* Unloading script now closes all open DLFilter windows. 
* Only those nicks that are in default nicklist color are now colored when detected to be fileservers. 
* Fixed @find results grouping.
* "Requests in private" now responds to !nick-que etc commands.

### 0.970 & 0.971
* Automatic version check - thanks to TipiTunes. 
* Added web page & direct download buttons and "..but accept DCC chats" option. 
* Added private `on text` event to capture some multiline spams.

### 0.967
* Minor fixes to use `on text` instead of `on open` event.

### 0.966
* Changed private text event to on open event (got the idea from TipiTunes' antispam script).
That way spam, private request and @find results are captured even before respective query windows open. Neat! 
* Minor changes in other events.

### 0.964
* Better "new release" capturing. 
* Improved/changed channel menu - now shows only "Add current channel" or "Remove current channel" instead of showing both items.
* If channels are set to all, "Set to all channels" item in channel menu is disabled and checked. 
* More filter definitions. 

### 0.961
* Fixed small bug in DoCheckComChan alias. 
* Too much DCC chat windows were closed.

### 0.960
* Included my oNotice script
* Some changes in the way how some events are handled and GUI. 
* More filter definitions.

### 0.955
* Changed GUI a bit, added links to website & direct download. 
* #find mistake is now filtered correctly. 
* Added option for coloring nicks of detected servers (works only if filtering of channel ads is enabled, overrides current nick color). 
* User related messages in the status window are now shown in user's default colour for respective events.

### 0.952 & 0.953
* Made version check for vPowerGet.dll
* "Copy line(s)" item in @find.results window right-click menu 
now removes unneeded stuff (such as filesize & bitrate) 
from filename when copying (may not be 100% foolproof). 
* Options dialog now shows script version in titlebar. 
* Additional spam & other filter definitions.
