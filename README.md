SAS-GSE
=======

To install run

    git clone git@github.com:HEROES-GSFC/SAS-GSE.git

Then go into your the root directory of the project and run

    git submodule init
    git submodule update
 
You should now be able to open the project in Xcode and compile it.

This project makes use of CorePlot 1.2 https://code.google.com/p/core-plot/. To install CorePlot. Download CorePlot.
You can find the documentation for CorePlot here http://core-plot.googlecode.com/hg/documentation/html/MacOS/index.html
We are going to do a static library install.

* Opened project preferences, via (+) opened dialog to add framework
* Add existing framework (+ copy files to dest. group if needed)
* DnD CorePlot to Frameworks Group
* Added CorePlot to Build Phases > Link Binary with Libraries
* Open your apps Target Build Settings, and for Other Linker Flags include this: -ObjC -all_load
* Add the Quartz framework to the project.
* Go to the "Link Binary With Libraries" tab under the "Build Phases" tab.
* Go to Project Settings > Build Phases
* In right bottom corner click Add buid phase > Copy Files
* Select Destination > Frameworks
* Drag&Drop framework to files list
* You should now be able to add In your ViewController.m file add 

    #import <CorePlot/CorePlot.h>
