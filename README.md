# graphimg-extractor
This is a matlab program that help extract point coordinates on images then it recreate the plot on matlab for comparison
# Since this is a Undergraduate Final Project, to verify I own this repository, if you are my professor here is my Name and Student ID
B11104136 馮楊訓

How does B11104136_Final_Project_PartB.m Determine Red Dots and Where in the Code?

### **Criteria for Determining Red Dots):**

The code identifies red dots using **RGB color thresholding** with the following conditions:

1. **Red channel (R) > 200** - High red intensity
2. **Green channel (G) < 100** - Low green intensity  
3. **Blue channel (B) < 100** - Low blue intensity
4. **Area ≥ 50 pixels** - Removes small noise

This combination ensures that only pixels with dominant red color and minimal green/blue components are classified as red dots.

### **Location in the Code:**

**Lines 8-11:**
```matlab
% Create a mask for red dots
red_mask = (R > 200) & (G < 100) & (B < 100);

% Remove small noise
red_mask = bwareaopen(red_mask, 50);
```

**Additional filtering occurs at:**

**Lines 13-15:** Blue marker detection (to avoid false positives)
```matlab
blue_mask = (B > 150) & (R < 100) & (G < 100);
blue_mask = bwareaopen(blue_mask, 30);
```

**Lines 18-20:** Morphological operations to separate touching dots
```matlab
se = strel('disk', 2);
red_mask_eroded = imerode(red_mask, se);
```

**Lines 23-24:** Connected component analysis
```matlab
[labeled, ~] = bwlabel(red_mask_eroded);
stats = regionprops(labeled, 'Centroid', 'Area', 'BoundingBox');
```

### **Summary:**
The primary red dot detection logic is in **lines 8-11**, where RGB thresholding creates a binary mask identifying pixels that meet the red color criteria, followed by noise removal to eliminate small artifacts.
