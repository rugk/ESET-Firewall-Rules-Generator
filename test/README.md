# Test files for ESET Firewall-Rules-Generator
These files are test files for the ESET Firewall-Rules-Generator. Try to convert the TXT files and you should get (depending on the options you choose) a similar output like the XML files in this repo.

## Sources
The Zeus Tracker IP Block List (*ZeuS-Tracker IP-Block-List by abuse.ch.txt*) is from [abuse.ch] (https://zeustracker.abuse.ch/blocklist.php).
Last updated: 08 June 2015

## Notes
* File testIPv6.txt deliberately contains an wrong IP at line 3. If you convert the file you should see an error message.
* **Important:** If you want to use the Zeus Tracker IP Block List please download the last version from abuse.ch and generate the settings file by yourself. The version here is certainly outdated and may only used for testing purposes.
