# dlFilter Options Help
The primary functions of dlFilter are:
* Filtering out irrelevant messages from file serving channels so that you don't lose
responses to your own requests and genuine chat amongst the quantity of messages from servers.
dlFilter comes with hundreds of pre-defined filters, but you can also define your own custom filters.
* Preventing a proliferation of query windows if other users or servers start sending you private
messages.
* Collecting responses from your own @find / @locator requests into a single window
* Controlling who can send you files
* If you are an op in a channel, channel-like functionality to allow you easily to chat with other ops. (oNotices)
* If you are an op in a channel, advertising dlFilter to other users.

With all this functionality, to avoid dlFilter from doing more than the user wants,
options are needed so that users have a choice of which parts of dlFilter functionality they want to use.
dlFilter gives you control of this functionality with a variety of settings
available through an Options dialog, by right clicking in windows or from mIRC's Commands menu.

This web page is to help you to understand what each of these options does
so that you can set it up to work the way you want it to.

(Screen shots will be added soon.)

# Options Dialog
The options dialog allows you to set most of dlFilter's options (with the exception of logging and line wrap options
for dlFilter's custom Filter and Server windows).

The options dialog consists of:
* [Global options](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#global-options) (which appear at the top and bottom of the Options dialog regardless of which tab you are viewing)
* [Channels tab](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#channels-tab)
* [Filters tab](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#filter-tab)
* [Other tab](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#other-tab)
* [Ops tab](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#ops-tab)
* [Custom tab](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#custom-tab)
* [About tab](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#about-tab)

## Global options
dlFilter's global options allow you to:
* [Enable or disable dlFilter's functionality](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#enable-dlfilter)
(without having to unload / reload the script)
* Show or Hide the [Filter window(s)](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#show-hide-filter-windows) and [Ads window(s)](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#show-hide-ads-windows)

### Enable dlFilter
This option enables / disables the event handling functionality that is the core of dlFilter.
When you disable dlFilter, the only functionality left enabled is to respond to VERSION requests.

### Show/Hide Filter windows
The core functionality of dlFilter is to analyse every message sent to you and decide how to handle it.
Messages that it decided should be hidden from you are sent to a Filter window instead of being displayed
in a channel, query or status window.

Filter windows can be in one of 3 states:
* Closed - the Filter window(s) do not exist and filtered lines are discarded
* Hidden - the Filter window(s) exist and filtered lines are sent to them, but they do not appear in the switchbar or treebar
* Visible - as Hidden but the Filter window(s) appear in mIRC's switchbar and treebar

Cick the **Show/Hide Filter Windows** button to switch between Visible and Hidden/Closed states.
The choice between Closed and Hidden is made using the "Keep Filter Windows active in the background" option described later.

### Show/Hide Ads windows
When you are in a file sharing channel the various server bots regularly advertise themselves including an @ trigger
which you can use to request a list of all the files that they are sharing.
The Ads window(s) maintain a list of all these adverts for your reference whenever you need to view them.

Ads windows can be in one of 2 states:
* Hidden - the Ads window(s) do not appear in the switchbar or treebar
* Visible - the Ads window(s) appear in mIRC's switchbar and treebar

Click the **Show/Hide Ads Windows** button to switch between Visible and Hidden states.

## Channels tab
The channels tab is primarily where you [define which channels you want dlFilter to operate on](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#channel-list).

This tab is also used for the [script Update functionality](https://github.com/DukeLupus/dlFilter/blob/master/options-help.md#dlFilter-update)

### Channel list
The channels tab is where you can see the list of channels that dlFilter is processing,
and add new channels (either selecting ones you are currently on or manually typing a
channel name.

* To delete one or more channels from the list, select them and click **Remove**.
* To edit a channel in the list double click to remove it from the list and copy it into
the add channel edit box.
* To add a channel that you are currently on, select it from the drop-down list and click **Add**.
* To manually add a channel, type the channel name into the edit box
(optionally preceded by the network name) and click **Add**.

Channel names can be either of the following two forms:
* #channel
* network#channel

If the only channel name in  the list is # (just #), then all channels you are on are filtered.

### dlFilter-update
This script has functionality that allows it to check whether a new version of the script is available for download,
and if it is then for you to click to tell dlFilter to download and update itself.

It also has an option for you to stick with stable versions,
or to update using more frequent but possibly buggy beta versions.

## Filters tab
File sharing channels are characterised by a never ending stream of messages that
you probably have little or no interest in, including:
* Adverts by file servers' for their lists of files
* Announcements by file servers of what files they have sent to other users
* Statistical messages about the number of files they are serving and how busy they are
* Other people's requests to find or get sent copies of files
* Trivia quiz questions, hints, answers attempts, answers and statistics
* Spam (about things not associated with file sharing activities)
* Joins, Parts, Quits etc.

With all these other messages (or noise), it can be difficult to spot the messages
that are for you.

Filtering is a process of analysing a message and discarding it
(or displaying it in a separate window)
if it meets certain criteria.

By filtering out all the messages from a file sharing that you are not interested in,
the messages you are interested in are now easy to see.

**Note:** Messages relating to users in your mIRC notify list are always shown.

The filters tab has a variety of options that control which type of messages are filtered.
Each of these options is described below:

### General
The general filter options cover channel messages that do not relate to user changes.

#### Filter other users file search/get requests (@/!)
If this option is checked, When other users type lines beginning with @ or ! in order
to find or get a file then it will be filtered out.

#### Filter adverts and announcements
File serving bots advertise and announce themselves every few minutes and these can be pretty annoying.
Adverts are messages which e.g. tell you how to use them.
Announcements are other messages such as those telling you what files have been sent to other users.
If this option is set, then both Adverts and Announcements are filtered.

Adverts are also used to populate the Ads window.

#### Filter channel mode changes
Some channels use a bot to continually adjust the maximum number of users allowed in the channel.
The purpose of this bot is to prevent IRC denial-of-service attacks where channels are crashed by
hackers having hundreds of users join the channel simultaneously.

The purpose of this option is to filter out these (and other) channel mode changes.
Unless they are an op, most users are not interested in these anyway.

#### Filter channel messages with control codes
Control codes are special characters in messages which display text in colours/bold/italic/underlined/reversed.

Whilst these are sometimes used by users, particularly in role playing channels,
in the file sharing channels that dlFilter is targeted at,
messages containing control codes are almost always sent by a server.

Whilst it is hoped that the other options will work very effectively in
filtering unwanted server messages, leaving just chat messages and the responses
to your own requests displayed in the channel, sometimes this is not enough and
you need a more heavy handed option, a filter-of-last-resort as it were,
that you can use when other filters are not sufficient.

This option filters out all messages containing control codes without a specific text filter.
These are almost always server messages, but you can never be certain that a user has not manually used colours etc.
Then again if you are only visiting a file sharing channel to share files,
you may not be bothered about any messages from other users.

Anyway the option is here if you need it.

#### Filter channel topic messages
In some channels a bot regularly sets the channel topic, often to the same text.
This option filters out these messages if they annoy.

#### Filter server responses to a separate window
This option sends the response messages to your own requests to a separate server window.

This functionality was originally implemented so that these responses were not scattered amongst other server messages,
but with better filtering it is now easier to see these in the main channel.

However, the functionality exists (for the moment at least), and this option enables it.

#### Separate dlFilter windows per connection
If you are connecting to several servers simultaneously
(e.g. separate networks, or several nicks on the same network)
this option create separate Ads, Server and Filter windows for each network.
If you are running with only one connection, this should make no difference to how dlFilter operates.

#### Keep Filter windows active in the background.
If this option is disabled, when the Filter window is hidden it is closed and all existing contents are lost.

With this option enabled, when you hide or close the filter window,
it actually stays open but is hidden from the switchbar & treebar.

When you Show the window again, it is added to the switchbar and treebar
and is already populated with previously filtered lines.

### Filter user events
User events are those relating to users joining or leaving channels etc.

#### Filter Joins / Parts / Quits / Nick changes / Kicks
In channels with large numbers of users,
the messages displayed when users join or leave a channel can be very distracting.

So why not filter them out?

#### Filter Away messages
When users have an away message set, this functionality filters them away.

#### User mode changes
This option filters out messages telling you that some user you don't really know
has been opped or deopped by another user that you don't really know.

#### Filter user events for all users
When this option is not set, only joins/parts/etc. for regular users are filtered out.
Quits etc. by ops / half-ops / voiced users are shown on the basis that you may want to
know when a server leaves the channel.

When this option is set, such messages relating to ops, half-ops and voices users are also filtered.

## Other tab
The other tab contains all the options that relate to functions other than filtering:
* @find (/ @locator) windows
* dlFilter statistics
* Colouring server nicks
* Controlling users sending you files with DCC Send
* Controlling what happens to messages sent to you privately.
* Other security options

### Collect @find / @locator results into a single (@find) window
Without dlFilter, @find results end up in multiple query windows.

With dlFilter and this option not set, they end up in a channel window spread amongst other messages.

With this option set, they are filtered and collected together in a single @find window -
a window which makes it easy to then request specific files.

### Display dlFilter efficiency in title bar
If you set this option, dlFilter displays the proportion of messages filtered for each channel in the status-bar.

### Colour uncoloured fileservers in channel
If this option is set, dlFilter colours the file servers brown in the channel nick list.

### Auto accept files you have specifically requested
When you request a file using ! or @ triggers, dlFilter attempts to get mIRC to
accept the file automatically by temporarily setting DCC Trust for the user
for just long enough to accept the file.

Auto-Accept means that the mIRC Accept / Ignore / Cancel dialog is not shown.
All other options block files but do not change mIRC's behaviour for this dialog.

### Block ALL files you have not specifically requested
This option, along with the sub-options, provides a firewall to stop people sending you unsolicited files.

This option block all files you have not specifically requested
**UNLESS** the user is in your DCC trust list.
Users in your mIRC DCC Trust list will be accepted regardless of these settings.

If you clear this option, then the sub-options are enabled to give you finer control over which files to accept:

#### Block potentially dangerous filetypes
If set, the following filetypes will be blocked:
* application bat cmd com cpl doc doc docm dotm exe gadget hta inf jar js jse lnk mrc msc msh msh1 msh1xml msh2 msh2xml mshxml msi msp pif potm ppam ppsm ppt pptm ps1 ps1xml ps2 ps2xml psc1 psc2 reg scf scr sldm vb vbe vbs ws wsc wsf wsh xlam xls xlsm xltm

**Note:** This is regardless of the list set in mIRC's DCC Ignore list.

#### Block files from users NOT in your DCC Trust list
If this option is checked, files will only be allowed through if the user is in your DCC Trust list.
If not set, then your other options may block it.

#### Block files from users not in a common channel
If checked, this option blocks files send by someone who is not in a channel you are in.
If it is from a user you know, add them to your trust list to allow their files to be received.

If not set, then your other options may block it.

#### Block files from regular users
If checked, this option blocks files send by someone
who is not an op / half-op / voiced in a channel you are in.

**Note 1:** Unless you have "Block ALL files you have not specifically requested set,
then files from ops / half-ops / voiced users (in non-moderated channels) will not be blocked.

**Note 2:** Many file servers are not ops / half-ops / voiced, but if you have
"Auto accept files you have specifically requested" set, then they will not be blocked
even if the nick is a regular user.

### Retry incomplete file requests (up to 3 times)
If checked, then if a file send fails, the script will reissue the trigger request for
you up to 3 times.

**Note:** The server may try to resend the file to you anyway.
Or it may not - hence this option.

### Check mIRC settings are secure
This setting is disabled and is a placeholder for future functionality
which will audit your mIRC settings to make sure that they are secure.

### Private messages options
Messages from users in your mIRC notify list or
from a user with an open query window will always be accepted.
If you want to chat with someone using private messages then open a query window
in order to receive their messages.

### Filter private messages from users not in a common channel
Messages from users who are not in a common channel will either be from friends
or will be spammers.

Setting this option allows

### Filter private messages from regular users

###

###

## Ops tab

## Custom tab
The custom tab allows you to define your own filters to avoid seeing repeating messages that you don't like.

You can define filters for the following types of event:
* Channel messages (e.g. <nick> This is a message)
* Channel action messages (e.g. * nick sends you an action message)
* Channel notices (e.g. -nick- sends you a notice)
* Channel ctcp commands (e.g. [nick SLOTS] stuff)
* Private messages (e.g. <nick> This is a message)
* Private action messages (e.g. * nick sends you an action message)
* Private notices (e.g. -nick- sends you a notice)
* Private ctcp commands (e.g. [nick QUESTION] stuff)

This tab works very much like the Channels tab with add and remove buttons.
* To delete one or more filters from the list, select them and click **Remove**.
* To edit a filter in the list double click to remove it from the list and copy it into
the add filter edit box.
* To add a filter, type or paste it into the edit box and click **Add**.

## About tab
The About tab provides you with an overview of dlFilter and links to key web pages
for help and support.
