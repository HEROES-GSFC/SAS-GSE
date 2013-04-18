SAS-GSE
=======

To install run

    git clone git@github.com:HEROES-GSFC/SAS-GSE.git

Then go into your the root directory of the project and run

    git submodule init
    git submodule update
 
This project makes use of CorePlot 1.2 https://code.google.com/p/core-plot/. 
You can find the documentation for CorePlot here http://core-plot.googlecode.com/hg/documentation/html/MacOS/index.html. 
To install CorePlot, first download CorePlot
from the project page. In order to do a static library install;

* Open project preferences, via (+) opened dialog to add framework
* Add CorePlot framework (+ copy files to dest. group if needed)
* Add CorePlot to Build Phases > Link Binary with Libraries
* Open your apps Target Build Settings, and for Other Linker Flags include this: -ObjC -all_load
* CorePlot depends on Quartz so also add the Quartz framework to the project.
* Go to the "Link Binary With Libraries" tab under the "Build Phases" tab.
* Go to Project Settings > Build Phases
* In right bottom corner click Add build phase > Copy Files
* Select Destination > Frameworks
* Drag and drop CorePlot framework to list

After completing the steps above, the project should compile properly and you
should be able to add a CorePlot through the following include statement

    #import <CorePlot/CorePlot.h>

Enjoy.
