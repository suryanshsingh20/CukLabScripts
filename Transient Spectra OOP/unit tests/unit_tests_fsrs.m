% This file constains unit tests for the transientSpectra class and 
% overriden methods in its subclasses

%% constructor tests
% construct default fsrs object
myFSRS = fsrs();

% NOTE FOR TEST DATA: I've dropped the timestamp in the file name so that 
% actual data is unique and does not get confused with test data while scripting

% load live tweaking gs FSRS data from a fsrs object
myGsFsrs = myFSRS.loadPath('OC_sample_1sp_GSraman_slit_closed.mat');

% load acquisition gs FSRS data from a fsrs object
myGsFsrs = myFSRS.loadPath('Sample_OC_D2O.mat');

% load acquisiton gs data acquired by an older version of the acquisition
% program (todo: add git SHA)
myGsFsrs = myFSRS.loadPath('Sample_None_Methanol.mat');

% load TR data acquired as part of a FSRS data set from a fsrs object
[myGsFsrs, myEsFsrs, myTR] = myFSRS.loadPath('Sample_BSP_Air.mat');
% only myTR should contain data: (todo implement equal methods)
%assert(myGsFsrs == fsrs(),'myGsFsrs is not a default fsrs object');
%assert(myEsFsrs == fsrs(),'myGsFsrs is not a default fsrs object');
%assert(myTR ~= fsrs(),'myTR is empty');

% load TR data acquired as part of a FSRS data set from a fsrs object using
% an alternative call method
[myGsFsrs, myEsFsrs, myTR] = loadPath(fsrs(),'Sample_BSP_Air.mat');

%% plotSpectra tests on a FSRS acquired TR data set (probe chirp test)
%load a TR data set that contains many delays but one repeat and one grating position:
[~,~,myTR] = loadPath(fsrs(),'Sample_BSP_Air.mat');

% plot all TR spectra data using the default options for plotSpectra()
figure;
myTR.plotSpectra();

% plot all TR spectra without the legend
figure;
myTR.plotSpectra('no legend');

% plot a delay subset of TR spectra in the delay vector. The option change
% uses a name-value pair
figure;
myTR.plotSpectra('delays',[0,0.5,1]+145.6);

% test if plotSpectra correctly removes non-unique delays
figure;
myTR.plotSpectra('delays',[0,0.001,0.5,1]+145.6);

% test if plotSpectra passes extra parameters to plot. '-k' is an otpional
% imput for plot() that tells to plot black solid lines
figure;
myTR.plotSpectra('delays',[0,0.5,1]+145.6,'-k');

%% test default plotSpectra behavior on data that contains multiple repeats and grating positions 
%load a test data set (live tweaking)
myFSRS = loadPath(fsrs(),'Sample_OC_D2O.mat');

% plot all FSRS spectra from acquisition data
figure;
myFSRS.plotSpectra();
ylim([-0.3 1]);
xlim([-1000 3500]);

% test changing units and plot FSRS spectra
myFSRS = myFSRS.setUnits('nm',[],'mOD');

figure;
myFSRS.plotSpectra();
ylim([-2 5]);
xlim([375 465]);

%% test updating the raman pump wavelength
myFSRS = loadPath(fsrs(),'Sample_OC_D2O.mat');
myFSRS.ramanPumpNm = 380;

figure;
myFSRS.plotSpectra();
ylim([-0.3 1]);
xlim([-500 4000]);

myFSRS = myFSRS.findRamanPumpNm(450);
figure;
myFSRS.plotSpectra();
ylim([-0.3 1]);
xlim([-1000 3500]);

%% test stiching multiple grating positions
myFSRS = loadPath(fsrs(),'Sample_OC_D2O.mat');
myFSRS = myFSRS.findRamanPumpNm(450);

figure; hold on;
myFSRS2 = myFSRS.stitch('average');
myFSRS2.plotSpectra('no legend');

myFSRS2 = myFSRS.stitch('lower');
myFSRS2.plotSpectra('no legend');

myFSRS2 = myFSRS.stitch('upper');
myFSRS2.plotSpectra('no legend');

myFSRS2 = myFSRS.stitch('half');
myFSRS2.plotSpectra('no legend');

myFSRS2 = myFSRS.stitch('linear');
myFSRS2.plotSpectra('no legend');

%default call test
myFSRS2 = myFSRS.stitch();

legend('average','lower','upper','half','linear');

ylim([-0.3 1]);
xlim([-1000 3500]);

%% plotTrace tests
%load a test data set (acquisition)
[~,~,myTR] = loadPath(fsrs(),'Sample_BSP_Air.mat');

figure;
myTR.plotTrace('wavelengths',[380,400,420,440]);
xlim([145 147]);

figure;
myTR.plotTrace('wavelengths',[350:5:500],'no legend');

%% Test trimming data
%spectra trim
myFSRS = loadPath(fsrs(),'Sample_OC_D2O.mat');
figure;
myFSRS = myFSRS.trim('wavelengths',[-5000 5000]);
myFSRS.plotSpectra('no legend');
myFSRS = myFSRS.trim('wavelengths',[-1000 1000]);
myFSRS.plotSpectra('no legend');

%delay trim
[~,~,myTR] = loadPath(fsrs(),'Sample_BSP_Air.mat');
figure;
myTR = myTR.trim('delays',[0,1000]);
myTR.plotTrace('wavelengths',[380,400,420,440],'no legend');
myTR = myTR.trim('delays',[140,155]);
myTR.wavelengths.unit = 'nm';
myTR.plotTrace('wavelengths',[380,400,420,440],'no legend');
%% Export tests
myFSRS = loadPath(fsrs(),'Sample_OC_D2O.mat');
outputStruct = myFSRS.export('');

%% All tests pass
disp('All tests passed!');