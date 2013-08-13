SAS-GSE
=======

To install run

    git clone git@github.com:HEROES-GSFC/SAS-GSE.git

Then go into your the root directory of the project and run

    git submodule init
    git submodule update
 
This will download a set of librairy which the SAS-GSE depends on (namely https://github.com/HEROES-GSFC/SAS).
 
This project makes use of [CorePlot 1.2] (https://code.google.com/p/core-plot/). 
You can find the documentation for CorePlot [here] (http://core-plot.googlecode.com/hg/documentation/html/MacOS/index.html). 
CorePlot is included in this source code so you do not need to download and install it.

Note
----
During development it may be necessary to update the SAS library. To do this go into 
the SAS directory which is lib/SAS-aspect and do

	git pull origin master
	
Then commit this change in the HEROES-GSE project. See this [page]  (http://stackoverflow.com/questions/5828324/update-git-submodule) for more detailed instructions.