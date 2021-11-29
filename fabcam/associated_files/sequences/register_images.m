% Given a sequence of similar images of identical size, 
% one of them selected as a reference,
% projectively transform the non-reference images to best fit the reference
% at manually selected control points.

function register_images(images_pathnames_cell_array, reference_image_index, reference_image_crop_rows_cols)
    ri = reference_image_crop_rows_cols(1); rf = reference_image_crop_rows_cols(2);
    ci = reference_image_crop_rows_cols(3); cf = reference_image_crop_rows_cols(4);

    % Acquire.
    number_of_images = length(images_pathnames_cell_array);
    images = cell(number_of_images);
    for image_index = 1:number_of_images
        images{image_index} = double(imread(images_pathnames_cell_array{image_index}))/255.0;
    end
    [nr, nc, ~] = size(images{reference_image_index});

    % For drawing the focus bar.
    final_width = cf - ci + 1;
    final_height = rf - ri + 1;
    line_thickness = round(0.005 * final_width);
    bar_thickness = round(0.05 * final_height);
    
    function focus_bar = make_horizontal_focus_bar(image_index)
        focus_bar = 0.35*ones(bar_thickness, final_width, 3);
        focus_bar(:,round((final_width-line_thickness)/number_of_images*(image_index-1)+line_thickness)+1:round((final_width-line_thickness)/number_of_images*image_index),:) = 1;
        focus_bar(1:line_thickness,:,:) = 0;
        focus_bar(bar_thickness-line_thickness+1:bar_thickness,:,:) = 0;
        focus_bar(:,final_width-line_thickness+1:final_width,:) = 0;
        for index = 1:number_of_images
            focus_bar(:,round((final_width-line_thickness)/number_of_images*(index-1)+1):round((final_width-line_thickness)/number_of_images*(index-1)+line_thickness),:) = 0;
        end
    end

    function focus_bar = make_vertical_focus_bar(image_index)
        focus_bar = 0.35*ones(final_height, bar_thickness, 3);
        focus_bar(round((final_height-line_thickness)/number_of_images*(number_of_images-image_index)+line_thickness)+1:round((final_height-line_thickness)/number_of_images*(number_of_images-image_index+1)),:,:) = 1;
        focus_bar(:,1:line_thickness,:) = 0;
        focus_bar(:,bar_thickness-line_thickness+1:bar_thickness,:) = 0;
        focus_bar(final_height-line_thickness+1:final_height,:,:) = 0;
        for index = 1:number_of_images
            focus_bar(round((final_height-line_thickness)/number_of_images*(index-1)+1):round((final_height-line_thickness)/number_of_images*(index-1)+line_thickness),:,:) = 0;
        end
    end

    % Crop the reference image and save.
    imwrite([images{reference_image_index}(ri:rf,ci:cf,:);make_horizontal_focus_bar(reference_image_index)], sprintf('h_%d.jpg', reference_image_index), 'Quality', 100);
    imwrite([images{reference_image_index}(ri:rf,ci:cf,:),make_vertical_focus_bar(reference_image_index)], sprintf('v_%d.jpg', reference_image_index), 'Quality', 100);

    % Have the user select corresponding control points in the first non-reference image and the reference image.
    % Then fit a projective transformation to the selected point pairs,
    % apply the transformation to the non-reference image, crop, and save the result.
    if reference_image_index == 1
        first_non_reference_image_index = 2;
    else
        first_non_reference_image_index = 1;
    end
    [pts, ref_pts] = cpselect(images{first_non_reference_image_index}, images{reference_image_index}, 'Wait', true);
    tform = fitgeotrans(pts, ref_pts, 'projective');
    transformed_image = imwarp(images{first_non_reference_image_index}, tform);
    min_transformed_coords = min(transformPointsForward(tform, [1, 1; 1, nr; nc, 1; nc, nr]));
    x_shift = round(1 - min_transformed_coords(1)); y_shift = round(1 - min_transformed_coords(2));
    imwrite([transformed_image(ri+y_shift:rf+y_shift,ci+x_shift:cf+x_shift,:);make_horizontal_focus_bar(first_non_reference_image_index)], sprintf('h_%d.jpg', first_non_reference_image_index), 'Quality', 100);
    imwrite([transformed_image(ri+y_shift:rf+y_shift,ci+x_shift:cf+x_shift,:),make_vertical_focus_bar(first_non_reference_image_index)], sprintf('v_%d.jpg', first_non_reference_image_index), 'Quality', 100);

    % Have the user select corresponding control points in each other non-reference image.
    % Then fit a projective transformation to the selected point pairs,
    % apply the transformation, 
    % crop, and save the resulting image.
    for image_index = 1:number_of_images
        if image_index ~= reference_image_index && image_index ~= first_non_reference_image_index
            [pts, new_ref_pts] = cpselect(images{image_index}, images{reference_image_index}, ref_pts, ref_pts, 'Wait', true);
            tform = fitgeotrans(pts, new_ref_pts, 'projective');
            transformed_image = imwarp(images{image_index}, tform);
            min_transformed_coords = min(transformPointsForward(tform, [1, 1; 1, nr; nc, 1; nc, nr]));
            x_shift = round(1 - min_transformed_coords(1)); y_shift = round(1 - min_transformed_coords(2));
            imwrite([transformed_image(ri+y_shift:rf+y_shift,ci+x_shift:cf+x_shift,:);make_horizontal_focus_bar(image_index)], sprintf('h_%d.jpg', image_index), 'Quality', 100);
            imwrite([transformed_image(ri+y_shift:rf+y_shift,ci+x_shift:cf+x_shift,:),make_vertical_focus_bar(image_index)], sprintf('v_%d.jpg', image_index), 'Quality', 100);
        end
    end
end