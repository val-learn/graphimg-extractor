% Read the image
img = imread('期末專題圖檔.jpeg');

% Extract RGB channels
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

% Create a mask for red dots
red_mask = (R > 200) & (G < 100) & (B < 100);

% Remove small noise
red_mask = bwareaopen(red_mask, 50);

% Detect blue markers (to avoid splitting near them)
blue_mask = (B > 150) & (R < 100) & (G < 100);
blue_mask = bwareaopen(blue_mask, 30);

% Morphological erosion to help separate touching dots
se = strel('disk', 2);
red_mask_eroded = imerode(red_mask, se);

% Label connected components
[labeled, ~] = bwlabel(red_mask_eroded);
stats = regionprops(labeled, 'Centroid', 'Area', 'BoundingBox');

% Process each region
centroids = [];
for i = 1:length(stats)
    bbox = stats(i).BoundingBox;
    x_start = max(1, round(bbox(1)));
    y_start = max(1, round(bbox(2)));
    x_end = min(size(img,2), round(bbox(1) + bbox(3)));
    y_end = min(size(img,1), round(bbox(2) + bbox(4)));

    % Check if there's blue nearby
    region_check = blue_mask(max(1,y_start-15):min(size(img,1),y_end+15), ...
                             max(1,x_start-15):min(size(img,2),x_end+15));
    has_blue_nearby = sum(region_check(:)) > 100;

    if stats(i).Area > 200 && ~has_blue_nearby
        % Try to split merged dots
        region_mask = labeled(y_start:y_end, x_start:x_end) == i;
        dist_transform = bwdist(~region_mask);
        dist_transform = imgaussfilt(dist_transform, 1.5);
        local_max = imregionalmax(dist_transform);
        [y_peaks, x_peaks] = find(local_max);

        if length(x_peaks) == 2
            peak_dist = sqrt((x_peaks(1)-x_peaks(2))^2 + (y_peaks(1)-y_peaks(2))^2);
            if peak_dist > 8
                for j = 1:2
                    centroids = [centroids; x_start + x_peaks(j) - 1, y_start + y_peaks(j) - 1];
                end
            else
                centroids = [centroids; stats(i).Centroid];
            end
        else
            centroids = [centroids; stats(i).Centroid];
        end
    else
        centroids = [centroids; stats(i).Centroid];
    end
end

fprintf('Detected %d red dots total\n', size(centroids, 1));

% Manual fix: merge dots 8 and 9 if present
if size(centroids, 1) >= 9
    merged_x = mean([centroids(8,1), centroids(9,1)]);
    merged_y = mean([centroids(8,2), centroids(9,2)]);

    fprintf('Merging dots 8 and 9:\n');
    fprintf('  Dot 8 was at: (%.1f, %.1f)\n', centroids(8,1), centroids(8,2));
    fprintf('  Dot 9 was at: (%.1f, %.1f)\n', centroids(9,1), centroids(9,2));
    fprintf('  Merged to: (%.1f, %.1f)\n', merged_x, merged_y);

    centroids(8,:) = [merged_x, merged_y]; % Replace dot 8 with merged coordinates
    centroids(9,:) = []; % Remove dot 9

    fprintf('After merge: %d red dots\n', size(centroids, 1));
end

% Remove legend dot (first centroid)
centroids(1,:) = [];
fprintf('Remaining dots after removing legend: %d data points\n', size(centroids, 1));

% Sort remaining centroids
centroids_sorted = centroids;
fprintf('\nPixel Coordinates in (x,y) array:\n');
disp(centroids_sorted);

% Convert to plot coordinates (axis scaling)
x_axis_min = 0.00; x_axis_max = 1.10;
y_axis_min = 229.2; y_axis_max = 230.2;


% Detect plot boundaries
gray_img = rgb2gray(img);
edge_img = edge(gray_img, 'Canny');
h_lines = sum(edge_img, 2);
v_lines = sum(edge_img, 1);

[~, locs_h] = findpeaks(h_lines, 'MinPeakHeight', max(h_lines)*0.3, 'MinPeakDistance', 50);
[~, locs_v] = findpeaks(v_lines, 'MinPeakHeight', max(v_lines)*0.3, 'MinPeakDistance', 50);

if length(locs_h) >= 2 && length(locs_v) >= 2
    locs_h = sort(locs_h); locs_v = sort(locs_v);
    y_top = locs_h(1); y_bottom = locs_h(end);
    x_left = locs_v(1); x_right = locs_v(end);

    x_plot = x_axis_min + (centroids_sorted(:,1) - x_left) / (x_right - x_left) * (x_axis_max - x_axis_min);
    y_plot = y_axis_max - (centroids_sorted(:,2) - y_top) / (y_bottom - y_top) * (y_axis_max - y_axis_min);


    coordinates_plot = [x_plot, y_plot];
    fprintf('\n=== FINAL COORDINATES (Se/S, Binding Energy) ===\n');
    fprintf('Index\tSe/S\t\tBinding Energy (eV)\n');
    fprintf('-----\t--------\t-------------------\n');
    for i = 1:size(coordinates_plot, 1)
        fprintf('%d\t%.4f\t\t%.4f\n', i, coordinates_plot(i,1), coordinates_plot(i,2));
    end
else
    fprintf('\nWarning: Could not detect plot boundaries.\n');
    coordinates_pixels = centroids_sorted;
    coordinates_plot = [];
end

% === VISUALIZATION ===
figure('Position', [100, 100, 1400, 600]);

% Plot 1: Original image with detected points
subplot(1,2,1);
imshow(img); 
hold on;

plot(centroids_sorted(:,1), centroids_sorted(:,2), 'rx', 'MarkerSize', 15, 'LineWidth', 3);
plot(centroids_sorted(:,1), centroids_sorted(:,2), 'ro', 'MarkerSize', 15, 'LineWidth', 2);

for i = 1:size(centroids_sorted, 1)
    text(centroids_sorted(i,1)+20, centroids_sorted(i,2), sprintf('%d', i), ...
        'Color', 'red', 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black');
end
hold off;
title('Detected Red Dots', 'FontSize', 12, 'FontWeight', 'bold');

% Plot 2: Extracted coordinates
if ~isempty(coordinates_plot)
    subplot(1,2,2);
    plot(coordinates_plot(:,1), coordinates_plot(:,2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    hold on;
    for i = 1:size(coordinates_plot, 1)
        text(coordinates_plot(i,1)+0.02, coordinates_plot(i,2), sprintf('%d', i), ...
            'FontSize', 9, 'FontWeight', 'bold');
    end
    xlabel('Se/S'); ylabel('Mo3d_{5/2} Binding energy (eV)');
    title('Extracted Data Points'); grid on;
    xlim([0, 1.1]); ylim([229.2, 230.2]);
    hold off;
end

fprintf('\n=== Extraction Complete ===\n');