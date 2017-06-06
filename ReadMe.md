# dlFilter
## dlFilter.mrc - Filter out messages on file sharing channels
### Authors: DukeLupus and Sophist

Annoyed by advertising messages from the various file serving bots?
Fed up with endless channel messages by other users searching for and requesting files?
Are the responses to your own requests getting lost in the crowd?

dlFilter is a text filtering script for mIRC. It is created with file sharing channels in mind.
This script filters out the crud, leaving only the useful messages displayed in the channel.
By default, the filtered messages are thrown away, but you can direct them to custom windows if you wish.

Remove (or display in separate windows) the following:
* Advertisements from sharing bots
* Annoying KeepTrack, mp3/sound play requests, away messages and spam
* Search and Get requests from other users

Additionally:
* Server responses to your own requests can be shown in channel or sent to their own window.
* Results from @find requests can be collected into their own window for easy viewing.

Note: For better handling of @search results, install the DukeLupus SearchBot client [sbClient](http://dukelupus.com/sbclient).

## Installation and overview
1. Download the latest release [here](https://github.com/SanderSade/dlFilter/releases).
2. Extract the contents of DLFilter.zip to your mIRC scripts folder.
3. Load into mIRC by typing into any mIRC window:
```
/load -rs1 dlFilter.mrc
```
and press enter. 

4. The dlFilter options dialog window will open for you to configure dlFilter to your needs.

Note 1: dlFilter loads itself automatically as a first script.
This avoids problems where other scripts halt events preventing this scripts events from running.

Note 2: Some other scripts may interfere with filtering, causing various problems. In particular usage of mIRC theme system (MTS) should be avoided.

## Support
For additional help and details, see [dlFilter website](http://dukelupus.com/dlfilter).

## Change log
The change log can be viewed [here](https://github.com/SanderSade/dlFilter/blob/master/ChangeLog.md).
