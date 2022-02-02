classdef fsrs < transientSpectra
    properties
        ramanPumpNm = 400;  %raman pump wavelength in nm
        %implement conversions methods
    end

    % Constructor, load, get and set methods with custom implementation
    methods
        %%CONSTRUCTOR/LOAD METHODS%%

        %use transientSpectra constructor. Matlab calls this implicitly
        
        %override superclass convertDH method to convert multi-scheme data
        %into specific scheme objects. Call this to load multiple objects
        function [objGsFsrs, objEsFsrs, objTR] = convertDH(obj, dh_static, dh_array)
            
            %call parent method first for generic conversion of dh_array to transientSpectra
            obj = convertDH@transientSpectra(obj, dh_static, dh_array);
            
            %add unit rules to spectra, delays, etc. todo: add to method
            obj.spectra = obj.spectra.addRule('mOD','\DeltaAbs. (mOD)',...
                                                @(f) 1e3*f, @(f) 1e-3*f);
            obj.spectra = obj.spectra.addRule('%Gain','Raman Gain (%)',...
                                                @(f) 1e2*(10.^f-1), @(f) log10(1+1e-2*f));
            obj.spectra = obj.spectra.addRule('ppmGain','Raman Gain (ppm)',...
                                                @(f) 1e6*(10.^f-1), @(f) log10(1+1e-6*f));
            
            obj.delays = obj.delays.addRule('fs','Delay (fs)',@(f) 1e3*f, @(f) 1e-3*f);
            obj.delays = obj.delays.addRule('ns','Delay (ns)',@(f) 1e-3*f, @(f) 1e3*f);
            obj.delays = obj.delays.addRule('us','Delay (\ms)',@(f) 1e-6*f, @(f) 1e6*f);
            
            obj.wavelengths = obj.wavelengths.addRule('um','Wavelength (\mm)',....
                                                        @(f) 1e3*f, @(f) 1e-3*f);
            obj.wavelengths = obj.wavelengths.addRule('eV','Energy (eV)',...
                                                        @(f) 1239.8./f, @(f) 1239.8./f);
            obj.wavelengths = obj.wavelengths.addRule('ecm-1','Wavenumber (cm^{-1})',...
                                                        @(f) 1e7./f, @(f) 1e7./f);
            obj.wavelengths = obj.wavelengths.addRule('rcm-1','Raman Shift (cm^{-1})',...
                                                        @(f) 1e7*(1/obj.ramanPumpNm-1./f),...
                                                        @(f) 1./(1/obj.ramanPumpNm-1e-7*f));
            
            %group various schemes into new objects
            schemeList = {'GS Raman','ES Raman','Transient Reflectance'};
            nSchemes = length(schemeList);
            tsArray = repmat(fsrs(),nSchemes,1);
            
            %todo: redesign how this works...
            for ii = 1:nSchemes
                loc = strcmp(obj.schemes,schemeList(ii));
                if any(loc)
                    tsArray(ii) = obj;
                    tsArray(ii).spectra = obj.spectra(:,:,:,:,loc);
                    tsArray(ii).spectra_std = obj.spectra(:,:,:,:,loc);
                end
            end
            
            %set output objects
            objGsFsrs = tsArray(1);
            objEsFsrs = tsArray(2);
            objTR = tsArray(3);
            
            %set output object units
            objGsFsrs = objGsFsrs.setUnits('rcm-1','ps','%Gain'); %change to raman shift, ps, and raman gain
            objEsFsrs = objGsFsrs.setUnits('rcm-1','ps','%Gain'); %change to raman shift, ps, and raman gain
            objTR = objTR.setUnits('eV','ps','mOD'); %change to raman shift, ps, and raman gain
            
        end
        
        %%GET/SET METHODS%% 
        
        %Set the raman pump nm. This updates the raman shift unit
        %definition, which is why it requires an explicit set method.
        function obj = set.ramanPumpNm(obj,newNm)
            obj.ramanPumpNm = newNm;
            %todo: figure out how to do this for all properties that might
            %have unit changes. Maybe cosmetic struct has .wavelengths,
            %.delays and .spectra properties
            obj.wavelengths = obj.wavelengths.updateRule('rcm-1','Raman Shift (cm^{-1})',...
                @(f) 1e7*(1/obj.ramanPumpNm-1./f),...
                @(f) 1./(1/obj.ramanPumpNm-1e-7*f));
        end
        
    end
    
    % Methods specific to the fsrs class that cannot be implemented in the transientSpectra class
    methods
        
        %Attempt to automatically find the raman pump wavelength
        function [obj, pumpNm] = findRamanPumpNm(obj, dropGPos)
            %Automatically finds the raman pump wavelength by trying two strategies: 
            %1) take the maximum point in each grating position in the fsrs object. 
            %2) try to resolve a peak and take the half way point of the fwhm as the 
            %   pump wavelelngth. 
            %The final pump wavelength is the average of all valid grating positions.
            %
            %Inputs:
            %   dropGPos: user input for grating positions that do not have an obvious 
            %   raman peak. todo: find automated way and make input optional
            %Outputs:
            %   obj: the fsrs object with updated pump wavelength and raman shift units
            %   pumpNm: the nm value of the new pump wavelength
        
            %remember old units
            tmpUnits = cell(3,1);
            [tmpUnits{:}] = obj.getUnits();
            
            %update units to units where x-axis is in nm and raman pump scatter is positive
            obj = obj.setUnits('nm',[],'%Gain');
            
            %get a single spectra by averaging over any extra dims except grating position (up to 5)
            data = permute(mean(obj.spectra.data,[2, 3, 5]),[1,4,2,3,5]); 
            
            %sort data and wavelengths by ascending order in grating position
            [gPosSorted,gInd] = sort(obj.gPos);
            data = data(:,gInd);
            lambda = obj.wavelengths.data(:,gInd);
            
            %find the raman pump peak (should be strongest signal)
            [val,maxInd] = max(data);
            
            %find pump peak fwhm while looping over sorted grating positions that do not get dropped
            pumpNm = NaN*zeros(1,obj.sizes.nGPos);
            for ii = 1:obj.sizes.nGPos
                %perform the fwhm routine only if the grating position is not dropped
                if ~any(dropGPos == gPosSorted(ii))
                    %find all "fwhm" intercepts in data. Sort in case lambda nm values
                    %are not sorted in ascending order.
                    intVals = sort(findGridIntercepts(lambda(:,ii),data(:,ii),val(ii)/2));

                    %Use the maximum point as an initial guess
                    pumpNm(ii) = lambda(maxInd(ii),ii);

                    %If two or more points are available, update initial guess
                    %as average of fwhm values
                    if length(intVals) > 1
                        lowPts = intVals(intVals<pumpNm(ii));  %intercepts lower in nm value than the peak
                        highPts = intVals(intVals>pumpNm(ii)); %intercepts higher in nm value than the peak
                        if ~isempty(lowPts) && ~isempty(highPts)  %if both a higher and lower point exist
                            pumpNm(ii) = (lowPts(end) + highPts(1))/2; %take the average to be the peak center
                        end
                    end
                end %dropped grating position
            end %for loop
            
            %average the results over non-dropped grating positions
            pumpNm = mean(pumpNm(~isnan(pumpNm)));
            
            %update the raman pump wavelength
            obj.ramanPumpNm = pumpNm;
            
            %set units back to input units
            obj = obj.setUnits(tmpUnits{:});
        end
        
    end
end