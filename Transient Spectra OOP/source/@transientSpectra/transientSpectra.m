classdef transientSpectra
	properties
        %raw data
        spectra = doubleWithUnits();  %[pixels, delays, rpts, grating pos, schemes]
        spectra_std = doubleWithUnits(); %[pixels, delays, rpts, grating pos, schemes]
        wavelengths = doubleWithUnits();  %[pixels, grating pos]
        delays = doubleWithUnits();   %[delays, repeats, grating pos]
        gPos = zeros(); %[]
        
        %identifying information
        name = '';
        shortName = '';
        description = '';
                         
        schemes = {}; %list of data schemes
                         
        %cosmetic information for data display. 
        %todo: convert to class so that display method calls can auto parse
        %varargin and return an updated  cosmetics object that can 
        %auto-convert data and auto-update axis labels
%         cosmetic = struct('pixelUnits','nm',...
%                           'signalUnits','OD',...
%                           'delayUnits','ps',...
%                           'pixelLimits',[0,0],...
%                           'delayLimits',[0,0],...
%                           'targetScheme',1);
%         
%         baseUnits = struct('pixels','nm',...
%                            'delay','ps',...
%                            'signal','OD');
        
        %size information
        sizes = struct('nRpts', 0, ...
                       'nGPos', 0, ...
                       'nSchemes', 0, ...
                       'nDelays', 0, ...
                       'nPixels', 0);
    end
    
    properties %(Access = protected)
       isDefault = true;
       displayNames = nameRule();
    end
    
    %methods that children classes must implement:
%     methods (Abstract)
%         
%         %converts any inferior class to another inferior class 
%         convertTransient(obj, targetObj);
%     end
    
    %% Constructor, load, export, get and set methods
    methods

        %%**CONSTRUCTOR METHODS**%%
        function obj = transientSpectra(varargin)
        %inputs:
        %transientSpectra(); initialize default FSRS object
        %transientSpectra(path); load data holder object or structs from path and
        %   convert to 
           
        %%--PREFORMAT INPUT ARGS--%%
           %To support object arrays, inputs classes will be queried as
           %elements of cell arrays. If the input is not a cell array,
           %convert it to a cell array first.
           for ii = 1:nargin %loop over arguments
               if ~iscell(varargin{ii}) %if argument is not already a scell
                   varargin{ii} = {varargin{ii}}; %convert non-cell varargin elements to cell
               end
           end
        
        %%--BUILD OBJECT--%%
           if nargin==0 %constructs a default object --do nothing  
               
           else %data is available, build non-default object
           %%--COPY DATA INTO OBJECT ARRAY--%%       
               argSize = size(varargin{1});      %determine input cell array size, this will be the object array size
               argNumel = numel(varargin{1});    %for easy looping, loop over elements of arguments
               argInd = 1;  %keep track of which argument is being parsed
               
               argCell = varargin{argInd}(:);
               
               %first set of inputs are data containing. Parse these first before name-value paris
               if ischar(varargin{argInd}{1}) && argInd == 1   %file path load routine
                   %initialize object by loading path
                   obj(argNumel) = loadPath(obj(1),argCell{argNumel});  %todo: loop inside loadPath?
                   for objInd = 1:argNumel-1
                      obj(objInd) = loadPath(obj(objInd),argCell{objInd});
                   end
                   argInd = argInd + 1;
               elseif isa(varargin{argInd}{1},'data_holder')    %data holder object load routine
                   argInd = argInd + 1;
               elseif isa(varargin{argInd}{1},'transientSpectra')   %conversion from child object to this class
                   argInd = argInd + 1;
               elseif isstruct(varargin{argInd}{1}) && nargin > 1   %dh_static and dh_array load routine
                   argInd = argInd + 2;
               else    %invalid 1st argument
                   error(['1st argument must pass data to object. Allowed data classes are an element ',...
                          'or cell array of: char, data_holder, struct, or transientSpectra. Got ',...
                          class(varargin{argInd}{1}) '.']);
               end
               
               %If data has been loaded succesfully, set each element default object flag to false
               [obj(:).isDefault] = deal(false);
               
           %%--PARSE KEYWORDS AND NAME_VALUE PAIRS--%%
               while argInd <= nargin
                   assert(ischar(varargin{argInd}{1}),['Expected element or cell array of chars for ',...
                          'keywords or name-value pairs. Got ' class(varargin{argInd}{1}) '.']);
                   switch varargin{argInd}{1}
                       case 'short name'
                           assert(argInd+1<=nargin,'Name-value pair short name requires an additional char input');
                           assert(ischar(varargin{argInd+1}{1}),'Name-value pair short name requires an additional',...
                                  ' char or cell array of char input.');
                           assert(numel(varargin{argInd+1})==argNumel,['The number of short names must',...
                                  'match the number of objects. Expected ' num2str(argNumel) ' elements, got ',...
                                   num2str(numel(varargin{argInd+1})) ' elements.']);
                               
                           %assign array of arguments directly using deal
                           [obj(:).shortName] = deal(varargin{argInd+1}{:});
                           argInd = argInd + 2;
                       otherwise %throw error to avoid infinite loop
                           error([varargin{argInd}{1} ' is an unsupported keyword or name-value pair.']);
                   end %switch
               end %while
               
           %%--FINAL OBJECT FORMATTING--%%
               %reshape object to match input array shape
               obj = reshape(obj,argSize);
               
           end %nargin
        end %constructor
               
        % EXPORT the object data to an igor compatible .mat file
        [outputStruct, filePath] = export(obj,filePath,varargin)
        
        %%**GET-SET METHODS**%%
        %Data units
        function obj = setUnits(obj,wavelengthUnit,delayUnit,spectraUnit)
        % SETUNITS sets the units for the wavelengths, delays, and spectra.
        % Use an empty char array, [] or '', as a flag to skip changing the unit.
        % Changing the unit updates the numeric values in the relavent arrays.
        %
        % obj = obj.SETUNITS(wavelengthUnit,delayUnit,spectraUnit)
        %   Changes the units for wavelengths, delays, and spectra
        %
        % obj = obj.SETUNITS([],[],spectraUnit)
        %   Changes the units for spectra only. Any combination of brakets is
        %   allowed to select which units need to be changed.
           
           % Formtat object array dims into a column for easy looping
           objSize = size(obj);
           objNumel = numel(obj);
           obj = obj(:);
           
           %loop through each object and update units
           for objInd = 1:objNumel
               if ~isempty(wavelengthUnit)
                   obj(objInd).wavelengths.unit = wavelengthUnit;
               end

               if ~isempty(delayUnit)
                   obj(objInd).delays.unit = delayUnit;
               end

               if ~isempty(spectraUnit)
                   obj(objInd).spectra.unit = spectraUnit;
                   obj(objInd).spectra_std.unit = spectraUnit;
               end
           end
           
           %convert object back to original array dims
           obj = reshape(obj,objSize);
        end
        
        function [wavelengthUnit, delayUnit, spectraUnit] = getUnits(obj)
        % GETUNITS returns the current wavelength, delay, and signal units for the
        % object array. If the units are the same for all elements, the units are
        % returned as char arrays. If the units are different for any element, all
        % outputs are returned as cell arrays of chars. The returned cell arrays
        % are the same size as the object array.
        %
        % [wavelengthUnit, delayUnit, spectraUnit] = GETUNITS(obj)
        %   Returns char arrays or cell arrays containing doubleWithUnits unit
        %   short names for the wavelengths, delays, and spectra.
            
            % Formtat object array dims into a column for easy looping
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            %initialize wavelength, delay, and spectra output for loop
            wavelengthUnit = cell(objNumel,1);
            delayUnit = cell(objNumel,1);
            spectraUnit = cell(objNumel,1);
            
            %loop over objects in array and retrive units 
            for objInd = 1:objNumel
                wavelengthUnit{objInd} = obj(objInd).wavelengths.unit;
                delayUnit{objInd} = obj(objInd).delays.unit;
                spectraUnit{objInd} = obj(objInd).spectra.unit;
            end
            
            %check to see if all units are the same for all objects
            sameWlUnit = all(strcmp(wavelengthUnit{1},wavelengthUnit));
            sameDelayUnit = all(strcmp(delayUnit{1},delayUnit));
            sameSpectraUnit = all(strcmp(spectraUnit{1},spectraUnit));
            allUnitsSame = sameWlUnit && sameDelayUnit && sameSpectraUnit;
            
            %Decide on whether to return one unit or cell array of units
            if allUnitsSame
                wavelengthUnit = wavelengthUnit{1};
                delayUnit = delayUnit{1};
                spectraUnit = spectraUnit{1};
            else
                wavelengthUnit = reshape(wavelengthUnit,objSize);
                delayUnit = reshape(delayUnit,objSize);
                spectraUnit = reshape(spectraUnit,objSize);
            end

        end
        
        %Schemes manipulation
        function obj = getScheme(obj, targetScheme)
        % GETSCHEME returns an object array that only contains the target scheme.
        % The target scheme can be either the char name of the scheme or its index.
        % 
        % obj = obj.GETSCHEME(targetScheme)
        %   Returns an object array with data that corresponds to the targetScheme
        %   name or index.
        
            %prepare object array for looping
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            %loop over object elements
            for objInd = 1:objNumel
                %compare target schemes against available schemes in object
                if ischar(targetScheme) %if scheme is a name, convert it to an index
                    schemeInd = strcmp(targetScheme,obj(objInd).schemes);
                    assert(any(schemeInd),[targetScheme ' was not found for object element ' num2str(objInd) '.']);
                else %if scheme is already an index
                    schemeInd = targetScheme;
                    assert(schemeInd<=length(obj(objInd).schemes),[num2str(schemeInd) ' is greater than the number ',...
                                                                 'of availble schemes for object element' num2str(objInd) '.']);
                end
                
                %update object properties
                obj(objInd).spectra.data = obj(objInd).spectra.data(:,:,:,:,schemeInd);
                obj(objInd).spectra_std.data = obj(objInd).spectra_std.data(:,:,:,:,schemeInd);
                obj(objInd).schemes = obj(objInd).schemes(schemeInd);
                obj(objInd).sizes.nSchemes = 1;
            end
            
            %return obj back to its original dims
            obj = reshape(obj, objSize);
        end   
                
        function [logicalOut, ind] = containsScheme(obj, targetScheme)
        % CONTAINSSCHEME returns a logical array whose elements are true when the
        % object array element contains the targetScheme. The output logical array
        % is the same size as the object array.
        %
        % logicalOut = obj.CONTAINSSCHEME(targetScheme)
        %
        % [logicalOut, ind] = obj.CONTAINSSCHEME(targetScheme)
        %   Returns an additional logical ind that indicates at which index the 
        %   target scheme is present. The size of ind is:
        %   [max number of schemes in any object element, [objSize]]

            %prepare object array for data access
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            %a cell array of all schemes for each object array element
            schemeList = {obj.schemes}; 
            
            %loop over object elements to see if its scheme list contains
            %the targetScheme
            logicalOut = false(objNumel,1);
            ind = false(max(cellfun(@length,schemeList)),objNumel);
            for ii = 1:objNumel
               tmp = strcmp(targetScheme,schemeList{ii});
               ind(1:length(tmp),ii) = tmp;
               logicalOut(ii) = any(ind(:,ii));
            end
            
            %convert the array size of logical out to the original object array size
            logicalOut = reshape(logicalOut,objSize);
            ind = reshape(ind,[size(ind,1),objSize]);
        end
        
        function [uniqueSchemes, ind] = getUniqueSchemes(obj)
        % GETUNIQUECHEMES returns a cell array of all unique scheme names contained
        % in the object array.
        %
        % uniqueSchemes = obj.GETUNIQUECHEMES(targetScheme)
        %   Returns a cell array of chars that contain the unique scheme names in 
        %   the obj array.  
        %
        % [uniqueSchemes, ind] = obj.GETUNIQUECHEMES(targetScheme)
        %   Returns an additional logical ind that indicates in dim 1 at which index
        %   each  unique scheme is present. The size of ind is:
        %   [max number of schemes in any object element, nUniqueSchemes, [objSize]] 
        
            %prepare object array for data access
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            %Get unique schemes out of the object
            schemeList = {obj.schemes};
            schemeListAll = vertcat(schemeList{:}); %a cell array of all schemes with char as elements
            uniqueSchemes = unique(schemeListAll); %unique schemes inside the object array
            
            %return index of unique scheme
            nUniqueSchemes = length(uniqueSchemes);          
            ind = false(max(cellfun(@length,schemeList)),nUniqueSchemes,objNumel);
            for ii = 1:nUniqueSchemes
                [~,ind(:,ii,:)] = containsScheme(obj,uniqueSchemes{ii});
            end
            
            %return indecies as original size of object
            %[scheme index, unique scheme, [objSize]]
            ind = reshape(ind, [size(ind,1), size(ind,2), objSize]);

        end
        
        function [commonSchemes, ind] = getCommonSchemes(obj)
        % GETCOMMONSCHEMES returns a cell array of scheme names that are common to 
        % all elements of the object array.
        %
        % commonSchemes = obj.GETCOMMONSCHEMES()
        %   Returns a cell array of chars that contain the common scheme names in 
        %   the obj array.
        %
        % [commonSchemes, ind] = obj.GETCOMMONSCHEMES()
        %   Returns an additional logical ind that indicates in dim 1 at which 
        %   index the scheme is present. The size of ind is:
        %   [max number of schemes in any object element, nCommonSchemes,[objSize]]

            %prepare object array for data access
            objSize = size(obj);
            obj = obj(:);
            
            %get unique schemes and their indicies from the object array
            [uniqueSchemes, ind] = obj.getUniqueSchemes();
            
            %schemes that are common to all elements of the object array
            %along object element dim 3 and scheme index dim 1
            commonInd = all(any(ind,1),3);
            commonSchemes = uniqueSchemes(commonInd(:));
            ind = ind(:,commonInd(:),:);
            
            %return indecies as original size of object
            %[scheme index, unique scheme, [objSize]]
            ind = reshape(ind, [size(ind,1), size(ind,2), objSize]);
        end
        
        function [objOut, schemeList] = splitSchemes(objIn, varargin)
        
        %%--PRE_PROCESSING OF OBJECT AND SCHEMES--%%
            %Get object size to determine final output object size
            if isvector(objIn)
                %on output, first dim will be the original vector length, and the 2nd dim will be the scheme size
                objSize = length(objIn); 
            else
                %on output, the obj size will be preserved and the scheme size will be appended as the last dim
                objSize = size(objIn);   
            end
            
            %prepare object array for looping
            objNumel = numel(objIn);
            objIn = objIn(:);
            
            %schemes that are common to all elements of the object array.
            %Only these schemes, or a subset, can be returned
            schemeList = objIn.getCommonSchemes;
            nSchemes = length(schemeList);
            
            assert(nSchemes>0,'No common schemes found. Schemes cannot be split of object array does not have common schemes');
            
        %%--PARSE USER INPUT--%%
            %default options for user input
            searchFlag = false;
            dropFlag = false;
            
            %parse varargin
            argInd = 1;
            userSchemes = {};
            while argInd <= length(varargin)
                if ischar(varargin{argInd}) %User is either using keyword, name-value pair, or listing the schemes to keep
                    switch varargin{argInd}
                        case '-search'  %search schemeList
                            searchChar = varargin{argInd+1}; %to do: check that next input is a string
                            searchFlag = true;
                            argInd = argInd + 2;
                        case '-drop' %user wants to drop schemes from search results or list
                            dropFlag = true;
                            argInd = argInd + 1;
                        otherwise %user is listing specific schemes to keep, add to scheme register
                            userSchemes = [userSchemes; varargin(argInd)];
                            argInd = argInd + 1;
                    end
                elseif isvector(varargin{argInd})   %User passed a vector of scheme indicies
                    userSchemes = schemeList(varargin{argInd});
                    break;  %no other inputs are allowed with vector input
                else
                    error('Invalid input. Expected keyword, name-value pair, list of schemes, or vector of scheme indicies');
                end
            end       
            
            %search common scheme against user input and add to userSchemes
            if searchFlag
                foundStr = contains(schemeList,searchChar,'IgnoreCase',true);
                userSchemes = [userSchemes; schemeList(foundStr)];
            end
            
            %if user made a custom selection
            if ~isempty(userSchemes)
                %remove duplicate user schemes
                userSchemes = unique(userSchemes);
                
                %check whether user schemes are valid
                schemeInd = false(length(userSchemes),nSchemes);
                for ii = 1:length(userSchemes)
                   schemeInd(ii,:) = strcmp(userSchemes{ii},schemeList); 
                   assert(any(schemeInd(ii,:)), ['Could not find scheme: ' userSchemes{ii} '. Available schemes are ' strjoin(schemeList,', ') '.']);
                end
                
                %once all schemes are validated, select subset of schemeList
                if dropFlag %drop user schemes from schemeList
                    schemeList = schemeList(~any(schemeInd,1),1);
                else %use user schemes instead of schemeList
                    schemeList = userSchemes;
                end
                
                nSchemes = length(schemeList);
            end
        
        %%--GENERATE OBJECT ARRAY WITH SPLIT SCHEMES--%%
            %initialize output object array, which will be [numel,nSchemes]
            objOut(objNumel,nSchemes) = objIn(objNumel);
            
            %loop over object elements
            for ii = 1:nSchemes
                objOut(:,ii) = objIn.getScheme(schemeList{ii});
            end
            
            %return obj back to its original dims
            objOut = reshape(objOut, [objSize, nSchemes]);
        end
            
    end
    
    %% Protected methods (loading data into object)
    %Use constructor to load data.
    methods (Access = protected)
        %loads a .mat file from a path and converts to a FSRS object
        function varargout = loadPath(obj,myPath)
            loaded = load(myPath);   %load the path contents 
            contents = fieldnames(loaded);   %get the variables in the loaded data
            fileName = split(myPath,'\');
            fileName = fileName{end};
            switch class(loaded.(contents{1}))   %check the variable class
                case 'struct'    %this should be a data_holder object
                    if strcmp(contents{1},'dh_static') %this is a raw data data_holder
                        %first load with acquisition data holder
                        [varargout{1:nargout}] = convertDH(obj,loaded.dh_static,loaded.dh_array);
                        
                        %update name in output objects
                        for ii = 1:nargout
                           varargout{ii}.name = fileName; 
                        end
                    else
                        %return error
                    end
                case 'data_holder'
                   %this is a data_holder object
                   %call dh conversion routine
                case 'FSRS'
                   %this is a FSRS object
                otherwise
                   %error
            end
        end
        
        % CONVERTDH converts a data holder into a transientSpectra. 
        % See convertDH.m for generic implementation. Override this method in 
        % subclasses for specific implementation.
        obj = convertDH(obj, dh_static, dh_array);
    end
    
    %% Protected methods (General class functionality)
    methods %(Access = protected)
        function [obj, unitStr, nameFlag] = buildDisplayNames(obj,varargin)
        % BUILDDISPLAYNAMES generates a generic name rule for data display and
        % export. The method updates the displayNames property. Further
        % modifications can be made by using the nameRule class methods.      
        
        %1. set default naming options for exported data when there are multiple schemes and grating positions
            nameFlag = struct('shortName', length(unique({obj(:).shortName}))>1,...     %show the short name
                              'label', false,...                                        %show function specific label
                              'scheme', length(obj.getUniqueSchemes)>1,...              %show the scheme name
                              'gPos', false,...         %show the grating position
                              'repeats', false,...      %show the rpt number
                              'delay', false,...        %show the delay number
                              'wavelengths', false,...  %show the wavelength number
                              'spectraUnit', false);    %show the data unit
        
        
        %2. use parser object to override nameFlag values with user arguments 
            % and pass additional inputs
            p = inputParser;
            p.FunctionName = 'buildDisplayNames';
            
            %add nameFlag fields in loop so that partial matching can be used
            paramNames = fieldnames(nameFlag);
            for ii = 1:length(paramNames)
                p.addParameter(paramNames{ii}, nameFlag.(paramNames{ii}), @(l)islogical(l));
            end
            
            %parse arguments and collect results
            p.parse(varargin{:});
            for ii = 1:length(paramNames)
                nameFlag.(paramNames{ii}) = p.Results.(paramNames{ii});
            end
            
        %3. define unit strings for each object
            
            % Format object array dims into a column for easy looping
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            for objInd = 1:objNumel
                unitStr = struct('spectra',obj(objInd).spectra.unit,...
                                 'wl',obj(objInd).wavelengths.unit,...
                                 'delay',obj(objInd).delays.unit);

            %4. build name rule for each object. NOTE: this does not add wavelength or delay 
                %strings since these are grating position and can be repeatindex specific
                obj(objInd).displayNames = nameRule({...
                    'shortName',  {obj(objInd).shortName},                                                          0, nameFlag.shortName && ~isempty(obj(objInd).shortName);...
                    'label',      {''},                                                                             0, nameFlag.label;...
                    'dataUnit',   {['in ' unitStr.spectra]},                                                        0, nameFlag.spectraUnit;...
                    'scheme',     obj(objInd).schemes,                                                              1, nameFlag.scheme;...
                    'gPos',       strcat({'gPos: '},strcat(strtrim(cellstr(num2str(obj(objInd).gPos(:))))), ' nm'), 2, nameFlag.gPos;...
                    'repeats',    strcat({'rpt '}, strtrim(cellstr(num2str((1:obj(objInd).sizes.nRpts)')))),        3, nameFlag.repeats;...
                    'wl',         {''},                                                                             4, nameFlag.wavelengths;... 
                    'delay',      {''},                                                                             4, nameFlag.delay});

            %5. reset counter
                obj(objInd).displayNames = obj(objInd).displayNames.reset;
            end
            
            %convert object array back to original size
            obj = reshape(obj,objSize);
        
        end
    end
    
    %% Plotting/contour methods for data display
    methods
        function plotSpectra(obj, varargin)
            
        %1. use parser object to override plotFlag values with user arguments and pass extra arguments to plot
            p = inputParser;
            p.FunctionName = 'plotSpectra';
            p.KeepUnmatched = true;
            
            %default values for flags
            plotFlag = struct('average',true,...
                               'legend',true);
            
            %allow user to specify axes object with plot
            p.addOptional('ax',gca,@(ax)isa(ax,'matlab.graphics.axis.Axes'));
                       
            %add plotFlag fields in loop so that partial matching can be used    
            paramNames = fieldnames(plotFlag);
            for ii = 1:length(paramNames)
                p.addParameter(paramNames{ii}, plotFlag.(paramNames{ii}), @(l)islogical(l));
            end
            
            %add delay list with all delays (empty array) as default value
            p.addParameter('delays',[], @(d) isa(d,'double') && isvector(d));
            
            %add an option to display the index on the x-axis
            p.addParameter('index',false, @(l) islogical(l));
            
            %User may also specify a linespec argument. inputParser is not
            %smart enough to parse linespec, therefore remove and parse
            %manually:
            linespec = '-';
            for ii = 1:length(varargin)
                if islinespec(varargin{ii}) %if the input is a linespec
                    linespec = varargin{ii}; %update linespec value
                    varargin(ii) = [];  %remove argument from varargin
                end
            end
            
            %parse arguments and collect results
            p.parse(varargin{:});
            
            %collect flag options
            for ii = 1:length(paramNames)
                plotFlag.(paramNames{ii}) = p.Results.(paramNames{ii});
            end
            
            %collect delay subset to plot
            delayVals = p.Results.delays;
            
            %collect extra arguments to pass to plot:
            extraArgs = struct2cell(p.Unmatched);
            
        %2. Object pre-formatting to ready data for plot loop
            % Format object array dims into a column for easy looping
            objNumel = numel(obj);
            obj = obj(:);
            
            %Ensure all objects in array have the same units
            tmpUnits = cell(3,1);
            [tmpUnits{:}] = obj(1).getUnits;
            obj = obj.setUnits(tmpUnits{:});
            
            %average object over repeats
            if plotFlag.average
                obj = obj.average;
            end
            
            %Generate object name rule for line/legend display
            [obj, unitStr] = obj.buildDisplayNames();
            
            %check hold state to preserve default axes class display behavior
            holdState = ishold();
            firstTime = true;
        
        %3. Loop over data, do object index specific formatting, and plot data
            for objInd = 1:objNumel  %loop over elements of object array
                
                %if user specified a delay subset, get object subset to plot
                if ~isempty(delayVals)
                    obj(objInd) = obj(objInd).subset('delays',delayVals);
                end
                
                %modify legend name rules for specific object element
                legendNames = obj(objInd).displayNames.modify(...
                    'gPos.flag',    obj(objInd).sizes.nGPos > 1,...     %if multiple grating positions
                    'repeats.flag', obj(objInd).sizes.nRpts > 1,...     %this will only display if average is off
                    'delay.flag',   obj(objInd).sizes.nDelays > 1,...   %display delays
                    'delay.values', strcat(strtrim(cellstr(num2str(mean(obj(objInd).delays.data,[2,3],'omitnan'),'%.3g'))), {' '}, unitStr.delay)); %delay values
                
                %adjust increment levels to match loop/permute/reshape
                %order:          pos loop, [spectra, rpts x delays x schemes]
                %significance:       1                 4       3        2
                legendNames = legendNames.modify(...
                    'gPos.level',1,...
                    'scheme.level',2,...
                    'repeats.level',4,...
                    'delay.level',3);
                
                %rearrange name display order to match significance order:
                legendNames = legendNames.rearrange('shortName','gPos','scheme','delay','repeats');
                
                %build legend name levels for autoincrementing name across loop
                legendNames = legendNames.buildLevels();
                
                %loop over grating positions
                for ii = 1:obj(objInd).sizes.nGPos  
                    %add data to x
                    x = obj(objInd).wavelengths.data(:,ii);
                    
                    %if user specified 'index', true option
                    if p.Results.index
                        x = 1:length(x);
                    end
                    
                    %avg of rpts and pick the first dataScheme
                    y = obj(objInd).spectra.data(:,:,:,ii,:); %[pixels, delays, rpts, grating pos, schemes]
                    y = permute(y,[1,3,2,5,4]); %change display priority [pixels, rpts, delays, schemes,1]
                    y = reshape(y,obj(objInd).sizes.nPixels,[]); %[pixels, rpts x delays x schemes x 1]
                    
                    %Loop over columns of y-data to assign a display name for each line
                    for jj = 1:size(y,2)
                        if ~all(isnan(y(:,jj))) %make sure there are values to plot
                            %generate legend name
                            [plotDispStr, legendNames] = legendNames.buildName('autoIncrement',true,'delimiter',', ');

                            %custom generate inputs to pass to plot function
                            plotArgs = [{p.Results.ax}; {x; y(:,jj)}; {linespec}; extraArgs{:}; {'DisplayName'}; {plotDispStr}];  

                            %This preserves the default axes class display behavior
                            if firstTime
                                plot(plotArgs{:});
                                firstTime = false;
                                hold on;
                            else
                                plot(plotArgs{:});
                            end
                        else %if the spectra is all NaN
                            %skip plotting in increment legend name
                            legendNames = legendNames.increment;
                        end
                        
                    end %loop over delays x schemes
                end %loop over grating positions
            end %loop over object elements
        
        %4. Post-formatting
            %return to previous hold state
            if ~holdState
                hold off;
            end
            
            %display legend for all lines
            if plotFlag.legend
                legend();
            end
            
            %update x and y units
            ylabel(obj(1).spectra.dispName);
            
            %if user specified 'index', true option
            if p.Results.index
                xlabel('index'); 
            else %normal x-axis label display
                xlabel(obj(1).wavelengths.dispName);
            end
        end
        
        function plotKinetics(obj, varargin)
        %1. use parser object to override plotFlag values with user arguments and pass extra arguments to plot
            p = inputParser;
            p.FunctionName = 'plotTrace';
            p.KeepUnmatched = true;
            
            %allow user to specify axes object with plot
            p.addOptional('ax',gca,@(ax)isa(ax,'matlab.graphics.axis.Axes'));
            
            %default values for flags
            plotFlag = struct('average',true,...
                               'legend',true);
            
            %add plotFlag fields in loop so that partial matching can be used
            paramNames = fieldnames(plotFlag);
            for ii = 1:length(paramNames)
                p.addParameter(paramNames{ii}, plotFlag.(paramNames{ii}), @(l)islogical(l));
            end
            
            %add delay list with all delays (empty array) as default value
            p.addParameter('wavelengths',[], @(d) isa(d,'double') && isvector(d));
            
            %add an option to display the index on the x-axis
            p.addParameter('index',false, @(l) islogical(l));
            
            %User may also specify a linespec argument. inputParser is not
            %smart enough to parse linespec, therefore remove and parse
            %manually:
            linespec = '-';
            for ii = 1:length(varargin)
                if islinespec(varargin{ii}) %if the input is a linespec
                    linespec = varargin{ii}; %update linespec value
                    varargin(ii) = [];  %remove argument from varargin
                end
            end
            
            %parse arguments and collect results
            p.parse(varargin{:});
            
            %collect flag options
            for ii = 1:length(paramNames)
                plotFlag.(paramNames{ii}) = p.Results.(paramNames{ii});
            end
            
            %collect delay subset to plot
            wlVals = p.Results.wavelengths;
            
            %collect extra arguments to pass to plot:
            extraArgs = struct2cell(p.Unmatched);
            
        %2. Object pre-formatting to ready data for plot loop
            % Format object array dims into a column for easy looping
            objNumel = numel(obj);
            obj = obj(:);
            
            %Ensure all objects in array have the same units
            tmpUnits = cell(3,1);
            [tmpUnits{:}] = obj(1).getUnits;
            obj = obj.setUnits(tmpUnits{:});
            
            %average object over repeats
            if plotFlag.average
                obj = obj.average;
            end
            
            %Generate object name rule for line/legend display
            [obj, unitStr] = obj.buildDisplayNames();
            
            %check hold state to preserve default axes class display behavior
            holdState = ishold();
            firstTime = true;
        
        %3. Loop over data, do object index specific formatting, and plot data
            for objInd = 1:objNumel  %loop over elements of object array
                
                %if user specified a delay subset, get object subset to plot
                if ~isempty(wlVals)
                    obj(objInd) = obj(objInd).subset('wavelengths',wlVals);
                end
                
                %modify legend name rules for specific object element
                legendNames = obj(objInd).displayNames.modify(...
                    'gPos.flag',    obj(objInd).sizes.nGPos > 1,...     %if multiple grating positions
                    'repeats.flag', obj(objInd).sizes.nRpts > 1,...     %this will only display if average is off
                    'wl.flag',   obj(objInd).sizes.nDelays > 1,...      %display delays
                    'wl.values', repmat({''},obj(objInd).sizes.nPixels)); %delay values
                
                %adjust increment levels to match loop/permute/reshape
                %order:          pos loop, [spectra, rpts x wls x schemes]
                %significance:       1                 4     3       2
                legendNames = legendNames.modify(...
                    'gPos.level',1,...
                    'scheme.level',2,...
                    'repeats.level',4,...
                    'wl.level',3);
                
                %rearrange name display order to match significance order:
                legendNames = legendNames.rearrange('shortName','gPos','scheme','wl','repeats');
                
                %build legend name levels for autoincrementing name across loop
                legendNames = legendNames.buildLevels();
                
                %loop over grating positions
                for ii = 1:obj(objInd).sizes.nGPos  
                    %add data to x, y to plot
                    x = mean(obj(objInd).delays.data(:,:,ii),2);
                    
                    %if user specified 'index', true option
                    if p.Results.index
                        x = 1:length(x);
                    end
                    
                    %avg of rpts and pick the first dataScheme
                    y = obj(objInd).spectra.data(:,:,:,ii,:); %[pixels, delays, rpts, grating pos, schemes]
                    y = permute(y,[2,3,1,5,4]); %change display priority [delays, rpts, pixels, schemes,1]
                    y = reshape(y,obj(objInd).sizes.nDelays,[]); %[delays, rpts x pixels x schemes x 1]
                    
                    %update wavelength values specific to the grating position
                    legendNames = legendNames.modify(...
                        'wl.values', strcat(strtrim(cellstr(num2str(obj(objInd).wavelengths(:,ii),'%.4g'))), {' '}, unitStr.wl));
                    
                    %Loop over columns of y-data to assign a display name for each line
                    for jj = 1:size(y,2)
                        %check if y-data exists (is not all NaN)
                        if ~all(isnan(y(:,jj)))
                            %generate legend name
                            [plotDispStr, legendNames] = legendNames.buildName('autoIncrement',true,'delimiter',', ');

                            %custom generate inputs to pass to plot function
                            plotArgs = [{p.Results.ax}; {x; y(:,jj)}; {linespec}; extraArgs{:}; {'DisplayName'}; {plotDispStr}];   

                            %This preserves the default axes class display behavior
                            if firstTime
                                plot(plotArgs{:});
                                firstTime = false;
                                hold on;
                            else
                                plot(plotArgs{:});
                            end
                        else
                            %This grating position does not contain the specified wavelength. 
                            %Skip this line and increment name rule
                            legendNames = legendNames.increment;
                        end
                        
                    end %loop over delays x schemes
                end %loop over grating positions
            end %loop over object elements
        
        %4. Post-formatting
            %return to previous hold state
            if ~holdState
                hold off;
            end
            
            %display legend for all lines
            if plotFlag.legend
                legend();
            end
            
            %update x and y units
            ylabel(obj(1).spectra.dispName);
            
            %if user specified 'index', true option
            if p.Results.index
                xlabel('index'); 
            else %normal x-axis label display
                xlabel(obj(1).delays.dispName);
            end
        end
    end
    
    %% Data manipulation methods that modify the spectra object
    methods
        
        function obj = average(obj)
        % AVERAGE all repeats for each element in the object array
        %
        % obj = obj.AVERAGE()
        %   Averages all repeats for obj.spectra, obj.spectra_std, obj.delays and
        %   updates obj.sizes
            
            % Format object array dims into a column for easy looping
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            for objInd = 1:objNumel
                %average over repeats in data
                obj(objInd).spectra.data = mean(obj(objInd).spectra.data,3,'omitnan');
                obj(objInd).spectra_std.data = sqrt(mean(obj(objInd).spectra_std.data.^2,3,'omitnan'));
                obj(objInd).delays.data = mean(obj(objInd).delays.data,2);
                %todo: add delay uncertainty?

                %update sizes
                obj(objInd).sizes.nRpts = 1;
            end
            
            %convert object array back to original size
            obj = reshape(obj,objSize);
        end
        
        function obj = stitch(obj,varargin)
        % STITCH together available grating positions in object array for each elem. 
        % This works by sorting the data in ascending wavelength and stitching a 
        % pair of grating positions at a time. For multiple grating positions, 
        % the previously stitched grating position is treated as the first grating 
        % position in the stich pair. The stitching behavior in any overlap region 
        % can be done with the following strageiges: average, lower, upper, half, 
        % and linear. Stitching preserves all other dimensions, such as repeats and
        % delays. Stitching currently updates all relevant properties such as 
        % wavelengths, spectra, and grating positions. 
        % todo: update spectra_std. 
        % todo: may need to create a case for direct stitching
        %
        % obj = obj.STITCH()
        %   Stitches all grating positions using the default strategy of linear.
        %   Updates obj.spectra, obj.delays, obj.wavelengths, and obj.sizes
        %
        % obj = obj.STITCH(strategy)
        %   Same as the obj.stitch call but with specified strategy. The strategy
        %   input is type char. Choose from 'average', 'lower', 'upper', 'half', 
        %   and 'linear'.
            
            %optional inputs: strategy for stitching. Default is linear
            if nargin==2
                strategy = varargin{1};
            else
                strategy = 'linear';
            end
                        
            % Format object array dims into a column for easy looping
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            for objInd = 1:objNumel
            %%--Revert units to nm--%%
                %remember old units
                tmpUnits = cell(3,1);
                [tmpUnits{:}] = obj(objInd).getUnits();

                %update units to units where x-axis is in nm
                obj(objInd) = obj(objInd).setUnits('nm',[],[]);       
                
            %%--Sort wavelengths and grating positions--%%
                %sort everything by ascending order in terms of grating position nm, wavelength nm, delay ps
                [gPosSorted,gInd] = sort(obj(objInd).gPos);
                [wl, lInd] = sort(obj(objInd).wavelengths.data(:,gInd));    %[wavelengths, grating positions]

                %sort by grating position first
                data = obj(objInd).spectra.data(:,:,:,gInd,:);  %[pixels, delays, rpts, GRATING POS, schemes]

                %sort by wavelengths next
                for ii = 1:size(lInd,2) %loop over grating positions
                    data(:,:,:,ii,:) = data(lInd(:,ii),:,:,ii,:); %[PIXELS, delays, rpts, GRATING POS, schemes]
                end

                %permute and reshape data so that it is easier to interpolate and stitch
                data = permute(data,[1,2,3,5,4]);   %[pixels, delays, rpts, schemes, grating pos]
                data = reshape(data,obj(objInd).sizes.nPixels,[],obj(objInd).sizes.nGPos); %[pixels, delays*rpts*schemes, grating pos]

            %%--Stitch wavelengths and data--%%
                %grating positions will be stitched in pairs sequentially. If
                %there are multiple grating positions, already stitched data
                %will be treated as one grating position
                tmpWl = wl(~isnan(wl(:,1)),1);    %holder for concatonated wavelengths starting from 1st grating pos
                tmpData1 = data(~isnan(wl(:,1)),:,1);  %holder for concatonated data starting from 1st grating pos

                for ii = 2:obj(objInd).sizes.nGPos %loop over grating positions starting from the 2nd one
                    %remove NaN from next grating position
                    tmpW2 = wl(~isnan(wl(:,ii)),ii); 
                    tmpData2 = data(~isnan(wl(:,ii)),:,ii);

                    %First find overlap region in wavelengths
                    high1 = tmpWl(end);    %highest wavelength in 1st grating position
                    low2 = tmpW2(1);     %lowest wavelength in 2nd grating position

                    [low1, low1Ind] = nearestVal(tmpWl,low2); %lowest wavelength and index in 1st grating position
                    [high2, high2Ind] = nearestVal(tmpW2,high1); %lowest wavelength and index in 2nd grating position

                    %Make sure indicies do not cause data/wavelength extrapolation (overlap region needs to be inclusive)
                    if low1<low2   %check first grating position
                        low1Ind = low1Ind + 1;
                        low1 = tmpWl(low1Ind);
                    end

                    if high2>high1 %check second grating position
                        high2Ind = high2Ind - 1;
                        high2 = wl(high2Ind,ii);
                    end

                    %define lower and upper regions
                    lowWl = tmpWl(1:low1Ind-1); %1st grating positions lower wavelengths
                    highWl = tmpW2(high2Ind+1:end); %2nd grating positions higher wavelengths
                    lowData = tmpData1(1:low1Ind-1,:);   %1st grating positions lower data
                    highData = tmpData2(high2Ind+1:end,:);   %second grating positoins higher data

                    %Next interpolate middle region
                    nInd = ceil(0.5*(length(tmpWl(low1Ind:end))+length(tmpW2(1:high2Ind))));    %average number of in-between indicies
                    midWl = linspace(low1,high2,nInd)';  %new wavelengths in overlap region with linear spacing between them
                    mid1Data = interp1(tmpWl,tmpData1,midWl,'linear');   %interpolate 1st grating position on overlap scale
                    mid2Data = interp1(tmpW2,tmpData2,midWl,'linear'); %interpolate 2nd grating position on overlap scale

                    %Execute strategy to combine data in overlap region
                    switch strategy
                        case 'average' %take the average in the overlap region
                            midData = 0.5*(mid1Data+mid2Data);  
                        case 'lower' %take the lower (1st) grating position
                            midData = mid1Data;  
                        case 'upper' %take the higher (2nd) grating position
                            midData = mid2Data;  
                        case 'half'  %stitch at half-way point
                            midData = [mid1Data(1:floor(nInd/2),:); mid2Data((floor(nInd/2)+1):end,:)];
                        case 'linear'   %do a weighted average with a linear sweep of the weights from the 1st to 2nd grating position
                            weightsFun = polyfit([midWl(1), midWl(end)],[0, 1],1);    %linear fit for weights
                            weights = polyval(weightsFun,midWl);    %calculate weights from nm values
                            midData = mid1Data.*(1-weights)+mid2Data.*weights;  %this does the weighted average
                        otherwise
                            error(['Unsupported strategy. Available stragegies are average, lower, upper, half, and linear. Got ' strategy '.']);
                    end
                    %concatonate the three regions across the 1st (pixel) dimension
                    tmpWl = [lowWl; midWl; highWl]; %store in tmpWl so that it can be fed as 1st grating position in next iteration 
                    tmpData1 = [lowData; midData; highData]; %store in tmpdata so that it can be fed as 1st grating position in next iteration 
                end

            %%--Convert wavelengths and data back to original state and update object parameters--%%
                %reshape and permute data back to original dim order
                data = reshape(tmpData1,[],obj(objInd).sizes.nDelays,obj(objInd).sizes.nRpts,obj(objInd).sizes.nSchemes); %[pixels, delays, rpts, schemes, grating pos]
                data = permute(data,[1,2,3,5,4]); %[pixels, delays, rpts, grating pos, schemes]

                %update values for object properties
                obj(objInd).spectra.data = data;
                obj(objInd).wavelengths.data = tmpWl;
                obj(objInd).gPos = median(gPosSorted);
                obj(objInd).sizes.nPixels = length(tmpWl);
                obj(objInd).sizes.nGPos = 1;
                obj(objInd).delays.data = mean(obj(objInd).delays.data,3);
                
                %set units back to input units
                obj(objInd) = obj(objInd).setUnits(tmpUnits{:});
            end
            
            %set 
            obj = reshape(obj, objSize);
        end
        
        function obj = trim(obj, varargin)
        % TRIM the specra wavelengths and/or delays to the specified range.
        % This function keeps data within the specified range and replaces data
        % outside the specified ranges with NaN. If all wavelengths or delays are
        % removed for the rpt, gpos, or scheme dimension, then the sizes of the
        % wavelength or delay dimensions are reduced to remove extra NaN values.
        % The trim ranges are specified by 'wavelengths',[lower,upper] or 
        % 'delays, [lower, upper]. By default, 'w' and 'delays' are set to 'all', 
        % which does not trim the dimensions.
        % 
        % obj = obj.TRIM()
        %   This call does nothing because the default values for 'wavelengths' and
        %   'delays' is 'all'.
        %
        % obj = obj.TRIM('wavelengths',[lowerWl,upperWl])
        %   Trims the wavelengths to be between lowerWl and upperWl for all grating
        %   positions, repeats, delays, and schemes. With multiple grating
        %   positions, trimmed data is replaced with NaN. Data size is adjsuted to
        %   remove extra NaN values.
        %
        % obj = obj.TRIM('delays',[lowerDelay,upperDelay])
        %   Trims the delays to be between lowerWl and upperWl. Delays are assumed
        %   to be nominally the same for all repeats, grating positions, and
        %   schemes. Trimmed data is replaced with NaN, but usually the data size
        %   is adjusted to remove the extra NaN values.
        % 
        % obj = obj.TRIM('wavelengths',[lowerWl,upperWl],...
        %                'delays',[lowerDelay,upperDelay])
        % obj = obj.TRIM('delays',[lowerDelay,upperDelay],...
        %                'wavelengths',[lowerWl,upperWl])
        %   Trims both wavelengths and delays as described above.
            
            %define default values
            trimVals = struct('wls','all',...
                          'delays','all');
            
            %parse varargin
            if nargin > 1
                for ii = 1:2:(nargin-1)
                    assert(ischar(varargin{ii}),...
                        ['Invalid argument class for name-value pair. Expected class char for name, got ' class(varargin{ii}) '.']);
                    switch varargin{ii}
                        case 'wavelengths'
                            trimVals.wls = varargin{ii+1};
                        case 'delays'
                            trimVals.delays = varargin{ii+1};
                        otherwise
                            error([varargin{ii} ' is not a valid argument name.']); 
                    end
                end
            end
            
            % Format object array dims into a column for easy looping
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            for objInd = 1:objNumel
            
                %trim wavelengths
                if ischar(trimVals.wls)  %this is a do nothing case
                    % Assert correct input to ensure user isn't accidently doing something they're not aware of
                    assert(strcmp(trimVals.wls,'all'),'Expected all keyword or wavelength range [wl1, wl2] of type double.');

                elseif isa(trimVals.wls,'double')   %this does the wavelength trim
                    %ensure the user has correct input before trimming
                    assert(length(trimVals.wls)==2, 'Expected wavelength range [wl1, wl2] of type double.');
                    trimVals.wls = sort(trimVals.wls);  %ensure wavelengths are in increasing order

                    %find the wavelength range indicies in all grating positions
                    wls = obj(objInd).wavelengths.data(:);  %[pixels x gPos]
                    wls = wls(~isnan(wls));
                    wls = sort(wls);

                    %select t subrange within (inclusive) the trim range
                    wls = wls(and(wls>=trimVals.wls(1),wls <= trimVals.wls(2)));

                    %select the object data subset that contains the trimmed t values

                    obj(objInd) = obj(objInd).subset('wavelengths',wls);

                else
                    error('Expected all keyword or wavelength range [wl1, wl2] of type double.');
                end

                %trim delays
                if ischar(trimVals.delays)  %this is a do nothing case
                    % Assert correct input to ensure user isn't accidently doing something they're not aware of
                    assert(strcmp(trimVals.delays,'all'),'Expected all keyword or delay range [d1, d2] of type double.');

                elseif isa(trimVals.delays,'double')   %this does the wavelength trim
                    %ensure the user has correct input before trimming
                    assert(length(trimVals.delays)==2, 'Expected delay range [d1, d2] of type double.');
                    trimVals.delays = sort(trimVals.delays);    %ensure delays are in increasing order

                    %find the wavelength range indicies
                    t = obj(objInd).delays.data(:);  %[delays x rpts x gPos]
                    t = t(~isnan(t));
                    t = sort(t);

                    %select t subrange within (inclusive) the trim range
                    t = t(and(t>=trimVals.delays(1),t <= trimVals.delays(2)));

                    %select the object data subset that contains the trimmed t values
                    obj(objInd) = obj(objInd).subset('delays',t);

                else
                    error('Expected all keyword or delay range [d1, d2] of type double.');
                end
            end
            
            %reshape object back to original array size
            obj = reshape(obj,objSize);
        end
        
        function obj = subset(obj, varargin)
        % SUBSET Returns a subset object array closest to the input target ranges.
        % This function returns objects with data limited to the wavelengths and
        % delays closest to the target ranges. If the user desires a subset with
        % wavelength and delay values that exactly match the input ranges, use the
        % interp method.
        %
        % If all wavelengths or delays are removed for a rpt, gpos, or scheme 
        % dimension, then the sizes of the wavelength or delay dimensions are 
        % reduced to remove extra NaN values. The subset ranges are specified by 
        % 'wavelengths',[lower,upper] or 'delays', [lower, upper]. By default, 
        % 'wls' and 'delays' are set to 'all' which does not change the the 
        % elements of the selected dimensions.
        % 
        % obj = obj.SUBSET()
        %   This call does nothing because the default values for 'wavelegnths' and
        %   'delays' is 'all'.
        %
        % obj = obj.SUBSET('wavelengths',wlArray)
        %   Returns a subset of the obj data with wavelengths closest to wlArray 
        %   for all grating positions, repeats, delays, and schemes. With multiple 
        %   grating positions, extra wavelength data is replaced with NaN. Data 
        %   size is adjsuted to remove extra NaN values.
        %
        % obj = obj.SUBSET('delays',tArray)
        %   Returns a subset of the obj data with delays closest to tArray 
        %   for all grating positions, repeats, delays, and schemes. Extra delays 
        %   are replaced with NaN, but usually the data size is adjusted to remove 
        %   the extra NaN values.
        % 
        % obj = obj.SUBSET('wavelengths',wlArray,'delays',tArray)
        % obj = obj.SUBSET('delays',tArray,'wavelengths',wlArray)
        %   Returns a subset of both wavelengths and delays as described above.    
            
            %define default values
            subVals = struct('wls','all',...
                          'delays','all');
            
            %parse varargin
            if nargin > 1
                for ii = 1:2:(nargin-1)
                    assert(ischar(varargin{ii}),...
                        ['Invalid argument class for name-value pair. Expected class char for name, got ' class(varargin{ii}) '.']);
                    switch varargin{ii}
                        case 'wavelengths'
                            subVals.wls = varargin{ii+1};
                        case 'delays'
                            subVals.delays = varargin{ii+1};
                        otherwise
                            error([varargin{ii} ' is not a valid argument name.']); 
                    end
                end
            end
            
            % Format object array dims into a column for easy looping
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            for objInd = 1:objNumel
            
                %subset wavelengths
                if ischar(subVals.wls)  %this is a do nothing case
                    % Assert correct input to ensure user isn't accidently doing something they're not aware of
                    assert(strcmp(subVals.wls,'all'),'Expected all keyword or wavelength range [wl1, wl2] of type double.');

                elseif isa(subVals.wls,'double') && ~isempty(subVals.wls)  %this does the wavelength trim              
                    %get actual indicies and wavelengths from object data. These may be
                    %multi-dim if there are multiple repeats and grating positions
                    wls = obj(objInd).wavelengths.data; %[wls, gpos]
                    [~, wlInd] = nearestVal(wls,subVals.wls,'threshold',0.01*(max(wls(:))-min(wls(:))));               

                    %for easy looping, do the following dim rearrangement:
                    %[pixels, delays, rpts, gpos, schemes] -> [pixels, delays x rpts x schemes, gpos]
                    tmpSpectra = permute(obj(objInd).spectra.data,[1,2,3,5,4]);
                    tmpSpectra = reshape(tmpSpectra,obj(objInd).sizes.nPixels,[],obj(objInd).sizes.nGPos);

                    %Allocate NaN double arrays and place spectra values into it 
                    trimmedSpectra = nan(size(tmpSpectra)); %[pixels, delays x rpts x schemes, gpos]
                    trimmedWls = nan(size(wls)); %[pixels, gpos]

                    %loop over grating positions to sub-select range dicated by wlInd
                    for ii = 1:obj(objInd).sizes.nGPos
                        %remove NaN from wlInd
                        wlIndNoNaN = wlInd(~isnan(wlInd(:,ii)),ii);

                        %copy desired subrange for each grating position into the NaN arrays starting from index 1
                        trimmedWls(1:length(wlIndNoNaN),ii) = wls(wlIndNoNaN,ii);
                        trimmedSpectra(1:length(wlIndNoNaN),:,ii) = tmpSpectra(wlIndNoNaN,:,ii); 
                    end

                    %remove any dims that are all NaN
                    isWlNaN = all(isnan(trimmedWls),2); %all wls are NaN for each gpos, delay, rpt, and scheme
                    isGPosNaN = all(isnan(trimmedWls),1); %all wls are NaN for each wl, delay, rpt, and scheme
                    trimmedWls = trimmedWls(~isWlNaN,~isGPosNaN); %[wls, gpos]
                    trimmedSpectra = trimmedSpectra(~isWlNaN,:,~isGPosNaN); %[pixels, delays x rpts x schemes, gpos]
                    trimmedGPos = obj(objInd).gPos(~isGPosNaN);

                    %update sizes
                    obj(objInd).sizes.nPixels = size(trimmedWls,1);
                    obj(objInd).sizes.nGPos = length(trimmedGPos);

                    %convert spectra back to original dimensions and dim order
                    %[pixels, delays x rpts x schemes, gpos] -> [pixels, delays, rpts, gpos, schemes]
                    trimmedSpectra = reshape(trimmedSpectra,obj(objInd).sizes.nPixels,obj(objInd).sizes.nDelays,obj(objInd).sizes.nRpts,obj(objInd).sizes.nSchemes,obj(objInd).sizes.nGPos); %[pixels, delays, rpts, schemes, gpos]
                    trimmedSpectra = permute(trimmedSpectra,[1,2,3,5,4]); %[pixels, delays, rpts, gpos, schemes]

                    %add data back to obj(objInd)ect
                    obj(objInd).wavelengths.data = trimmedWls;
                    obj(objInd).spectra.data = trimmedSpectra;
                    obj(objInd).gPos = trimmedGPos;

                else
                    error('Expected all keyword or wavelengths array of type double.');
                end

                %subset delays
                if ischar(subVals.delays)  %this is a do nothing case
                    % Assert correct input to ensure user isn't accidently doing something they're not aware of
                    assert(strcmp(subVals.delays,'all'),'Expected all keyword or delay range [d1, d2] of type double.');

                elseif isa(subVals.delays,'double') && ~isempty(subVals.delays)   %this does the delay subset               
                    %find the wavelength range indicies
                    t = reshape(obj(objInd).delays.data, obj(objInd).sizes.nDelays, []);  %[delays, rpts x gPos]
                    [~,tInd] = nearestVal(t,subVals.delays); %tInd is [delays, rpts x gPos]

                    %for easy looping, do the following dim rearrangement:
                    %[pixels, delays, rpts, gpos, schemes] -> [delays, pixels x schemes, rpts x gpos]
                    tmpSpectra = permute(obj(objInd).spectra.data,[2,1,5,3,4]);
                    tmpSpectra = reshape(tmpSpectra,obj(objInd).sizes.nDelays,obj(objInd).sizes.nPixels*obj(objInd).sizes.nSchemes,[]);

                    %Allocate NaN double arrays and place spectra values into it 
                    trimmedSpectra = nan(size(tmpSpectra)); %[delays, pixels x schems, rpts x gpos]
                    trimmedDelays = nan(size(t)); %[delays, rpts x gpos]

                    %loop over grating positions and repeats to sub-select range dicated by wlInd
                    for ii = 1:size(tInd,2)
                        %remove NaN from tInd
                        tNoNaN = tInd(~isnan(tInd(:,ii)),ii);

                        %copy desired subrange for each grating position into the NaN arrays starting from index 1
                        trimmedDelays(1:length(tNoNaN),ii) = t(tNoNaN,ii); %[delays, rpts x gpos]
                        trimmedSpectra(1:length(tNoNaN),:,ii) = tmpSpectra(tNoNaN,:,ii); %[delays, pixels x schems, rpts x gpos]
                    end

                    %remove any dims that are all NaN
                    isDelayNaN = all(isnan(trimmedDelays),2); %all delays are NaN for each rpt and gpos
                    trimmedDelays = trimmedDelays(~isDelayNaN,:); %[delays, rpts x gpos]
                    trimmedSpectra = trimmedSpectra(~isDelayNaN,:,:); %[delays, pixels x schems, rpts x gpos]

                    %update sizes
                    obj(objInd).sizes.nDelays = size(trimmedDelays,1);

                    %convert spectra back to original dimensions and dim order
                    %[delays, pixels x schemes, rpts x gpos] -> %[pixels, delays, rpts, gpos, schemes]
                    trimmedDelays = reshape(trimmedDelays,obj(objInd).sizes.nDelays,obj(objInd).sizes.nRpts,obj(objInd).sizes.nGPos); %[delays, rpts, gPos]
                    trimmedSpectra = reshape(trimmedSpectra,obj(objInd).sizes.nDelays,obj(objInd).sizes.nPixels,obj(objInd).sizes.nSchemes,obj(objInd).sizes.nRpts,obj(objInd).sizes.nGPos); %[delays, pixels, schemes, rpts, gpos]
                    trimmedSpectra = permute(trimmedSpectra,[2,1,4,5,3]); %[pixels, delays, rpts, gpos, schemes]

                    %add data back to object
                    obj(objInd).delays.data = trimmedDelays;
                    obj(objInd).spectra.data = trimmedSpectra;

                else
                    error('Expected all keyword or delay array of type double.');
                end
            end
            
            %reshape object back to original array size
            obj = reshape(obj,objSize);
        end
        
        function obj = interp(obj, varargin)
        %NOT YET IMPLEMENTED
            %define default values
            interpVals = struct('wls','all',...
                          'delays','all');
            
            %parse varargin
            if nargin > 1
                for ii = 1:2:(nargin-1)
                    assert(ischar(varargin{ii}),...
                        ['Invalid argument class for name-value pair. Expected class char for name, got ' class(varargin{ii}) '.']);
                    switch varargin{ii}
                        case 'wavelengths'
                            interpVals.wls = varargin{ii+1};
                        case 'delays'
                            interpVals.delays = varargin{ii+1};
                        otherwise
                            error([varargin{ii} ' is not a valid argument name.']); 
                    end
                end
            end
                      
            %interp wavelengths
            if ischar(interpVals.wls) && ischar(interpVals.delays)  %this is a do nothing case
                % Assert correct input to ensure user isn't accidently doing something they're not aware of
                assert(strcmp(interpVals.wls,'all') && strcmp(interpVals.delays,'all'),...
                    'Expected all keyword or wavelength array of type double.');
                
            elseif isa(interpVals.wls,'double') && ischar(interpVals.delays)   %this does the wavelength trim       
                %ensure the user has correct input before trimming
                assert(isvector(interpVals.wls),'Wavelengths must be a vector');
                
                %load wavelengths
                wls = obj.wavelengths.data; %[wls, gpos]
                
                %ensure wavelengths are in increasing order and within the 
                %available wavelength range. For now, extrapolation is not allowed
                interpVals.wls = sort(interpVals.wls);
                interpVals.wls = interpVals.wls(and(interpVals.wls>min(wls(:)),interpVals.wls<max(wls(:))));
                nInterpWls = length(interpVals.wls);
                
                %for easy looping, do the following dim rearrangement:
                %[pixels, delays, rpts, gpos, schemes] -> [pixels, delays x rpts x schemes, gpos]
                tmpSpectra = permute(obj.spectra.data,[1,2,3,5,4]);
                tmpSpectra = reshape(tmpSpectra,obj.sizes.nPixels,[],obj.sizes.nGPos);
                
                %Allocate NaN double arrays and place spectra values into it 
                interpSpectra = zeros([nInterpWls,size(tmpSpectra,2),obj.sizes.nGPos]); %[interp pixels, delays x rpts x schemes, gpos]
                interpWls = nan([nInterpWls,obj.sizes.nGPos]); %[interp pixels, gpos]
               
                %loop over grating positions to sub-select range dicated by wlInd
                for ii = 1:obj.sizes.nGPos
                    %Interpolate for each grating position, which will have different wavelengths
                    isWlNaN = isnan(wls(:,ii)); %flag wavelengths that are NaN. interp1 requires numeric input (no NaN)
                    interpSpectra(:,:,ii) = interp1(wls(~isWlNaN,ii),tmpSpectra(~isWlNaN,:,ii),interpVals.wls);
                    
                    %Find values that were not set to NaN for extrapolation
                    isInterpWlNaN = all(isnan(interpSpectra(:,:,ii)),2);
                    interpWlsNoNaN = interpVals.wls(~isInterpWlNaN);
                    
                    %copy desired subrange for each grating position into the NaN arrays starting from index 1
                    interpWls(1:length(interpWlsNoNaN),ii) = interpWlsNoNaN;
                    interpSpectra(1:length(interpWlsNoNaN),:,ii) = interpSpectra(~isInterpWlNaN,:,ii);
                end
                
                %remove any dims that are all NaN. This happens when not all interpWls were used 
                %between two different grating positions
                isWlNaN = all(isnan(interpWls),2); %all wls are NaN for each gpos, delay, rpt, and scheme
                isGPosNaN = all(isnan(interpWls),1); %all wls are NaN for each wl, delay, rpt, and scheme
                interpWls = interpWls(~isWlNaN,~isGPosNaN); %[wls, gpos]
                interpSpectra = interpSpectra(~isWlNaN,:,~isGPosNaN); %[pixels, delays x rpts x schemes, gpos]
                trimmedGPos = obj.gPos(~isGPosNaN);
                
                %update sizes
                obj.sizes.nPixels = size(interpWls,1);
                obj.sizes.nGPos = length(trimmedGPos);
                
                %convert spectra back to original dimensions and dim order
                %[pixels, delays x rpts x schemes, gpos] -> [pixels, delays, rpts, gpos, schemes]
                interpSpectra = reshape(interpSpectra,obj.sizes.nPixels,obj.sizes.nDelays,obj.sizes.nRpts,obj.sizes.nSchemes,obj.sizes.nGPos); %[pixels, delays, rpts, schemes, gpos]
                interpSpectra = permute(interpSpectra,[1,2,3,5,4]); %[pixels, delays, rpts, gpos, schemes]
                
                %add data back to object
                obj.wavelengths.data = interpWls;
                obj.spectra.data = interpSpectra;
                obj.gPos = trimmedGPos;
                
            else
                error('Expected all keyword or wavelength range [wl1, wl2] of type double.');
            end
            
%             %trim delays
%             if ischar(interpVals.delays)  %this is a do nothing case
%                 % Assert correct input to ensure user isn't accidently doing something they're not aware of
%                 assert(strcmp(interpVals.delays,'all'),'Expected all keyword or delay range [d1, d2] of type double.');
%                 
%             elseif isa(interpVals.delays,'double')   %this does the wavelength trim
%                 %ensure the user has correct input before trimming
%                 assert(length(interpVals.delays)==2, 'Expected delay range [d1, d2] of type double.');
%                 interpVals.delays = sort(interpVals.delays);    %ensure delays are in increasing order
%                 
%                 %find the wavelength range indicies
%                 t = obj.delays.data(:);  %[delays x rpts x gPos]
%                 t = t(~isnan(t));
%                 t = sort(t);
%                 
%                 %select t subrange within (inclusive) the trim range
%                 t = t(and(t>=interpVals.delays(1),t <= interpVals.delays(2)));
%                 
%                 %select the object data subset that contains the trimmed t values
%                 obj = obj.subset('delays',t);
%                 
%             else
%                 error('Expected all keyword or delay range [d1, d2] of type double.');
%             end            
        end
        
        function obj = prune(obj, varargin)
% PRUNE sets selected bad data points to NaN. PRUNE can be run by
% specifying a prune string, followed by a cell array of data points to
% remove, or by specifying a logical array the same size as the object
% spectra being pruned.
%
% obj = obj.PRUNE(pruneRule, pruneData);
%
% obj = obj.PRUNE(logicalArray
            p = inputParser();
            
            p.addOptional('pruneRule','',@(s) ischar(s));
            p.addRequired('pruneData',@(c) iscell(c) || islogical(c));
            
            p.parse(varargin{:});
            
            % Format object array dims into a column for easy looping
            objSize = size(obj);
            objNumel = numel(obj);
            obj = obj(:);
            
            if ~iscell(p.Results.pruneData) || ~islogical(p.Results.pruneData{1})
                dimOrder = {'pixels','delays','rpts','gpos','schemes'};
                
                pruneStr = strsplit(p.Results.pruneRule);
                pruneData = p.Results.pruneData;
                
                logicalArray = cell(objSize);  %default value for logical array cell
                
                %determine pruneData nest depth
                nestDepth = 1;
                tmp = pruneData;
                isIndCell = cellfun('isclass',tmp,'cell');
                while any(isIndCell(:))
                    cellInd = find(isIndCell);
                    tmp = tmp{cellInd(1)};
                    isIndCell = cellfun('isclass',tmp,'cell');
                    nestDepth = nestDepth + 1;
                end
                
                %ensure that the pruneStr has an entry for each nest level
                assert(length(pruneStr)==nestDepth,['The nested levels in the cell tree must '...
                    'match the number of entries in the prune string. Nested levels: '...
                    num2str(nestDepth) ' Prune strings: ' num2str(length(pruneStr))]);
                
                if strcmp(pruneStr{1},'obj')
                    pruneStr = pruneStr(2:end); %remove obj from pruneStr
                    
                    %determine if pruneData explicitly specifies object index
                    isIndex = cellfun('isclass',pruneData,'double');  
                    if any(isIndex)    %explicit object index -- convert to implicit
                        
                    end
                    
                    %pruneData shold be a cell array the same size as obj and logical Array
                    
                else
                    %convert pruneData to specify object index as outermost cell
                    pruneData = p.Results.pruneData;
                end
                
                %convert pruneData to column for easy looping
                pruneData = pruneData(:);
                pruneNumel = numel(pruneData);
                
                %loop over prune object index
                for pruneInd = 1:pruneNumel
                    %initialize prune logical array. False means keep the
                    %data point, true means prune it (set to NaN)
                    logicalArray{pruneInd} = false(size(obj(pruneInd).spectra.data));
                    
                    %loop over nested levels
                    for ii = 1:nestDepth
                        
                    end
                end
                
                
            else
               logicalArray = p.Results.pruneData; 
               if ~iscell(logicalArray)
                   logicalArray = {logicalArray};
               end
            end
            
            %Prune object data
            for objInd = 1:objNumel
               %create local copy of spectra data for pruning
               tmpSpectra = obj(objInd).spectra.data;
               tmpSpectraStd = obj(objInd).spectra_std.data;
               
               %convert spectra data to column for easy indexing
               spectraSize = size(tmpSpectra);
               tmpSpectra = tmpSpectra(:);
               tmpSpectraStd = tmpSpectraStd(:);
               
               %depending on number of entries in logicalArray cell, set
               %specified indicies to NaN
               if length(logicalArray)==1
                   tmpSpectra(logicalArray{1}(:)) = NaN;
                   tmpSpectraStd(logicalArray{1}(:)) = NaN;
               else
                   tmpSpectra(logicalArray{objInd}(:)) = NaN;
                   tmpSpectraStd(logicalArray{objInd}(:)) = NaN;
               end
               
               %reassign reshaped pruned spectra back to object data
               obj(objInd).spectra.data = reshape(tmpSpectra,spectraSize);
               obj(objInd).spectra_std.data = reshape(tmpSpectraStd,spectraSize);
            end
            
        end
    end
    
    
end