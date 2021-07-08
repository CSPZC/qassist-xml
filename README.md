# qassist-xml
Several features that are meant to make qa's life easier when dealing with tons of xml. It's really cross-platform clutch that does not need to be .Net Linq etc libs preinstalled=)

..to do various tasks related with "tons" of xml processing ..

Currently working:
* '0' - show ED value by xPath "
* '1' - edit the ED array by xPath value from the keyboard "
* '2' - edit the ED array by xPath with a list of values from the file "
* '3' - multiply ED "
* '4' - embedding the ED array into the envelope "
* '5' - packing the ED array into .bin "
* '123' - launch of the test version of the ED normalizer "
* '321' - get data collection xpath-value from ED "

Temporary way to get a collection of data from ED of the form xpath, meaning:
* copy the console output to notepad
* replace hyphen + comma + space with comma
* remove all node prefixes by replacing

Normalizer: both collection and ED files must be in UTF-8 encoding with BOM
