# dlFilter
## dlFilter.mrc - Filter out messages on file sharing channels
### Authors: DukeLupus and Sophist

Annoyed by advertising messages from the various file serving bots?
Fed up with endless channel messages by other users searching for and requesting files?
Are the responses to your own requests getting lost in the crowd?

dlFilter is a text filtering script for mIRC. It is created with file sharing channels in mind.
This script filters out the crud, leaving only the useful messages displayed in the channel.
By default, the filtered messages are thrown away, but you can direct them to custom windows if you wish.

Functions include:
* For file sharing channels, filter other peoples messages, server adverts and spam
* Collect @find results from file sharing channels into a custom window
* Protect your computer from DCC Sends from other users, except those you have explicitly requested - files you have explicitly requested are accepted automatically
* Limit private messages of all types from other users
* If you are a channel op, provide a separate chat window for operators

dlFilter has received a significant upgrade from the previous major release 1.16 with significant new functionality, which we hope will encourage strong take-up.

Feedback on this new version is appreciated. Now that dlFilter is hosted on Github, we welcome contributions of bug fixes and further improvement from the community.

## Installation and overview
1. Download the latest release [here](https://github.com/DukeLupus/dlFilter/releases).
2. Extract the contents of DLFilter.zip to your mIRC scripts folder.
3. Load into mIRC by typing into any mIRC window:
```
/load -rs1 dlFilter.mrc
```
and press enter.

4. The dlFilter options dialog window will open for you to configure dlFilter to your needs.

Note 1: dlFilter loads itself automatically as a first script.
This avoids problems where other scripts halt events.

Note 2: Some other scripts may interfere with filtering, causing various problems. In particular usage of mIRC theme system (MTS) should be avoided.

## Roadmap
* Improve the ability of users to report issues (e.g. channel messages handled incorrectly) directly from dlFilter popup menus via GitReports.
* Option to filter trivia-games channel messages.
* Integrate sbClient functionality and rename to sbFilter.

## Support
To report issues or suggest improvements create an issue here on Github.
If you have a Github account you can create it directly, otherwise you can use [GitReports](https://gitreports.com/issue/DukeLupus/dlFilter/) to create it anonymously.

## Change log
The change log can be viewed [here](https://github.com/DukeLupus/dlFilter/blob/master/ChangeLog.md).
