<<<<<<< HEAD
#Inventory Manager
========================

A script for OS X that discovers client/machine specific information and publishes info to KeyServer and nvram.
## Contents

* [Download](#download) - get the script
* [Contact](#contact) - how to reach us
* [Purpose](#purpose) - what is this script for?
* [Usage](#usage) - details of invocation
  * [Variables](#variables)
  * [Getting warranty information from Apple](#Getting-warranty-information-from-Apple)
  * [Checking for a firmware password](#Checking-for-a-firmware-password)
  * [Custom fields in KeyServer client (`keyaccess`) plist
](#Custom-fields-in-KeyServer-client-(`keyaccess`)-plist)
  * [Writing data into nvram](#Writing-data-into-nvram)
  * [Generating error email](#Generating-error-email)
  * [Installation](#installation)
  * [Execution](#execution)
* [Attribution](#attribution) - information on how it all works

## Download

[Download the latest installer for Inventory Manager here!](../../releases/)


## Contact

If you have any comments, questions, or other input, either [file an issue](../../issues) or [send an email to us](mailto:mlib-its-mac-github@lists.utah.edu). Thanks!

## Purpose
This script was written to provide a short-term inventory management solution. We were interested in developing a administrative dashboard using Sassafrass KeyServer containing more hardware information than was currently offered. We wanted to take advantage of user-defined data fields located in the Keyserver client's preferences plist.


## Usage
This script was ultimately written to fit within our specific radmind client management environment. However, it can be modified for use with other management applications, such as Apple Remote Desktop.

As written, the script makes use of a CSV file containing a inventory of purchase dates, various asset tag numbers, and machine specific info. The format is as follows:

`acquisition date, asset tag #, scan tag #, model name (unused), serial # (unused)`


In the following sections I'll describe individual sections of the script.


#### Variables
Before using the script there are a number of variable that should be customized to fit your environment.

`rundate` Current date, used in email reporting.

`runhost` IP address of running machine, used in email reporting.

`osVersion` OS version of running machine

`modelID` Model ID (ie "MacPro4,1") of the running machine

`marketingID` Marketing name (ie "Mac Pro Early 2009") of the running machine. It should be noted that this information is not consistent with Apple itself and is used for informational purposes only. Apple's own websites can report different names for the same hardware.

`serialNumber` Serial number of the running machine. Also used as a key to parse the inventory CSV file. If the serial number can't be found, it fills the following variables with an error.

`aqDate` Aquisition date

`assetNumber` Asset tag number

`scanNumber` Alternate asset tag number

#### Getting warranty information from Apple
The script attempts to query Apple's self service page for warranty information. Due to the different purchasing methods used at our institution, a majority of our machines were not recognized as they were seperately enrolled in Apple's GSX site. While it is possible to query the GSX site for machine information, this script *does not* attempt to do so.

`appleCare``daysSincePurchase` If the machine is in the self service database, the script with scrape the page to find the state of AppleCare support and the number of days past since the computer was purchased.

#### Checking for a firmware password
The machines we manage are secured with a firmware password. We have a solution that maintains these passwords, this script leverages that solution to check for the presence of a firmware password. Under OS X 10.9, it will use `setregproptool`, and under OS X 10.10 it will use `firmwarepasswd`. `setregproptool` is installed by our management tools, it may not be available in your environment.

`firmWarePassword` A boolean that records the presence of a firmware password.

#### Custom fields in KeyServer client (`keyaccess`) plist
The KeyAccess preferences are located at `/Library/Preferences/com.sassafras.KeyAccess.plist`

The plist does not initially contain the custom fields we will be using. There are 10 supported fields: `assetCustom0` to `assetCustom9`


#### Writing data into nvram
The script will collate all of the fields and write it to nvram.
The result will look like this:
`scl-data-line	13in MacBook Pro with Retina display Late 2013:************:n/nn/nn:Snnnnn:Lnnnnn:_ACareUndef_:_DOPAgeUndef_:true`


#### Generating error email
If the script encounters an error, for example the serial number not being found in the inventory datatbase, an email is sent to the address(s) defined in the `mailto` variable.




#### Installation
Coming soon.
#### Execution
Coming soon.
### Attribution
Coming soon.
=======
# Inventory-Manager
Script that discovers client specific information and publishes info to KeyServer and nvram.

Additional documentation available soon.
>>>>>>> origin/master
