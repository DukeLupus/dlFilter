# dlFilter
## dlFilter.mrc - Filter out messages on file sharing channels
### Authors: DukeLupus and Sophist
dlFilter is a text filtering script for mIRC. 
It is created with file sharing channels in mind, and it filters out all the file sharing commands sent by other users, 
leaving only the responses to your own file sharing comamnds and chat displayed.

dlFilter was originally written by DukeLupus. 
In 2017 it was rewritten by Sophist as v2.0 and received a significant upgrade from the previous major release 1.16 with significant new functionality.

This included:
* Complete rewrite to make it more efficient
* Significantly better filtering lists
* A DCC GET firewall - automatically accepting files you have explicitly requested
* (For channel operators) oChat - a channel-like window whereby channel operators can chat amongst themselves behind the scenes 

Feedback on this new version is appreciated. Now that dlFilter is hosted on Github, we welcome contributions of bug fixes and further improvement from the community.

Unfortunately in 2024 DukeLupus passed away at an untimely early age - he is sorely missed.
Consequently, this script is deedicated to his memory.

## Downloading
The best way to download the latest formal release of the script is to 
go to the [Releases Page](https://github.com/DukeLupus/dlFilter/releases) and download the zip file.

Alternative to download the latest alpha version [right click here and select save](https://raw.githubusercontent.com/DukeLupus/dlFilter/master/dlFilter.mrc).

## Installing
The best place to install scripts is in your mIRC settings directory (use the mIRC command `//echo -a $mircdir` to find out where this is) or in a scripts subdirectory.

When you have placed the file in the directory you want, then use the mIRC command `//load -rs1 [directory]\dlFilter.mrc`.

## Upgrading
The best way to upgrade if you are on dlFilter v2 is to use the built in upgrader. Otherwise, 
download the dlFilter.mrc script as above, replace your old version with the new version and restart mIRC.

## Help & Support
For full help and support, please read our [Wiki](https://github.com/DukeLupus/dlFilter/wiki).

To report issues or suggest improvements create an issue here on Github.
If you have a Github account you can create it directly, otherwise you can use [GitReports](https://gitreports.com/issue/DukeLupus/dlFilter/) to create it anonymously.

## Change log
The change log can be viewed [here](https://github.com/DukeLupus/dlFilter/wiki/Change-Log).
