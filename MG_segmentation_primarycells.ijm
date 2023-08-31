/*
 * Max Adrian
 * Genentech Inc gRED Neuroscience
 * October 2021
 * 
 * Cell Morphology Analysis
 * v3
 * 
 * Record Morphology of cells acquired in 2D widefield,
 * uses SCF H-watershed algorithm with variable threshold
 * asseses how well mage is focud in FFT and reports metric in summary table
 * Expects folder containing TIF mages ending on "ch_01.tif" ignores others
 * Saves Results (per cell) and summaary (per image) tables as csv in same folder
 * Saves binary count masks in new subfolder
 */

#@File (style="directory") dir


//get vars, clean up
run("Fresh Start");
setBatchMode(true);
run("Set Measurements...", "area centroid center perimeter bounding fit shape feret's stack limit display redirect=None decimal=2");
filelist = getFileList(dir);
count = 0; // counter to keep track of no of analysed images
FTFocus = newArray(lengthOf(filelist)); // empty array to store focus values

// parameters
size_min = 200;
f1 = 10;
w_seed = 10000; //used 5,000 first but it seemed to seperate too much


//make subfolder for count masks
if(!File.exists(dir+"/count_masks")) {
	File.makeDirectory(dir+"/count_masks");
}



// set up log
print("Iba-1 segmentation in vitro - v3");
print("Directory: " + dir);
print("Threshold = "+ f1 + " x min");
print("Seed = "+ w_seed);
print("size_ filter = "+ size_min);
print("------");


// looping through folder, find all ch01 tifs to perform analysis
for (i = 0; i < lengthOf(filelist); i++) { /// change 0 to random number here for testing
    if (endsWith(filelist[i], "_ch01.tif")) { //opens only ch01

        // open image, get tile, scale and stats
        open(dir + File.separator + filelist[i]);
        title = getTitle();
        getStatistics(area, mean, min, max, sd, histogram);
        getPixelSize(unit, pW, pH); // record scale
        w_th = f1*min;
        print("Working on :"+ title);

        // run FFT-based focus evaluation, store value in array
        FTFocus[count] = measureFFT(); 
        count++;

		//renmae image and run Median filter
		rename("cellmask"); 
		run("Gaussian Blur...", "radius=3");

		// watershed segmentation
		run("H_Watershed", "impin=[cellmask] hmin="+w_seed+" thresh="+w_th+" peakflooding=100.0 outputmask=true allowsplitting=false");
		selectImage(nImages); // watershed window is not active by default, this should open the most recent image
		rename(title);
		run("Set Scale...", "distance=1 known="+pW+" unit=um");  // get scale automatically above, watershed functon removes scale

		// Particle Analyser & save segmentation
		
		run("Analyze Particles...", "size="+size_min+"-Infinity show=[Count Masks] display exclude summarize");
		run("glasbey");
		run("Enhance Contrast", "saturated=0.35");		
		saveAs("tiff", dir+"/count_masks_v3/"+title);

		// make overlay and save
		rename ("mask"); // renames current image (the count mask)
		selectWindow("cellmask");
		run("Add Image...", "image=mask x=0 y=0 opacity=40 zero");
		saveAs("tiff", dir+"/count_masks_v3/Overlay_"+title);

		// clean up windows
		run("Close All");
		run("Collect Garbage");
		
    } 
}

print("Done!");
//save results table
selectWindow("Results");
saveAs("Results", dir+"/Results_v3.csv");

//save Summary table after adding focus metric
selectWindow("Summary");
IJ.renameResults("Results"); // renaming summary table to 'results' to add focus values' then saving again as 'summary.csv'......
for (k = 0; k<count; k++){ //importantly length of the array does not matter
	setResult("FTFocus", k, FTFocus[k]); // add focus vector as new column
}
saveAs("Results", dir+"/Summary_v3.csv");
print("All done!");

// save Log
selectWindow("Log");
saveAs("Text", dir+"/Log_v3.txt");

//measure focus quality in fft space, larger is sharper, returns value, see https://forum.image.sc/t/blur-detection-in-imagej/36880/9  nranthony
function measureFFT(){
	run("FFT");
	run("Specify...", "width=512 height=512 x=200 y=200");
	getStatistics(area, mean, min, max, std, histogram);
	setThreshold(mean + (3*std), 255);
	run("Create Selection");
	getStatistics(area);
	close("FFT*"); // close FFT
	return(area);
	
}

