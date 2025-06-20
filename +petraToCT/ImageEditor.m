classdef ImageEditor < handle
    % ImageEditor - Simple tool for editing grayscale segmentation masks
    % Sets values to any specified value while preserving other grayscale values
    % Supports three orthogonal views (View 1, 2, 3)
    % Usage: 
    %   editor = ImageEditor(segmentation)  % From matrix
    %   editor = ImageEditor('segmentation.nii')  % From NIFTI file
    
    properties (Access = private)
        % Data
        segmentation    % Segmentation image (3D double)
        seg_nii         % NIFTI structure for segmentation
        seg_filename    % Filename of segmentation
        undoStack       % Cell array of previous segmentation states
        redoStack       % Cell array of undone states
        
        % UI State
        currentSlice    % Current slice index
        toolRadius      % Radius of editing tool
        setValue        % Value to set when painting
        orientation     % Current view: 'axial', 'sagittal', 'coronal'
        
        % UI Components
        fig             % Main figure
        ax              % Axes for image display
        imgHandle       % Image object handle
        toolPreview     % Handle for tool preview overlay (patch object)
        colorbarAx      % Axes for colorbar
        colorbarImg = []  % Colorbar image handle
        
        % UI Controls
        sliceSlider     % Slider for slice navigation
        sliceText       % Text showing current slice
        toolSlider      % Slider for tool size
        toolText        % Text input for tool size
        valueText       % Text input for set value
        setMinButton    % Button to set value to min
        setZeroButton   % Button to set value to 0
        setMaxButton    % Button to set value to max
        orientDropdown  % Dropdown for view orientation
        undoButton      % Undo button
        redoButton      % Redo button
        saveButton      % Save button
        loadButton      % Load button
        valueLabel      % Label showing value under cursor
    end
    
    methods
        function obj = ImageEditor(segmentation_input)
            % Constructor - Initialize editor with segmentation
            % Input can be either:
            %   1. Matrix: segmentation (3D double)
            %   2. Filename: segmentation_filename (NIFTI file)
            
            % Handle segmentation input
            if ischar(segmentation_input) || isstring(segmentation_input)
                % Load from NIFTI file
                obj.seg_nii = load_untouch_nii(segmentation_input);
                obj.segmentation = double(obj.seg_nii.img);
                obj.seg_filename = char(segmentation_input);
            else
                % Direct matrix input
                obj.segmentation = double(segmentation_input);
                obj.seg_nii = [];
                obj.seg_filename = '';
            end
            
            obj.undoStack = {};
            obj.redoStack = {};
            obj.orientation = 'axial';
            obj.currentSlice = round(size(obj.segmentation, 3) / 2);
            obj.toolRadius = 5;
            obj.setValue = 1;  % Default paint value
            
            obj.setupUI();
            obj.updateDisplay();
        end
        
        function setupUI(obj)
            % Create the user interface
            obj.fig = uifigure('Name', 'Image Editor', ...
                'Position', [100, 100, 800, 600], ...
                'WindowButtonMotionFcn', @(~,~) obj.onMouseMove(), ...
                'WindowButtonDownFcn', @(~,~) obj.onMouseClick(), ...
                'WindowScrollWheelFcn', @(~,e) obj.onScroll(e), ...
                'KeyPressFcn', @(~,e) obj.onKeyPress(e));
            
            % Main layout
            mainLayout = uigridlayout(obj.fig, [2, 1]);
            mainLayout.RowHeight = {'1x', 60};
            
            % Top panel for image and controls
            topPanel = uigridlayout(mainLayout, [1, 3]);
            topPanel.ColumnWidth = {'1x', 50, 150};
            
            % Image axes
            obj.ax = uiaxes(topPanel);
            obj.ax.XTick = [];
            obj.ax.YTick = [];
            obj.ax.DataAspectRatio = [1 1 1];  % Maintain aspect ratio
            
            % Tool preview will be created after first image display
            obj.toolPreview = [];
            
            % Colorbar axes
            colorbarPanel = uigridlayout(topPanel, [3, 1]);
            colorbarPanel.RowHeight = {20, '1x', 20};
            colorbarPanel.Padding = [5, 20, 5, 20];
            
            % Max label at top
            uilabel(colorbarPanel, 'Text', '', 'HorizontalAlignment', 'center', ...
                'Tag', 'maxLabel');
            
            obj.colorbarAx = uiaxes(colorbarPanel);
            obj.colorbarAx.XTick = [];
            obj.colorbarAx.YTick = [];
            
            % Min label at bottom
            uilabel(colorbarPanel, 'Text', '', 'HorizontalAlignment', 'center', ...
                'Tag', 'minLabel');
            
            % Control panel
            controlPanel = uigridlayout(topPanel, [12, 1]);
            controlPanel.RowHeight = {40, 40, 30, 30, 30, 40, 40, 40, 30, 30, 30, 30};
            controlPanel.Padding = [10, 10, 10, 10];
            
            % Orientation dropdown
            orientPanel = uigridlayout(controlPanel, [1, 2]);
            orientPanel.ColumnWidth = {'fit', '1x'};
            uilabel(orientPanel, 'Text', 'View:');
            obj.orientDropdown = uidropdown(orientPanel, ...
                'Items', {'View 1', 'View 2', 'View 3'}, ...
                'ItemsData', {'axial', 'sagittal', 'coronal'}, ...
                'Value', 'axial', ...
                'ValueChangedFcn', @(~,e) obj.setOrientation(e.Value));
            
            % Set value controls
            valuePanel = uigridlayout(controlPanel, [1, 2]);
            valuePanel.ColumnWidth = {'fit', '1x'};
            uilabel(valuePanel, 'Text', 'Set Value:');
            obj.valueText = uieditfield(valuePanel, 'numeric', ...
                'Value', obj.setValue, ...
                'ValueChangedFcn', @(~,e) obj.setSetValue(e.Value));
            
            % Quick set buttons (vertically stacked)
            minVal = min(obj.segmentation(:));
            maxVal = max(obj.segmentation(:));
            
            obj.setMinButton = uibutton(controlPanel, ...
                'Text', sprintf('Set to Min (%.2f)', minVal), ...
                'ButtonPushedFcn', @(~,~) obj.quickSetValue(minVal));
            
            obj.setZeroButton = uibutton(controlPanel, ...
                'Text', 'Set to 0', ...
                'ButtonPushedFcn', @(~,~) obj.quickSetValue(0));
            
            obj.setMaxButton = uibutton(controlPanel, ...
                'Text', sprintf('Set to Max (%.2f)', maxVal), ...
                'ButtonPushedFcn', @(~,~) obj.quickSetValue(maxVal));
            
            % Tool size label
            uilabel(controlPanel, 'Text', 'Tool Size:');
            
            % Tool size controls
            toolPanel = uigridlayout(controlPanel, [1, 2]);
            toolPanel.ColumnWidth = {'1x', 60};
            
            obj.toolSlider = uislider(toolPanel, ...
                'Limits', [1, 20], ...
                'Value', obj.toolRadius, ...
                'ValueChangedFcn', @(~,e) obj.setToolRadius(e.Value));
            
            obj.toolText = uieditfield(toolPanel, 'numeric', ...
                'Value', obj.toolRadius, ...
                'Limits', [1, 50], ...
                'ValueChangedFcn', @(~,e) obj.setToolRadius(e.Value));
            
            % Value under cursor label
            obj.valueLabel = uilabel(controlPanel, ...
                'Text', 'Value: N/A', ...
                'FontWeight', 'bold');
            
            % Undo button
            obj.undoButton = uibutton(controlPanel, ...
                'Text', 'Undo', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) obj.undo());
            
            % Redo button
            obj.redoButton = uibutton(controlPanel, ...
                'Text', 'Redo', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) obj.redo());
            
            % Save button
            obj.saveButton = uibutton(controlPanel, ...
                'Text', 'Save', ...
                'ButtonPushedFcn', @(~,~) obj.save());
            
            % Load button
            obj.loadButton = uibutton(controlPanel, ...
                'Text', 'Load', ...
                'ButtonPushedFcn', @(~,~) obj.load());
            
            % Bottom panel for slice navigation
            bottomPanel = uigridlayout(mainLayout, [1, 2]);
            bottomPanel.ColumnWidth = {'1x', 100};
            
            % Slice slider
            obj.sliceSlider = uislider(bottomPanel, ...
                'Limits', [1, size(obj.segmentation, 3)], ...
                'Value', obj.currentSlice, ...
                'MajorTicks', [], ...
                'ValueChangedFcn', @(~,e) obj.setSlice(round(e.Value)));
            
            % Slice text
            obj.sliceText = uilabel(bottomPanel, ...
                'Text', sprintf('Slice: %d/%d', obj.currentSlice, size(obj.segmentation, 3)), ...
                'HorizontalAlignment', 'center');
        end
        
        function updateDisplay(obj)
            % Update the displayed image
            switch obj.orientation
                case 'axial'
                    slice_data = obj.segmentation(:, :, obj.currentSlice);
                case 'sagittal'
                    slice_data = squeeze(obj.segmentation(:, obj.currentSlice, :))';
                case 'coronal'
                    slice_data = squeeze(obj.segmentation(obj.currentSlice, :, :))';
            end
            
            % Flip vertically
            slice_data = flipud(slice_data);
            
            % Get data range including negative values
            minVal = min(obj.segmentation(:));
            maxVal = max(obj.segmentation(:));
            
            % Normalize to 0-1 for display
            if maxVal > minVal
                display_data = (slice_data - minVal) / (maxVal - minVal);
            else
                display_data = slice_data * 0 + 0.5;  % All same value, show as gray
            end
            
            % Convert to RGB (grayscale)
            rgb = repmat(display_data, [1, 1, 3]);
            
            if isempty(obj.imgHandle) || ~isvalid(obj.imgHandle)
                obj.imgHandle = image(obj.ax, rgb);
                obj.ax.XLim = [0.5, size(rgb, 2) + 0.5];
                obj.ax.YLim = [0.5, size(rgb, 1) + 0.5];
                obj.ax.YDir = 'reverse';
                obj.ax.DataAspectRatio = [1 1 1];  % Maintain aspect ratio
            else
                obj.imgHandle.CData = rgb;
                % Update axis limits in case dimensions changed
                obj.ax.XLim = [0.5, size(rgb, 2) + 0.5];
                obj.ax.YLim = [0.5, size(rgb, 1) + 0.5];
                obj.ax.DataAspectRatio = [1 1 1];  % Maintain aspect ratio
            end
            
            % Update colorbar
            obj.updateColorbar(minVal, maxVal);
            
            % Update slice text
            maxSlice = obj.getMaxSlice();
            obj.sliceText.Text = sprintf('Slice: %d/%d', obj.currentSlice, maxSlice);
        end
        
        function onMouseMove(obj)
            % Update tool preview on mouse movement
            point = obj.ax.CurrentPoint;
            x = round(point(1, 1));
            y = round(point(1, 2));
            
            % Get current slice dimensions
            [h, w] = obj.getCurrentSliceDims();
            
            if x >= 1 && x <= w && y >= 1 && y <= h
                % Get the actual data value
                % The image is displayed flipped, so we need to get the value from the flipped data
                switch obj.orientation
                    case 'axial'
                        slice_data = obj.segmentation(:, :, obj.currentSlice);
                        slice_data = flipud(slice_data);  % Match the display flip
                        value = slice_data(y, x);
                    case 'sagittal'
                        slice_data = squeeze(obj.segmentation(:, obj.currentSlice, :))';
                        slice_data = flipud(slice_data);  % Match the display flip
                        value = slice_data(y, x);
                    case 'coronal'
                        slice_data = squeeze(obj.segmentation(obj.currentSlice, :, :))';
                        slice_data = flipud(slice_data);  % Match the display flip
                        value = slice_data(y, x);
                end
                obj.valueLabel.Text = sprintf('Value: %.2f', value);
                
                % Create tool preview using patch
                if obj.toolRadius == 1
                    % Single pixel - create small square
                    xv = [x-0.5, x+0.5, x+0.5, x-0.5];
                    yv = [y-0.5, y-0.5, y+0.5, y+0.5];
                else
                    % Create circle
                    theta = linspace(0, 2*pi, 50);
                    xv = x + (obj.toolRadius - 0.5) * cos(theta);
                    yv = y + (obj.toolRadius - 0.5) * sin(theta);
                end
                
                % Delete old preview if exists
                if ~isempty(obj.toolPreview) && isvalid(obj.toolPreview)
                    delete(obj.toolPreview);
                end
                
                % Create new preview patch
                hold(obj.ax, 'on');
                if obj.setValue > 0.5
                    % White for high values
                    obj.toolPreview = patch(obj.ax, xv, yv, [1 1 1], ...
                        'FaceAlpha', 0.3, 'EdgeColor', 'w', 'LineWidth', 1);
                else
                    % Dark gray for low values
                    obj.toolPreview = patch(obj.ax, xv, yv, [0.2 0.2 0.2], ...
                        'FaceAlpha', 0.3, 'EdgeColor', 'k', 'LineWidth', 1);
                end
                hold(obj.ax, 'off');
            else
                % Hide preview when outside image
                if ~isempty(obj.toolPreview) && isvalid(obj.toolPreview)
                    delete(obj.toolPreview);
                    obj.toolPreview = [];
                end
                obj.valueLabel.Text = 'Value: N/A';
            end
        end
        
        function onMouseClick(obj)
            % Apply tool on mouse click
            point = obj.ax.CurrentPoint;
            x = round(point(1, 1));
            y = round(point(1, 2));
            
            % Get current slice dimensions
            [h, w] = obj.getCurrentSliceDims();
            
            if x >= 1 && x <= w && y >= 1 && y <= h
                % Save current state for undo
                obj.pushUndo();
                
                % Create mask
                if obj.toolRadius == 1
                    % Single voxel
                    mask = false(h, w);
                    mask(y, x) = true;
                else
                    % Circular brush
                    [xx, yy] = meshgrid(1:w, 1:h);
                    mask = ((xx - x).^2 + (yy - y).^2) <= (obj.toolRadius - 0.5)^2;
                end
                
                % Flip mask vertically to match the flipped display
                mask = flipud(mask);
                
                % Apply to volume based on orientation
                switch obj.orientation
                    case 'axial'
                        slice_data = obj.segmentation(:, :, obj.currentSlice);
                        slice_data(mask) = obj.setValue;
                        obj.segmentation(:, :, obj.currentSlice) = slice_data;
                    case 'sagittal'
                        for i = 1:size(obj.segmentation, 1)
                            for j = 1:size(obj.segmentation, 3)
                                if mask(j, i)
                                    obj.segmentation(i, obj.currentSlice, j) = obj.setValue;
                                end
                            end
                        end
                    case 'coronal'
                        for i = 1:size(obj.segmentation, 2)
                            for j = 1:size(obj.segmentation, 3)
                                if mask(j, i)
                                    obj.segmentation(obj.currentSlice, i, j) = obj.setValue;
                                end
                            end
                        end
                end
                
                obj.updateDisplay();
                obj.updateSetButtons();
            end
        end
        
        function onScroll(obj, event)
            % Handle mouse wheel scrolling
            maxSlice = obj.getMaxSlice();
            newSlice = obj.currentSlice - event.VerticalScrollCount;
            newSlice = max(1, min(maxSlice, newSlice));
            obj.setSlice(newSlice);
        end
        
        function onKeyPress(obj, event)
            % Handle keyboard shortcuts
            switch event.Key
                case {'z', 'Z'}
                    if any(strcmp(event.Modifier, 'control'))
                        obj.undo();
                    end
                case {'y', 'Y'}
                    if any(strcmp(event.Modifier, 'control'))
                        obj.redo();
                    end
            end
        end
        
        function setSlice(obj, slice)
            % Set current slice
            obj.currentSlice = slice;
            obj.sliceSlider.Value = slice;
            obj.updateDisplay();
        end
        
        function setToolRadius(obj, radius)
            % Set tool radius
            obj.toolRadius = round(radius);
            obj.toolSlider.Value = obj.toolRadius;
            obj.toolText.Value = obj.toolRadius;
        end
        
        function setOrientation(obj, orientation)
            % Set view orientation
            obj.orientation = orientation;
            
            % Reset slice to middle of new dimension
            maxSlice = obj.getMaxSlice();
            obj.currentSlice = round(maxSlice / 2);
            
            % Update slider limits
            obj.sliceSlider.Limits = [1, maxSlice];
            obj.sliceSlider.Value = obj.currentSlice;
            
            % Hide/delete tool preview during orientation change
            if ~isempty(obj.toolPreview) && isvalid(obj.toolPreview)
                delete(obj.toolPreview);
                obj.toolPreview = [];
            end
            
            obj.updateDisplay();
        end
        
        function setSetValue(obj, value)
            % Set the value to paint with
            obj.setValue = value;
            obj.valueText.Value = value;
        end
        
        function quickSetValue(obj, value)
            % Quick set value and update UI
            obj.setValue = value;
            obj.valueText.Value = value;
        end
        
        function maxSlice = getMaxSlice(obj)
            % Get maximum slice number for current orientation
            switch obj.orientation
                case 'axial'
                    maxSlice = size(obj.segmentation, 3);
                case 'sagittal'
                    maxSlice = size(obj.segmentation, 2);
                case 'coronal'
                    maxSlice = size(obj.segmentation, 1);
            end
        end
        
        function updateColorbar(obj, minVal, maxVal)
            % Update the colorbar display
            colorbarData = linspace(1, 0, 256)';  % Reverse: max at top, min at bottom
            colorbarRGB = repmat(colorbarData, [1, 20, 3]);
            
            if isempty(obj.colorbarImg) || ~isvalid(obj.colorbarImg)
                obj.colorbarImg = image(obj.colorbarAx, colorbarRGB);
                obj.colorbarAx.XLim = [0.5, 20.5];
                obj.colorbarAx.YLim = [0.5, 256.5];
                obj.colorbarAx.YDir = 'normal';
            else
                obj.colorbarImg.CData = colorbarRGB;
            end
            
            % Update min/max labels
            maxLabel = findobj(obj.fig, 'Tag', 'maxLabel');
            minLabel = findobj(obj.fig, 'Tag', 'minLabel');
            if ~isempty(maxLabel)
                maxLabel.Text = sprintf('%.2f', maxVal);
            end
            if ~isempty(minLabel)
                minLabel.Text = sprintf('%.2f', minVal);
            end
        end
        
        function updateSetButtons(obj)
            % Update the text on the set buttons when data changes
            minVal = min(obj.segmentation(:));
            maxVal = max(obj.segmentation(:));
            
            if ~isempty(obj.setMinButton) && isvalid(obj.setMinButton)
                obj.setMinButton.Text = sprintf('Set to Min (%.2f)', minVal);
            end
            if ~isempty(obj.setMaxButton) && isvalid(obj.setMaxButton)
                obj.setMaxButton.Text = sprintf('Set to Max (%.2f)', maxVal);
            end
        end
        
        function [h, w] = getCurrentSliceDims(obj)
            % Get current slice dimensions
            switch obj.orientation
                case 'axial'
                    h = size(obj.segmentation, 1);
                    w = size(obj.segmentation, 2);
                case 'sagittal'
                    h = size(obj.segmentation, 3);
                    w = size(obj.segmentation, 1);
                case 'coronal'
                    h = size(obj.segmentation, 3);
                    w = size(obj.segmentation, 2);
            end
        end
        
        function pushUndo(obj)
            % Save current state to undo stack
            obj.undoStack{end+1} = obj.segmentation;
            obj.redoStack = {}; % Clear redo stack
            
            % Limit undo stack size
            if length(obj.undoStack) > 50
                obj.undoStack(1) = [];
            end
            
            obj.undoButton.Enable = 'on';
            obj.redoButton.Enable = 'off';
        end
        
        function undo(obj)
            % Undo last action
            if ~isempty(obj.undoStack)
                obj.redoStack{end+1} = obj.segmentation;
                obj.segmentation = obj.undoStack{end};
                obj.undoStack(end) = [];
                
                obj.updateDisplay();
                obj.updateSetButtons();
                
                if isempty(obj.undoStack)
                    obj.undoButton.Enable = 'off';
                end
                obj.redoButton.Enable = 'on';
            end
        end
        
        function redo(obj)
            % Redo last undone action
            if ~isempty(obj.redoStack)
                obj.undoStack{end+1} = obj.segmentation;
                obj.segmentation = obj.redoStack{end};
                obj.redoStack(end) = [];
                
                obj.updateDisplay();
                obj.updateSetButtons();
                
                if isempty(obj.redoStack)
                    obj.redoButton.Enable = 'off';
                end
                obj.undoButton.Enable = 'on';
            end
        end
        
        function save(obj)
            % Save the current segmentation to a NIFTI file
            % Prompts for output filename
            
            % Get default filename
            if ~isempty(obj.seg_filename)
                [path, name, ext] = fileparts(obj.seg_filename);
                defaultName = fullfile(path, [name ext]);
            else
                defaultName = 'segmentation.nii';
            end
            
            % Prompt for filename
            obj.fig.Visible = 'off';
            [filename, pathname] = uiputfile({'*.nii;*.nii.gz', 'NIFTI files (*.nii, *.nii.gz)'}, ...
                'Save Segmentation As', defaultName);
            obj.fig.Visible = 'on';
            
            if filename == 0
                return;  % User cancelled
            end
            
            fullPath = fullfile(pathname, filename);
            
            % Update segmentation in NIFTI structure
            if isempty(obj.seg_nii)
                error('Cannot save: No NIFTI structure available. Please load from a NIFTI file first.');
            end
            
            % Update the image data
            obj.seg_nii.img = obj.segmentation;
            
            % Save
            save_untouch_nii(obj.seg_nii, fullPath);
            
            % Update stored filename
            obj.seg_filename = fullPath;
            
            fprintf('Segmentation saved to: %s\n', fullPath);
        end
        
        function load(obj, segmentation_input)
            % Load a segmentation from file or matrix
            % Input: either a filename (string) or a 3D matrix
            
            obj.pushUndo();
            
            if nargin < 2
                % Prompt for file
                obj.fig.Visible = 'off';
                [filename, pathname] = uigetfile({'*.nii;*.nii.gz', 'NIFTI files (*.nii, *.nii.gz)'}, ...
                    'Load Segmentation');
                obj.fig.Visible = 'on';
                
                if filename == 0
                    return;  % User cancelled
                end
                
                segmentation_input = fullfile(pathname, filename);
            end
            
            if ischar(segmentation_input) || isstring(segmentation_input)
                % Load from file
                obj.seg_nii = load_untouch_nii(segmentation_input);
                obj.segmentation = double(obj.seg_nii.img);
                obj.seg_filename = char(segmentation_input);
            else
                % Load from matrix
                obj.segmentation = double(segmentation_input);
            end
            
            % Update button texts
            obj.updateSetButtons();
            
            obj.updateDisplay();
        end
        
        function segmentationMatrix = getSegmentation(obj)
            % Get the current segmentation as a 3D matrix
            % Output: segmentationMatrix - double matrix with original values
            segmentationMatrix = obj.segmentation;
        end
    end
end
