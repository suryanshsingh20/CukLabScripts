%% Load test data set
% Test cListFile import
myTR = wlTR('0V pH 13 IS 100 mM.mat','loadType','cListFile','shortName','0 V pH 13 fs');

% Test cListIndex import
% Get conditionList file path (note fullfile returns path with
% system-specific file seperator, i.e. linux, macOS, windows...
cListPath = fullfile(fileparts(matlab.desktop.editor.getActiveFilename),'sample data','TR','ConditionList');

% load one cListIndex from Avgd Combined Only folder
myTR = wlTR(fullfile(cListPath, 'Avgd Combined Only','44'),'loadType','cListIndex');

% load two cListIndex from Phonon Removed folder
myTR = wlTR(fullfile(cListPath, 'Phonon Removed',{'107','108'}),'loadType','cListIndex');

% Test TABin import
myTR = wlTR({'19-12-05_13h56m05s_0p04Fl_0V_pH13_100mM_630nm_cont_0-2ns_spol',...
    '19-12-05_14h53m12s_0p04Fl_0V_pH13_100mM_460nm_cont_0-2ns_spol'},'loadType','bin');
%% findT0 tests
testData = wlTR('22-07-28_15h03m26s_OC_chirp_calibration_W_Water.mat','shortName','chirp');

%flip sign
testData.spectra.data = -testData.spectra.data;

%test without stitching
[~,t0] = testData.findT0;
t0 = t0{1};
assert(all(size(t0)==[1,1,2]),'Incorrect t0 size');
assert(all(t0 > 0.5) & all(t0 < 0.7),'Could not find correct t0');

%test with stitching
testData = testData.stitch;

[~,t0] = testData.findT0;
t0 = t0{1};
assert(all(size(t0)==[1,1]),'Incorrect t0 size');
assert((t0 > 0.5) & (t0 < 0.7),'Could not find correct t0');

%test actual multi-d data with repeats
testData = wlTR('22-07-22_20h36m26s_Sample_W_pH_12100mMNa.mat','shortName','pH 12');
[~,t0] = testData.findT0;
t0 = t0{1};
assert(all(size(t0)==[1,4,2]),'Incorrect t0 size');
assert(all(t0 > 0.5,'all') & all(t0 < 0.7,'all'),'Could not find correct t0');

%test with stitch and average
testData = testData.average;
testData = testData.stitch;
[~,t0] = testData.findT0;
t0 = t0{1};
assert(all(size(t0)==[1,1]),'Incorrect t0 size');
assert((t0 > 0.5) && (t0 < 0.7),'Could not find correct t0');

%% correctT0 tests
testData = wlTR('22-07-22_20h36m26s_Sample_W_pH_12100mMNa.mat','shortName','chirp');
testData = testData.trim('delays',[-2,2]);

figure;
testData.plotKinetics('wavelengths',540);
hold on;

testData = testData.correctT0('average',false);
testData.plotKinetics('wavelengths',540);
hold off;

assert(all(size(testData.t0.data)==[1,4,2]),'Incorrect obj.t0 size');

testData = wlTR('22-07-22_20h36m26s_Sample_W_pH_12100mMNa.mat','shortName','chirp');
testData = testData.trim('delays',[-2,2]);

figure;
testData.plotKinetics('wavelengths',540);
hold on;

testData = testData.correctT0();
testData.plotKinetics('wavelengths',540);
hold off;

assert(all(size(testData.t0.data)==[1,1]),'Incorrect obj.t0 size');

%% Find and correct t0 with non-default params
testData = transientSpectra('22-06-29_12h07m46s_Sample_V_pH_1210mMNa');
% Cosmetic pre-processing
% size: [pixels, delays, rpts, grating pos, schemes]
pruneLogical = false(size(testData.spectra.data));
pruneLogical(:,:,[2,3,4],1,:) = true;
pruneLogical(:,:,3,2,:) = true;
testData = testData.prune(~pruneLogical);

testData = testData.stitch;
testData = testData.average;

[testData, t0] = testData.findT0('tRange',[-5000 10000]);
testData = testData.correctT0;

figure; testData.plotKinetics('wavelengths',560);
xlim([-5e3 10e3]);
%% fit chirp tests
testData = wlTR('22-07-28_15h03m26s_OC_chirp_calibration_W_Water.mat','short name','chirp');

testData = testData.stitch();
testData = testData.subset('wavelengths',375:5:725);

[testData, chirpParam] = testData.fitChirp();

testData = wlTR('22-07-28_15h03m26s_OC_chirp_calibration_W_Water.mat','short name','chirp');

[testData, chirpParam] = testData.fitChirp('order',7,'wavelengths',365:5:735,'delays',[-3,3]);

%% correct chirp tests
testData = wlTR('22-07-28_15h03m26s_OC_chirp_calibration_W_Water.mat','short name','chirp');

testData = testData.fitChirp('order',7,'wavelengths',365:5:735,'delays',[-3,3]);

%%
% Test chirp correction with multi-d data set
testData2 = testData.correctChirp();
testData2 = testData2.average();
testData2 = testData2.stitch();
figure; 
contourf(testData2.wavelengths.data, testData2.delays.data, testData2.spectra.data');

% Test chirp correction with different central wavelengths:
testData2 = testData.average();
testData2 = testData2.stitch();
testData3 = testData2.correctChirp('wlRef','min');
figure; 
contourf(testData3.wavelengths.data, testData3.delays.data, testData3.spectra.data');

testData3 = testData2.correctChirp('wlRef','max');
figure; 
contourf(testData3.wavelengths.data, testData3.delays.data, testData3.spectra.data');

testData3 = testData2.correctChirp('wlRef',400);
figure; 
contourf(testData3.wavelengths.data, testData3.delays.data, testData3.spectra.data');
%% Generate test data for CC chirp correction
% Test different interpolation and extrapolation strategies
testData = wlTR('22-07-28_15h03m26s_OC_chirp_calibration_W_Water.mat','short name','chirp');
testData = testData.fitChirp('order',7,'wavelengths',365:5:735,'delays',[-3,3]);

testData2 = wlTR('22-07-22_20h36m26s_Sample_W_pH_12100mMNa.mat','short name','chirp');
testData2 = testData2.trim('delays',[-3,3]);
testData2.chirpParams = testData.chirpParams;
%% Test different interpolation and extrapolation strategies
testData3 = testData2.correctChirp('interp','spline');
testData3 = testData2.correctChirp('extrap','extrap');
testData3 = testData2.correctChirp('extrap',0);
testData3 = testData2.correctChirp('extrap','none');
testData3 = testData3.average;
testData3 = testData3.stitch;

figure; 
contour(testData3.wavelengths.data, testData3.delays.data, -testData3.spectra.data',[-3:0.1:2]);

%% Set chirp parameters using setChirp
testData = wlTR('22-07-28_15h03m26s_OC_chirp_calibration_W_Water.mat','short name','chirp');
testData = testData.fitChirp('order',7,'wavelengths',365:5:735,'delays',[-3,3]);

% chirp param from vector
testData2 = wlTR('22-07-22_20h36m26s_Sample_W_pH_12100mMNa.mat','short name','chirp');
testData2 = testData2.setChirp(testData.chirpParams);
assert(all(testData2.chirpParams == testData.chirpParams),'Failed to set chirp params.');

% chirp param from file
testData2 = testData2.setChirp('chirpFitParam20Dec01.mat');
assert(length(testData2.chirpParams)==8,'Failed to set chirp params.');