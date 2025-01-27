classdef wlTR < transientSpectra
   properties
       chirpParams = 0; % (vector double) a polfit vector fitting white light group delay vs. wavelength
   end
   
   properties (Access = protected)
       TRflag = struct('chirpFit',false);     
   end
   
   % Constructor method
   methods
       function obj = wlTR(varargin)
        % A WLTR object contains white-light transient reflectance-specific 
        % funtionality in addition to everything inside the transientSpectra class.
        % The main additional features are related to chirp correction and loading 
        % legacy TA binary and conditionList data.
        % 
        % obj = wlTR(__);
        %   Constructs a wlTR object with the same arguments as the transientSpectra
        %   constructor call.
        %
        % obj = wlTR(__, 'loadType', lType);
        %   Constructs a wlTR object with data imported from a file using the
        %   import method specified with the 'loadType' name-value pair. lType is a
        %   char array or cell of char arrays. Allowed values are:
        %       'dataHolder': loads a data holder .mat file created by the LabVIEW 
        %           MATLAB API using the new acquisition program
        %       'bin': loads a legacy TA binary file acquired by the old
        %           acquisition program
        %       'cListFile': loads a .mat file that is part of the legacy
        %           conditionList database
        %       'cListIndex': loads a file specified by conditionList index, where
        %           conditionList is a cell array inside dataList.mat. When using
        %           this loadType, the file path should navigate to the directory
        %           containing the dataList.mat file. Instead of specifying a .mat
        %           file, specify the index inside the conditionList cell array. 
        %           For example: 
        %            obj = wlTR('..\Phonon Removed\5','loadType','cListIndex'); 
        %           will load the data for the 5th entry in the phonon removed
        %           conditionList. Note that this loadType only works with full
        %           paths, so the .. in the example will have to be replaced with
        %           the full path for the phonon removed folder.
        %       
        % WLTR has the same units as transientSpectra.
        %
        % The default units for a wlTR object are mOD, ps, and nm
        %
        % See also: TRANSIENTSPECTRA, DOUBLEWITHUNITS
           
           % Currently, wlTR does not define additional constructor
           % functionality. Call the transientspectra superclass
           % constructor directly.
           obj@transientSpectra(varargin{:});
       end
   end
   
   % Methods that define the inner workings of the class
   methods (Access = 'protected')
        function obj = importData(obj,myPath,loadType)
        % IMPORTDATA loads a file from a path using the import method specified by
        % a load type and populates the objects member data. This method is 
        % designed to dispatch the correct import/load method and not implement a
        % specific import/load routine, therby allowing the developer to override 
        % import implementations in subclasses. 
        %
        % The wlTR class adds implementation for loading raw TA/TR binary files
        % generated by the older version of the LabVIEW TR Acquisition program and
        % for loading processed data stored in conditionList. ConditionList is a
        % database prototype that was used to log TR data acquired from 2019 to
        % 2021.
        %
        % obj = obj.LOADPATH(path, loadType);
        %   Loads data into the object from path depending on the load type. Load
        %   types that are supported for wlTR are:
        %   'cListFile': a .mat file that corresponds to a conditionList entry
        %   'cListIndex': a condition list index specified in path by:
        %       path = '..\index'. For example, '..\Phonon Removed\1' will load the
        %       first entry in conditionList in the ..\Phonon Removed\ path 
        %
        % See Also: TRANSIENTSPECTRA
        
            switch loadType
                case 'cListFile'
                    % Call the convertCList import method to convert a conditionList file to a wlTR object
                    obj = convertCList(obj,'file',myPath);
                case 'cListIndex'
                    % Call the convertCList import method to convert a conditionList index to a wlTR object
                    [myPath,ind] = fileparts(myPath); %extract the parent 
                    obj = convertCList(obj,'file',myPath,'index',str2double(ind));
                case 'bin'
                    % Call convertTABin importmethod to load and convert a TA bin file into a wlTR object
                    obj = convertTABin(obj,myPath);
                otherwise
                    % Call superclass importData method for loading a dataholder or handle unknown loadType
                    obj = importData@transientSpectra(obj,myPath,loadType);
            end
        end
        
        % Converts a conditionList file to a wlTR object
        obj = convertCList(obj,varargin)
   end
   
   % Data correction and manipulation methods
   methods
       
       function obj = setChirp(obj, chirpFit)
        % SETCHIRP sets the chirp parameters for every element in the object array.
        % This method accepts a *.mat file with a variable called chirpFit or a
        % polyval vector of chirp parameters.
        %
        % obj = obj.SETCHIRP(chirpVector)
        % obj = obj.SETCHIRP(filePath)
        %   Sets the chirp parameters for every element of obj
        %
        % See Also: fitChirp, correctChirp, polyval
           
           % User has an option to load chirp parameters from a .mat file
           if ischar(chirpFit)
              tmp = load(chirpFit);
              chirpFit = tmp.chirpFit;
           elseif ~isvector(chirpFit)
              error('chirpParams expected path or polyval vector.');
           end
           
           % Formtat object array dims into a column for easy looping
           objSize = size(obj);
           objNumel = numel(obj);
           obj = obj(:);
           
           %loop through each object and update chirp params
           for objInd = 1:objNumel
               obj(objInd).chirpParams = chirpFit;
           end
               
           %convert object back to original array dims
           obj = reshape(obj,objSize);
       end
       
       function obj = correctChirp(obj, varargin)
        % CORRECTCHIRP corrects the probe wavelength-dependent group delay (chirp)
        % by interpolating spectra data on a chirp-corrected delay. This
        % chirp-corrected delay is wavelength dependent and is determined by a
        % chirp correction polynomial. This polynomial is calculated by calling the
        % findChirp method. This polynomial is usually found from a seperate
        % calibration spectrum (e.g.high fluence OC with delays collected from
        % -3:0.1:3 ps). 
        %
        % Chirp correcion is applied as a wavelength-dependent offset for the
        % delay. This offset is calculated with respect to a reference wavelength,
        % which has zero offset. By default, this wavelength is the central
        % wavelength in each object element.
        %
        % obj = obj.CORRECTCHIRP()
        %   Interpolates spectral data inside obj using internally assigned chirp 
        %   paramters. This call uses the default options of using the center 
        %   wavelength as the reference wavelength and without any extrapolation.
        %
        % obj = obj.CORRECTCHIRP(varargin)
        %   Interpolates spectra data inside obj with additional name-value pair
        %   options.
        %
        % Name-Value Pairs
        %   'chirpParams': (vector double or char array) chirp parameters to be
        %       passed to the setChirp method. The value can either be a vector of 
        %       chirp parameters (as defined by polfit) or a path to a chirp 
        %       parameter .mat file.
        %   'wlRef': (char or scalar) the wavelength to use as the reference
        %       wavelength or a flag to calculate the reference wavelength. Allowed
        %       flags are: 'min', 'mid', or 'max' which choose the minimum, middle,
        %       or maximum wavelength in each object element. Default is 'mid'.
        %   'interp': (char) the interpolation method passed to griddedInterpolant.
        %       The default interpolation method is 'linear'.
        %   'extrap': (char) an extrapolation method passed to griddedInterpolant.
        %       The default extrapolation method is 'nearest'.
        %
        % See Also: FITCHIRP, SETCHIRP, GRIDDEDINTERPOLANT, POLYVAL
           
           % Format object array dims into a column for easy looping
           objSize = size(obj);
           objNumel = numel(obj);
           obj = obj(:);
           
           % Format varargin using input parser
           p = inputParser;
           p.FunctionName = 'correctChirp';
           p.addParameter('chirpParams', []);
           p.addParameter('wlRef','mid', @(p) (ischar(p) && any(strcmp(p,{'min','mid','max'})) || isscalar(p)));
           p.addParameter('interp','linear');
           p.addParameter('extrap','nearest');
           
           % Parse arguemnts, results will be in p.Results
           p.parse(varargin{:});
           
           % Setup a griddedInterpolant object with user defined interpolation and extrapolation
           F = griddedInterpolant();
           F.Method = p.Results.interp;
           F.ExtrapolationMethod = p.Results.extrap;
           
           % Assign external chirp parameters
           if ~isempty(p.Results.chirpParams)
               obj = obj.setChirp(p.Results.chirpParams);
           end
           
           % Loop over object array
           for objInd = 1:objNumel
               % Temporarily set units to match chirp correction polynomial
               tmpUnits = cell(3,1);
               [tmpUnits{:}] = obj(objInd).getUnits;
               obj(objInd) = obj(objInd).setUnits('nm','ps','');
               
               % Extract data for numerical processing
               s = obj(objInd).spectra.data;
               t = obj(objInd).delays.data;
               l = obj(objInd).wavelengths.data;
               
               % Determine what wavelength is the delay reference point wlRef
               if ischar(p.Results.wlRef)
                   switch p.Results.wlRef
                       case 'min'
                           wlRef = min(l,[],'all','omitnan');
                       case 'max'
                           wlRef = max(l,[],'all','omitnan');
                       case 'mid'
                           wlRef = mean([min(l,[],'all','omitnan'), max(l,[],'all','omitnan')]);
                       otherwise
                           error(['Expected min, max, or mid for wlRef, got ' wlRef '.']);
                   end
               else
                   wlRef = p.Results.wlRef;
               end
               
               % Convert array sizes of t and l to match the size of s for easy vectorization
               % s old: [pixels, delays, rpts, g pos, schemes]
               % s new: [pixels, delays, rpts x g pos x schemes]
               % t old: [delays, rpts, g pos]
               % t new: [delays, rpts x g pos x schemes]
               % l old: [pixels, g pos]
               % l new: [pixels, rpts x g pos x schemes]
               t = reshape(explicitExpand(t,sizePadded(s,2:5)),obj(objInd).sizes.nDelays,[]);
               l = reshape(explicitExpand(permute(l,[1,3,2]),sizePadded(s,[1 3:5])),obj(objInd).sizes.nPixels,[]);
               s = reshape(s,obj(objInd).sizes.nPixels,obj(objInd).sizes.nDelays,[]);
               
               % Evalaute t0 shifts by evaluation the polynomial at the reference point wlRef
               tRef = polyval(obj(objInd).chirpParams,wlRef);
               
               % loop over extra dims
               for ii = 1:size(s,3)
                   % MATLAB's griddedInterpolant requires that grid vectors are sorted
                   [t(:,ii), tI] = sort(t(:,ii));
                   [l(:,ii), lI] = sort(l(:,ii));
                   s(:,:,ii) = s(lI,tI,ii);
                   
                   % Updated the griddedInterpolant object with new vectors and data
                   % Update grid vectors, values, and evaluate on new grid
                   F.GridVectors = {l(:,ii), t(:,ii)};    %set interpolant grid
                   F.Values = s(:,:,ii);                  %set interpolant values
                   
                   % Define the new interpolation grid and evalaute interpolant
                   
                   % Define a new delay axis for each wavelength as a matrix first
                   tShift = t(:,ii)' + polyval(obj(objInd).chirpParams, l(:,ii))-tRef;
                   % Define the corresponding evaluation wavelength matrix
                   lEval = explicitExpand(l(:,ii),size(tShift));
                   
                   % Evaluate the interpolant on the (x,y) coordinate matrix by 
                   % reshaping tShift and lEval into column vectors, concatonating,
                   % and followed by reshaping back into pixel x delay
                   s(:,:,ii) = reshape(F([lEval(:), tShift(:)]),obj(objInd).sizes.nPixels, obj(objInd).sizes.nDelays);
                   
                   % Unsort the sorted dims
                   s(lI,tI,ii) = s(:,:,ii);  
               end
               
               % After for loop, undo reshape operation
               % s old: [pixels, delays, rpts x g pos x schemes]
               % s new: [pixels, delays, rpts, g pos, schemes]
               s = reshape(s, obj(objInd).sizes.nPixels, obj(objInd).sizes.nDelays, obj(objInd).sizes.nRpts, obj(objInd).sizes.nGPos, obj(objInd).sizes.nSchemes);

               % Assign interpolated spectra back to object data
               obj(objInd).spectra.data = s;
               
               %Change units back to original units
               obj(objInd) = obj(objInd).setUnits(tmpUnits{:});
           end
           
           %convert object array back to original size
           obj = reshape(obj,objSize);
       end
       
       function [obj,chirpFit] = fitChirp(obj,varargin) 
        % FITCHIRP attempts to extract the white light continuum group delay as a 
        % function of wavelength. The group delay is approximated with a polynomial
        % function (default: 5th order). The ideal data set is a high fluence OC 
        % spectra with finely spaced delay points (~100 fs) with a range of 
        % +/- 2 ps around t0.
        %
        % This method works by fitting a specified delay range (Default, -2 to 2 ps)
        % to an erf sigmoid for every wavelength in the dataset. The sigmoid's 
        % center vs. wavelength is then fit to a polynomial of specified order 
        % (default: 5th order).
        %
        % obj = obj.FITCHIRP()
        %   Extracts the WLC group delay vs. wavelength and fits the data to a 5th
        %   order polynomial.
        %
        % obj = obj.FITCHIRP(varargin)
        %   Extracts the WLC group delay vs. wavelengths and fits to a polynomial
        %   with the additional name-value pair options.
        %
        % [obj, chirpParam] = obj.FITCHIRP(__)
        %   Additionally returns array of size [polyOrder, objSize].
        %
        % Name-value pairs:
        %   'wavelengths': (double array) an array of wavelengths to subset the
        %      spectra to help speed up fitChirp. Default is to use all
        %      wavelengths.
        %   'delays': (double array) [lower, upper] a 1x2 array of delays to trim
        %      that limits the sigmoid fit range. Default is -2 to 2 ps.
        %   'order': (int) an integer > 0 that specifies the polynomial order of
        %      the group delay vs. wavelength. The default order is 5.
        %
        % See Also: CORRECTCHIRP, FINDT0, CORRECTT0, LSQFITSIGMOID,
        % POLYFIT, POLYVAL
           
           % Format object array dims into a column for easy looping
           objSize = size(obj);
           objNumel = numel(obj);
           obj = obj(:);
           
           % Format varargin using input parser
           p = inputParser;
           p.FunctionName = 'fitChirp';
           p.addParameter('wavelengths', []);
           p.addParameter('delays', [-2,2]);
           p.addParameter('order',5);
           
           % Parse arguemnts, results will be in p.Results
           p.parse(varargin{:});
           
           % Trim and subset object size to desired sub-range
           objTmp = obj.trim('delays',p.Results.delays);
           
           if ~isempty(p.Results.wavelengths)
               objTmp = objTmp.subset('wavelengths',p.Results.wavelengths);
           end
           
           % Set units to common values so that initial guess below can be
           % referenced in other data sets
           objTmp = objTmp.setUnits('nm','ps','mOD');
           
           % Average repeats and stitch grating position to make the
           % procedure below easier to run
           objTmp = objTmp.average();
           objTmp = objTmp.stitch();
           
           % Initialize chirpFit output
           chirpFit = zeros(p.Results.order+1, objNumel);
           
           % Start waitbar
           f = waitbar(0,['Fitting group delay for spectra 1 of ' num2str(objNumel)]);
           
           % Loop over individual object elements
           for objInd = 1:objNumel
               % Update waitbar
               waitbar(0,f,['Fitting group delay for spectra ' num2str(objInd) ' of ' num2str(objNumel)]);
               
               % Extract spectra data from object and use locally
               data = objTmp(objInd).spectra.data; %[wls,delays]
               wl = objTmp(objInd).wavelengths.data; %[wls,1]
               t = objTmp(objInd).delays.data;  %[delays,1]
               
               % Initialize sigmoid fit parameter matrix
               myFP = zeros(length(wl),4);
               
               % Loop over wavelengths
               for wlInd = 1:length(wl)
                   % Update waitbar
                   waitbar(wlInd/length(wl),f);
                   
                   % Do the least squares fit using the lsqsigmoid fit
                   myFP(wlInd,:) = lsqFitSigmoid(t, data(wlInd,:));
               end
               
               % Once the sigmoid fit is done, find the chirp parameters
               % and update object data
               chirpFit(:,objInd) = polyfit(wl,myFP(:,3),p.Results.order);
               obj(objInd).chirpParams = chirpFit(:,objInd);
               
               % Plot resuls
               % todo: make an option to display (and possibly log?) results
               figure;
                    contour(wl,t,data',25);
                    hold on;
                    p1 = plot(wl,myFP(:,3),'r','DisplayName','sigmoid t0');
                    p2 = plot(wl,polyval(chirpFit(:,objInd),wl),'k--','DisplayName','polynomial');
                    hold off;
                    
               xlabel('Wavelength (nm)');
               ylabel('Delay (ps)');
               legend([p1,p2]);
               colorbar();
           end
           
           close(f);
           
           %convert object array back to original size
           obj = reshape(obj,objSize);
           chirpFit = reshape(chirpFit, [p.Results.order+1,objSize]);
       end
       
%        function [obj, phononObj] = fitPhonons(obj, phononModel)
%            
%        end
%        
%        function obj = removePhonons(obj, varargin)
%            
%        end
   end
end