/*
 * Max Adrian
 * Genentech Inc gRED Neuroscience
 * 2021-2023
 * 
 * Cell Morphology Analysis
 * 
 * Expects folder containing TIF mages ending on ".tiff", ignores others
 * Saves Results (per cell) table as csv in same folder. Does not create a summary table per image but only per cell measurements!
 * Saves binary label masks and maxima regions(to define cells) in new subfolder
 * 
 * Compared to the in vitro IF macro, this pipeline uses seed-based watershed. To define maxima (darkest DAB stain ~ nuclei) a stringent threshold is used with the Area Maxima function from SCF.
 * Based on these seeds the guided watershed can seperate clustered microglia.
 * Thresholds are dynamic, dependend on mean image intensity, and need to be optimised empirically.
 */

#@ File (style="directory") dir
#@ int px //defaults missing
#@ int uM


//get standard settings
run("Fresh Start");
setBatchMode(true);
run("Set Measurements...", "area centroid center perimeter bounding fit shape feret's stack limit display redirect=None decimal=2");

// set parameters
f1 = 2.5; // How many SD below the max intensity defines the local maxima? smaller = stricter
f2 = 0.5; // How many % of Intensity values are Iba1 signal? smaller = stricter, sensitive!
area_max = 250; // minimum size for spot detection of local maxima in px
opening = 2; // binary opening of maxima areas, sensitive!
size_filter = 700; // filter size for segmented cells in px


//make subfolder for count masks
if(!File.exists(dir+"/segmentation")) {
	File.makeDirectory(dir+"/segmentation");
}

filelist = getFileList(dir);

// set up log
print("Iba-1 segmentation in vivo v2");
print("Directory; " + dir);
print("f1 = "+ f1);
print("f2 = "+ f2);
print("area_max = "+ area_max);
print("opening = "+ opening);
print("size_ filter = "+ size_filter);
print("------");

print("Working on "+dir);

// looping through folder, find all tifs to perform analysis
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".tif")||endsWith(filelist[i], ".tiff")) { //tiff files

    	// update Log
    	print(filelist[i] + " - File " + i + " of " + lengthOf(filelist));

        // open image, avg project and invert, get tile, scale and stats
        //open(dir + File.separator + filelist[i]);
        run("Bio-Formats Importer", "open=["+dir + File.separator + filelist[i]+"] autoscale color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");

        title = getTitle();
        run("Z Project...", "projection=[Max Intensity]");
        run("Invert");
        run("Subtract Background...", "rolling=50");
        run("Gaussian Blur...", "sigma=1");
        rename("currentimage"); 
        
        // get Image stats and set threshold values, set scale
        run("Set Scale...", "distance="+px+" known="+uM+" unit=microns");
        getStatistics(area, mean, min, max, std, histogram);
        th_max = max - f1 * std; // threshold for Area Maxima
        th_ws = max - f2 * max ; // threshold for watershed    
		
		
		// area maxima 
		run("AreaMaxima local maximum detection (2D, 3D)", "minimum="+area_max+" threshold="+th_max);
		selectImage(nImages); // watershed window is not active by default, this should open the most recent image
		run("Apply binary opening to a label map (2D, 3D)", "margin="+opening);
		saveAs("tiff", dir+"/segmentation/maxima_"+title);
		rename("maxima");
		
		// Watershed
		run("Watershed with seed points (2D, 3D)", "image_to_segment=currentimage image_with_seed_points=maxima use_threshold threshold="+th_ws);
		selectImage(nImages); // watershed window is not active by default, this should open the most recent image

		// remove border labels and remove small areas (in px)
		run("Remove Border Labels", "left right top bottom");
		run("Label Size Filtering", "operation=Greater_Than size="+size_filter);
		
		//save segmentation count mask
		saveAs("tiff", dir+"/segmentation/segmented_"+title);
		
		// make overlay
		selectWindow(title);
		run("Add Image...", "image=segmented_"+ title +" x=0 y=0 opacity=40");
		saveAs("tiff", dir+"/segmentation/overlay_"+title);
		
		// Measure segemnted areas with MorphoLibJ
		selectWindow("segmented_"+title);
		run("Analyze Regions", "area perimeter circularity euler_number bounding_box centroid equivalent_ellipse ellipse_elong. convexity max._feret oriented_box oriented_box_elong. geodesic tortuosity max._inscribed_disc average_thickness geodesic_elong.");
		saveAs("Results", dir+"/segmentation/Results_"+title+".csv");
	
		// clean up
		run("Close All");
		run("Collect Garbage");
    } 
}

print("All done!");

// save Log
selectWindow("Log");
saveAs("Text", dir+"/segmentation/Log.txt");
