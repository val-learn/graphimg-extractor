# graphimg-extractor
This is a matlab program that help extract point coordinates on images then it recreate the plot on matlab for comparison
### Since this is a Undergraduate Final Project, to verify I own this repository, if you are my professor here is my Name and Student ID
B11104136 馮楊訓

## To make sure everything runs correctly:
1. Download All File in this repository(including 期末專題圖檔.jpeg)
2. Make sure every file is in the same directory
3. Open the directory in matlab
4. Run the program one by one
5. Follow the program instruction(Only for part A, since its a manual extractor)

### Part B Code is created using the assistant of LLM / AI Specifically Claude Sonnet 4.5 by Anthropic, here are the link of the conversation with Claude:
First Conversation: https://claude.ai/share/7ada7123-03e4-4c99-970f-aa4d6e1d93c5
Second Conversation: https://claude.ai/share/2f358de0-03e0-48ef-992e-52fff0a94a3f

## How the Code Determines Red Dots?

### 1. **Image Loading and Channel Extraction** (Lines 1-5)
```matlab
img = imread('期末專題圖檔.jpeg');
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);
```
- Reads the input image
- Separates the image into Red (R), Green (G), and Blue (B) color channels
- Each channel is a 2D matrix containing intensity values (0-255)

---

### 2. **Primary Red Dot Detection** (Lines 8-11)

#### RGB Color Thresholding
```matlab
red_mask = (R > 200) & (G < 100) & (B < 100);
```
**Detection Criteria:**
- **R > 200**: Red channel must be very bright (above 200 out of 255)
- **G < 100**: Green channel must be dim (below 100)
- **B < 100**: Blue channel must be dim (below 100)

**Why these thresholds?**
- Red dots have high red intensity and low green/blue intensity
- This creates a binary mask where `1` = red pixel, `0` = not red
- The combination ensures we only detect pixels that are predominantly red

#### Noise Removal
```matlab
red_mask = bwareaopen(red_mask, 50);
```
- Removes small connected components with area < 50 pixels
- Eliminates noise and tiny artifacts that aren't actual data points
- Only keeps substantial red regions that are likely real dots

---

### 3. **Blue Marker Detection** (Lines 13-15)
```matlab
blue_mask = (B > 150) & (R < 100) & (G < 100);
blue_mask = bwareaopen(blue_mask, 30);
```
**Purpose:** Detect blue triangle markers to avoid splitting them incorrectly

**Detection Logic:**
- Blue channel > 150 (high blue)
- Red channel < 100 (low red)
- Green channel < 100 (low green)
- Remove noise smaller than 30 pixels

**Why detect blue markers?**
- The plot contains blue triangular data points
- We want to avoid accidentally splitting or misclassifying them
- This mask helps the algorithm distinguish between red and blue markers

---

### 4. **Morphological Processing** (Lines 18-20)
```matlab
se = strel('disk', 2);
red_mask_eroded = imerode(red_mask, se);
```
**Erosion Operation:**
- Creates a disk-shaped structuring element with radius 2 pixels
- Applies erosion to the red mask
- **Effect:** Shrinks the red regions slightly

**Why use erosion?**
- Separates touching or overlapping red dots
- If two dots are very close together, erosion helps create a gap between them
- Makes it easier for the labeling algorithm to recognize them as separate objects

---

### 5. **Connected Component Labeling** (Lines 23-24)
```matlab
[labeled, ~] = bwlabel(red_mask_eroded);
stats = regionprops(labeled, 'Centroid', 'Area', 'BoundingBox');
```
**What this does:**
- `bwlabel`: Assigns a unique label to each connected red region
- `regionprops`: Extracts properties of each labeled region:
  - **Centroid**: (x, y) center position of the dot
  - **Area**: Number of pixels in the dot
  - **BoundingBox**: Rectangle enclosing the dot [x, y, width, height]

**Purpose:** Identifies individual dots and calculates their properties for further processing

---

### 6. **Intelligent Dot Splitting** (Lines 26-59)

This section processes each detected region to handle merged dots:

#### Check Each Region (Lines 27-32)
```matlab
for i = 1:length(stats)
    bbox = stats(i).BoundingBox;
    x_start = max(1, round(bbox(1)));
    y_start = max(1, round(bbox(2)));
    x_end = min(size(img,2), round(bbox(1) + bbox(3)));
    y_end = min(size(img,1), round(bbox(2) + bbox(4)));
```
- Iterates through each detected region
- Extracts bounding box coordinates
- Ensures coordinates stay within image boundaries

#### Blue Proximity Check (Lines 35-37)
```matlab
region_check = blue_mask(max(1,y_start-15):min(size(img,1),y_end+15), ...
                         max(1,x_start-15):min(size(img,2),x_end+15));
has_blue_nearby = sum(region_check(:)) > 100;
```
- Checks a 15-pixel radius around the region for blue markers
- If blue pixels > 100, marks `has_blue_nearby = true`
- **Purpose:** Avoid splitting blue triangular markers

#### Large Region Splitting (Lines 39-56)
```matlab
if stats(i).Area > 200 && ~has_blue_nearby
    % Try to split merged dots
    region_mask = labeled(y_start:y_end, x_start:x_end) == i;
    dist_transform = bwdist(~region_mask);
    dist_transform = imgaussfilt(dist_transform, 1.5);
    local_max = imregionalmax(dist_transform);
    [y_peaks, x_peaks] = find(local_max);
```

**Splitting Algorithm:**
1. **Area > 200 pixels**: Likely contains multiple merged dots
2. **Distance Transform**: Calculates distance from each pixel to the nearest edge
3. **Gaussian Smoothing**: Smooths the distance map (σ=1.5)
4. **Regional Maxima**: Finds peaks in the distance map = dot centers

#### Two-Peak Validation (Lines 48-54)
```matlab
if length(x_peaks) == 2
    peak_dist = sqrt((x_peaks(1)-x_peaks(2))^2 + (y_peaks(1)-y_peaks(2))^2);
    if peak_dist > 8
        for j = 1:2
            centroids = [centroids; x_start + x_peaks(j) - 1, y_start + y_peaks(j) - 1];
        end
```
- If exactly 2 peaks found and they're > 8 pixels apart
- Treats them as 2 separate dots
- Otherwise, treats as single dot

---

## Data Cleanup Operations

### 7. **Manual Merge Correction** (Lines 64-77)
```matlab
if size(centroids, 1) >= 9
    merged_x = mean([centroids(8,1), centroids(9,1)]);
    merged_y = mean([centroids(8,2), centroids(9,2)]);
    
    centroids(8,:) = [merged_x, merged_y];
    centroids(9,:) = [];
end
```
**Purpose:** Fixes a known issue where one dot was incorrectly split into two

**How it works:**
- Checks if at least 9 dots were detected
- Merges dots #8 and #9 by averaging their coordinates
- Removes the duplicate entry
- Prints diagnostic information about the merge

**Why needed?**
- Automated splitting sometimes over-segments
- This manual correction ensures accurate data extraction

---

### 8. **Legend Dot Removal** (Lines 80-81)
```matlab
centroids(1,:) = [];
fprintf('Remaining dots after removing legend: %d data points\n', size(centroids, 1));
```
**Critical cleanup step:**
- The first detected centroid is typically from the legend box
- Removes this non-data point
- Ensures only actual experimental data points remain

**Why the first centroid?**
- Detection proceeds top-to-bottom, left-to-right
- Legend is usually in the upper portion of the plot
- First detected red dot is almost always the legend marker

---

### 9. **Coordinate Transformation** (Lines 87-107)

#### Plot Boundary Detection
```matlab
gray_img = rgb2gray(img);
edge_img = edge(gray_img, 'Canny');
h_lines = sum(edge_img, 2);
v_lines = sum(edge_img, 1);
```
- Converts to grayscale and detects edges
- Finds horizontal and vertical lines (plot axes)
- Identifies plot boundaries automatically

#### Coordinate Conversion
```matlab
x_plot = x_axis_min + (centroids_sorted(:,1) - x_left) / (x_right - x_left) * (x_axis_max - x_axis_min);
y_plot = y_axis_max - (centroids_sorted(:,2) - y_top) / (y_bottom - y_top) * (y_axis_max - y_axis_min);
```
**Transforms pixel coordinates → plot coordinates:**
- X-axis: Pixels → Se/S ratio (0.00 to 1.10)
- Y-axis: Pixels → Binding Energy (229.2 to 230.2 eV)
- Uses linear interpolation based on detected plot boundaries

---

## Summary: Complete Red Dot Detection Pipeline

```
Input Image
    ↓
1. RGB Channel Separation
    ↓
2. Color Thresholding (R>200, G<100, B<100)
    ↓
3. Noise Removal (area ≥ 50 pixels)
    ↓
4. Blue Marker Detection (avoid confusion)
    ↓
5. Morphological Erosion (separate touching dots)
    ↓
6. Connected Component Labeling
    ↓
7. Region Analysis & Intelligent Splitting
    ↓
8. Manual Merge Correction (dots 8 & 9)
    ↓
9. Legend Dot Removal (first centroid)
    ↓
10. Coordinate Transformation (pixels → plot units)
    ↓
Output: (Se/S, Binding Energy) coordinates
```

---

## Key Detection Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Red threshold | R > 200 | Ensure high red intensity |
| Green/Blue threshold | G, B < 100 | Ensure low non-red colors |
| Minimum dot area | 50 pixels | Remove noise |
| Erosion disk radius | 2 pixels | Separate touching dots |
| Split area threshold | 200 pixels | Identify potentially merged dots |
| Peak separation | 8 pixels | Minimum distance for valid split |
| Blue proximity | 15 pixels | Check radius for blue markers |

---

## Output Format

The script produces:
1. **Console Output**: Detected coordinates in both pixel and plot units
2. **Visualization**: 
   - Left panel: Original image with numbered detected dots
   - Right panel: Extracted coordinates on a clean plot
3. **Final Data**: Array of (Se/S, Binding Energy) coordinates

---

## Robustness Features

- ✅ Automatic noise filtering
- ✅ Touching dot separation
- ✅ Blue marker differentiation
- ✅ Manual merge correction for known issues
- ✅ Legend removal
- ✅ Automatic plot boundary detection
- ✅ Clear visualization and diagnostic output

---

## Assignment Context

This code addresses **Part (c)** of the final project:
> "寫出(b)程式中如何判斷是否是紅色點的依據,以及在程式碼中的位置"
> 
> "Write how the program in part (b) determines whether something is a red dot and where this logic appears in the code"

The detection relies on **RGB color thresholding** (lines 8-11) as the primary mechanism, supported by multiple validation and cleanup steps throughout the pipeline.
The primary red dot detection logic is in **lines 8-11**, where RGB thresholding creates a binary mask identifying pixels that meet the red color criteria, followed by noise removal to eliminate small artifacts.
