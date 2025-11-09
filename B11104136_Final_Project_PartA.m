% Read the image
img = imread('期末專題圖檔.jpeg');

imshow(img);

% Step 2: Manually click on points
n = 9;   % number of red points you expect
title('Click The Red Dot', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'red');

fprintf('Click the RED dots on the image shown')
[x_pixels, y_pixels] = ginput(n);
pixel_coordinates = [x_pixels, y_pixels]

% Convert to plot coordinates (axis scaling)
x_axis_min = 0.00; x_axis_max = 1.125;
y_axis_min = 229.2; y_axis_max = 230.2;

% Detect plot boundaries
gray_img = rgb2gray(img);
edge_img = edge(gray_img, 'Canny');
h_lines = sum(edge_img, 2);
v_lines = sum(edge_img, 1);

[~, locs_h] = findpeaks(h_lines, 'MinPeakHeight', max(h_lines)*0.3, 'MinPeakDistance', 50);
[~, locs_v] = findpeaks(v_lines, 'MinPeakHeight', max(v_lines)*0.3, 'MinPeakDistance', 50);

locs_h = sort(locs_h); locs_v = sort(locs_v);
y_top = locs_h(1); y_bottom = locs_h(end);
x_left = locs_v(1); x_right = locs_v(end);

x_plot = x_axis_min + (x_pixels - x_left) / (x_right - x_left) * (x_axis_max - x_axis_min);
y_plot = y_axis_max - (y_pixels - y_top) / (y_bottom - y_top) * (y_axis_max - y_axis_min);


coordinates_plot = [x_plot, y_plot];
fprintf('\n=== FINAL COORDINATES (Se/S, Binding Energy) ===\n');
fprintf('Index\tSe/S\t\tBinding Energy (eV)\n');
fprintf('-----\t--------\t-------------------\n');
for i = 1:size(coordinates_plot, 1)
    fprintf('%d\t%.4f\t\t%.4f\n', i, coordinates_plot(i,1), coordinates_plot(i,2));
end
 
% Plot the Extracted coordinates for comparison
if ~isempty(coordinates_plot)
    subplot(1,2,1); % Change to subplot(1,2,1) to show the image on the left
    imshow(img); % Ensure the image is displayed on the left side
    title('Original Image')
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